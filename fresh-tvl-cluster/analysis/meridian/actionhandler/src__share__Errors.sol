// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {PythLazerLib} from "../lib/external/pyth/PythLazerLib.sol";
import {ActionType, EngineType, OrderSide, ProductStatus} from "../share/Enums.sol";
import {ActionId, WithdrawRequestId} from "../share/UserDefinedTypes.sol";

// --- processAction errors --- //

/// @notice Thrown when an call was performed by an unauthorized sender.
error NotSequencer(address sender);

/// @notice Thrown when no actions was provided.
error EmptyActions();

/// @notice Successful result returned by `processActionsDryRun` as revert data.
/// @param gasLeft Remaining gas immediately after all actions were processed.
error DryRunResult(uint256 gasLeft);

/// @notice Returned by a dry run when the gas remaining after an action is below the provided minimum.
/// @param id Action after which the remaining gas fell below the minimum.
/// @param gasLeft Gas remaining after the action.
/// @param previousGasLeft Gas remaining before the action.
error GasLimitExceeded(ActionId id, uint256 gasLeft, uint256 previousGasLeft);

/// @notice Thrown when a function is prevented from executing due to the pause state.
error ExchangePaused();

/// @notice Thrown when attempting to unpause when exchange is not paused.
error ExchangeNotPaused();

/// @notice Thrown when an action id is duplicated or smaller than a previous action id.
error ActionAlreadyProcessed(ActionId id, ActionId previousId, ActionId lastCompleteId);

/// @notice Thrown when an action is expired.
error ActionExpired(ActionId id, uint256 blockTime, uint64 signedAt, uint64 buffer);

/// @notice Thrown when an action amount is less than the fee for that action.
error FeeNotCoveredByBalance(
    ActionId id, address account, bytes32 subaccount, address token, uint256 amount, uint128 fee
);

/// @notice Thrown when a subaccount has insufficient balance.
error InsufficientBalance(
    ActionId id, address account, bytes32 subaccount, address token, uint256 amount, uint256 balance
);

/// @notice Thrown when a processActions action in batch is invalid.
error InvalidAction(ActionId id, ActionType actionType);

/// @notice Thrown when a packed action does not match the expected encoding.
error InvalidActionEncoding(ActionId id, ActionType actionType);

/// @notice Thrown when a packed action does not have enough data to read the action header.
error InvalidActionEncodingHeader(uint256 length);

/// @notice Thrown when an engineType is invalid.
error InvalidEngineType(ActionId id, EngineType engineType);

/// @notice Thrown when a fee token is invalid.
error InvalidFeeToken(address token);

/// @notice Thrown when a fee conversion pair is invalid.
error InvalidFeeConversionPair(address fromToken, address toToken);

/// @notice Thrown when a nonce is invalid.
error InvalidNonce(ActionId id, uint64 nonce);

/// @notice Thrown when the withdraw fee provided by the sequencer does not match the onchain fee.
error WithdrawFeeMismatch(ActionId id, uint128 externalValue, uint128 internalValue);

/// @notice Thrown when a position cost is invalid.
error InvalidCost(ActionId id, uint128 cost);

/// @notice Thrown when the provided realized PnL differs from reference calculation beyond tolerance.
error InvalidRealizedPnl(ActionId id, int128 externalValue, int128 internalValue, uint128 tolerance);

/// @notice Thrown when the provided notional cost differs from reference calculation beyond tolerance.
error InvalidFillNotional(ActionId id, uint128 externalValue, uint128 internalValue, uint128 tolerance);

/// @notice Thrown when the provided balance transfer amount differs from reference calculation beyond tolerance.
error InvalidLiquidationBalanceTransfer(ActionId id, int128 externalValue, int256 internalValue, uint256 tolerance);

/// @notice Thrown when the position-fee liquidator is not configured.
error PositionFeeLiquidatorNotConfigured(ActionId id);

/// @notice Thrown when the provided liquidator position-fee credit does not match fee-paying open interest.
error InvalidPositionFeeLiquidatorCredit(ActionId id, uint256 externalValue, uint256 internalValue);

