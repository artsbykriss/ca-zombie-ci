// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {VaultAggregatorConfidentialUpgradeable} from "./VaultAggregatorConfidentialUpgradeable.sol";
import {AggregatorConfidentialUpgradeable} from "./AggregatorConfidentialUpgradeable.sol";
import {IConfidentialERC20Converter} from "../converter/interfaces/IConfidentialERC20Converter.sol";

/// @dev Minimal view of the external UnitasProxy contract. It exposes public getters for the tokens the
/// aggregator needs, so they are derived at runtime rather than configured (and stay fresh if UnitasProxy
/// is ever reconfigured). `staked` returns the sUSDu ERC4626; `usdu` returns the USDu address.
interface IUnitasProxy {
    function usdu() external view returns (address);
    function staked() external view returns (address);
}

/**
 * @title UnitasAggregatorConfidentialUpgradeable
 * @notice Shared async-route machinery for the two Unitas USDu Booster aggregators (mint + redeem).
 *
 * Each leaf contract is unidirectional with a fixed `fromToken` / `toToken`, so the inherited base
 * (`VaultAggregatorConfidentialUpgradeable`) is reused verbatim for aggregation, unshield, claim, quit,
 * dispatch, min-age, pause and deadline. This intermediate base only adds:
 *   - an async `Step` state machine stored per aggregate,
 *   - a cancel-safe `_executeRoute` (cancels only from an `*Init` step, before any irreversible action;
 *     past the point-of-no-return it keeps advancing the route even after the pinned callback deadline,
 *     so a keeper that starts the redeem cooldown late can never strand a batch mid-route — the deadline
 *     only bounds how long an untouched aggregate may wait before it may be canceled),
 *   - serialized dispatches (the previous aggregate must settle before a new one is dispatched, because
 *     the inherited finalization shields the contract's entire toToken-underlying balance),
 *   - a keeper-gated `dispatchAggregateCallback`: the callback parameters are public and replayable,
 *     and the `*AwaitOutput` steps return `Complete` without verifying that the external order's output
 *     actually arrived, so anyone could replay them after donating dust and finalize a waiting batch at
 *     a near-zero rate (its real output, arriving later, would be swept into the NEXT batch). Restricting
 *     settlement to a dedicated keeper removes that replay surface. The keeper is exclusive — even the
 *     deadline/pause cancel path requires it; if the keeper goes down the owner rotates it via
 *     `setKeeper` or settles directly via `recoverAggregate`,
 *   - an owner `recoverAggregate` escape hatch, and
 *   - the UnitasProxy address (approve target). USDu and sUSDu are derived from UnitasProxy at runtime.
 *
 * The contract never calls UnitasProxy's `mintAndStake` / `redeemAndWithdraw`; it only approves
 * UnitasProxy to pull the unshielded input and re-shields the output once it arrives. The keeper drives
 * the off-chain Unitas API and is the only account allowed to dispatch and advance aggregates via
 * `dispatchAggregate` / `dispatchAggregateCallback`.
 *
 * The inherited `vault_` slot holds `UnitasProxy.staked()` (sUSDu, a real ERC4626), which also lets
 * `_validateVaultAssetMatch` check the configured esUSDu converter matches the Unitas staked token.
 *
 * Upgradeable: deployed behind a UUPS proxy via the leaf `initialize`. Storage is ERC-7201 namespaced.
 */
