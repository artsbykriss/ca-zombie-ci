// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {OrderSide, ProductStatus} from "../share/Enums.sol";
import {ActionId} from "../share/UserDefinedTypes.sol";
import {IActionHandler} from "./IActionHandler.sol";

interface IPerpEngine {
    // --- Events --- //

    /// @notice Emitted when a perp product is registered.
    event PerpProductRegistered(uint32 indexed productId, bytes32 baseTokenName, bytes32 quoteTokenName);

    /// @notice Emitted when a perp product's Pyth feed id has been updated.
    event PerpProductPythFeedIdUpdated(uint32 indexed productId, uint32 pythFeedId);

    /// @notice Emitted when a perp product's status has been updated.
    event PerpProductStatusUpdated(uint32 indexed productId, ProductStatus status);

    /// @notice Emitted when a perp product has been updated.
    event PerpProductUpdated(uint32 indexed productId);

    /// @notice Emitted when a perp product configuration update has been initiated by the owner.
    event PerpProductUpdateInitiated(uint32 indexed productId);

    /// @notice Emitted when a pending perp product configuration update has been finalized by the sequencer.
    event PerpProductUpdateFinalized(uint32 indexed productId, uint64 messageIdx);

    /// @notice Emitted when the owner has invoked delisting for a perp product.
    event PerpProductDelistInvoked(uint32 indexed productId);

    /// @notice Emitted when the sequencer has initiated the delist context for a perp product.
    event PerpProductDelistInitiated(uint32 indexed productId, uint256 expiryPrice, uint64 messageIdx);

    /// @notice Emitted when delisting is finalized.
    event PerpProductDelistFinalized(uint32 indexed productId, uint256 expiryPrice, uint64 messageIdx);

    /// @notice Emitted when an open position on a delisting product is cash-settled.
    event PerpProductDelistPositionSettlement(
        address indexed account,
        bytes32 indexed subaccount,
        uint32 indexed productId,
        int128 size,
        int128 realizedPnl,
        uint64 messageIdx
    );

    /// @notice Emitted when a perp product's cumulative funding is updated.
    event PerpProductFundingUpdated(
        uint32 indexed productId, int256 fundingUsd, int256 cumulativeFundingUsd, uint64 messageIdx
    );

    /// @notice Emitted when a perp product's cumulative position fee is updated.
    event PerpProductPositionFeeUpdated(
        uint32 indexed productId,
        uint128 positionFeeDeltaUsd,
        uint128 cumulativePositionFeeUsd,
        uint256 liquidatorCreditAmount,
        uint64 messageIdx
    );

    /// @notice Emitted when a fill notional mismatch is detected.
    event PerpFillNotionalMismatch(ActionId id, uint128 externalValue, uint128 internalValue, uint128 tolerance);

    /// @notice Emitted when two orders in a perp product match.
    event PerpOrderMatched(
        uint32 indexed productId,
        address indexed maker,
        address indexed taker,
        bytes32 makerSubaccount,
        bytes32 takerSubaccount,
        OrderSide makerSide,
        OrderSide takerSide,
        uint128 fillQuantity,
        uint128 price,
        uint128 makerFee,
        uint128 takerFee,
        uint64 messageIdx
    );

    /// @notice Emitted when funding for positions held by `account/subaccount` is realized.
    event PerpFundingRealized(
        address indexed account,
        bytes32 indexed subaccount,
        uint32[] productIds,
        int256 realizedFundingUsd,
        uint64 messageIdx
    );

    /// @notice Emitted when PnL for a position is realized ad-hoc.
    event PerpPnlRealized(
        address indexed account,
        bytes32 indexed subaccount,
        uint32 indexed productId,
        int128 costDelta,
        uint64 messageIdx
    );

    // --- Structs --- //

    /// @notice Params used to register a perp product.
    struct RegisterPerpProductParams {
        bytes32 baseTokenName;
        bytes32 quoteTokenName;
        ProductStatus status;
        uint16 maxLeverage;
        uint32 feeScheduleId;
        uint32 pythFeedId;
        uint128 tickSize;
        uint128 maxQuantity;
        uint128 lotSize;
        uint128 maxOpenInterestUsd;
        uint128 maxPositionNotionalUsd;
    }

    /// @notice Params used to update a perp product.
    struct UpdatePerpProductParams {
        uint32 id;
        uint16 maxLeverage;
        uint128 maxQuantity;
        uint128 maxOpenInterestUsd;
        uint128 maxPositionNotionalUsd;
    }

