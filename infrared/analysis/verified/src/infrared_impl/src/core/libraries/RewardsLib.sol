// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {IRewardVault as IBerachainRewardsVault} from
    "@berachain/pol/interfaces/IRewardVault.sol";

import {IInfraredDistributor} from "src/interfaces/IInfraredDistributor.sol";
import {IBerachainBGTStaker} from "src/interfaces/IBerachainBGTStaker.sol";
import {IInfraredVault} from "src/interfaces/IInfraredVault.sol";
import {ConfigTypes} from "src/core/libraries/ConfigTypes.sol";
import {IBerachainBGT} from "src/interfaces/IBerachainBGT.sol";
import {IInfraredV1_10 as IInfrared} from "src/interfaces/IInfraredV1_10.sol";
import {IWBERA} from "src/interfaces/IWBERA.sol";
import {IInfraredBGT} from "src/interfaces/IInfraredBGT.sol";
import {IInfraredBERA} from "src/depreciated/interfaces/IInfraredBERA.sol";
import {Errors} from "src/utils/Errors.sol";

/// @dev Minimal probe interface for reading the active reward token from a
///      Berachain RewardVault. Neither the legacy nor vnext upstream interface
///      declares this view, but both concrete contracts expose it (legacy ABI
///      `IERC20 public rewardToken`; vnext `function rewardToken() returns
///      (IERC20)`). Used to discriminate the BGT-paying vs WBERA-paying path
///      in the unified harvest view.
interface IRewardVaultTokenProbe {
    function rewardToken() external view returns (address);
}

