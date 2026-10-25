// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {PrimusConfigUpgradeable} from "@primuslabs/fhe-contracts/contracts/config/PrimusConfigUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AggregatorConfidentialUpgradeable} from "./AggregatorConfidentialUpgradeable.sol";
import {IConfidentialERC20Converter} from "../converter/interfaces/IConfidentialERC20Converter.sol";
import {IVaultAggregatorConfidentia} from "./interfaces/IVaultAggregatorConfidential.sol";

/// @title VaultAggregatorConfidentialUpgradeable
/// @notice Shared logic for confidential deposit/redeem aggregators.
/// @dev Child contracts supply route-specific token checks, approvals, and vault execution.
///
/// After dispatch, the aggregate must complete before the callback deadline.
/// Otherwise, it is automatically canceled.
///
/// Notes:
/// - Deposit amounts are encrypted, so a per-aggregate size cap cannot be enforced on-chain. A griefer can
///   force a aggregate to deadline-cancel and repeat via `quit`; keep `minAggregateAge` and `callbackDeadline`
///   tight so the griefing cycle is slow relative to organic aggregate cadence.
/// - The base callback wraps the full `toToken` balance at finalization, so residual dust from a prior
///   aggregate is absorbed into the next finalized aggregate. Avoid many simultaneously-finalizable aggregatees.
/// - Confidentiality is best-effort. When a aggregate reaches `minAggregateAge` with a single depositor, the
///   unshield publicly reveals that depositor's amount.
///
/// Upgradeable: storage is namespaced under ERC-7201 and initialization is performed via
/// {__VaultAggregatorConfidential_init}. Concrete contracts disable initializers in their constructor and
/// expose an `initialize` function for proxy deployment.
abstract contract VaultAggregatorConfidentialUpgradeable is
    IVaultAggregatorConfidentia,
    PrimusConfigUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AggregatorConfidentialUpgradeable
{
    /// @dev Maximum slippage value in basis points (100% = 10 000 bps).
    uint16 internal constant MAX_BPS = 10_000;

    /// @dev Upper bound on `minAggregateAge`. Prevents operator error and overflow on the age check.
    uint256 internal constant MAX_MIN_AGGREGATE_AGE = 7 days;

    /// @dev Upper bound on `callbackDeadline`. Prevents overflow on the deadline check at callback time.
    uint256 internal constant MAX_CALLBACK_DEADLINE = 30 days;

    /// @custom:storage-location erc7201:primus.fhetransform.storage.VaultAggregatorConfidential
    struct VaultAggregatorConfidentialStorage {
        /// @dev ERC4626 vault this aggregator routes aggregated amounts through.
        IERC4626 _vault;
        /// @dev Minimum seconds a aggregate must exist before it can be dispatched.
        uint256 _minAggregateAge;
        /// @dev Seconds after dispatch before the route is no longer attempted (0 = cancel on first callback).
        uint256 _callbackDeadline;
        /// @dev Maximum tolerated slippage in basis points (0 = disabled).
        uint16 _maxSlippageBps;
        /// @dev Timestamp when each aggregate was opened (for min-age enforcement).
        mapping(uint256 aggregateId => uint256 timestamp) _aggregateCreatedAt;
        /// @dev Timestamp when each aggregate was dispatched (for callback deadline enforcement).
        mapping(uint256 aggregateId => uint256 timestamp) _aggregateDispatchedAt;
        /// @dev Per-aggregate slippage tolerance, frozen at aggregate creation so policy changes don't affect open aggregatees.
        mapping(uint256 aggregateId => uint16 maxSlippageBps) _aggregateMaxSlippageBps;
        /// @dev Per-aggregate min age, frozen at aggregate creation to preserve the age users expected when joining.
        mapping(uint256 aggregateId => uint256 minAggregateAge) _aggregateMinAggregateAge;
        /// @dev Per-aggregate callback deadline, frozen at aggregate creation so the owner can't force-cancel a
        /// dispatched aggregate by lowering the deadline afterwards.
        mapping(uint256 aggregateId => uint256 callbackDeadline) _aggregateCallbackDeadline;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.VaultAggregatorConfidential")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VAULT_AGGREGATOR_CONFIDENTIAL_STORAGE_LOCATION =
        0x917a228c6e8ae8c3018f34979eb21b834c00f46bc0b4ae0e397a4147bb45dd00;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Returns a pointer to the vault aggregator namespaced storage.
    function _getVaultAggregatorConfidentialStorage()
        internal
        pure
        returns (VaultAggregatorConfidentialStorage storage $)
    {
        assembly {
            $.slot := VAULT_AGGREGATOR_CONFIDENTIAL_STORAGE_LOCATION
        }
    }

    /// @notice Initializes a vault aggregator for a confidential token pair and vault.
    /// @param fromToken_ Confidential converter for the route input token.
    /// @param toToken_ Confidential converter for the route output token.
    /// @param vault_ ERC4626 vault used by this route.
    /// @param owner_ Owner authorized to update policy parameters.
    /// @param minAggregateAge_ Minimum seconds a aggregate must age before dispatch.
    /// @param callbackDeadline_ Seconds after dispatch before the aggregate is automatically canceled.
    /// @param maxSlippageBps_ Initial slippage tolerance in basis points (0 = disabled, max 10 000).
    function __VaultAggregatorConfidential_init(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter toToken_,
        IERC4626 vault_,
        address owner_,
        uint256 minAggregateAge_,
        uint256 callbackDeadline_,
        uint16 maxSlippageBps_
    ) internal onlyInitializing {
        __PrimusConfigUpgradeable_init();
        __Ownable_init(owner_);
        __Pausable_init();
        __AggregatorConfidential_init(fromToken_, toToken_);

        _validateVaultAssetMatch(fromToken_, toToken_, vault_);

        // Non-standard converters could report a zero rate, causing division-by-zero or zero-output routes.
        require(fromToken_.rate() > 0, InvalidTokenRate());
        require(toToken_.rate() > 0, InvalidTokenRate());

        require(minAggregateAge_ <= MAX_MIN_AGGREGATE_AGE, InvalidMinAggregateAge());
        require(callbackDeadline_ <= MAX_CALLBACK_DEADLINE, InvalidCallbackDeadline());
        require(maxSlippageBps_ <= MAX_BPS, InvalidMaxSlippageBps());

        VaultAggregatorConfidentialStorage storage $ = _getVaultAggregatorConfidentialStorage();
        $._vault = vault_;
        $._minAggregateAge = minAggregateAge_;
        $._callbackDeadline = callbackDeadline_;
        $._maxSlippageBps = maxSlippageBps_;

        _initializeApprovals(fromToken_, toToken_, vault_);
        _initializeCurrentAggregate();
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function vault() external view returns (IERC4626) {
        return _getVaultAggregatorConfidentialStorage()._vault;
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function minAggregateAge() external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._minAggregateAge;
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function callbackDeadline() external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._callbackDeadline;
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function maxSlippageBps() external view returns (uint16) {
        return _getVaultAggregatorConfidentialStorage()._maxSlippageBps;
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function aggregateCreatedAt(uint256 aggregateId) external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._aggregateCreatedAt[aggregateId];
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function aggregateDispatchedAt(uint256 aggregateId) external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._aggregateDispatchedAt[aggregateId];
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function aggregateMaxSlippageBps(uint256 aggregateId) external view returns (uint16) {
        return _getVaultAggregatorConfidentialStorage()._aggregateMaxSlippageBps[aggregateId];
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function aggregateMinAggregateAge(uint256 aggregateId) external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._aggregateMinAggregateAge[aggregateId];
    }

    /// @inheritdoc IVaultAggregatorConfidentia
    function aggregateCallbackDeadline(uint256 aggregateId) external view returns (uint256) {
        return _getVaultAggregatorConfidentialStorage()._aggregateCallbackDeadline[aggregateId];
    }

    /// @notice Updates the minimum aggregate age required before dispatch. Owner only, capped at `MAX_MIN_AGGREGATE_AGE`.
    function setMinAggregateAge(uint256 minAggregateAge_) external onlyOwner {
        require(minAggregateAge_ <= MAX_MIN_AGGREGATE_AGE, InvalidMinAggregateAge());
        _getVaultAggregatorConfidentialStorage()._minAggregateAge = minAggregateAge_;
        emit MinAggregateAgeSet(minAggregateAge_);
    }

    /// @notice Updates the callback deadline for dispatched aggregatees. Owner only, capped at `MAX_CALLBACK_DEADLINE`.
    /// Setting to 0 cancels immediately on the first callback attempt.
    function setCallbackDeadline(uint256 callbackDeadline_) external onlyOwner {
        require(callbackDeadline_ <= MAX_CALLBACK_DEADLINE, InvalidCallbackDeadline());
        _getVaultAggregatorConfidentialStorage()._callbackDeadline = callbackDeadline_;
        emit CallbackDeadlineSet(callbackDeadline_);
    }

    /// @notice Updates the slippage tolerance in basis points. Owner only, 0 disables the check, max 10 000.
    /// @dev The tolerance is frozen per aggregate at creation; changes only apply to newly-opened aggregatees. At
    /// callback the deposit aggregator verifies the received share value is at least
    /// `depositAmount * (MAX_BPS - aggregateMaxSlippageBps) / MAX_BPS`.
    function setMaxSlippageBps(uint16 maxSlippageBps_) external onlyOwner {
        require(maxSlippageBps_ <= MAX_BPS, InvalidMaxSlippageBps());
        _getVaultAggregatorConfidentialStorage()._maxSlippageBps = maxSlippageBps_;
        emit MaxSlippageBpsSet(maxSlippageBps_);
    }

    /// @notice Registers (`skip` = true) or removes an internal caller that skips the FHE fee because its own
    /// entry point already charged the EOA for the transaction. Owner only.
    /// @dev Used to whitelist a contract that calls this aggregator's charged entry points internally (e.g. a
    /// reward pool or another dispatcher), so its calls reuse the outer fee session instead of reverting on a
    /// missing/duplicate `chargeFee`.
    function setFeeSkipCaller(address caller, bool skip) external virtual onlyOwner {
        _setFeeSkipCaller(caller, skip);
    }

    /// @notice Pauses the aggregator. Deposits and dispatch are blocked; quit and claim stay available.
    /// In-flight aggregatees that reach callback while paused are force-canceled (the vault is not touched).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the aggregator, re-enabling deposits and dispatch.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Dispatches the current aggregate once its minimum age is reached. Blocked when paused.
    function dispatchAggregate() public payable virtual override whenNotPaused {
        super.dispatchAggregate();
    }

    /// @dev Core dispatch, split from the public entry point so a subclass can re-expose it under its
    /// own fee-charging policy (e.g. a keeper-gated `chargeFeeAsSelf` variant). Enforces the pause and
    /// the per-aggregate minimum age on BOTH paths — a subclass calling this directly must not bypass
    /// them — then records the dispatch timestamp and opens the next aggregate.
    function _dispatchAggregate() internal virtual override whenNotPaused {
        VaultAggregatorConfidentialStorage storage $ = _getVaultAggregatorConfidentialStorage();
        uint256 aggregateId = currentAggregateId();
        uint256 elapsed = block.timestamp - $._aggregateCreatedAt[aggregateId];
        uint256 pinnedMinAggregateAge = $._aggregateMinAggregateAge[aggregateId];

        require(elapsed >= pinnedMinAggregateAge, AggregateTooYoung(aggregateId, elapsed, pinnedMinAggregateAge));

        super._dispatchAggregate();
        $._aggregateDispatchedAt[aggregateId] = block.timestamp;
        _initializeCurrentAggregate();
    }

    /// @dev Blocks new deposits while paused.
    function _join(address to, ve_uint64 amount) internal virtual override whenNotPaused returns (ve_uint64) {
        return super._join(to, amount);
    }

    /// @dev Child-specific validation that fromToken/toToken underlying assets match the vault's asset and share token.
    function _validateVaultAssetMatch(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter toToken_,
        IERC4626 vault_
    ) internal view virtual;

    /// @dev Child-specific approval setup for route execution. Empty by default because some routes rely
    /// only on the approvals already configured by `AggregatorConfidential`.
    function _initializeApprovals(
        IConfidentialERC20Converter fromToken_,
        IConfidentialERC20Converter toToken_,
        IERC4626 vault_
    ) internal virtual {}

    /// @dev Runs the child route, but force-cancels when paused or past the callback deadline (checked first,
    /// so cancellation is guaranteed even if the vault route would revert). Uses the deadline pinned at
    /// aggregate creation, not the live value.
    function _executeRoute(uint256 aggregateId, uint256 amount) internal virtual override returns (ExecuteOutcome) {
        VaultAggregatorConfidentialStorage storage $ = _getVaultAggregatorConfidentialStorage();
        if (paused()) return ExecuteOutcome.Cancel;
        if (block.timestamp >= $._aggregateDispatchedAt[aggregateId] + $._aggregateCallbackDeadline[aggregateId]) {
            return ExecuteOutcome.Cancel;
        }
        return _executeVaultRoute(aggregateId, amount);
    }

    /// @dev Child hook executing the concrete vault route for a finalized unshield amount.
    function _executeVaultRoute(uint256 aggregateId, uint256 amount) internal virtual returns (ExecuteOutcome);

    /// @dev Internal accessor for child route execution.
    function _vault() internal view returns (IERC4626) {
        return _getVaultAggregatorConfidentialStorage()._vault;
    }

    /// @dev Freezes policy metadata for the newly opened current aggregate.
    function _initializeCurrentAggregate() private {
        VaultAggregatorConfidentialStorage storage $ = _getVaultAggregatorConfidentialStorage();
        uint256 aggregateId = currentAggregateId();
        $._aggregateCreatedAt[aggregateId] = block.timestamp;
        $._aggregateMaxSlippageBps[aggregateId] = $._maxSlippageBps;
        $._aggregateMinAggregateAge[aggregateId] = $._minAggregateAge;
        $._aggregateCallbackDeadline[aggregateId] = $._callbackDeadline;
        _afterInitializeCurrentAggregate(aggregateId);
    }

    /// @dev Optional child hook for storing route-specific metadata when a new aggregate opens.
    function _afterInitializeCurrentAggregate(uint256 aggregateId) internal virtual {}

    /// @dev Authorizes an implementation upgrade. Only the owner may upgrade the proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
