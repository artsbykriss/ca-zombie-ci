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
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IConfidentialERC20Converter} from "../converter/interfaces/IConfidentialERC20Converter.sol";
import {IConfidentialERC20Receiver} from "../token/interfaces/IConfidentialERC20Receiver.sol";
import {ConfidentialSafeMath} from "../utils/ConfidentialSafeMath.sol";
import {ConfidentialFeeable} from "../utils/ConfidentialFeeable.sol";

/**
 * @dev Aggregatees confidential deposits and routes between two ConfidentialConverter tokens.
 *
 * Flow:
 * 1. Users deposit `fromToken` using `confidentialTransferAndCall`.
 * 2. The aggregate unwraps `fromToken` into the underlying token.
 * 3. `_executeRoute()` swaps the underlying token.
 * 4. The output is wrapped into `toToken`.
 * 5. Users claim their `toToken`.
 *
 * Developers must implement:
 * - `_executeRoute()` to perform the token swap.
 *
 * Notes:
 * - Claim amounts are rounded down. Small deposits may become 0.
 * - Rounding dust remains in the aggregator.
 * - The aggregator itself does not guarantee privacy.
 *
 * Warning:
 * Ensure `fromToken` and `toToken` have enough capacity.
 *
 * Upgradeable: storage is namespaced under ERC-7201 and initialization is performed via
 * {__AggregatorConfidential_init}. Concrete contracts disable initializers in their constructor and
 * expose an `initialize` function for proxy deployment.
 */