library RewardsLib {
    using SafeTransferLib for ERC20;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       STORAGE TYPE                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // @notice Storage for all reward accumulators and configurations
    // @notice protocolFeeAmounts Tracks accumulated protocol fees per token so that the protocol can claim them at a later time
    // @notice irMintRate         Rate for minting IR tokens at a rate of BGT to IR in hundredths of 1 bip (1e6)
    // @notice bribeSplitRatio    Ratio for splitting received bribes to the iBERA and IBGT product, weighted towards iBERA, ie iBGT weight = (UNIT_DENOMINATOR - bribeSplitRatio))
    // @notice fees               Mapping of fee rates for different fee types
    struct RewardsStorage {
        mapping(address => uint256) protocolFeeAmounts;
        uint256 irMintRate;
        uint256 bribeSplitRatio;
        mapping(uint256 => uint256) fees;
        uint256 irSplitRatio;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CONSTANTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Unit denominotor for calculating all fees and rates in the system
     * @dev All fees and rates are calculated out of 1e6
     */
    uint256 internal constant UNIT_DENOMINATOR = 1e6;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              VNEXT SELF-FETCH HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev External library calls run via DELEGATECALL, so `address(this)`
    ///      inside this library is the calling Infrared contract. We can
    ///      therefore read its public `wbera()` / `ibera()` getters back
    ///      out without expanding the legacy selectors with new parameters
    ///      — preserving the live V1_10 ABI while adding vnext semantics.
    function _wberaAndIbera()
        internal
        view
        returns (address wbera, address ibera)
    {
        wbera = address(IInfrared(address(this)).wbera());
        ibera = address(IInfrared(address(this)).ibera());
    }

    /// @dev Sweep WBERA accrued on Infrared (base + commission from the vnext
    ///      `BlockRewardController`) to iBERA's receivor. Subtracts the
    ///      `protocolFeeAmounts[wbera]` accumulator so we never sweep WBERA
    ///      that bribes have already earmarked as protocol revenue. Read
    ///      via the public getter so we don't have to thread storage `$`
    ///      through legacy selectors.
    function _sweepWberaToReceivor(address ibera) internal returns (uint256) {
        address wbera = address(IInfrared(address(this)).wbera());
        uint256 balance = ERC20(wbera).balanceOf(address(this));
        uint256 reserved = IInfrared(address(this)).protocolFeeAmounts(wbera);
        if (balance <= reserved) return 0;
        uint256 amt = balance - reserved;

        IWBERA(wbera).withdraw(amt);
        address receivor = IInfraredBERA(ibera).receivor();
        (bool ok,) = receivor.call{value: amt}("");
        if (!ok) revert Errors.ETHTransferFailed();
        return amt;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       FEES                                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Harvest rewards given to our operators for setting their cuttingboard weights
    /// ref - https://github.com/infrared-dao/infrared-contracts/blob/develop/src/staking/InfraredBERAFeeReceivor.sol#L83
    /// @param $                The storage pointer for all rewards accumulators
    /// @param ibera            The address of the InfraredBERA token
    /// @param distributor      The address of the distributor
    ///
    /// @return amountOperators            The amount of rewards harvested
    function harvestOperatorRewards(
        RewardsStorage storage $,
        address ibera,
        address distributor
    ) external returns (uint256 amountOperators) {
        // Compound + Collect, syncing the iBERA rewards to latest.
        IInfraredBERA(ibera).compound();
        uint256 iBERAShares = IInfraredBERA(ibera).collect();
        if (iBERAShares == 0) return 0;

        // The total fee rate to charge on iBERA harvest rewards.
        uint256 feeTotal =
            $.fees[uint256(ConfigTypes.FeeType.HarvestOperatorFeeRate)];

        /// The amount of rewards going to the protocol treasury
        uint256 amountProtocol;
        (amountOperators, amountProtocol) =
            chargedFeesOnRewards(iBERAShares, feeTotal);

        // Distribute the fees for the protocol and voter amounts.
        _distributeFeesOnRewards($.protocolFeeAmounts, ibera, amountProtocol);

        // Send the rewards owed to the operators to the distributor.
        if (amountOperators > 0) {
            ERC20(ibera).safeApprove(distributor, amountOperators);
            IInfraredDistributor(distributor).notifyRewardAmount(
                amountOperators
            );
        }
    }

    /// @notice Generic function to calculate the fees charged on rewards, returning the amount owed to the recipient and protocol.
    /// @notice the recipient is the amount of rewards being sent forward into the protocol for example a vault
    /// @param  amount          The amount of rewards to calculate fees on
    /// @param  totalFeeRate    The total fee rate to charge on rewards (protocol + voter)
    /// @return recipient       The amount of rewards to send to the recipient
    /// @return protocolFees    The amount of rewards to send to the protocol
    function chargedFeesOnRewards(uint256 amount, uint256 totalFeeRate)
        public
        pure
        returns (uint256 recipient, uint256 protocolFees)
    {
        // if the total fee charged is 0, return the amount as is and 0 for the rest
        if (totalFeeRate == 0) return (amount, 0);

        // calculate the total fees to be charged = amount * totalFeeRate
        protocolFees = (amount * totalFeeRate) / UNIT_DENOMINATOR;

        // deduct the total fees from the amount to get the recipient amount
        recipient = amount - protocolFees;
    }

    /// @notice Distributes fees on rewards to the protocol, voter, and recipient.
    /// @notice _protocolFeeAmounts The accumulator for protocol fees per token
    /// @notice _token              The address of the reward token
    /// @notice _amtProtocol        The amount of rewards for the protocol
    function _distributeFeesOnRewards(
        mapping(address => uint256) storage protocolFeeAmounts,
        address _token,
        uint256 _amtProtocol
    ) internal {
        // add protocol fees to accumulator for token
        protocolFeeAmounts[_token] += _amtProtocol;

        emit IInfrared.ProtocolFees(_token, _amtProtocol, 0);
    }

    /// @notice Handles non-InfraredBGT token rewards to the vault.
    /// @param $            RewardsStorage  The storage pointer for all rewards accumulators.
    /// @param _vault       IInfraredVault   The address of the vault.
    /// @param _token       address          The reward token.
    /// @param _amount      uint256          The amount of reward token to send to vault.
    /// @param _feeTotal    uint256          The rate to charge for total fees on `_amount`.
    /// @param rewardsDuration uint256        The duration of the rewards.
    function _handleTokenRewardsForVault(
        RewardsStorage storage $,
        IInfraredVault _vault,
        address _token,
        uint256 _amount,
        uint256 _feeTotal,
        uint256 rewardsDuration
    ) internal {
        if (_amount == 0) return;

        // add reward if not already added
        (, uint256 _vaultRewardsDuration,,,,,) = _vault.rewardData(_token);
        if (_vaultRewardsDuration == 0) {
            _vault.addReward(_token, rewardsDuration);
        }

        uint256 _amtProtocol;

        // calculate and distribute fees on rewards
        (_amount, _amtProtocol) = chargedFeesOnRewards(_amount, _feeTotal);
        _distributeFeesOnRewards($.protocolFeeAmounts, _token, _amtProtocol);

        // increase allowance then notify vault of new rewards
        if (_amount > 0) {
            ERC20(_token).safeApprove(address(_vault), _amount);
            _vault.notifyRewardAmount(_token, _amount);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ADMIN                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Delegates Berachain Governance Voting Power to a delegatee
    /// @param _delegatee The address to delegate voting power to
    /// @param bgt        The address of the BGT token
    function delegateBGT(address _delegatee, address bgt) external {
        IBerachainBGT(bgt).delegate(_delegatee);
    }

    /// @notice Update the split ratio for iBERA and iBGT rewards
    /// @param $           The storage pointer for all rewards accumulators
    /// @param _split The ratio for splitting received bribes to be iBERA and iBGT, weighted towards iBERA
    function updateInfraredBERABribeSplit(
        RewardsStorage storage $,
        uint256 _split
    ) external {
        if (_split > UNIT_DENOMINATOR) revert Errors.InvalidWeight();
        $.bribeSplitRatio = _split;
    }

    /// @notice Update the split ratio for IR and iBGT rewards
    /// @param $           The storage pointer for all rewards accumulators
    /// @param _split The ratio for splitting iBGT Vault rewards to IR, weighted towards IR
    function updateIRSplit(RewardsStorage storage $, uint256 _split) external {
        if (_split > UNIT_DENOMINATOR) revert Errors.InvalidWeight();
        $.irSplitRatio = _split;
    }

    /// @notice Update the fee rate for a given fee type
    /// @param $           The storage pointer for all rewards accumulators
    /// @param _t          The fee type to update
    /// @param _fee        The new fee rate
    function updateFee(
        RewardsStorage storage $,
        ConfigTypes.FeeType _t,
        uint256 _fee
    ) external {
        if (_fee > UNIT_DENOMINATOR) revert Errors.InvalidFee();
        $.fees[uint256(_t)] = _fee;
    }

    /// @notice Claim protocol fees for a given token
    /// @param $           The storage pointer for all rewards accumulators
    /// @param _to         The address to send the protocol fees to
    /// @param _token      The token to claim protocol fees for
    function claimProtocolFees(
        RewardsStorage storage $,
        address _to,
        address _token
    ) external returns (uint256 _amountClaimed) {
        _amountClaimed = $.protocolFeeAmounts[_token];
        delete $.protocolFeeAmounts[_token];

        ERC20(_token).safeTransfer(_to, _amountClaimed);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       HARVEST Functions                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Harvet's base rewards from the BGT contract, ie rewards from Distributor, given in BGT
    ///     ref - https://github.com/berachain/contracts-monorepo/blob/main/src/pol/rewards/Distributor.sol#L160
    /// @notice The BGT accumilates in the contract, therfore can check balance(this) since all other BGT rewards are claimed and harvested atomically
    /// @notice Reward paid out to validators proposing a block, MUST be forwarded to IBERA.receivor, the fees are handled there. TODO: Link here.
    /// @param ibgt     The address of the InfraredBGT toke
    /// @param bgt      The address of the BGT token
    /// @param ibera    The address of the InfraredBERA token
    ///
    /// @return bgtAmt  The amount of BGT rewards harvested
    /// @notice Harvest base + commission rewards via the legacy BGT redeem
    ///         path **and** sweep accrued WBERA from the vnext emission stream
    ///         to iBERA's receivor — both legs are now executed by every call
    ///         to this selector so the live `InfraredV1_10` wrapper does not
    ///         need to change.
    /// @dev    BGT leg: unchanged — redeems accrued BGT for BERA to the iBERA
    ///         receivor (BERA-backing-aware via the existing try/catch).
    /// @dev    WBERA leg: sweeps `balanceOf(this) - protocolFeeAmounts[wbera]`,
    ///         unwraps, and forwards as native BERA to the iBERA receivor.
    ///         Subtracting the protocol-fee accumulator guarantees we never
    ///         sweep WBERA earmarked by the bribe pipeline. Keepers must run
    ///         `harvestBribes` → `collector.claimFees` → `collectBribes`
    ///         before this call so no bribe-WBERA lingers when the sweep fires.
    /// @dev    Return value is `bgtAmt + wberaAmt`. Pre-fork only the BGT leg
    ///         contributes; post-fork only the WBERA leg does. The event slot
    ///         named `_bgtAmt` on `IInfraredV1_10.BaseHarvested` thus carries
    ///         BERA-equivalent units after the vnext flip.
    function harvestBase(address ibgt, address bgt, address ibera)
        external
        returns (uint256 bgtAmt)
    {
        uint256 minted = IInfraredBGT(ibgt).totalSupply();
        uint256 balance = IBerachainBGT(bgt).balanceOf(address(this));
        // Guard the subtraction: post-fork (and mid-decommission as boosts are
        // dropped) iBGT supply can exceed free BGT balance, which would
        // underflow `balance - minted` and revert the whole call — blocking
        // the WBERA sweep below. Treat that case as "no redeemable excess".
        if (balance > minted) {
            uint256 redeemable = balance - minted;
            if (redeemable > 0 && redeemable <= bgt.balance) {
                try IBerachainBGT(bgt).redeem(
                    IInfraredBERA(ibera).receivor(), redeemable
                ) {
                    bgtAmt = redeemable;
                } catch {
                    // BERA backing not available — leave BGT in place, retry next cycle.
                }
            }
        }

        bgtAmt += _sweepWberaToReceivor(ibera);
    }

    /// @notice Alternative to Harvet base rewards, auctioning iBGT on harvestBaseCollector, from BGT rewards from Distributor
    ///     ref - https://github.com/berachain/contracts-monorepo/blob/main/src/pol/rewards/Distributor.sol#L160
    /// @notice The BGT accumilates in the contract, therfore can check balance(this) since all other BGT rewards are claimed and harvested atomically
    /// @param ibgt     The address of the InfraredBGT toke
    /// @param bgt      The address of the BGT token
    /// @param harvestBaseCollector The address of the harvestBaseCollector contract
    /// @return bgtAmt  The amount of BGT rewards harvested
    /// @dev BGT leg unchanged. WBERA leg appended so the auction-mode path
    ///      sweeps base + commission WBERA to iBERA's receivor on the same
    ///      call, matching `harvestBase`. Selector preserved.
    function auctionBase(
        address ibgt,
        address bgt,
        address harvestBaseCollector
    ) external returns (uint256 bgtAmt) {
        uint256 minted = IInfraredBGT(ibgt).totalSupply();
        uint256 balance = IBerachainBGT(bgt).balanceOf(address(this));
        // Guard the subtraction (see `harvestBase`): underflow here would
        // revert before the WBERA sweep runs.
        if (balance > minted) {
            bgtAmt = balance - minted;
            IInfraredBGT(ibgt).mint(harvestBaseCollector, bgtAmt);
        }

        address ibera = address(IInfrared(address(this)).ibera());
        bgtAmt += _sweepWberaToReceivor(ibera);
    }

    /// @notice Harvests the accrued vault rewards. Handles both the legacy BGT
    ///         payout and the vnext WBERA payout in a single call: pre-migration
    ///         only the BGT delta is non-zero, post-migration only the WBERA
    ///         delta is, and during the per-vault lazy switch both can be.
    /// @dev    vnext `_safeTransferRewardToken` (`RewardVault.sol:600-604`)
    ///         can deliver BGT and WBERA in the same `getReward` call.
    ///         Measuring both balance deltas catches every reward dollar
    ///         regardless of which side of the switch the vault is on.
    /// @dev    Selector is preserved from the legacy V1_10 surface so the
    ///         live `InfraredV1_10` caller does not need to change. The
    ///         `wbera` and `ibera` addresses are fetched from the calling
    ///         contract via `IInfrared(address(this))`, which works because
    ///         external library calls run via DELEGATECALL — `address(this)`
    ///         inside the library is the Infrared proxy.
    /// @dev    The single returned `bgtAmt` is a BERA-equivalent total of
    ///         the BGT rewards harvested **plus** the iBERA shares minted
    ///         from the WBERA leg. The naming is preserved for ABI/event
    ///         compatibility; the unit can mean iBERA-shares post-migration.
    /// @return bgtAmt BGT + iBERA-shares total (see unit note above).
    function harvestVault(
        RewardsStorage storage $,
        IInfraredVault vault,
        address bgt,
        address ibgt
    ) external returns (uint256 bgtAmt) {
        if (vault == IInfraredVault(address(0))) {
            revert Errors.VaultNotSupported();
        }

        bgtAmt = _harvestRewardsVaultTo($, vault, vault, bgt, ibgt);
    }

    /// @dev Shared harvest body for `harvestVault` / `harvestOldVault`:
    ///      claims the underlying Berachain `rewardsVault` for `from`, measures
    ///      both BGT and WBERA balance deltas, and routes each non-zero leg
    ///      into `to` via `_handleTokenRewardsForVault` (which self-registers
    ///      the reward token on the destination vault when missing). The two
    ///      route helpers below keep the per-leg stack footprint small —
    ///      inlining both branches here trips solc's stack-too-deep.
    function _harvestRewardsVaultTo(
        RewardsStorage storage $,
        IInfraredVault from,
        IInfraredVault to,
        address bgt,
        address ibgt
    ) internal returns (uint256 bgtAmt) {
        (address wbera, address ibera) = _wberaAndIbera();

        uint256 bgtBefore = IBerachainBGT(bgt).balanceOf(address(this));
        uint256 wberaBefore = ERC20(wbera).balanceOf(address(this));

        from.rewardsVault().getReward(address(from), address(this));

        uint256 bgtDelta =
            IBerachainBGT(bgt).balanceOf(address(this)) - bgtBefore;
        uint256 wberaDelta = ERC20(wbera).balanceOf(address(this)) - wberaBefore;

        if (bgtDelta > 0) _routeBgtRewardsToVault($, to, ibgt, bgtDelta);
        uint256 iberaShares;
        if (wberaDelta > 0) {
            iberaShares =
                _routeWberaRewardsToVault($, to, wbera, ibera, wberaDelta);
        }
        // BERA-equivalent return — see function-level comment.
        bgtAmt = bgtDelta + iberaShares;
    }

    /// @dev BGT branch: mint iBGT, then defer to `_handleTokenRewardsForVault`
    ///      so the destination vault self-registers iBGT if it isn't already
    ///      a reward token there (a no-op for normal vaults — the InfraredVault
    ///      constructor pre-registers iBGT — but cheap insurance for migration
    ///      and transitional paths).
    function _routeBgtRewardsToVault(
        RewardsStorage storage $,
        IInfraredVault vault,
        address ibgt,
        uint256 bgtAmt
    ) internal {
        IInfraredBGT(ibgt).mint(address(this), bgtAmt);
        _handleTokenRewardsForVault(
            $,
            vault,
            ibgt,
            bgtAmt,
            $.fees[uint256(ConfigTypes.FeeType.HarvestVaultFeeRate)],
            IInfrared(address(this)).rewardsDuration()
        );
    }

    /// @dev WBERA branch: unwrap, mint iBERA, then defer to
    ///      `_handleTokenRewardsForVault`. The self-registering `addReward`
    ///      inside the helper is what makes transitional / freshly-migrated
    ///      vaults (which have iBGT pre-registered but not iBERA) accept the
    ///      vnext WBERA-emission leg without an out-of-band governance call.
    ///      The notified reward token is raw iBERA.
    function _routeWberaRewardsToVault(
        RewardsStorage storage $,
        IInfraredVault vault,
        address wbera,
        address ibera,
        uint256 wberaAmt
    ) internal returns (uint256 iberaShares) {
        iberaShares = _wberaToIbera(wbera, ibera, wberaAmt);
        _handleTokenRewardsForVault(
            $,
            vault,
            ibera,
            iberaShares,
            $.fees[uint256(ConfigTypes.FeeType.HarvestVaultFeeRate)],
            IInfrared(address(this)).rewardsDuration()
        );
    }

    /// @dev Convert a WBERA reward amount into the reward token distributed to
    ///      stakers: unwrap WBERA to native BERA and mint iBERA, returning the
    ///      minted iBERA shares. Centralizes the conversion shared by the vault
    ///      and per-user harvest legs. The distributed reward token is raw
    ///      iBERA. iBERA is read from the calling Infrared contract
    ///      (DELEGATECALL — `address(this)` is the proxy), matching the
    ///      `_wberaAndIbera()` self-fetch convention.
    /// @return iberaShares The amount of iBERA minted from `wberaAmt`.
    function _wberaToIbera(address wbera, address ibera, uint256 wberaAmt)
        internal
        returns (uint256 iberaShares)
    {
        IWBERA(wbera).withdraw(wberaAmt);
        iberaShares = IInfraredBERA(ibera).mint{value: wberaAmt}(address(this));
    }

    /// @notice Harvests a Berachain reward vault as operator for `user`,
    ///         handling both BGT and WBERA payouts in a single call.
    /// @dev    BGT branch: mints iBGT, takes fee, transfers post-fee iBGT to user.
    ///         WBERA branch: unwraps, mints iBERA, takes fee, transfers post-fee
    ///         iBERA to user. See `harvestVault` for transition semantics
    ///         and the rationale for keeping the legacy selector.
    /// @return bgtAmt BGT + iBERA-shares total in BERA-equivalent units.
    function harvestVaultForUser(
        RewardsStorage storage $,
        IBerachainRewardsVault vault,
        address bgt,
        address ibgt,
        address user
    ) external returns (uint256 bgtAmt) {
        if (address(vault) == address(0)) {
            revert Errors.VaultNotSupported();
        }
        if (vault.operator(user) != address(this)) {
            revert Errors.InvalidOperator();
        }

        (address wbera, address ibera) = _wberaAndIbera();
        uint256 bgtBefore = IBerachainBGT(bgt).balanceOf(address(this));
        uint256 wberaBefore = ERC20(wbera).balanceOf(address(this));

        vault.getReward(user, address(this));

        uint256 bgtDelta =
            IBerachainBGT(bgt).balanceOf(address(this)) - bgtBefore;
        uint256 wberaDelta = ERC20(wbera).balanceOf(address(this)) - wberaBefore;

        if (bgtDelta > 0) _payBgtToUser($, ibgt, user, bgtDelta);
        uint256 iberaShares;
        if (wberaDelta > 0) {
            iberaShares =
                _payWberaAsIberaToUser($, wbera, ibera, user, wberaDelta);
        }

        bgtAmt = bgtDelta + iberaShares;
    }

    /// @dev Mint iBGT, charge fee, transfer post-fee iBGT to user.
    function _payBgtToUser(
        RewardsStorage storage $,
        address ibgt,
        address user,
        uint256 bgtDelta
    ) internal {
        IInfraredBGT(ibgt).mint(address(this), bgtDelta);
        (uint256 _amt, uint256 _amtProtocol) = chargedFeesOnRewards(
            bgtDelta, $.fees[uint256(ConfigTypes.FeeType.HarvestVaultFeeRate)]
        );
        _distributeFeesOnRewards($.protocolFeeAmounts, ibgt, _amtProtocol);
        if (_amt > 0) ERC20(ibgt).safeTransfer(user, _amt);
    }

    /// @dev Unwrap WBERA, mint iBERA, charge fee, transfer the post-fee iBERA
    ///      to the user. Fee accrues in iBERA.
    function _payWberaAsIberaToUser(
        RewardsStorage storage $,
        address wbera,
        address ibera,
        address user,
        uint256 wberaDelta
    ) internal returns (uint256 iberaShares) {
        iberaShares = _wberaToIbera(wbera, ibera, wberaDelta);
        (uint256 _amt, uint256 _amtProtocol) = chargedFeesOnRewards(
            iberaShares,
            $.fees[uint256(ConfigTypes.FeeType.HarvestVaultFeeRate)]
        );
        _distributeFeesOnRewards($.protocolFeeAmounts, ibera, _amtProtocol);
        if (_amt > 0) ERC20(ibera).safeTransfer(user, _amt);
    }

    /// @notice View rewards claimable on a berachain reward vault for `user`.
    /// @dev    `RewardVault.earned(user)` returns the active reward token's
    ///         earned amount; we use `rewardToken()` (via a probe interface,
    ///         since neither upstream `IRewardVault` declares it) to
    ///         discriminate the BGT vs WBERA leg. Pre-fork returns the
    ///         post-fee iBGT amount; post-fork returns the post-fee iBERA
    ///         shares (the iBERA `previewMint` of the earned WBERA) — both
    ///         surfaced through the legacy `iBgtAmount` slot so the caller and
    ///         ABI stay unchanged.
    function externalVaultRewards(
        RewardsStorage storage $,
        IBerachainRewardsVault vault,
        address user
    ) external view returns (uint256 iBgtAmount) {
        if (address(vault) == address(0)) {
            revert Errors.VaultNotSupported();
        }
        if (vault.operator(user) != address(this)) {
            revert Errors.InvalidOperator();
        }

        uint256 earned = vault.earned(user);
        if (earned == 0) return 0;

        uint256 feeRate =
            $.fees[uint256(ConfigTypes.FeeType.HarvestVaultFeeRate)];

        // Discriminate by comparing the vault's current reward token against
        // WBERA (vnext pin). Anything else is treated as legacy BGT.
        (address wbera, address ibera) = _wberaAndIbera();
        address rt = IRewardVaultTokenProbe(address(vault)).rewardToken();
        if (rt == wbera) {
            // Post-fork the distributed token is raw iBERA, so quote the
            // iBERA `previewMint` of the earned WBERA directly.
            uint256 preview = IInfraredBERA(ibera).previewMint(earned);
            (iBgtAmount,) = chargedFeesOnRewards(preview, feeRate);
        } else {
            (iBgtAmount,) = chargedFeesOnRewards(earned, feeRate);
        }
    }

    /// @notice Harvests an old vault, forwarding both BGT (legacy) and WBERA
    ///         (vnext) rewards into its successor `newVault`.
    /// @dev    Same dual-delta semantics as `harvestVault`. Selector preserved.
    /// @return bgtAmt BGT + iBERA-shares total in BERA-equivalent units.
    function harvestOldVault(
        RewardsStorage storage $,
        IInfraredVault vault,
        IInfraredVault newVault,
        address bgt,
        address ibgt
    ) external returns (uint256 bgtAmt) {
        if (
            vault == IInfraredVault(address(0))
                || newVault == IInfraredVault(address(0))
        ) {
            revert Errors.VaultNotSupported();
        }

        bgtAmt = _harvestRewardsVaultTo($, vault, newVault, bgt, ibgt);
    }

    /// @notice Harvest Bribes in tokens from RewardVault, sent to us via processIncentive
    /// ref - https://github.com/berachain/contracts-monorepo/blob/c374de32077ede0147985cf2bf6ed89570244a7e/src/pol/rewards/RewardVault.sol#L421
    /// @param $            The storage pointer for all rewards accumulators
    /// @param collector    The address of the bribe collector, which will auction off fees for WBERA
    /// @param _tokens      The array of token addresses to harvest
    /// @param whitelisted  The array of booleans indicating if the token is whitelisted, and should be collected
    /// @dev WBERA is **never** collected as a bribe. Post-vnext it is the
    ///      base/commission token swept to the iBERA receivor by
    ///      `harvestBase`/`_sweepWberaToReceivor`, and it is the collector's
    ///      own payout token — auctioning WBERA for WBERA is meaningless.
    ///      Because both the bribe sweep and the base sweep read the same
    ///      `balanceOf(wbera) - protocolFeeAmounts[wbera]` pool, collecting
    ///      WBERA here would divert accumulated base rewards into the bribe
    ///      split. We skip it on-chain so keeper input cannot misroute it.
    function harvestBribes(
        RewardsStorage storage $,
        address collector,
        address[] memory _tokens,
        bool[] memory whitelisted
    ) external returns (address[] memory tokens, uint256[] memory amounts) {
        // Create new arrays for the tokens and amounts
        uint256 len = _tokens.length;
        amounts = new uint256[](len);
        tokens = new address[](len);

        // Base/commission token — guarded against being swept as a bribe.
        address wbera = address(IInfrared(address(this)).wbera());

        // Iterate over the tokens, checking if they are whitelisted and collecting them to the bribe collector
        // if they are. Since we accumulate protocol fees for each token, balance - protocol fees = amounts the contract has earned from bribes.
        for (uint256 i = 0; i < len; i++) {
            if (!whitelisted[i]) continue;
            // Current token being processed
            address _token = _tokens[i];

            // Never sweep base WBERA into the bribe pipeline (see @dev above).
            if (_token == wbera) continue;

            // Calculate the amount of the token to forward to the bribe collector = balance of this address - existing protocol fees
            uint256 _amount = ERC20(_token).balanceOf(address(this))
                - $.protocolFeeAmounts[_token];

            // Store the token and amount in the arrays
            amounts[i] = _amount;
            tokens[i] = _token;

            // Transfer the tokens to the bribe collector
            if (_amount > 0) {
                ERC20(_token).safeTransfer(collector, _amount);
            }
        }
    }

    /// @notice Harvest boost rewards from the BGT staker (in HONEY -- likely)
    /// @param $                The storage pointer for all rewards accumulators
    /// @param bgt              The address of the BGT token
    /// @param ibgtVault        The address of the InfraredBGT vault
    /// @param rewardsDuration  The duration of the rewards
    ///
    /// @return _token           The rewards token harvested (likely hunny)
    /// @return _amount          The amount of rewards harvested
    function harvestBoostRewards(
        RewardsStorage storage $,
        address bgt,
        address ibgtVault,
        uint256 rewardsDuration
    ) external returns (address _token, uint256 _amount) {
        IBerachainBGTStaker _bgtStaker =
            IBerachainBGTStaker(IBerachainBGT(bgt).staker());
        _token = address(_bgtStaker.rewardToken());

        // @dev claim the boost rewards and use return value to calculate the amount
        _amount = _bgtStaker.getReward();

        // get total and protocol fee rates
        uint256 feeTotal =
            $.fees[uint256(ConfigTypes.FeeType.HarvestBoostFeeRate)];

        _handleTokenRewardsForVault(
            $,
            IInfraredVault(ibgtVault),
            _token,
            _amount,
            feeTotal,
            rewardsDuration
        );
    }

    /// @notice redeem ibgt for bera
    /// @param bgt              The address of the BGT token
    /// @param ibgt             The address of the iBGT token
    /// @param amount           Amount of ibgt to redeem
    function redeemIbgtForBera(address bgt, address ibgt, uint256 amount)
        external
    {
        ERC20(ibgt).safeTransferFrom(msg.sender, address(this), amount);
        IInfraredBGT(ibgt).burn(amount);
        IBerachainBGT(bgt).redeem(msg.sender, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CALLBACK                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Callback from the BribeCollector to payout the WBERA bribes were auctioned off for
    ///     ref - https://github.com/infrared-dao/infrared-contracts/blob/develop/src/depreciated/core/BribeCollector.sol#L87
    /// @param $        Storage pointer for reward accumulators
    /// @param _amount          The amount of WBERA our bribes were auctioned off for
    /// @param wbera            The address of the WBERA token
    /// @param ibera            The address of the InfraredBERA token
    /// @param ibgtVault        The address of the InfraredBGT vault
    /// @param rewardsDuration  The duration of the rewards
    ///
    /// @notice WBERA is split between the iBERA product (where it is redeemed for BERA) and the rest is sent to the IBGT vault.
    /// @return amtInfraredBERA The amount of WBERA sent to the iBERA product
    /// @return amtIbgtVault    The amount of WBERA sent to the IBGT vault
    function collectBribesInWBERA(
        RewardsStorage storage $,
        uint256 _amount,
        address wbera,
        address ibera,
        address ibgtVault,
        address irCollector,
        uint256 rewardsDuration
    )
        external
        returns (
            uint256 amtInfraredBERA,
            uint256 amtIbgtVault,
            uint256 amountIR
        )
    {
        // transfer WBERA from bribe collector
        ERC20(wbera).safeTransferFrom(msg.sender, address(this), _amount);

        // determine amount to send to iBERA and IBGT vault
        amtInfraredBERA = (_amount * $.bribeSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = _amount - amtInfraredBERA;
        // update for IR split
        amountIR = (amtIbgtVault * $.irSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = amtIbgtVault - amountIR;

        // Redeem WBERA for BERA and send to IBERA receivor for compounding.
        if (amtInfraredBERA > 0) {
            IWBERA(wbera).withdraw(amtInfraredBERA);
            SafeTransferLib.safeTransferETH(
                IInfraredBERA(ibera).receivor(), amtInfraredBERA
            );
        }

        // send sIR revenue to IR auction to be compounded in sIR
        if (amountIR > 0) ERC20(wbera).safeTransfer(irCollector, amountIR);

        // Get Fee totals (voter + protocol)
        uint256 feeTotal =
            $.fees[uint256(ConfigTypes.FeeType.HarvestBribesFeeRate)];

        // Charge fees and notify rewards
        _handleTokenRewardsForVault(
            $,
            IInfraredVault(ibgtVault),
            wbera,
            amtIbgtVault,
            feeTotal,
            rewardsDuration
        );
    }

    /// @notice Callback from the BribeCollector to payout the iBGT bribes were auctioned off for
    ///     ref - https://github.com/infrared-dao/infrared-contracts/blob/develop/src/depreciated/core/BribeCollector.sol#L87
    /// @param $        Storage pointer for reward accumulators
    /// @param _amount          The amount of iBGT our bribes were auctioned off for
    /// @param ibgt            The address of the iBGT token
    /// @param ibgtVault        The address of the InfraredBGT vault
    /// @param harvestBaseCollector The address of base collector auction contract
    /// @param rewardsDuration  The duration of the rewards
    ///
    /// @notice iBGT is split between the iBERA product (where it is redeemed for BERA) and the rest is sent to the IBGT vault.
    /// @return amtInfraredBERA The amount of iBGT sent to the iBERA product
    /// @return amtIbgtVault    The amount of iBGT sent to the IBGT vault
    function collectBribesInIBGT(
        RewardsStorage storage $,
        uint256 _amount,
        address ibgt,
        address ibgtVault,
        address irCollector,
        address harvestBaseCollector,
        uint256 rewardsDuration
    )
        external
        returns (
            uint256 amtInfraredBERA,
            uint256 amtIbgtVault,
            uint256 amountIR
        )
    {
        // transfer iBGT from bribe collector
        ERC20(ibgt).safeTransferFrom(msg.sender, address(this), _amount);

        // determine amount to send to iBERA and IBGT vault
        amtInfraredBERA = (_amount * $.bribeSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = _amount - amtInfraredBERA;
        // update for IR split
        amountIR = (amtIbgtVault * $.irSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = amtIbgtVault - amountIR;

        // Send iBGT to harvestBaseCollector to auction for BERA to send to
        // IBERA receivor for compounding. Guarded so a zeroed bribe split
        // does not fire a 0-value transfer on every auction callback.
        if (amtInfraredBERA > 0) {
            ERC20(ibgt).safeTransfer(harvestBaseCollector, amtInfraredBERA);
        }

        // send sIR revenue to IR auction to be compounded in sIR
        if (amountIR > 0) ERC20(ibgt).safeTransfer(irCollector, amountIR);

        // Get Fee totals (voter + protocol)
        uint256 feeTotal =
            $.fees[uint256(ConfigTypes.FeeType.HarvestBribesFeeRate)];

        // Wrap into wiBGT and notify only when a vault leg remains; a fully
        // routed split (no ibgtVault residual) skips the 0-asset ERC4626
        // deposit, which some 4626 implementations revert on.
        if (amtIbgtVault > 0) {
            address wiBGT = IInfrared(address(this)).wiBGT();
            uint256 wibgtAmount =
                ERC4626(wiBGT).deposit(amtIbgtVault, address(this));

            // Charge fees and notify rewards
            _handleTokenRewardsForVault(
                $,
                IInfraredVault(ibgtVault),
                wiBGT,
                wibgtAmount,
                feeTotal,
                rewardsDuration
            );
        }
    }

    /// @notice Callback from the BribeCollector to payout the IR bribes were auctioned off for
    ///     ref - https://github.com/infrared-dao/infrared-contracts/blob/develop/src/core/BribeCollector.sol#L87
    /// @param $        Storage pointer for reward accumulators
    /// @param _amount          The amount of IR our bribes were auctioned off for
    /// @param ir            The address of the IR token
    /// @param ibgtVault        The address of the InfraredBGT vault
    /// @param harvestBaseCollector The address of base collector auction contract
    /// @param rewardsDuration  The duration of the rewards
    ///
    /// @notice IR is split between the iBERA product (where it is redeemed for BERA) and the rest is sent to the IBGT vault and sIR.
    /// @return amtInfraredBERA The amount of iBGT sent to the iBERA product
    /// @return amtIbgtVault    The amount of iBGT sent to the IBGT vault
    /// @return amountIR    The amount of IR sent to the sIR
    function collectBribesInIR(
        RewardsStorage storage $,
        uint256 _amount,
        address ir,
        address ibgtVault,
        address irCollector,
        address harvestBaseCollector,
        uint256 rewardsDuration
    )
        external
        returns (
            uint256 amtInfraredBERA,
            uint256 amtIbgtVault,
            uint256 amountIR
        )
    {
        // transfer ir from bribe collector
        ERC20(ir).safeTransferFrom(msg.sender, address(this), _amount);

        // determine amount to send to iBERA and IBGT vault
        amtInfraredBERA = (_amount * $.bribeSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = _amount - amtInfraredBERA;
        // update for IR split
        amountIR = (amtIbgtVault * $.irSplitRatio) / UNIT_DENOMINATOR;
        amtIbgtVault = amtIbgtVault - amountIR;

        // Send IR to harvestBaseCollector to auction for BERA to send to
        // IBERA receivor for compounding. Guarded so a zeroed bribe split
        // does not fire a 0-value transfer on every auction callback.
        if (amtInfraredBERA > 0) {
            ERC20(ir).safeTransfer(harvestBaseCollector, amtInfraredBERA);
        }

        // send sIR revenue to IR auction to be compounded in sIR
        if (amountIR > 0) ERC20(ir).safeTransfer(irCollector, amountIR);

        // Get Fee totals (voter + protocol)
        uint256 feeTotal =
            $.fees[uint256(ConfigTypes.FeeType.HarvestBribesFeeRate)];

        // Charge fees and notify rewards
        _handleTokenRewardsForVault(
            $,
            IInfraredVault(ibgtVault),
            ir,
            amtIbgtVault,
            feeTotal,
            rewardsDuration
        );
    }
}