abstract contract UnitasAggregatorConfidentialUpgradeable is VaultAggregatorConfidentialUpgradeable {
    /// @dev Async route step. `*Init` steps have not yet performed any irreversible action and may still
    /// be safely canceled. Each leaf uses only its own direction's steps.
    enum Step {
        None,
        MintInit,
        MintAwaitOutput,
        RedeemInit,
        RedeemCooldown,
        RedeemAwaitOutput
    }

    /// @custom:storage-location erc7201:primus.fhetransform.storage.UnitasAggregator
    struct UnitasAggregatorStorage {
        /// @dev UnitasProxy: approve target and the API `address`. USDu / sUSDu are derived from it.
        address _unitasProxy;
        /// @dev Per-aggregate async step.
        mapping(uint256 => Step) _aggregateStep;
        /// @dev Exclusive caller of `dispatchAggregate` and `dispatchAggregateCallback`. Appended after
        /// the existing fields so already-initialized proxies keep their layout; the owner sets it
        /// post-upgrade via `setKeeper`.
        address _keeper;
        /// @dev Optional UnitasRewardPool the aggregators grant deposit/claim handle access to, so the
        /// pool can run FHE arithmetic on user amounts (zero = disabled). Appended after the existing
        /// fields so already-initialized proxies keep their layout; the owner sets it via `setRewardPool`.
        address _rewardPool;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.UnitasAggregator")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant UNITAS_AGGREGATOR_STORAGE_LOCATION =
        0x142a13949d132549eac27f603ede7446bc81c131ebb3c3723e329282dd1b6d00;

    /// @dev Thrown when a required address argument (UnitasProxy, or the staked token derived from it)
    /// is the zero address.
    error ZeroAddress();

    /// @dev Thrown by `recoverAggregate(forceComplete=true)` when the contract holds no `toToken`
    /// underlying balance to shield and finalize with.
    error NothingToShield();

    /// @dev Thrown by `recoverAggregate` when `aggregateId` has no step (Step.None), i.e. it was never
    /// opened/committed and cannot be recovered.
    error NotCommittedAggregate();

    /// @dev Thrown by `recoverAggregate` when `aggregateId` is not in the `Dispatched` state. Recovery is
    /// an escape hatch for stuck in-flight aggregates only: calling it on an `Open` aggregate would orphan
    /// un-unshielded deposits, and calling it on an already-`Finalized`/`Canceled` aggregate would overwrite
    /// the settled exchange rate / flags.
    error NotDispatchedAggregate();

    /// @dev Thrown by `dispatchAggregate` when the previous aggregate has not yet settled. The keeper
    /// must settle it first (normal callback, or the owner via `recoverAggregate` if it is stuck) before
    /// a new batch can be dispatched, so stranded output can never be swept into a later batch's
    /// finalization.
    error PreviousAggregateUnsettled(uint256 aggregateId);

    /// @dev Thrown by `dispatchAggregate` / `dispatchAggregateCallback` when the caller is not the keeper.
    error NotKeeper(address caller);

    /// @dev Thrown by `_validateVaultAssetMatch` when `UnitasProxy.staked()` (the sUSDu address) does not
    /// match either converter's underlying. `actual` is the staked address; `expected` is the fromToken
    /// underlying (the esUSDu converter's sUSDu) that should match it.
    error StakedTokenMismatch(address actual, address expected);

    /// @dev Aggregate `aggregateId` advanced to `step`.
    event StepAdvanced(uint256 indexed aggregateId, Step step);

    /// @dev Owner force-recovered a stuck aggregate.
    event Recovered(uint256 indexed aggregateId, bool forceComplete);

    /// @dev The keeper was rotated to `keeper`.
    event KeeperSet(address indexed keeper);

    /// @dev The reward pool was set to `rewardPool` (zero = disabled).
    event RewardPoolSet(address indexed rewardPool);

    /// @dev Returns a pointer to the unitas aggregator namespaced storage.
    function _getUnitasAggregatorStorage() internal pure returns (UnitasAggregatorStorage storage $) {
        assembly {
            $.slot := UNITAS_AGGREGATOR_STORAGE_LOCATION
        }
    }

    /// @dev Stores the UnitasProxy address and the keeper. USDu and sUSDu are derived from UnitasProxy at
    /// runtime. Must be called after `__VaultAggregatorConfidential_init` (which reads
    /// `_validateVaultAssetMatch`).
    function __UnitasAggregatorConfidential_init(address unitasProxy_, address keeper_) internal onlyInitializing {
        require(unitasProxy_ != address(0), ZeroAddress());
        require(keeper_ != address(0), ZeroAddress());
        UnitasAggregatorStorage storage $ = _getUnitasAggregatorStorage();
        $._unitasProxy = unitasProxy_;
        $._keeper = keeper_;
        emit KeeperSet(keeper_);
    }

    /// @dev The UnitasProxy address (approve target + API `address`).
    function _unitasProxy() internal view returns (address) {
        return _getUnitasAggregatorStorage()._unitasProxy;
    }

    /// @dev USDu address, derived from UnitasProxy. Used by the redeem route to approve UnitasProxy.
    function _usdu() internal view returns (address) {
        return IUnitasProxy(_unitasProxy()).usdu();
    }

    // ----------------------------------------------------------------------------------------------
    // Views
    // ----------------------------------------------------------------------------------------------

    /// @return The UnitasProxy address (approve target + API `address`).
    function unitasProxy() external view returns (address) {
        return _unitasProxy();
    }

    /// @return The async step of `aggregateId`.
    function aggregateStep(uint256 aggregateId) external view returns (Step) {
        return _getUnitasAggregatorStorage()._aggregateStep[aggregateId];
    }

    /// @return The keeper: the only account allowed to call `dispatchAggregate` and
    /// `dispatchAggregateCallback`.
    function keeper() external view returns (address) {
        return _getUnitasAggregatorStorage()._keeper;
    }

    /// @return The reward pool granted access to deposit/claim handles (zero = disabled).
    function rewardPool() external view returns (address) {
        return _rewardPool();
    }

    /// @dev The configured reward pool, or zero when rewards are disabled.
    function _rewardPool() internal view returns (address) {
        return _getUnitasAggregatorStorage()._rewardPool;
    }

    // ----------------------------------------------------------------------------------------------
    // Settlement: keeper-gated callback
    // ----------------------------------------------------------------------------------------------

    /// @notice Rotates the keeper. Owner only.
    /// @dev The keeper is the single settlement key for every in-flight aggregate; rotate it promptly
    /// if it is compromised or goes offline (a dead keeper otherwise strands batches until the owner
    /// settles them via `recoverAggregate`). Prefer an address whose key is held by a multisig or a
    /// hardened signer. Emits {KeeperSet}.
    function setKeeper(address keeper_) external onlyOwner {
        require(keeper_ != address(0), ZeroAddress());
        _getUnitasAggregatorStorage()._keeper = keeper_;
        emit KeeperSet(keeper_);
    }

    /// @notice Sets the reward pool the aggregators grant deposit/claim handle access to. Owner only.
    /// @dev ACL rule: only an existing access holder can grant access, so the leaves grant the pool
    /// access to the mint claim-amount handle (`_claim`) and the redeem cumulative-deposit handle
    /// (`_join`) at the moment those handles exist. Pass zero to disable. Existing handles from
    /// before the upgrade are NOT granted retroactively — only new claims/joins are covered.
    function setRewardPool(address rewardPool_) external onlyOwner {
        _getUnitasAggregatorStorage()._rewardPool = rewardPool_;
        emit RewardPoolSet(rewardPool_);
    }

    /// @notice Advances settlement of a dispatched aggregate; callable only by the keeper.
    /// @dev The callback parameters are public and replayable (the base re-verifies the settled
    /// unshield's signature on every re-entry), and the `*AwaitOutput` steps return `Complete` without
    /// verifying that the external order's output actually arrived. If anyone could call this, a dust
    /// donation plus a replayed proof would finalize a waiting batch at a near-zero rate, and the
    /// batch's real output — arriving later — would be swept into the NEXT batch's full-balance
    /// finalization. Gating on the keeper removes that replay surface. The gate is strict: the
    /// deadline/pause cancel path (only available from an `*Init` step, see `_executeRoute`) also
    /// requires the keeper, since a permissionless cancel would still let a griefer force-cancel
    /// batches the keeper intends to settle.
    ///
    /// Fee session: this entry point charges via `chargeFeeAsSelf` — the aggregator itself is the FHE
    /// fee payer and the attached `msg.value` tops up the aggregator's prepaid balance at the executor,
    /// so the protocol funds settlement centrally and the keeper only supplies gas (plus the FHE
    /// prepayment). Unlike the base's `chargeFeeIfExternal` this also works when the keeper is a
    /// contract wallet (multisig): charging the caller would revert `UnauthorizedFeeUser` because a
    /// contract caller is neither `msg.sender` nor `tx.origin` of the executor call. It calls
    /// `_dispatchAggregateCallback` directly rather than `super.dispatchAggregateCallback`, whose
    /// `chargeFeeIfExternal` would double-charge (`UserLockedInTx`); it therefore re-declares
    /// `nonReentrant` itself.
    function dispatchAggregateCallback(
        uint256 aggregateId,
        uint64 unshieldAmountCleartext,
        bytes calldata decryptionProof
    ) public payable override nonReentrant chargeFeeAsSelf {
        require(msg.sender == _getUnitasAggregatorStorage()._keeper, NotKeeper(msg.sender));
        _dispatchAggregateCallback(aggregateId, unshieldAmountCleartext, decryptionProof);
    }

    // ----------------------------------------------------------------------------------------------
    // Dispatch serialization: at most one unsettled aggregate at a time
    // ----------------------------------------------------------------------------------------------

    /// @notice Dispatches the current aggregate only after the previous one has settled; keeper only.
    /// @dev The inherited callback finalizes by shielding the contract's ENTIRE toToken-underlying
    /// balance (not a per-aggregate delta). That sweep is only sound if everything in the balance
    /// belongs to the completing aggregate — i.e. at most one unsettled aggregate exists at a time.
    /// Serializing dispatches restores that invariant: a stuck aggregate blocks new dispatches until
    /// the owner settles it via `recoverAggregate`, so its stranded output can never be swept into a
    /// later batch (and `recoverAggregate`'s own full-balance sweep is then correct, since no other
    /// aggregate can be in-flight when it runs).
    ///
    /// Only the immediately previous aggregate needs checking: ids increment only here, so by
    /// induction every earlier aggregate was required to settle before the previous one dispatched.
    /// Deposits into the open aggregate are unaffected, and users may still `quit` it.
    ///
    /// Gated to the keeper (like `dispatchAggregateCallback`): dispatch starts the off-chain Unitas
    /// order the keeper drives, so the operator alone drives the batch pipeline. Charged via
    /// `chargeFeeAsSelf` — the aggregator's own prepaid executor balance pays for the FHE ops
    /// (`msg.value` tops it up), which also keeps the entry point callable by a contract-wallet
    /// keeper (Safe multisig): charging the caller would revert `UnauthorizedFeeUser`. Calls
    /// `_dispatchAggregate` directly rather than `super.dispatchAggregate`, whose `chargeFeeIfExternal`
    /// would double-charge (`UserLockedInTx`); the pause and min-age guards still run inside the
    /// inherited `_dispatchAggregate` override.
    function dispatchAggregate() public payable override chargeFeeAsSelf {
        require(msg.sender == _getUnitasAggregatorStorage()._keeper, NotKeeper(msg.sender));
        uint256 previousId = currentAggregateId() - 1;
        if (previousId > 0) {
            AggregateState previousState = aggregateState(previousId);
            require(
                previousState == AggregateState.Finalized || previousState == AggregateState.Canceled,
                PreviousAggregateUnsettled(previousId)
            );
        }
        _dispatchAggregate();
    }

    // ----------------------------------------------------------------------------------------------
    // Async route: cancel-safe wrapper delegating to the leaf step handler
    // ----------------------------------------------------------------------------------------------

    /// @inheritdoc VaultAggregatorConfidentialUpgradeable
    /// @dev Fully replaces the base route. Cancel is only allowed from an `*Init` step (before any
    /// irreversible action), where the original `fromToken` is still present and the base can safely
    /// re-shield it. Past that point the route refuses to cancel and relies on the keeper (and
    /// `recoverAggregate`) to make progress.
    ///
    /// Unlike the base, a passed callback deadline does NOT halt forward progress: for non-`*Init`
    /// steps execution still delegates to `_executeUnitasStep` after the deadline, so a keeper that
    /// starts the redeem cooldown late can still unstake and settle once the cooldown elapses. The
    /// point-of-no-return can only be crossed before the deadline (at/after it an `*Init` step can
    /// only cancel), so a deadline cancel always finds the input untouched and re-shieldable.
    function _executeRoute(uint256 aggregateId, uint256 amount) internal override returns (ExecuteOutcome) {
        UnitasAggregatorStorage storage $ = _getUnitasAggregatorStorage();
        Step step = $._aggregateStep[aggregateId];

        bool isInit = step == Step.MintInit || step == Step.RedeemInit;
        if (paused()) {
            return isInit ? ExecuteOutcome.Cancel : ExecuteOutcome.Partial;
        }

        VaultAggregatorConfidentialStorage storage v$ = _getVaultAggregatorConfidentialStorage();
        bool deadlinePassed = block.timestamp >= v$._aggregateDispatchedAt[aggregateId] + v$._aggregateCallbackDeadline[aggregateId];

        if (deadlinePassed && isInit) {
            return ExecuteOutcome.Cancel;
        }

        return _executeUnitasStep(aggregateId, amount, step);
    }

    /// @dev Unreachable: the base declares this abstract, but `_executeRoute` is fully overridden and
    /// never delegates to the vault-route hook.
    function _executeVaultRoute(uint256, uint256) internal pure override returns (ExecuteOutcome) {
        revert("UnitasAggregator: unreachable");
    }

    /// @dev Tags each freshly opened aggregate with the leaf's initial step.
    function _afterInitializeCurrentAggregate(uint256 aggregateId) internal override {
        _getUnitasAggregatorStorage()._aggregateStep[aggregateId] = _initialStep();
    }

    // ----------------------------------------------------------------------------------------------
    // Owner recovery
    // ----------------------------------------------------------------------------------------------

    /// @notice Owner escape hatch that force-moves a stuck aggregate to a terminal state so users can
    /// `claim` or `quit`.
    ///
    /// @dev When to use: once an aggregate passes its point-of-no-return (mint has approved USDT to
    /// UnitasProxy, or redeem has called `cooldownShares`), `_executeRoute` refuses to cancel and only
    /// returns `Partial`. If the keeper then never advances it (keeper down, or the off-chain Unitas API
    /// permanently failed for this order), the aggregate is stuck in `Dispatched` and user funds are
    /// locked. This function lets the owner manually push it to `Finalized` or `Canceled`.
    ///
    /// It bypasses the step machine and the cancel guard, replicating what the base `dispatchAggregateCallback`
    /// does on `Complete`/`Cancel`. Both branches first revoke any remaining UnitasProxy allowance the
    /// aggregate granted (via `_revokeProxyAllowance`), so a forced settle never leaves a live spending
    /// capability behind:
    ///   - `forceComplete = true`  → shield whatever `toToken` underlying (output) is currently in the
    ///     contract, set the exchange rate, mark `Finalized`. Users then `claim` their `toToken`. Use when
    ///     the output has already arrived (e.g. sUSDu/USDT delivered by the API) but the callback never ran.
    ///   - `forceComplete = false` → re-shield `unshieldAmountCleartext * fromToken().rate()` of the
    ///     `fromToken` underlying (input) back into confidential `fromToken`, mark `Canceled`. Users then
    ///     `quit` to recover their original deposit. Use when the input has NOT been consumed yet.
    ///
    /// The owner MUST verify actual on-chain balances and pick the mode accordingly before calling —
    /// shielding funds that are no longer present reverts. Rough guide:
    ///   - mint stuck at `MintAwaitOutput`, USDT not pulled            → `false` (re-shield USDT, refund)
    ///   - mint, API already delivered sUSDu but callback #2 never ran → `true`  (shield sUSDu, finalize)
    ///   - redeem stuck at `RedeemInit`, sUSDu not yet locked          → `false` (re-shield sUSDu, refund)
    ///   - redeem, API already delivered USDT but callback #3 never ran→ `true`  (shield USDT, finalize)
    ///   - redeem mid-cooldown (`RedeemCooldown`) or after unstake with no USDT yet → neither mode works
    ///     cleanly; the owner must first let cooldown elapse and advance via `dispatchAggregateCallback`
    ///     (forward execution continues even after the callback deadline, so this always works).
    ///
    /// @param aggregateId The stuck aggregate to recover.
    /// @param unshieldAmountCleartext The aggregate's decrypted unshield amount (converter units). The
    ///   owner reads it from the aggregate's `totalDeposits` decryption / off-chain records; it is the
    ///   same cleartext used in the callbacks. Used to size the re-shield (`false`) and to compute the
    ///   exchange rate (`true`).
    /// @param forceComplete `true` to finalize (shield output, users `claim`); `false` to cancel
    ///   (re-shield input, users `quit`).
    ///
    /// Fee session: both branches call a converter's `shield`, which performs charged FHE operations.
    /// This function is therefore `payable` and charges via `chargeFeeAsSelf`, locking the aggregator
    /// itself as the transaction's FHE fee payer (the attached `msg.value` tops up the aggregator's
    /// prepaid balance at the executor), so the owner may be a contract wallet (multisig) — charging
    /// the caller would revert `UnauthorizedFeeUser` for a contract caller. The nested `shield` calls
    /// skip charging because this aggregator is registered as a fee-skip caller on both converters
    /// (done at deployment), so they reuse this outer session instead of reverting on a
    /// missing/duplicate `chargeFee`. The owner must attach enough `msg.value` to cover the FHE
    /// prepayment.
    function recoverAggregate(uint256 aggregateId, uint64 unshieldAmountCleartext, bool forceComplete)
        external
        payable
        onlyOwner
        nonReentrant
        chargeFeeAsSelf
    {
        // Recovery is an escape hatch for aggregates stuck in-flight (`Dispatched`). It must not run on an
        // `Open` aggregate (deposits not yet unshielded — re-shielding/finalizing would orphan them with no
        // refund path), nor on an already-settled `Finalized`/`Canceled` aggregate (would overwrite the
        // exchange rate / flags and change payouts for un-claimed users).
        require(aggregateState(aggregateId) == AggregateState.Dispatched, NotDispatchedAggregate());

        UnitasAggregatorStorage storage $ = _getUnitasAggregatorStorage();
        // `Dispatched` implies a step was committed, but guard defensively against a corrupt state slot.
        require($._aggregateStep[aggregateId] != Step.None, NotCommittedAggregate());

        // Revoke whatever per-batch allowance this aggregate granted UnitasProxy before settling. The
        // approval is keyed by (token, spender), not by the batch that created it, so a forced cancel
        // (input never pulled) or force-complete (input only partially pulled) would otherwise leave a
        // live spending capability over matching tokens the contract holds now or receives later.
        // Dispatch serialization guarantees no other aggregate can hold an allowance at this point.
        _revokeProxyAllowance($._aggregateStep[aggregateId]);

        AggregatorConfidentialStorage storage a$ = _getAggregatorConfidentialStorage();
        if (forceComplete) {
            // Shield the output currently held and finalize, so users can claim toToken.
            uint256 balance = IERC20(toToken().underlying()).balanceOf(address(this));
            require(balance > 0, NothingToShield());
            toToken().shield(address(this), balance);
            uint256 shieldedAmount = balance / toToken().rate();
            uint64 exchangeRate_ = SafeCast.toUint64(
                Math.mulDiv(shieldedAmount, uint256(10) ** exchangeRateDecimals(), uint256(unshieldAmountCleartext))
            );
            require(
                exchangeRate_ != 0 && shieldedAmount <= type(uint64).max,
                InvalidExchangeRate(aggregateId, unshieldAmountCleartext, exchangeRate_)
            );
            a$._aggregatees[aggregateId].exchangeRate = exchangeRate_;
            emit AggregateFinalized(aggregateId, exchangeRate_);
        } else {
            // Re-shield the input (still held as plaintext) back into confidential fromToken and cancel,
            // so users can quit and recover their original deposit. Mirrors the base Cancel branch.
            fromToken().shield(address(this), uint256(unshieldAmountCleartext) * fromToken().rate());
            a$._aggregatees[aggregateId].canceled = true;
            emit AggregateCanceled(aggregateId);
        }
        // Clear the step so the now-settled aggregate cannot be recovered again (which would overwrite the
        // settled exchange rate / canceled flag).
        $._aggregateStep[aggregateId] = Step.None;
        emit Recovered(aggregateId, forceComplete);
    }

    // ----------------------------------------------------------------------------------------------
    // Validation overrides
    // ----------------------------------------------------------------------------------------------

    /// @dev Replaces the ERC4626 asset/share match. `vault_` is `UnitasProxy.staked()` (sUSDu); it must
    /// equal the leaf-specific converter underlying (see `_stakedTokenUnderlying`): Mint awaits sUSDu as
    /// the output (`toToken`), while Redeem calls the cooldown API on the input (`fromToken`). A
    /// direction-agnostic OR check would let a reversed converter pair pass initialization and then
    /// deterministically break the route after users deposit. No other IERC4626 calls are made.
    function _validateVaultAssetMatch(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter toToken_,
        IERC4626 vault_
    ) internal view override {
        address staked = address(vault_);
        require(staked != address(0), ZeroAddress());
        address expected = _stakedTokenUnderlying(fromToken_, toToken_);
        require(staked == expected, StakedTokenMismatch(staked, expected));
        require(fromToken_.underlying() != toToken_.underlying(), DuplicateUnderlyingTokens());
    }

    /// @dev No persistent extra approvals: per-step exact `forceApprove` to UnitasProxy handles pulling.
    /// The base init already force-approves the converter pair for shield/unshield.
    function _initializeApprovals(IConfidentialERC20Converter, IConfidentialERC20Converter, IERC4626) internal override {}

    // ----------------------------------------------------------------------------------------------
    // Leaf hooks
    // ----------------------------------------------------------------------------------------------

    /// @dev Advances one step of the async route. Called only when not cancelling.
    function _executeUnitasStep(uint256 aggregateId, uint256 amount, Step step)
        internal
        virtual
        returns (ExecuteOutcome);

    /// @return The initial `Step` for a freshly opened aggregate (leaf-specific).
    function _initialStep() internal pure virtual returns (Step);

    /// @return The converter underlying that `UnitasProxy.staked()` (sUSDu) must equal for this route
    /// (leaf-specific, enforced by `_validateVaultAssetMatch`). Mint: `toToken_` underlying (sUSDu is the
    /// awaited output). Redeem: `fromToken_` underlying (the cooldown API is called on the input).
    function _stakedTokenUnderlying(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter toToken_
    ) internal view virtual returns (address);

    /// @dev Revokes any remaining UnitasProxy allowance created by the aggregate at `step`. Called by
    /// `recoverAggregate` before it settles the aggregate. Approvals are exact per batch and normally
    /// consumed to zero by the proxy's pull, so only the `*AwaitOutput` steps can leave residue
    /// (leaf-specific: Mint approved USDT, Redeem approved USDu).
    function _revokeProxyAllowance(Step step) internal virtual;
}
