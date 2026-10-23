//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { SafeTransferLib } from "@solady/utils/SafeTransferLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math as OZMath } from "@openzeppelin/contracts/utils/math/Math.sol";
import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";

// OVERRIDE STUFF
import { Policies } from "./Policies.sol";
import { ShMonadStorage } from "./Storage.sol";
import { CommittedData, Delivery, AdminValues, CurrentLiabilities } from "./Types.sol";
import {
    DEFAULT_STAKING_YIELD_DEADBAND_BPS,
    EIP1967_ADMIN_SLOT,
    EPOCHS_TRACKED,
    OWNER_COMMISSION_ACCOUNT
} from "./Constants.sol";
import { IHolisticMON } from "./interfaces/IHolisticMON.sol";
import { AccountingLib } from "./libraries/AccountingLib.sol";
import { TradUnstakeLib } from "./libraries/TradUnstakeLib.sol";

/// @title ShMonad - Liquid Staking Token on Monad
/// @notice ShMonad is an LST integrated with the FastLane ecosystem
/// @dev Extends Policies which provides ERC4626 functionality plus policy-based commitment mechanisms
/// @author FastLane Labs
contract ShMonad is Policies {
    using SafeTransferLib for address;
    using SafeCast for uint256;
    using Math for uint256;

    constructor(address holisticMonProxy) ShMonadStorage(holisticMonProxy) {
        // Disable initializers on implementation
        _disableInitializers();
    }

    /// @notice Initializes ShMonad for either a fresh deployment or the v1.2 upgrade path.
    /// @dev Fresh deployments run the full module initialization stack. Already-initialized proxies skip the full
    /// module init path and only install the shared coinbase beacon.
    /// @dev Protected against front-running: constructor disables initializers on implementation.
    /// @dev Under TransparentUpgradeableProxy this must be invoked via ProxyAdmin.upgradeAndCall().
    /// @param owner_ The address that owns the contract on fresh deployment.
    /// @param codeUpgradeAuthority_ The authority allowed to rotate implementation pointers.
    /// @custom:selector 0x485cc955
    function initialize(address owner_, address codeUpgradeAuthority_) public reinitializer(12) {
        require(msg.sender == _getProxyAdmin(), UnauthorizedInitializer());
        require(HMON_TOKEN_ADDRESS.code.length != 0, InvalidZeroYieldToken(HMON_TOKEN_ADDRESS));
        require(IHolisticMON(HMON_TOKEN_ADDRESS).shMonad() == address(this), InvalidZeroYieldToken(HMON_TOKEN_ADDRESS));
        // Activation stays closed while the proxy runs legacy code. This call atomically proves that this ShMonad
        // upgrade installed the exact hMON instance before any legacy balance can be surfaced to indexers.
        IHolisticMON(HMON_TOKEN_ADDRESS).enableActivation();
        _setCodeUpgradeAuthority(codeUpgradeAuthority_);
        s_stakeAllocationConfig.stakingYieldDeadbandBps = DEFAULT_STAKING_YIELD_DEADBAND_BPS;
        // Default-fill snapshot slots so raw zero remains a valid explicit governance value.
        for (uint256 i; i < EPOCHS_TRACKED; ++i) {
            s_stakingYieldDeadbandBpsSnapshots[i] = DEFAULT_STAKING_YIELD_DEADBAND_BPS;
        }

        // Fresh deployments still need the full ShMonad initialization stack. Live pre-beacon proxies already ran
        // this setup and only need the new shared beacon installed.
        if (s_admin.internalEpoch == 0) {
            __EIP712_init("ShMonad", "3");
            __Ownable_init(owner_);
            __AtomicUnstakePool_init();
            __ReentrancyGuardTransient_init();
            __StakeTracker_init();
        } else {
            // Enforce the live-upgrade idle precheck onchain; permissionless cranks can race offchain reads.
            _assertAllocationRoundIdle();

            // Live pre-allocation upgrades do not have historical split-revenue windows. Set the first split-weighted
            // allocation round to E+3 so that round reads E+1 and E+2, both populated after the v1.2 upgrade.
            s_stakeAllocationConfig.splitStartEpoch = s_admin.internalEpoch + 3;
        }

        emit ZeroYieldTokenConfigured(HMON_TOKEN_ADDRESS);

        // StakeTracker init does not depend on the beacon, so initialize the new v1.2 coinbase subsystem last.
        __CoinbaseBeacon_init();
    }

    /// @notice Updates the authority that can perform delayed code upgrades.
    /// @dev Intended to be called by the current timelock to rotate to a successor timelock.
    /// @param newAuthority The replacement code-upgrade authority.
    /// @custom:selector 0x93f8bff5
    function updateCodeUpgradeAuthority(address newAuthority) external onlyCodeUpgradeAuthority {
        _setCodeUpgradeAuthority(newAuthority);
    }

    /// @dev Returns the proxy admin when running behind a TransparentUpgradeableProxy.
    function _getProxyAdmin() private view returns (address _proxyAdmin) {
        // Assembly required to sload the admin slot defined by the proxy standard.
        // Pseudocode: proxyAdmin = StorageSlot(EIP1967_ADMIN_SLOT).read();
        assembly ("memory-safe") {
            _proxyAdmin := sload(EIP1967_ADMIN_SLOT)
        }
    }

    function _setCodeUpgradeAuthority(address newAuthority) private {
        require(newAuthority != address(0), ZeroAddress());
        address oldAuthority = s_codeUpgradeAuthority;
        s_codeUpgradeAuthority = newAuthority;
        emit CodeUpgradeAuthorityUpdated(oldAuthority, newAuthority);
    }

    // --------------------------------------------- //
    //                 Agent Functions               //
    // --------------------------------------------- //

    /// @notice Transfers committed shares from one account to another within the same policy.
    /// @dev Implementation details:
    /// 1. Releases any holds on the source account if requested.
    /// 2. If `inUnderlying` is true, interprets `amount` as MON (post-fee, ignoring liquidity limits) and converts
    /// to shares via `_convertToShares(amount)` semantics.
    /// 3. Updates the source account's committed balance in memory then persists to storage.
    /// 4. Updates the destination account's committed balance directly in storage.
    /// 5. Does not decrease committedTotalSupply as the value remains committed.
    /// @param policyID The ID of the policy powering the transfer.
    /// @param from The address providing the committed shares.
    /// @param to The address receiving the committed shares.
    /// @param amount The amount to transfer (shares or assets depending on `inUnderlying`).
    /// @param fromReleaseAmount Shares to release from holds before transferring.
    /// @param inUnderlying Whether `amount` is specified in MON (`true`) or shMON (`false`).
    /// @custom:selector 0x402f1cd4
    function agentTransferFromCommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool inUnderlying
    )
        external
        nonReentrant
        onlyPolicyAgentAndActive(policyID)
    {
        // Agents cannot transfer their own committed funds, otherwise they could circumvent the rule that disallows
        // them from instantly uncommitting their own funds by first transferring them to a non-agent account.
        require(!_isPolicyAgent(policyID, from), AgentInstantUncommittingDisallowed(policyID, from));

        // Release hold on `from` account if necessary
        if (fromReleaseAmount > 0) _release(policyID, from, fromReleaseAmount);
        // Interpret `amount` in underlying units using the vault exchange rate (no fee path)
        if (inUnderlying) amount = _convertToShares(amount, OZMath.Rounding.Ceil, false, false);

        uint128 sharesToDeduct = amount.toUint128();

        // Changes to the `from` account - done in memory then persisted to storage:
        // - decrease committed balance (respecting any holds if not released above)
        // - do not decrease committedTotalSupply (value stays in committed form)
        CommittedData memory fromCommittedData = s_committedData[policyID][from];
        _spendFromCommitted(fromCommittedData, policyID, from, sharesToDeduct, Delivery.Committed);
        s_committedData[policyID][from] = fromCommittedData;

        // Changes to the `to` account - done directly in storage:
        // - increase committed balance (holds not applicable if increasing)
        s_committedData[policyID][to].committed += sharesToDeduct;
        s_balances[to].committed += sharesToDeduct;

        emit AgentTransferFromCommitted(policyID, from, to, amount);
    }

    /// @notice Transfers committed shares from an account into another account's uncommitted balance.
    /// @dev Implementation details:
    /// 1. Prevents agents from uncommitting their own balance.
    /// 2. Releases any holds on the source account if requested.
    /// 3. If `inUnderlying` is true, interprets `amount` as MON and converts to shares via `_convertToShares`.
    /// 4. Updates the source account's committed balance in memory then persists to storage.
    /// 5. Increases the destination account's uncommitted balance.
    /// 6. Decreases committedTotalSupply because value leaves the committed form.
    /// @param policyID The ID of the policy powering the transfer.
    /// @param from The address providing the committed shares.
    /// @param to The address receiving the uncommitted shares.
    /// @param amount The amount to transfer (shares or assets depending on `inUnderlying`).
    /// @param fromReleaseAmount Shares to release from holds before transferring.
    /// @param inUnderlying Whether `amount` is specified in MON (`true`) or shMON (`false`).
    /// @custom:selector 0xbfece887
    function agentTransferToUncommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool inUnderlying
    )
        external
        onlyPolicyAgentAndActive(policyID)
    {
        // Agents cannot instantly uncommit their own or other agents' balances
        require(!_isPolicyAgent(policyID, from), AgentInstantUncommittingDisallowed(policyID, from));

        // Release hold on `from` account if necessary
        if (fromReleaseAmount > 0) _release(policyID, from, fromReleaseAmount);
        // Interpret `amount` in underlying units using the vault exchange rate (no fee path)
        if (inUnderlying) amount = _convertToShares(amount, OZMath.Rounding.Ceil, false, false);

        uint128 sharesToDeduct = amount.toUint128();

        // Changes to the `from` account - done in memory then persisted to storage:
        // - decrease committed balance (respecting any holds if not released above)
        // - decreases committedTotalSupply (value converts to uncommitted form)
        CommittedData memory fromCommittedData = s_committedData[policyID][from];
        _spendFromCommitted(fromCommittedData, policyID, from, sharesToDeduct, Delivery.Uncommitted);
        s_committedData[policyID][from] = fromCommittedData;

        // Increase uncommitted balance
        s_balances[to].uncommitted += sharesToDeduct;

        emit AgentTransferToUncommitted(policyID, from, to, amount);
    }

    /// @notice Withdraws MON from an account's committed balance to a recipient.
    /// @dev Implementation details:
    /// 1. Prevents agents from withdrawing their own balance.
    /// 2. Releases any holds on the source account if requested.
    /// 3. Handles conversion between shares and assets based on the `amountSpecifiedInUnderlying` flag.
    /// 4. Updates the source account's committed balance in memory then persists to storage.
    /// 5. Temporarily increases the destination's uncommitted balance.
    /// 6. Burns the shares from the destination account.
    /// 7. Transfers the underlying assets (MON) to the destination.
    /// NOTE: Conversions go through the AtomicUnstakePool. Fees and liquidity limits apply; agents should consult
    /// `previewWithdraw()`/`previewRedeem()` before calling.
    /// @param policyID The ID of the policy powering the withdrawal.
    /// @param from The address providing the committed shares.
    /// @param to The address receiving the withdrawn MON.
    /// @param amount The amount to withdraw (shares or assets depending on `amountSpecifiedInUnderlying`).
    /// @param fromReleaseAmount Shares to release from holds before withdrawing.
    /// @param amountSpecifiedInUnderlying Whether `amount` is specified in MON (`true`) or shMON (`false`).
    /// @custom:selector 0x74662009
    function agentWithdrawFromCommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool amountSpecifiedInUnderlying
    )
        external
        nonReentrant
        onlyPolicyAgentAndActive(policyID)
        cbPooledShareRate
    {
        // Agents cannot instantly uncommit their own or other agents' balances
        require(!_isPolicyAgent(policyID, from), AgentInstantUncommittingDisallowed(policyID, from));

        // Release hold on `from` account if necessary
        if (fromReleaseAmount > 0) _release(policyID, from, fromReleaseAmount);

        uint128 _sharesToDeduct;
        uint256 _assetsToReceive;
        uint256 _feeTaken;

        if (amountSpecifiedInUnderlying) {
            // CASE: amount is a net assets (MON) figure.
            _assetsToReceive = amount;
            uint256 _grossAssets;
            (_grossAssets, _feeTaken) = _getGrossAndFeeFromNetAssets(_assetsToReceive);
            // Burn shares equivalent to the required before-fee gross (ceil rounding).
            _sharesToDeduct = _convertToShares(_grossAssets, OZMath.Rounding.Ceil, true, false).toUint128();
        } else {
            // CASE: amount is a gross shares (shMON) figure.
            uint256 _grossAssetsWanted = _convertToAssets(amount, OZMath.Rounding.Floor, true, false);
            uint256 _grossAssetsCapped;

            (_grossAssetsCapped, _feeTaken) = _getGrossCappedAndFeeFromGrossAssets({
                grossRequested: _grossAssetsWanted, revertIfNetExceedsLiquidity: true
            });

            _assetsToReceive = _grossAssetsCapped - _feeTaken;
            _sharesToDeduct = amount.toUint128();
        }

        // Changes to the `from` account - done in memory then persisted to storage:
        // - decrease committed balance (respecting any holds if not released above)
        // - decrease committedTotalSupply (value leaving committed form)
        CommittedData memory fromCommittedData = s_committedData[policyID][from];
        _spendFromCommitted(fromCommittedData, policyID, from, _sharesToDeduct, Delivery.Underlying);
        s_committedData[policyID][from] = fromCommittedData;

        // Call StakeTracker hook to account for assets leaving via instant unstake
        _accountForWithdraw(_assetsToReceive.toUint128(), _feeTaken.toUint128());

        // Send net assets to the `to` address
        to.safeTransferETH(_assetsToReceive);

        emit AgentWithdrawFromCommitted(policyID, from, to, _assetsToReceive);
    }

    // --------------------------------------------- //
    //            Unstake Functions                  //
    // --------------------------------------------- //

    /// @notice Returns the current traditional-unstake completion-epoch timing quote for `shares`.
    /// @dev This view uses the same amount conversion and global redemption-capacity timing logic as `requestUnstake`.
    /// It does not inspect the caller's traditional-unstake request slots and does not guarantee
    /// `requestUnstake(shares)` acceptance. The state-changing request can still revert during request validation,
    /// share-rate checks, legacy request migration, matured compaction, or pending-slot enqueue.
    /// @param shares The amount of shMON shares to preview for a traditional unstake request.
    /// @return completionEpoch The internal epoch the current timing model would quote if the request were accepted.
    /// @custom:selector 0xcfd4ad73
    function previewRequestUnstake(uint256 shares) external view returns (uint64 completionEpoch) {
        uint256 amount = previewUnstake(shares);
        completionEpoch = _calcUnstakeRequestCompletionEpoch(amount);
    }

    /// @notice Returns the maximum MON amount a new traditional unstake can request without the extra delay.
    /// @dev `requestUnstake` accepts shares, but the delay rule is applied after those shares are converted to MON.
    /// Integrators can compare `previewUnstake(shares)` with this amount to explain whether a request currently fits
    /// in the base completion window, while `previewRequestUnstake(shares)` remains the global timing quote.
    /// @return amount The current MON amount available before a new request would receive the extra two-epoch delay.
    /// @custom:selector 0x37ea0bcb
    function getMaxUnstakeRequestAmountWithoutDelay() external view returns (uint256 amount) {
        amount = AccountingLib.maximumNewGlobalRedemptionAmount(
            s_globalCapital, s_globalLiabilities, s_admin, s_globalPending, address(this).balance, s_isolatedTotalAssets
        );
    }

    /// @notice Requests an unstake of shMON shares for the caller.
    /// @dev Burns the specified amount of shMON shares and queues the corresponding MON for withdrawal.
    /// The unstake request may take multiple epochs to complete depending on queue capacity.
    /// Starting in the v1.2 upgrade, each account can track multiple concurrent requests:
    /// - requests with the same predicted completion epoch are merged into a single request bucket
    /// - already-matured requests may be compacted into a dedicated matured bucket to keep pending buckets available
    /// - `getUnstakeRequest(address)` remains as a compatibility summary over the whole request set
    /// @param shares The amount of shMON shares to unstake.
    /// @return completionEpoch The internal epoch at which the newly requested slice can be completed.
    /// @custom:selector 0x23095721
    function requestUnstake(uint256 shares)
        external
        notWhenClosed
        nonReentrant
        cbPooledShareRate
        returns (uint64 completionEpoch)
    {
        completionEpoch = _requestUnstake(shares);
    }

    function _requestUnstake(uint256 shares) internal returns (uint64 completionEpoch) {
        require(shares != 0, CannotUnstakeZeroShares());
        require(shares <= balanceOf(msg.sender), InsufficientBalanceForUnstake());

        uint256 amount = previewUnstake(shares);

        // Quote before booking this request as a liability. Existing pending requests already reduce capacity through
        // redemptionsPayable, while this request should only be delayed if it exceeds the currently safe envelope.
        completionEpoch = _calcUnstakeRequestCompletionEpoch(amount);

        // burn shMON → record request into global trackers
        _burn(msg.sender, shares);
        _afterRequestUnstake(amount);

        // Normalize any legacy v1.1 single-slot request and compact matured requests before allocating a pending slot.
        TradUnstakeLib.prepare(s_unstakeRequests, s_userUnstakesState, msg.sender, s_admin.internalEpoch);
        TradUnstakeLib.enqueuePendingRequest(s_userUnstakesState, msg.sender, amount.toUint128(), completionEpoch);

        emit RequestUnstake(msg.sender, shares, amount, completionEpoch);
    }

    /// @notice Completes every matured traditional unstake request for the caller in a single payout.
    /// @dev The function normalizes matured requests into a dedicated matured bucket, drains that bucket, and leaves
    /// later requests untouched. If no request is currently mature, the call reverts with the earliest pending
    /// completion epoch, which is the effective "oldest request" once requests are bucketed by epoch.
    /// @custom:selector 0x63803b23
    function completeUnstake() external virtual notWhenClosed nonReentrant cbPooledShareRate {
        _completeUnstake(msg.sender);
    }

    function _completeUnstake(address account) internal {
        uint64 _currentInternalEpoch = s_admin.internalEpoch;
        uint64 _oldestPendingCompletionEpoch =
            TradUnstakeLib.prepare(s_unstakeRequests, s_userUnstakesState, account, _currentInternalEpoch);
        uint128 _amount = TradUnstakeLib.consumeMaturedRequests(s_userUnstakesState, account);

        require(_amount != 0 || _oldestPendingCompletionEpoch != type(uint64).max, NoUnstakeRequestFound());
        require(_amount != 0, CompletionEpochNotReached(_currentInternalEpoch, _oldestPendingCompletionEpoch));

        _beforeCompleteUnstake(_amount);

        account.safeTransferETH(_amount);

        emit CompleteUnstake(account, _amount);
    }

    function _calcUnstakeRequestCompletionEpoch(uint256 amount) internal view returns (uint64 completionEpoch) {
        return _calcUnstakeRequestCompletionEpoch(amount, s_globalLiabilities);
    }

    function _calcUnstakeRequestCompletionEpoch(
        uint256 amount,
        CurrentLiabilities memory liabilities
    )
        internal
        view
        returns (uint64 completionEpoch)
    {
        uint64 _currentInternalEpoch = s_admin.internalEpoch;
        // Worst case: users can `completeUnstake()` [k + 4] internal (ShMonad) epochs after calling `requestUnstake()`
        // where k is the native withdrawal delay (currently 1 Monad epoch)
        completionEpoch = _currentInternalEpoch + STAKING_WITHDRAWAL_DELAY + 4;
        // TIMING - Assumption of Worst Case
        //  Epoch N+0 Request Unstake
        //  Epoch N+1 (boundary) Last validator cranked
        //  Epoch N+2 (effective epoch of crank due to boundary)
        //  Epoch N+3 EPOCH_DELAY_PERIOD
        //  Epoch N+4 collect unstaked amount from validators
        //  Epoch N+5 user can withdraw safely
        uint256 _maxGlobalRedemptionAllowed = AccountingLib.maximumNewGlobalRedemptionAmount(
            s_globalCapital, liabilities, s_admin, s_globalPending, address(this).balance, s_isolatedTotalAssets
        );

        // If the requested amount exceeds the maximum global redemption allowed, the completion epoch is extended by 2
        // additional epochs to account for the activation of pending stake.
        if (amount > _maxGlobalRedemptionAllowed) {
            // TIMING - Assumption of Worst Case
            // NOTE: We must wait for deposit to finish before we can start unstaking it
            //  Epoch N+0 Deposit requested in boundary block
            //  Epoch N+1 effective deposit block
            //  Epoch N+2 verify deposit complete +  Request Unstake
            //  Epoch N+3 (boundary) Last validator cranked
            //  Epoch N+4 (effective epoch of crank due to boundary)
            //  Epoch N+5 EPOCH_DELAY_PERIOD
            //  Epoch N+6 collect unstaked amount from validators <- Net New Delay
            //  Epoch N+7 user can withdraw safely <- Net New Delay
            completionEpoch += 2;
        }
    }

    /// @notice Deposits native MON into an isolated stake position for one validator.
    /// @dev Mints validator-specific vShares to `receiver` and immediately delegates `assets` to `validatorId`.
    /// The validator must be active, `msg.value` must equal `assets`, and `assets` must meet the staking minimum.
    /// A contract receiver must be able to transfer native MON from its own balance, for example through a sweep or
    /// generic execution function: permissionless isolated finalizers can settle MON directly to the vShare owner.
    /// @param validatorId The validator receiving the isolated stake.
    /// @param assets The MON amount to stake.
    /// @param receiver The account receiving validator-specific isolated vShares.
    /// @return vShares The isolated vShares minted to `receiver`.
    /// @custom:selector 0xa69749eb
    function depositIsolated(
        uint64 validatorId,
        uint256 assets,
        address receiver
    )
        external
        payable
        notWhenClosed
        notWhenFrozen
        nonReentrant
        cbPooledShareRate
        returns (uint256 vShares)
    {
        vShares = _depositIsolated(_msgSender(), validatorId, assets, receiver);
    }

    /// @notice Requests unstaking of validator-specific isolated vShares.
    /// @dev Burns the caller's vShares, records a MON-denominated redemption request, and queues isolated validator
    /// liquidity as needed. Multiple requests from the same account and validator collapse into one request while
    /// preserving fixed principal and the latest required completion epoch. Partial exits must leave either zero
    /// isolated shares or a remaining isolated position worth at least `MIN_VALIDATOR_DEPOSIT`.
    /// @param validatorId The validator whose isolated vShares are being redeemed.
    /// @param vShares The amount of isolated vShares to redeem.
    /// @return completionEpoch The internal epoch when the request can be completed.
    /// @custom:selector 0x2f11c240
    function requestUnstakeIsolated(
        uint64 validatorId,
        uint256 vShares
    )
        external
        notWhenClosed
        nonReentrant
        cbPooledShareRate
        returns (uint64 completionEpoch)
    {
        completionEpoch = _requestUnstakeIsolated(_msgSender(), validatorId, vShares);
    }

    /// @notice Completes the caller's matured isolated unstake request.
    /// @dev Pays the caller from isolated idle liquidity after the request completion epoch has been reached. A final
    /// request against a validator with no remaining isolated shares or stake may settle with a sub-dust haircut
    /// instead of waiting for a possible later isolated credit.
    /// @param validatorId The validator associated with the isolated unstake request.
    /// @custom:selector 0x3a6e2a62
    function completeUnstakeIsolated(uint64 validatorId) external notWhenClosed nonReentrant cbPooledShareRate {
        _completeUnstakeIsolated(_msgSender(), validatorId);
    }

    /// @notice Allows anyone to settle an isolated unstake request once it is ready.
    /// @dev Settlement always pays the original request owner, never the caller. If a normal transfer fails, MON is
    /// force-sent to the owner's address, so a contract owner must expose a way to recover native MON from its balance.
    /// A final request against a validator with no remaining isolated shares or stake may settle with a sub-dust
    /// haircut instead of waiting for a possible later isolated credit.
    /// @return amountMon The MON actually paid to the request owner.
    /// @custom:selector 0xda243e6f
    function completeUnstakeIsolatedFor(
        uint64 validatorId,
        address account
    )
        external
        notWhenClosed
        nonReentrant
        cbPooledShareRate
        returns (uint256 amountMon)
    {
        amountMon = _completeUnstakeIsolated(account, validatorId, account, true);
    }

    /// @notice Claims isolated shares directly after a validator has been deactivated and fully idled.
    /// @dev Available only when the validator is no longer active, all isolated stake has become idle, and no isolated
    /// redemption requests remain payable. This bypasses the normal request/complete flow for final deactivation
    /// cleanup.
    /// @param validatorId The deactivated validator whose isolated shares are being claimed.
    /// @param vShares The amount of isolated vShares to redeem.
    /// @param receiver The account receiving the MON payout.
    /// @return amountMon The MON amount paid to `receiver`.
    /// @custom:selector 0x6b1bdb96
    function claimDeactivatedIsolated(
        uint64 validatorId,
        uint256 vShares,
        address receiver
    )
        external
        notWhenClosed
        nonReentrant
        cbPooledShareRate
        returns (uint256 amountMon)
    {
        amountMon = _claimDeactivatedIsolated(_msgSender(), validatorId, vShares, receiver);
    }

    /// @notice Allows anyone to finalize deactivated isolated shares once the validator is fully idle.
    /// @dev Finalization always pays the share owner, never the caller. This can execute before the owner-selectable
    /// claim path and force MON to the owner address; contract owners must expose a native-MON sweep or equivalent.
    /// @custom:selector 0xd6f4ff72
    function claimDeactivatedIsolatedFor(
        uint64 validatorId,
        uint256 vShares,
        address account
    )
        external
        notWhenClosed
        nonReentrant
        cbPooledShareRate
        returns (uint256 amountMon)
    {
        amountMon = _claimDeactivatedIsolated(account, validatorId, vShares, account, true);
    }

    // --------------------------------------------- //
    //        Zero Yield Tranche Functions           //
    // --------------------------------------------- //

    /// @custom:selector 0x46543b9c
    function transferZeroYieldBalanceFromToken(address from, address to, uint256 amount) external nonReentrant {
        require(msg.sender == HMON_TOKEN_ADDRESS, NotZeroYieldToken(msg.sender));
        _transferZeroYieldBalance(from, to, amount);
    }

    /// @notice Deposits assets into the zero-yield tranche, crediting the balance to the receiver
    /// @dev The zero-yield tranche does not earn any yield. Yield earned on the deposited assets go towards boosting
    /// shMON yield. Accounts with zero-yield tranche balances can convert their balances into yield-bearing shMON at
    /// any time, via `convertZeroYieldTrancheToShares()`.
    /// @param assets The amount of underlying assets (MON) to deposit
    /// @param receiver The address receiving the zero-yield tranche shares
    /// @custom:selector 0x8d01c5c8
    function depositToZeroYieldTranche(
        uint256 assets,
        address receiver
    )
        external
        payable
        notWhenClosed
        nonReentrant
        cbPooledShareRate
    {
        _depositToZeroYieldTranche(assets, msg.sender, receiver);
    }

    function _depositToZeroYieldTranche(uint256 assets, address from, address to) internal {
        AdminValues memory _admin = s_admin;

        require(msg.value == assets, IncorrectNativeTokenAmountSent());

        _increaseZeroYieldBalance(from, to, assets, true);

        // Increase total liabilities to reflect the new assets held in the zero-yield tranche
        _admin.totalZeroYieldPayable += uint128(assets);

        // Queue up the new funds to be staked
        _accountForDeposit(assets.toUint128());

        // Persist AdminValues changes to storage
        s_admin = _admin;
    }

    /// @notice Converts zero-yield tranche balances into yield-bearing shMON shares.
    /// @param assets The amount of underlying assets (MON) to convert
    /// @param receiver The address receiving the yield-bearing shMON shares
    /// @return shares The amount of yield-bearing shMON shares minted to the receiver
    /// @custom:selector 0xbc3ec4c2
    function convertZeroYieldTrancheToShares(
        uint256 assets,
        address receiver
    )
        external
        notWhenClosed
        nonReentrant
        returns (uint256 shares)
    {
        shares = _convertZeroYieldBalanceToShares(assets, msg.sender, receiver);
    }

    /// @notice Allows the contract owner to claim their accumulated commission as yield-bearing shMON shares.
    /// @param assets The amount of underlying assets (MON) to convert
    /// @param receiver The address receiving the yield-bearing shMON shares
    /// @return shares The amount of yield-bearing shMON shares minted to the receiver
    /// @custom:selector 0x73e45bae
    function claimOwnerCommissionAsShares(
        uint256 assets,
        address receiver
    )
        external
        notWhenClosed
        onlyOwner
        nonReentrant
        returns (uint256 shares)
    {
        shares = _convertZeroYieldBalanceToShares(assets, OWNER_COMMISSION_ACCOUNT, receiver);
        emit AdminCommissionClaimedAsShares(receiver, assets, shares);
    }

    function _convertZeroYieldBalanceToShares(
        uint256 assets,
        address from,
        address to
    )
        internal
        cbPooledShareRate
        returns (uint256 shares)
    {
        AdminValues memory _admin = s_admin;

        _decreaseZeroYieldBalance(from, assets);

        // Instead of depositing new assets, we decrease totalZeroYieldPayable, which decreases total liabilities. Thus
        // there is still an increase in totalEquity that is commensurate with the increase in totalSupply caused by new
        // shares minted below.
        _admin.totalZeroYieldPayable -= uint128(assets);

        // Logic below is similar to standard `deposit()` logic, but bypasses maxDeposit and msg.value checks.
        // `false` indicates that msg.value should not be deducted from total assets before calculating shares. Recent
        // revenue will also not be deducted from total assets.
        shares = _previewDeposit(assets, false);
        _mint(to, shares);

        // NOTE: `_accountForDeposit()` not called, as no new assets are being deposited

        // Persist AdminValues changes to storage
        s_admin = _admin;

        // Transfer event emitted by _mint(). Additional Deposit event emitted here.
        emit ZeroYieldBalanceConvertedToShares(from, to, assets, shares);
        emit Deposit(from, to, assets, shares);
    }

    /// @notice Returns the zero-yield tranche balance of an account
    /// @param account The account to query
    /// @return The zero-yield tranche balance of the account, in MON
    /// @custom:selector 0x1d07c5cf
    function balanceOfZeroYieldTranche(address account) external view returns (uint256) {
        return s_zeroYieldBalances[account];
    }

    /// @notice Returns the unclaimed owner commission balance
    /// @return The unclaimed owner commission balance, in MON
    /// @custom:selector 0x41faf0a7
    function unclaimedOwnerCommission() external view returns (uint256) {
        return s_zeroYieldBalances[OWNER_COMMISSION_ACCOUNT];
    }
}