abstract contract AggregatorConfidentialUpgradeable is
    Initializable,
    ConfidentialFeeable,
    ReentrancyGuardTransient,
    IConfidentialERC20Receiver
{
    /// @dev Enum representing the state of a aggregate.
    enum AggregateState {
        Open,       // Aggregate is opening and accepting deposits
        Dispatched, // Aggregate has been dispatched but not yet finalized
        Finalized,  // Aggregate is complete, users can claim their tokens
        Canceled    // Aggregate is canceled, users can claim their refund
    }

    /// @dev Result of running {_executeRoute} for one step of the aggregator.
    enum ExecuteOutcome {
        Complete,   // Route execution is complete. Full balance of underlying {toToken} is assigned to the aggregate.
        Partial,    // Route execution is incomplete and will be called again. Intermediate steps must not result in underlying {toToken} being transferred into the aggregator.
        Cancel      // Route execution failed. Aggregate is canceled.
    }

    /// @dev Holds all the data for a single aggregate.
    struct Aggregate {
        /// @dev Total encrypted deposit amounts in this aggregate.
        ve_uint64 totalDeposits;
        /// @dev ID of the unshield request tied to this aggregate.
        bytes32 unshieldRequestId;
        /// @dev Final rate used to calculate payouts, set once the aggregate finalizes.
        uint64 exchangeRate;
        /// @dev True if this aggregate failed and is refund-only.
        bool canceled;
        /// @dev Each user's encrypted deposit amount in this aggregate.
        mapping(address => ve_uint64) deposits;
    }

    /// @custom:storage-location erc7201:primus.fhetransform.storage.AggregatorConfidential
    struct AggregatorConfidentialStorage {
        /// @dev Token users deposit. They get {toToken} back in exchange.
        IConfidentialERC20Converter _fromToken;
        /// @dev Token users receive back in exchange for their deposits.
        IConfidentialERC20Converter _toToken;
        /// @dev Maps a aggregate id to its data.
        mapping(uint256 => Aggregate) _aggregatees;
        /// @dev ID of the aggregate currently accepting deposits.
        uint256 _currentAggregateId;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.AggregatorConfidential")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AGGREGATOR_CONFIDENTIAL_STORAGE_LOCATION =
        0xaa24cacb839997c4e598792cb9cddb8468617eb5489e1b264389b2c3081aa900;

    /// @dev Emitted when a aggregate with id `aggregateId` is dispatched via {dispatchAggregate}.
    event AggregateDispatched(uint256 indexed aggregateId);

    /// @dev Emitted when a aggregate with id `aggregateId` is canceled.
    event AggregateCanceled(uint256 indexed aggregateId);

    /// @dev Emitted when a aggregate with id `aggregateId` is finalized with an exchange rate of `exchangeRate`.
    event AggregateFinalized(uint256 indexed aggregateId, uint64 exchangeRate);

    /// @dev Emitted when an `account` joins a aggregate with id `aggregateId` with a deposit of `amount`.
    event Joined(uint256 indexed aggregateId, address indexed account, ve_uint64 amount);

    /// @dev Emitted when an `account` claims their `amount` from aggregate with id `aggregateId`.
    event Claimed(uint256 indexed aggregateId, address indexed account, ve_uint64 amount);

    /// @dev Emitted when an `account` quits a aggregate with id `aggregateId`.
    event Quit(uint256 indexed aggregateId, address indexed account, ve_uint64 amount);

    /// @dev The `aggregateId` does not exist. Aggregate IDs start at 1 and must be less than or equal to {currentAggregateId}.
    error AggregateNonexistent(uint256 aggregateId);

    /// @dev The `account` has zero deposits in aggregate `aggregateId`.
    error ZeroDeposits(uint256 aggregateId, address account);

    /**
     * @dev The aggregate `aggregateId` is in the state `current`, which is invalid for the operation.
     * The `expectedStates` is a bitmap encoding the expected/allowed states for the operation.
     */
    error UnexpectedAggregateState(uint256 aggregateId, AggregateState current, bytes32 expectedStates);

    /**
     * @dev Thrown when the given exchange rate is invalid. The exchange rate must be non-zero and the shielded
     * amount of {toToken} must be less than or equal to `type(uint64).max`.
     */
    error InvalidExchangeRate(uint256 aggregateId, uint256 totalDeposits, uint64 exchangeRate);

    /// @dev The caller is not authorized to call this function.
    error Unauthorized();

    /// @dev The given `token` does not support `IConfidentialERC20Converter` via `ERC165`.
    error InvalidConverterToken(address token);

    /// @dev The underlying tokens are the same.
    error DuplicateUnderlyingTokens();

    /// @dev Intermediate steps must not result in underlying {toToken} being transferred to or from the aggregator.
    error IntermediateStepToTokenBalanceChanged(uint256 aggregateId);

    /// @dev The unshield request is still pending — underlying tokens were not transferred, so the route cannot proceed.
    error UnshieldFinalizationPending(bytes32 unshieldRequestId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Returns a pointer to the aggregator namespaced storage.
    function _getAggregatorConfidentialStorage() internal pure returns (AggregatorConfidentialStorage storage $) {
        assembly {
            $.slot := AGGREGATOR_CONFIDENTIAL_STORAGE_LOCATION
        }
    }

    /**
     * @dev Initializes the aggregator with its confidential token pair. Validates both tokens implement
     * {IConfidentialERC20Converter} and grant max approvals on their underlying tokens so the aggregator can
     * unwrap/wrap during route execution. Opens the first aggregate (id 1).
     */
    function __AggregatorConfidential_init(IConfidentialERC20Converter fromToken_, IConfidentialERC20Converter toToken_)
        internal
        onlyInitializing
    {
        require(
            ERC165Checker.supportsInterface(address(fromToken_), type(IConfidentialERC20Converter).interfaceId),
            InvalidConverterToken(address(fromToken_))
        );
        require(
            ERC165Checker.supportsInterface(address(toToken_), type(IConfidentialERC20Converter).interfaceId),
            InvalidConverterToken(address(toToken_))
        );
        require(fromToken_.underlying() != toToken_.underlying(), DuplicateUnderlyingTokens());

        AggregatorConfidentialStorage storage $ = _getAggregatorConfidentialStorage();
        $._fromToken = fromToken_;
        $._toToken = toToken_;
        $._currentAggregateId = 1;

        SafeERC20.forceApprove(IERC20(fromToken().underlying()), address(fromToken()), type(uint256).max);
        SafeERC20.forceApprove(IERC20(toToken().underlying()), address(toToken()), type(uint256).max);
    }

    /**
     * @dev Claim the {toToken} corresponding to `account`'s deposit in aggregate with id `aggregateId`.
     */
    function claim(uint256 aggregateId, address account) public payable virtual nonReentrant chargeFeeIfExternal returns (ve_uint64) {
        return _claim(aggregateId, account);
    }

    /**
     * @dev Quit the aggregate with id `aggregateId`. Entire deposit is returned to the user. This can only be called if the
     * aggregate has not yet been dispatched or if the aggregate was canceled.
     */
    function quit(uint256 aggregateId) public payable virtual nonReentrant chargeFeeIfExternal returns (ve_uint64) {
        _validateStateBitmap(aggregateId, _encodeStateBitmap(AggregateState.Open) | _encodeStateBitmap(AggregateState.Canceled));

        ve_uint64 deposit = deposits(aggregateId, msg.sender);
        require(FHE.isInitialized(deposit), ZeroDeposits(aggregateId, msg.sender));

        ve_uint64 totalDeposits_ = totalDeposits(aggregateId);

        FHE.accessPolicy(deposit, address(fromToken()), PermissionType.Transient);
        ve_uint64 sent = fromToken().confidentialTransfer(msg.sender, deposit);
        ve_uint64 newTotalDeposits = FHE.sub(totalDeposits_, sent);
        ve_uint64 newDeposit = FHE.sub(deposit, sent);

        FHE.accessPolicy(newTotalDeposits, address(this));
        FHE.accessPolicy(newDeposit, address(this));
        FHE.accessPolicy(newDeposit, msg.sender);

        AggregatorConfidentialStorage storage $ = _getAggregatorConfidentialStorage();
        $._aggregatees[aggregateId].totalDeposits = newTotalDeposits;
        $._aggregatees[aggregateId].deposits[msg.sender] = newDeposit;

        emit Quit(aggregateId, msg.sender, sent);

        return sent;
    }

    /**
     * @dev Permissionless function to dispatch the current aggregate. Increments the {currentAggregateId}.
     */
    function dispatchAggregate() public payable virtual chargeFeeIfExternal {
        _dispatchAggregate();
    }

    /**
     * @dev Core of {dispatchAggregate}, split from the public entry point so a subclass can re-expose
     * the same logic under a different fee-charging policy (see {_dispatchAggregateCallback} for the
     * rationale — e.g. a keeper-gated variant that charges the aggregator itself via `chargeFeeAsSelf`
     * because the keeper may be a contract wallet).
     */
    function _dispatchAggregate() internal virtual {
        uint256 aggregateId = _getAndIncreaseAggregateId();

        ve_uint64 amountToUnshield = totalDeposits(aggregateId);
        if (!FHE.isInitialized(amountToUnshield)) amountToUnshield = FHE.asVEUint64(0);

        FHE.accessPolicy(amountToUnshield, address(fromToken()), PermissionType.Transient);
        // Reuse the already-materialized handle as an "unverified" input with empty data. The converter's
        // {FHE-fromUnverified} takes the empty-data fast path and only re-checks ACL access (this aggregator was
        // granted access to `totalDeposits` in {_join}).
        uve_uint64 memory uveAmount = uve_uint64(ve_uint64.unwrap(amountToUnshield), "");
        _getAggregatorConfidentialStorage()._aggregatees[aggregateId].unshieldRequestId =
            fromToken().unshield(address(this), address(this), uveAmount);

        emit AggregateDispatched(aggregateId);
    }

    /**
     * @dev Dispatch aggregate callback callable by anyone. This function finalizes the unshield of {fromToken} and calls
     * {_executeRoute} to perform the aggregate's route. If `_executeRoute` returns {ExecuteOutcome.Partial}, this function
     * should be called again with the same `aggregateId`, `unshieldAmountCleartext`, and `decryptionProof`.
     */
    function dispatchAggregateCallback(
        uint256 aggregateId,
        uint64 unshieldAmountCleartext,
        bytes calldata decryptionProof
    ) public payable virtual nonReentrant chargeFeeIfExternal {
        _dispatchAggregateCallback(aggregateId, unshieldAmountCleartext, decryptionProof);
    }

    /**
     * @dev Core of {dispatchAggregateCallback}, split from the public entry point so a subclass can
     * re-expose the same logic under a different fee-charging policy. The public function charges the
     * caller via `chargeFeeIfExternal`; a subclass whose settlement caller may be a contract wallet
     * (e.g. a multisig keeper) overrides the entry point with `nonReentrant chargeFeeAsSelf` and calls
     * this function directly instead of `super.dispatchAggregateCallback` — calling the public base
     * function would run `chargeFeeIfExternal` on top and double-charge (`UserLockedInTx`), or revert
     * `UnauthorizedFeeUser` for a contract caller. Such an override must therefore re-declare
     * `nonReentrant` itself.
     */
    function _dispatchAggregateCallback(
        uint256 aggregateId,
        uint64 unshieldAmountCleartext,
        bytes calldata decryptionProof
    ) internal {
        _validateStateBitmap(aggregateId, _encodeStateBitmap(AggregateState.Dispatched));

        bytes32 unshieldRequestId_ = unshieldRequestId(aggregateId);
        try IConfidentialERC20Converter(fromToken()).finalizeUnshield(unshieldRequestId_, unshieldAmountCleartext, decryptionProof) {
            // No need to validate input since `finalizeUnshield` succeeded.
        } catch {
            // `finalizeUnshield` can fail for two distinct reasons:
            // 1. The request was already settled (underlying tokens already transferred). In this case we only
            //    need to validate that the supplied cleartext matches the original request.
            // 2. The request is still pending but finalizeUnshield reverted for another reason (e.g. a
            //    recipient, holder, or operator became denied, the underlying denylist call failed, or the
            //    converter transfer reverted). In this case the underlying tokens were NOT transferred, so
            //    executing the route would be incorrect — propagate the failure instead.
            if (!IConfidentialERC20Converter(fromToken()).isUnshieldSettled(unshieldRequestId_)) {
                revert UnshieldFinalizationPending(unshieldRequestId_);
            }
            // Request was already settled — validate the supplied cleartext matches the request handle.
            // The handle is derived purely from the request id, so it remains verifiable even after the
            // request record was deleted.
            bytes32[] memory handles = new bytes32[](1);
            handles[0] = unshieldRequestId_;
            FHE.checkSignatures(handles, abi.encode(unshieldAmountCleartext), decryptionProof);
        }

        uint256 beforeUnderlyingToTokenBalance;
        ExecuteOutcome outcome;
        if (unshieldAmountCleartext == 0) {
            outcome = ExecuteOutcome.Cancel;
        } else {
            beforeUnderlyingToTokenBalance = IERC20(toToken().underlying()).balanceOf(address(this));
            outcome = _executeRoute(aggregateId, unshieldAmountCleartext);
        }

        if (outcome == ExecuteOutcome.Complete) {
            uint256 swappedAmount = IERC20(toToken().underlying()).balanceOf(address(this));

            // If the converter is full, this reverts and will brick the aggregator.
            // If the output is less than toToken().rate() the aggregate can never be finalized.
            // Any dust left after (amount % toToken().rate()) goes to the next aggregate.
            toToken().shield(address(this), swappedAmount);

            uint256 shieldedAmount = swappedAmount / toToken().rate();
            uint64 exchangeRate_ = SafeCast.toUint64(
                Math.mulDiv(shieldedAmount, uint256(10) ** exchangeRateDecimals(), unshieldAmountCleartext)
            );

            // Ensure a valid exchange rate: not 0 and will not overflow when calculating user outputs.
            require(
                exchangeRate_ != 0 && shieldedAmount <= type(uint64).max,
                InvalidExchangeRate(aggregateId, unshieldAmountCleartext, exchangeRate_)
            );
            _getAggregatorConfidentialStorage()._aggregatees[aggregateId].exchangeRate = exchangeRate_;

            emit AggregateFinalized(aggregateId, exchangeRate_);
        } else if (outcome == ExecuteOutcome.Cancel) {
            // Re-shield tokens so that users can quit and receive their original deposit back. This assumes that the
            // unshield was successful and that the aggregate has not executed any route logic.
            fromToken().shield(address(this), unshieldAmountCleartext * fromToken().rate());
            _getAggregatorConfidentialStorage()._aggregatees[aggregateId].canceled = true;

            emit AggregateCanceled(aggregateId);
        } else if (outcome == ExecuteOutcome.Partial) {
            require(
                IERC20(toToken().underlying()).balanceOf(address(this)) == beforeUnderlyingToTokenBalance,
                IntermediateStepToTokenBalanceChanged(aggregateId)
            );
        }
    }

    /**
     * @dev See {IConfidentialERC20Receiver-onConfidentialTransferReceived}.
     * Deposit {fromToken} into the current aggregate.
     */
    function onConfidentialTransferReceived(
        address,
        address from,
        ve_uint64 amount,
        bytes calldata
    ) external virtual returns (ve_bool) {
        require(msg.sender == address(fromToken()), Unauthorized());
        ve_bool success = FHE.gt(_join(from, amount), FHE.asVEUint64(0));
        FHE.accessPolicy(success, msg.sender, PermissionType.Transient);
        return success;
    }

    /// @dev Aggregator from token. Users deposit this token in exchange for {toToken}.
    function fromToken() public view virtual returns (IConfidentialERC20Converter) {
        return _getAggregatorConfidentialStorage()._fromToken;
    }

    /// @dev Aggregator to token. Users receive this token in exchange for their {fromToken} deposits.
    function toToken() public view virtual returns (IConfidentialERC20Converter) {
        return _getAggregatorConfidentialStorage()._toToken;
    }

    /// @dev The current aggregate id. New deposits join this aggregate.
    function currentAggregateId() public view virtual returns (uint256) {
        return _getAggregatorConfidentialStorage()._currentAggregateId;
    }

    /// @dev The unshield request id for a aggregate with id `aggregateId`.
    function unshieldRequestId(uint256 aggregateId) public view virtual returns (bytes32) {
        return _getAggregatorConfidentialStorage()._aggregatees[aggregateId].unshieldRequestId;
    }

    /// @dev The total deposits made in aggregate with id `aggregateId`.
    function totalDeposits(uint256 aggregateId) public view virtual returns (ve_uint64) {
        return _getAggregatorConfidentialStorage()._aggregatees[aggregateId].totalDeposits;
    }

    /// @dev The deposits made by `account` in aggregate with id `aggregateId`.
    function deposits(uint256 aggregateId, address account) public view virtual returns (ve_uint64) {
        return _getAggregatorConfidentialStorage()._aggregatees[aggregateId].deposits[account];
    }

    /// @dev The exchange rate set for aggregate with id `aggregateId`.
    function exchangeRate(uint256 aggregateId) public view virtual returns (uint64) {
        return _getAggregatorConfidentialStorage()._aggregatees[aggregateId].exchangeRate;
    }

    /// @dev The number of decimals of precision for the exchange rate.
    function exchangeRateDecimals() public pure virtual returns (uint8) {
        return 6;
    }

    /// @dev Returns the current state of a aggregate. Reverts if the aggregate does not exist.
    function aggregateState(uint256 aggregateId) public view virtual returns (AggregateState) {
        AggregatorConfidentialStorage storage $ = _getAggregatorConfidentialStorage();
        if ($._aggregatees[aggregateId].canceled) {
            return AggregateState.Canceled;
        }
        if (exchangeRate(aggregateId) != 0) {
            return AggregateState.Finalized;
        }
        if (unshieldRequestId(aggregateId) != 0) {
            return AggregateState.Dispatched;
        }
        if (aggregateId == currentAggregateId()) {
            return AggregateState.Open;
        }

        revert AggregateNonexistent(aggregateId);
    }

    /**
     * @dev Claims {toToken} for `account`'s deposit in aggregate with id `aggregateId`. Tokens are always sent to `account`,
     * enabling third-party relayers to claim on behalf of depositors.
     *
     * The deposit is widened to a 128-bit encrypted integer before multiplying by the exchange rate, so the
     * intermediate product cannot overflow (`type(uint64).max ** 2 < type(uint128).max`). Since the whole aggregate
     * output fits in `uint64`, each user output does too, and the result narrows back to `ve_uint64`.
     */
    function _claim(uint256 aggregateId, address account) internal virtual returns (ve_uint64) {
        _validateStateBitmap(aggregateId, _encodeStateBitmap(AggregateState.Finalized));

        ve_uint64 deposit = deposits(aggregateId, account);
        require(FHE.isInitialized(deposit), ZeroDeposits(aggregateId, account));

        ve_uint64 amountToSend = FHE.asVEUint64(
            FHE.div(
                FHE.mul(FHE.asVEUint128(deposit), uint128(exchangeRate(aggregateId))),
                uint128(10) ** exchangeRateDecimals()
            )
        );
        FHE.accessPolicy(amountToSend, address(toToken()), PermissionType.Transient);

        ve_uint64 amountTransferred = toToken().confidentialTransfer(account, amountToSend);

        ve_bool transferSuccess = FHE.ne(amountTransferred, FHE.asVEUint64(0));
        ve_uint64 newDeposit = FHE.select(transferSuccess, FHE.asVEUint64(0), deposit);

        FHE.accessPolicy(newDeposit, address(this));
        FHE.accessPolicy(newDeposit, account);
        _getAggregatorConfidentialStorage()._aggregatees[aggregateId].deposits[account] = newDeposit;

        emit Claimed(aggregateId, account, amountTransferred);

        return amountTransferred;
    }

    /**
     * @dev Joins a aggregate with amount `amount` on behalf of `to`. Does not do any transfers in. Returns the amount
     * joined with.
     */
    function _join(address to, ve_uint64 amount) internal virtual returns (ve_uint64) {
        uint256 aggregateId = currentAggregateId();

        (ve_bool success, ve_uint64 newTotalDeposits) = ConfidentialSafeMath.tryIncrease(totalDeposits(aggregateId), amount);
        ve_uint64 joinedAmount = FHE.select(success, amount, FHE.asVEUint64(0));
        ve_uint64 newDeposits = FHE.add(deposits(aggregateId, to), joinedAmount);

        FHE.accessPolicy(newTotalDeposits, address(this));
        FHE.accessPolicy(newDeposits, address(this));
        FHE.accessPolicy(joinedAmount, address(this));
        FHE.accessPolicy(newDeposits, to);
        FHE.accessPolicy(joinedAmount, to);

        AggregatorConfidentialStorage storage $ = _getAggregatorConfidentialStorage();
        $._aggregatees[aggregateId].totalDeposits = newTotalDeposits;
        $._aggregatees[aggregateId].deposits[to] = newDeposits;

        emit Joined(aggregateId, to, joinedAmount);

        return joinedAmount;
    }

    /**
    * @dev Executes the route after the aggregate has been validated and unshielded.
    *
    * `amount` is the plaintext amount of confidential {fromToken} units that were
    * unshielded. The corresponding underlying amount is:
    *
    *     amount * fromToken().rate()
    *
    * This function swaps the underlying {fromToken} into the underlying {toToken},
    * and returns an {ExecuteOutcome} indicating the current execution state.
    *
    * - {ExecuteOutcome.Partial}: More execution steps are required.
    * - {ExecuteOutcome.Complete}: Route finished. The received {toToken} is shielded
    *   and the aggregate exchange rate is finalized.
    * - {ExecuteOutcome.Cancel}: Route execution is aborted.
    *
    * {dispatchAggregateCallback} may invoke this function multiple times until the route
    * is completed. During intermediate ({Partial}) steps, no underlying {toToken}
    * may be transferred to or from the aggregator.
    *
    * Requirements:
    * - The function must eventually return {Complete} or {Cancel}; otherwise user
    *   deposits remain locked.
    * - The final swapped amount must produce a non-zero exchange rate and fit within
    *   the `uint64` limit after shielding.
    */
    function _executeRoute(uint256 aggregateId, uint256 amount) internal virtual returns (ExecuteOutcome);

    /// @dev Human readable description of what the aggregator does.
    function routeDescription() public pure virtual returns (string memory);

    /**
     * @dev Check that the current state of a aggregate matches the requirements described by the `allowedStates` bitmap.
     * This bitmap should be built using {_encodeStateBitmap}.
     * If requirements are not met, reverts with a {UnexpectedAggregateState} error.
     */
    function _validateStateBitmap(uint256 aggregateId, bytes32 allowedStates) internal view returns (AggregateState) {
        AggregateState currentState = aggregateState(aggregateId);
        require(
            (_encodeStateBitmap(currentState) & allowedStates) != bytes32(0),
            UnexpectedAggregateState(aggregateId, currentState, allowedStates)
        );
        return currentState;
    }

    /// @dev Gets the current aggregate id and increments it.
    function _getAndIncreaseAggregateId() internal virtual returns (uint256) {
        AggregatorConfidentialStorage storage $ = _getAggregatorConfidentialStorage();
        return $._currentAggregateId++;
    }

    /**
     * @dev Encodes a {AggregateState} into a `bytes32` representation where each enabled bit corresponds to the underlying
     * position in the {AggregateState} enum. For example:
     *
     * 0x000...1000
     *         ^--- Canceled
     *          ^-- Finalized
     *           ^- Dispatched
     *            ^ Open
     */
    function _encodeStateBitmap(AggregateState aggregateState_) internal pure returns (bytes32) {
        return bytes32(1 << uint8(aggregateState_));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * storage variables when upgrading without causing storage collisions.
     */
    uint256[49] private __gap;
}