    struct ExecuteMatchDigests {
        bytes32 maker; // Hash of the EIP-712 maker message
        bytes32 taker; // Hash of the EIP-712 taker message
    }

    /// @dev Data structure to hold the fill data for a position settlement.
    struct FillData {
        uint128 quantity;
        uint128 price;
        int128 oldSize;
        int128 newSize;
        int128 sizeDelta;
    }

    /// @dev Data structure to hold the fill data for a position settlement from an external source.
    struct ExternalFillData {
        uint128 eFillNotional;
        int128 eRealizedPnl;
    }

    /// @notice Initiates a sequencer-delivered delist context for a perp product.
    /// @param id Id of the initiate delist action in the `processActions` array
    /// @param action Action containing product id, engine message index, and Pyth price update
    function initiateDelist(ActionId id, IActionHandler.InitiatePerpProductDelistAction calldata action)
        external
        payable;

    /// @notice Cash-settles a single open position during a product delist.
    /// @param id Id of the settle action in the `processActions` array
    /// @param action Settlement action with account/subaccount/productId, engine-reported realized PnL,
    ///               expiry price, and engine message index
    function settleDelistPosition(ActionId id, IActionHandler.PerpProductDelistPositionSettlementAction calldata action)
        external
        payable;

    /// @notice Finalizes a perp product delist after all positions have been settled and open interest is zero.
    /// @param id Id of the finalize delist action in the `processActions` array
    /// @param action Action containing product id and engine message index
    function finalizeDelist(ActionId id, IActionHandler.FinalizePerpProductDelistAction calldata action)
        external
        payable;

    /// @notice Finalizes and applies a pending product update.
    /// @param id Id of the finalize action in the `processActions` array
    /// @param action The sequencer-finalized pending product update
    function finalizeUpdate(ActionId id, IActionHandler.FinalizePerpProductUpdateAction calldata action)
        external
        payable;

    /// @notice Match a maker and take order by its product.
    /// @param id Id of the match action in the `processActions` array
    /// @param action The match action containing maker and taker orders with signatures and fees
    /// @param digests Digests of the EIP-712 maker and taker messages
    function executeMatch(
        ActionId id,
        IActionHandler.MatchOrdersAction calldata action,
        ExecuteMatchDigests calldata digests
    ) external payable;

    /// @notice Updates a perp product's funding, adding `cumulativeFundingUsd`.
    /// @param id Id of the update funding action in the `processActions` array
    /// @param productId Id of the product to update funding on
    /// @param cumulativeFundingUsd Funding USD delta to update with
    /// @param messageIdx Message index that produced funding update
    function updateFunding(ActionId id, uint32 productId, int128 cumulativeFundingUsd, uint64 messageIdx)
        external
        payable;

    /// @notice Updates a perp product's position fee, adding `positionFeeDeltaUsd`.
    /// @param id Id of the update position fee action in the `processActions` array
    /// @param productId Id of the product to update position fee on
    /// @param positionFeeDeltaUsd Position fee USD delta to update with
    /// @param liquidatorCreditAmount Amount to credit to the configured liquidator
    /// @param messageIdx Message index that produced position fee update
    function updatePositionFee(
        ActionId id,
        uint32 productId,
        uint128 positionFeeDeltaUsd,
        uint256 liquidatorCreditAmount,
        uint64 messageIdx
    ) external payable;

    /// @notice Realizes funding for a list of products for a specific account/subaccount.
    /// @param id Id of the realize funding action in the `processActions` array
    /// @param account Address to realize funding for (cannot be a signer)
    /// @param subaccount Subaccount to realize funding for
    /// @param productIds Sorted (asc) list of all productIds with open positions
    /// @param messageIdx Message index that produced this action
    /// @dev This function will no-op if all parameters are valid but positions are fresh or funding is net zero.
    function realizeFunding(
        ActionId id,
        address account,
        bytes32 subaccount,
        uint32[] calldata productIds,
        uint64 messageIdx
    ) external payable;

    /// @notice Realizes PnL by adjusting position cost and user balance.
    /// @param id Id of the realize pnl action in the `processActions` array
    /// @param account Address of the account holding the position
    /// @param subaccount Subaccount holding the position
    /// @param productId Product ID of the position to realize PnL for
    /// @param costDelta Cost adjustment to apply to position and balance
    /// @param messageIdx Message index that produced this action
    function realizePnl(
        ActionId id,
        address account,
        bytes32 subaccount,
        uint32 productId,
        int128 costDelta,
        uint64 messageIdx
    ) external payable;
}