/// @notice Thrown when a reduce-only order has a fill higher than the max possible fill quantity.
error InvalidReduceOnlyFillQuantity(ActionId id, uint128 fillQuantity, uint128 maxFillableQuantity);

/// @notice Thrown when the provided fill quantity differs from the calculated fill quantity.
error InvalidFillQuantity(ActionId id, uint128 fillQuantity, uint128 calculatedFillQuantity);

/// @notice Thrown when matching two orders where price does not cross.
error InvalidOrderPriceNotCrossed(ActionId id, uint256 makerPrice, uint256 takerPrice);

/// @notice Thrown when matching two orders on the same side.
error InvalidOrderSameSide(ActionId id, OrderSide side);

/// @notice Thrown when matching two orders on different products.
error InvalidOrderProduct(ActionId id, uint32 makerProductId, uint32 takerProductId);

/// @notice Thrown when an order's quantity is invalid.
error InvalidOrderQuantity(ActionId id, uint128 quantity);

/// @notice Thrown when an order's price is zero.
error InvalidOrderZeroPrice(ActionId id);

/// @notice Thrown when an order's price is invalid.
error InvalidOrderPrice(ActionId id, uint256 price);

/// @notice Thrown when the match parameters lead to a fill with zero quantity.
error InvalidMatchZeroQuantity(ActionId id, uint128 makerFillableQty, uint128 takerFillableQty);

/// @notice Thrown when a reduceOnly order receives a fill that doesn't reduce the position.
error InvalidReduceOnlyFill(ActionId id, int128 positionSize, int128 sizeDelta);

/// @notice Thrown when a signature was found to be invalid.
error InvalidSignature(ActionId id, address sender, address signer, bytes signature);

/// @notice Thrown when a signer address is invalid.
error InvalidSigner(ActionId id, address signer);

/// @notice Thrown when an id is not increasing.
error InvalidNonIncreasingId(ActionId id, uint32 currentId, uint32 lastId);

/// @notice Thrown when an action's message index is zero.
error ZeroMessageIdx(ActionId id);

/// @notice Thrown when a position is not found.
error PositionNotFound(ActionId id, address account, bytes32 subaccount, uint32 productId);

/// @notice Thrown when a message is received from a paused sequencer.
error SequencerPaused(address sequencer);

/// @notice Thrown when an existing signer was not found
error SignerNotFound(ActionId id, address sender, bytes32 subaccount, address signer);

/// @notice Thrown when an `account` is attempting an operation it has been excluded from.
error ExcludedAccount(ActionId id, address account);

/// @notice Thrown when a subaccount for sender was not found.
error SubaccountNotFound(ActionId id, address sender, bytes32 subaccount);

/// @notice Thrown when an attempt to withdraw on a token that is currently paused.
error TokenWithdrawPaused(ActionId id, address token);

/// @notice Thrown when OFT withdrawal fails.
error WithdrawOftFailed(address account, bytes32 withdrawDigest);

/// @notice Thrown when there are insufficient fees sent in the transaction to cover the OFT fees.
error WithdrawOftInsufficientFees(address account, bytes32 withdrawDigest, uint256 fee);

/// @notice Thrown when an action interacts on a product where the status is in violation of domain rules.
error ProductStatusViolation(ActionId id, uint32 productId, EngineType engineType, ProductStatus status);

/// @notice Thrown when delisting is acted on without a prior owner `delist` invocation.
error DelistNotInvoked(ActionId id, uint32 productId);

/// @notice Thrown when a delist settlement or finalize is submitted before the sequencer has initiated the delist context.
error DelistNotInitiated(ActionId id, uint32 productId);

/// @notice Thrown when the sequencer tries to initiate a delist context that has already been initiated.
error DelistAlreadyInitiated(ActionId id, uint32 productId, uint64 delistMessageIdx);

/// @notice Thrown when delist finalization is invoked while the product still has open interest.
error DelistOpenInterestRemaining(ActionId id, uint32 productId, uint128 openInterest);

/// @notice Thrown when a delist settlement or finalize carries a different engine message index than the rest of the delist.
error DelistMessageIdxMismatch(ActionId id, uint32 productId, uint64 messageIdx, uint64 expectedMessageIdx);

