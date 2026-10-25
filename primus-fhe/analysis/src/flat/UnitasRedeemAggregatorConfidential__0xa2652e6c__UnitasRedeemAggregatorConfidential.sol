// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {UnitasAggregatorConfidentialUpgradeable, IUnitasProxy} from "./UnitasAggregatorConfidentialUpgradeable.sol";
import {IConfidentialERC20Converter} from "../converter/interfaces/IConfidentialERC20Converter.sol";

/// @dev Minimal view of the Unitas staked token (sUSDu) interface the redeem aggregator relies on.
/// Confirm the real sUSDu ABI matches before mainnet wiring (cooldown signature / unstake semantics).
struct UserCooldown {
  uint104 cooldownEnd;
  uint256 underlyingAmount;
}
interface IUnitasStakedToken {
    /// @dev Starts the cooldown for `shares` belonging to `owner` (the share holder).
    function cooldownShares(uint256 shares) external;
    /// @dev After cooldown elapses, withdraws all cooled shares and sends the underlying to `receiver`.
    function unstake(address receiver) external;
    /// @return The user's pending cooldown.
    function cooldowns(address owner) external view returns (UserCooldown memory);
}

/**
 * @title UnitasRedeemAggregatorConfidential
 * @notice Confidential redeem aggregator for the Unitas USDu Booster off-chain API.
 *
 * Route: esUSDu -> (unshield sUSDu, cooldownShares, wait 7d, unstake -> USDu, approve UnitasProxy,
 * keeper calls proxy_redeem API) -> USDT -> shield -> eUSDT. Users deposit esUSDu and claim eUSDT.
 *
 * The 7-day sUSDu cooldown is unavoidable (cannot pre-cooldown), so `callbackDeadline_` should exceed 7
 * days plus a keeper buffer. If the keeper starts the cooldown late the batch simply settles after the
 * deadline — late, not stuck: `_executeRoute` keeps advancing non-`*Init` steps past the deadline.
 * Unshielded sUSDu sits plaintext at this contract for the cooldown period.
 *
 * The contract never calls UnitasProxy on-chain; it only approves UnitasProxy to pull USDu and
 * re-shields the USDT once it arrives.
 *
 * Upgradeable: deployed behind a UUPS proxy via {initialize}.
 */