/// @notice Thrown when attempting to propose a product update while one is already pending.
error PendingPerpProductUpdateFound(uint32 productId);

/// @notice Thrown when attempting to finalize a product update that does not exist.
error PendingPerpProductUpdateNotFound(ActionId id, uint32 productId);

/// @notice Thrown when a sequencer-finalized product update does not match the pending update.
error PendingPerpProductUpdateMismatch(ActionId id, uint32 productId);

/// @notice Thrown when no products were found at liquidation.
error LiquidateEmptyProducts(ActionId id, address account, bytes32 subaccount);

/// @notice Thrown when liquidating an account with zero address.
error LiquidateZeroAccount(ActionId id);

/// @notice Thrown when liquidating a subaccount with zero subaccount.
error LiquidateZeroSubaccount(ActionId id, address account);

/// @notice Thrown when liquidating a subaccount with zero margin.
/// @custom:deprecated Error is no longer thrown.
error LiquidateZeroMargin(ActionId id, address account, bytes32 subaccount);

/// @notice Thrown when the number open positions does not match the number to liquidate.
error LiquidateProductsMismatch(ActionId id, uint128 openPositions, uint128 products);

/// @notice Thrown when the quote token does not match the product's quote token.
error LiquidateProductQuoteTokenMismatch(ActionId id, uint32 productId, bytes32 quoteTokenName);

/// @notice Thrown when a liquidation pre-realization product has a different quote token than the liquidation batch.
error LiquidatePreRealizationQuoteTokenMismatch(ActionId id, uint32 productId, bytes32 quoteTokenName);

/// @notice Thrown when the quote token does not match the product's quote token.
error RealizeFundingProductQuoteTokenMismatch(ActionId id, uint32 productId, bytes32 quoteTokenName);

/// @notice Thrown when pre-realization counts do not match the number of products to liquidate.
error LiquidatePreRealizationCountsMismatch(ActionId id, uint256 preRealizationCounts, uint256 products);

/// @notice Thrown when liquidation is rejected because the account's margin is still above the required maintenance margin.
error LiquidateAboveMaintenanceMargin(
    ActionId id, address account, bytes32 subaccount, int256 remainingMargin, uint256 requiredMaintenanceMargin
);

/// @notice Thrown when a size or size delta is invalid.
error LiquidateSizeNotNetZero(
    ActionId id, address account, bytes32 subaccount, uint32 productId, int128 sizeDelta, int128 netSize
);

/// @notice Thrown when updating the liquidator's balance would cause an underflow.
error LiquidatorInsufficientBalance(
    ActionId id, address liquidatorAccount, bytes32 liquidatorSubaccount, address token, uint256 balance, int256 delta
);

/// @notice Thrown when a liquidation is attempted while the liquidator is being deleveraged.
error LiquidatorIsDeleveraging(ActionId id);

/// @notice Thrown when a liquidation or deleverage targets the liquidator's own subaccount.
error InvalidLiquidatorCounterparty(ActionId id, address account, bytes32 subaccount);

/// @notice Thrown when a deleverage action's message index does not match the sequencer's initiating index.
error DeleverageBatchMessageIdxMismatch(ActionId id, uint64 expected, uint64 actual);

/// @notice Thrown when a deleverage action's quote token does not match the sequencer's initiating quote token.
error DeleverageBatchQuoteTokenMismatch(ActionId id, address expected, address actual);

/// @notice Thrown when a deleverage product's quote token does not match the expected quote token.
error DeleverageProductQuoteTokenMismatch(ActionId id, uint32 productId, bytes32 quoteTokenName);

/// @notice Thrown when no products were provided for deleveraging.
error DeleverageEmptyProducts(ActionId id);

/// @notice Thrown when deleveraging closed all positions but the unrealized mark pnl delta does not offset with the mark pnl to zero.
error DeleverageIncomplete(ActionId id, int256 unrealizedMarkPnl, int256 unrealizedMarkPnlDelta, uint128 tolerance);

/// @notice Thrown when deleveraging is attempted but the liquidator is not bankrupt.
error DeleverageLiquidatorNotBankrupt(ActionId id, int256 equity);