contract UnitasRedeemAggregatorConfidential is UnitasAggregatorConfidentialUpgradeable {
    /// @dev Keeps the `reinitializer` version aligned between `initialize` and any future `reinitializeVX`.
    uint64 private constant REINITIALIZER_VERSION = 1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the redeem aggregator behind a UUPS proxy.
    /// @param esUSDu_ Confidential converter over sUSDu (input token).
    /// @param eUSDT_ Confidential converter over USDT (output token).
    /// @param unitasProxy_ UnitasProxy address (approve target + API `address`). USDu is derived from it.
    /// @param keeper_ Exclusive caller of `dispatchAggregateCallback` (rotatable by the owner via
    ///   `setKeeper`).
    /// @param owner_ Owner authorized to update policy.
    /// @param minAggregateAge_ Minimum seconds an aggregate must age before dispatch.
    /// @param callbackDeadline_ Seconds after dispatch before the aggregate may cancel. Should exceed the
    ///   sUSDu cooldown (7 days) plus keeper buffer (e.g. 8 days); a late cooldown merely settles after
    ///   the deadline rather than stranding the batch (see `_executeRoute`).
    /// @custom:oz-upgrades-validate-as-initializer
    function initialize(
        IConfidentialERC20Converter esUSDu_,
        IConfidentialERC20Converter eUSDT_,
        address unitasProxy_,
        address keeper_,
        address owner_,
        uint256 minAggregateAge_,
        uint256 callbackDeadline_
    ) public reinitializer(REINITIALIZER_VERSION) {
        // `vault_` holds UnitasProxy.staked() (sUSDu, a real ERC4626); validated in `_validateVaultAssetMatch`.
        // Slippage check is unused by this route (0 = disabled).
        __VaultAggregatorConfidential_init(
            esUSDu_, eUSDT_, IERC4626(IUnitasProxy(unitasProxy_).staked()), owner_, minAggregateAge_, callbackDeadline_, 0
        );
        __UnitasAggregatorConfidential_init(unitasProxy_, keeper_);
    }

    /// @notice Human-readable summary of the redeem route.
    /// @dev Two layers: users deposit/claim confidential tokens (esUSDu -> eUSDT); the underlying
    /// plaintext route inside `_executeUnitasStep` is sUSDu -> (7d cooldown) -> USDu -> USDT via the
    /// off-chain Unitas API.
    function routeDescription() public pure override returns (string memory) {
        return "Unitas USDu Booster redeem: esUSDu -> eUSDT (underlying sUSDu -> USDu -> USDT via off-chain API, 7d cooldown).";
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    function _initialStep() internal pure override returns (Step) {
        return Step.RedeemInit;
    }

    /// @dev Override of the base join: additionally grants the configured reward pool persistent
    /// access to the user's cumulative esUSDu deposit handle, so the pool's keeper can settle rewards
    /// via `UnitasRewardPool.claimRewardBatch` once this aggregate is dispatched. The base `_join` already
    /// granted this aggregator access to the handle, and only an existing holder can re-grant — hence
    /// the grant must happen here.
    function _join(address to, ve_uint64 amount) internal override returns (ve_uint64) {
        ve_uint64 joinedAmount = super._join(to, amount);
        address pool = _rewardPool();
        if (pool != address(0)) {
            FHE.accessPolicy(deposits(currentAggregateId(), to), pool);
        }
        return joinedAmount;
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev Redeem calls `cooldownShares`/`unstake` on the INPUT underlying (`fromToken_`, the esUSDu
    /// converter's sUSDu), so the staked token must equal it. Requiring the output side instead would
    /// let a reversed converter pair pass initialization and then call the cooldown API on USDT.
    function _stakedTokenUnderlying(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter
    ) internal view override returns (address) {
        return fromToken_.underlying();
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev `amount` is in esUSDu converter units; `rawSUSDu = amount * fromToken().rate()` (sUSDu shares).
    /// Unstake converts sUSDu shares to USDu 1:1; the off-chain API then redeems USDu to USDT.
    function _executeUnitasStep(uint256 aggregateId, uint256 amount, Step step) internal override returns (ExecuteOutcome) {
        UnitasAggregatorStorage storage $ = _getUnitasAggregatorStorage();
        // sUSDu (the staked token exposing cooldownShares/unstake) is the esUSDu converter's underlying.
        // Do NOT use `_usdu()` here — that returns USDu, the underlying asset, which has no cooldown API.
        IUnitasStakedToken staked = IUnitasStakedToken(fromToken().underlying());
        uint256 rawSUSDu = amount * fromToken().rate();

        if (step == Step.RedeemInit) {
            // Irreversible: lock the sUSDu into the 7-day cooldown. The keeper waits, then advances.
            staked.cooldownShares(rawSUSDu);
            $._aggregateStep[aggregateId] = Step.RedeemCooldown;
            emit StepAdvanced(aggregateId, Step.RedeemCooldown);
            return ExecuteOutcome.Partial;
        }

        if (step == Step.RedeemCooldown) {
            UserCooldown memory userCooldown = staked.cooldowns(address(this));
            if (block.timestamp < userCooldown.cooldownEnd) return ExecuteOutcome.Partial;
            // Unstake converts cooled sUSDu shares into USDu at this address. Approve only the USDu actually
            // received this step (balance delta) — not the full USDu balance, which may belong to other
            // in-flight aggregates.
            address usdu = _usdu();
            uint256 usduBefore = IERC20(usdu).balanceOf(address(this));
            staked.unstake(address(this));
            uint256 rawUSDu = IERC20(usdu).balanceOf(address(this)) - usduBefore;
            SafeERC20.forceApprove(IERC20(usdu), _unitasProxy(), rawUSDu);
            $._aggregateStep[aggregateId] = Step.RedeemAwaitOutput;
            emit StepAdvanced(aggregateId, Step.RedeemAwaitOutput);
            return ExecuteOutcome.Partial;
        }

        // RedeemAwaitOutput: the keeper only re-enters this callback once the off-chain API has delivered
        // the USDT, so reaching this step means the output is present — finalize. If the callback runs
        // before delivery, the base `Complete` branch reverts on a zero exchange rate (no USDT to shield),
        // leaving the aggregate `Dispatched` for the keeper to retry.
        return ExecuteOutcome.Complete;
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev Redeem approved the unstaked USDu to UnitasProxy when the batch entered `RedeemAwaitOutput`;
    /// earlier steps hold no allowance.
    function _revokeProxyAllowance(Step step) internal override {
        if (step == Step.RedeemAwaitOutput) {
            SafeERC20.forceApprove(IERC20(_usdu()), _unitasProxy(), 0);
        }
    }
}