/// @notice Thrown when the number of Pyth price updates does not match the number of products.
error DeleveragePythUpdateCountMismatch(ActionId id, uint256 provided, uint256 expected);

/// @notice Thrown when the deleveraged products provided do not include the products of all of the liquidator's open positions.
error DeleverageLiquidatorPositionsMismatch(
    ActionId id, address liquidatorAccount, bytes32 liquidatorSubaccount, uint128 openPositions, uint128 products
);

/// @notice Thrown when a deleverage match does not result in a reduction or close for the position.
error DeleverageNotReducing(
    ActionId id, address account, bytes32 subaccount, uint32 productId, int128 oldSize, int128 newSize
);

/// @notice Thrown when a deleverage match references a product index outside the provided products array.
error DeleverageInvalidProductIndex(
    ActionId id, address account, bytes32 subaccount, uint32 productIndex, uint32 numProducts
);

/// @notice Thrown when liquidator has no position for product but deleverage matches are provided.
error DeleverageUnexpectedMatches(
    ActionId id, address liquidatorAccount, bytes32 liquidatorSubaccount, uint32 productId
);

/// @notice Thrown when price has an unsupported exponent.
error PriceInvalidExponent(ActionId id, int16 exponent);

/// @notice Thrown when a Pyth price is zero.
error PriceZero(ActionId id);

/// @notice Thrown when a Pyth price is negative.
error PriceNegative(ActionId id, int64 price);

/// @notice Thrown when a Pyth price is too old.
error PriceTooOld(ActionId id, uint64 priceTimestamp, uint64 timestamp);

/// @notice Thrown when price has an unsupported price Pyth feedId.
error PriceInvalidFeedId(ActionId id, uint32 priceFeedId, uint32 productFeedId);

/// @notice Thrown when there are too many Pyth prices in price blob.
error PriceFeedsTooMany(ActionId id, uint256 length);

/// @notice Thrown when a Pyth price feed property is invalid.
error PriceFeedInvalidProperty(ActionId id, PythLazerLib.PriceFeedProperty property);

/// @notice Thrown when a required Pyth price feed property is absent.
error PriceFeedMissingProperty(ActionId id, PythLazerLib.PriceFeedProperty property);

/// @notice Thrown when a feed update timestamp is later than its payload timestamp.
error PriceFeedTimestampAfterPayload(ActionId id, uint64 feedUpdateTimestamp, uint64 payloadTimestamp);

/// @notice Thrown when the number open positions does not match the number to realize.
error RealizeFundingProductsMismatch(
    ActionId id, address account, bytes32 subaccount, uint128 openPositions, uint128 products
);

/// @notice Thrown when realizing PnL and the position's costDelta sign doesn't match position size.
error InvalidRealizePnlCostDelta(
    ActionId id, address account, bytes32 subaccount, uint32 productId, int128 positionSize, int128 costDelta
);

/// @notice Thrown when realizing PnL would result in negative position cost.
error InvalidRealizePnlNegativeCost(
    ActionId id, address account, bytes32 subaccount, uint32 productId, uint128 currentCost, int128 costDelta
);

/// @notice Thrown when a token conversion's from/to pair is not a valid convertible pair.
/// @dev Valid pairs: parent <-> child OR sibling <-> sibling (same backing token).
error InvalidTokenConversionPair(ActionId id, address fromToken, address toToken);

/// @notice Thrown when a token conversion amount is zero.
error InvalidTokenConversionZeroAmount(ActionId id);

/// @notice Thrown when a token conversion carries a non-zero fee.
error InvalidTokenConversionFee(ActionId id);

/// @notice Thrown when a token conversion output amount does not match the signed input amount.
error InvalidTokenConversionAmount(ActionId id);

// --- Shared (processActions) --- //

/// @notice Thrown when a product was not found.
error ProductNotFound(ActionId id, uint32 productId, EngineType engineType);

/// @notice Thrown when a product id is mismatched between storage and the provided id.
error ProductIdMismatch(ActionId id, uint32 expectedId, uint32 actualId);

/// @notice Thrown when a pending deposit was not found.
error PendingDepositNotFound(ActionId id, address account, bytes32 subaccount);

/// @notice Thrown when a pending deposit is found to have a mismatch.
error PendingDepositMismatch(ActionId id, address account, bytes32 subaccount, address token, uint256 amount);

// --- Admin/User initiated errors --- //

/// @notice Thrown when attempting to finalize a signer revoke that is not pending
error PendingRevokeNotFound(address sender, bytes32 subaccount, address signer);

/// @notice Thrown when gateway fails to delegate to downstream contracts.
error DelegationFailed();

/// @notice Thrown when a ping is emitted too soon after the previous ping.
error PingTooSoon(uint64 lastPingTimestamp, uint64 timestamp, uint64 minDelta);

/// @notice Thrown result of deposit exceeds max capacity.
error DepositCapacityExceeded(uint256 capacity, uint256 amount);

/// @notice Thrown when the deposit amount provided is insufficient.
error DepositInsufficient(uint256 amount);

///@notice Thrown when deposit on behalf exceeds max batch size.
error DepositOnBehalfBatchSizeExceeded(uint256 maxBatchSize);

/// @notice Thrown during configuration when a parameter is invalid.
error InvalidParameter(bytes32 parameter, bytes32 reason);

/// @notice Thrown when deposit on behalf is invalid.
error InvalidDepositOnBehalf(address sender, address account, bytes32 subaccount, bytes32 reason);

/// @notice Thrown when token address is invalid.
error InvalidDepositToken(address token);

/// @notice Thrown when a deposit is already pending for subaccount.
error PendingDepositFound(address sender, bytes32 subaccount, address token, uint256 amount);

/// @notice Thrown when attempting to deposit into a linked signer.
error SignerDepositUnauthorized(address account);

/// @notice Thrown when an attempt to deposit on a token that is currently paused.
error TokenDepositPaused(address token);

/// @notice Thrown when a product status is invalid for the action.
error InvalidProductStatus(uint32 productId, ProductStatus status);

/// @notice Thrown when removing a token that's remove protected.
error TokenRemoveProtected(bytes32 tokenName);

/// @notice Thrown when gateway rejects adding a new registry record.
error InvalidRegistryRecord();

/// @notice Thrown when `account` is unauthorized to perform an action.
error UnauthorizedAccount(address account);

/// @notice Thrown when an active withdraw is not found.
error WithdrawNotFound();

/// @notice Thrown when an expected value was found to be zero.
error ZeroAmount();

/// @notice Thrown when bytes32 or string was expected to have a length.
error ZeroLength();

/// @notice Thrown when address is zero.
error ZeroAddress();

/// @notice Thrown when attempting to rescue funds before the rescue delay has passed.
error RescueTooEarly(uint256 rescueReadyTimestamp);

// --- Claimer errors --- //

/// @notice Thrown when insufficient ETH value is provided to cover all OFT send fees.
error InsufficientOftSendFees(uint256 provided, uint256 required);

/// @notice Thrown when a withdraw request id is duplicated or smaller than a previous id.
error WithdrawRequestAlreadyProcessed(
    WithdrawRequestId id, WithdrawRequestId previousId, WithdrawRequestId lastProcessedId
);

/// @dev All possible InvalidParameter reasons as bytes32 constants.
bytes32 constant P_ERR_AMT_GT_MAX = "AMT_GT_MAX";
bytes32 constant P_ERR_AMT_ZERO = "AMT_ZERO";
bytes32 constant P_ERR_AMT_NON_ZERO = "AMT_NON_ZERO";
bytes32 constant P_ERR_BAD_VAL = "BAD_VAL";
bytes32 constant P_ERR_BAD_ACCOUNT = "BAD_ACCOUNT";
bytes32 constant P_ERR_BAD_ADDR = "BAD_ADDR";
bytes32 constant P_ERR_BAD_SIGNER = "BAD_SIGNER";
bytes32 constant P_ERR_BAD_SUBACCOUNT = "BAD_SUBACCOUNT";
bytes32 constant P_ERR_FOUND = "FOUND";
bytes32 constant P_ERR_NOT_FOUND = "NOT_FOUND";
