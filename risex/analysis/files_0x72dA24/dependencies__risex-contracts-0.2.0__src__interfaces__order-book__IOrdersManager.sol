// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IAccountRegistry } from "src/interfaces/account/IAccountRegistry.sol";
import { IExpiryOrderCleaner } from "src/interfaces/order-book/IExpiryOrderCleaner.sol";
import { IPendingSettlementCleaner } from "src/interfaces/order-book/IPendingSettlementCleaner.sol";
import { IPartialPauseManaged } from "src/interfaces/securities/IPartialPauseManaged.sol";
import { Tick } from "src/libraries/order-book/price-level-queue/LibTick.sol";
import { RestingOrderId } from "src/libraries/types/RestingOrderId.sol";
import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

interface IOrdersManager is IExpiryOrderCleaner, IPendingSettlementCleaner, IPartialPauseManaged {
    /// @notice Order book configuration (step size and step price)
    /// @dev Using uint64 for gas efficiency - sufficient range for most markets
    struct Config {
        uint64 stepSize;
        uint64 stepPrice;
    }

    /// @dev STPMode is a 2-bit enum, max 4 values
    enum STPMode {
        ExpireMaker,
        ExpireTaker,
        ExpireBoth
    }

    enum OrderType {
        Market,
        Limit
    }

    enum OrderSide {
        Buy,
        Sell
    }

    enum TimeInForce {
        GoodTillCancelled,
        GoodTillTime,
        FillOrKill,
        ImmediateOrCancel
    }

    /// @notice Tight order struct for storage — single 21-byte slot
    /// @dev sizeSteps(4) + filledSteps(4) + feeBps(2) + builderFeeBps(2) + tick(3) + epochId(4) + builderId(2) = 21 bytes
    ///      userId and side are encoded in the RestingOrderId key, not stored in the struct.
    struct Order {
        uint32 sizeSteps;
        uint32 filledSteps;
        int16 feeBps;
        uint16 builderFeeBps;
        Tick tick;
        uint32 epochId;
        uint16 builderId;
    }

    /// @notice Fee snapshot captured at order placement time
    struct OrderFee {
        int16 makerFeeBps;
        int16 takerFeeBps;
        uint16 builderFeeBps;
    }

    /// @notice Compact place order parameters matching encoding scheme
    /// @dev Used for bytes-based encoding/decoding in Packed Layout v1
    struct PlaceOrderParams {
        uint16 marketId; // 2 bytes
        uint32 sizeSteps; // 4 bytes - size in steps (multiply by stepSize)
        uint24 priceTicks; // 3 bytes - price in ticks (multiply by stepPrice)
        uint16 ttlUnits; // 2 bytes - TTL in 5-min units
        OrderSide side;
        STPMode stpMode;
        OrderType orderType;
        bool postOnly;
        bool reduceOnly;
        TimeInForce timeInForce;
        uint8 headerVersion;
        uint16 builderId;
    }

    /// @notice Compact cancel order parameters
    /// @dev Used for bytes-based encoding/decoding (7 bytes total)
    struct CancelOrderParams {
        uint16 marketId; // 2 bytes
        RestingOrderId orderId; // 5 bytes — only resting orders can be cancelled
    }

    /// @notice Taker context cached in transient storage during placeOrder, readable by hooks.
    /// @dev takerUserId and takerSide are encoded in takerOrderId (WideOrderId).
    struct TakerContext {
        uint16 marketId;
        WideOrderId takerOrderId;
        int16 takerFeeBps;
        int16 makerFeeBps;
        uint16 builderFeeBps;
        uint16 builderId;
    }

    /// @notice Full order context for matching (not stored)
    /// @dev userId and side are encoded in orderId (WideOrderId).
    struct TakerOrder {
        uint16 marketId;
        WideOrderId orderId;
        uint128 size;
        uint128 filledSize;
        Tick tick;
        OrderType orderType;
        TimeInForce timeInForce;
        uint32 expiry;
        int16 makerFeeBps;
        int16 takerFeeBps;
        uint16 builderFeeBps;
        STPMode stpMode;
        uint16 builderId;
    }

    /// @notice Thrown when the order size is below the minimum order size
    error BelowMinOrderSize(uint256 size);

    /// @notice Thrown when the order does not exist
    error OrderNotExists(RestingOrderId orderId);

    /// @notice Thrown when the order is not owned by the caller
    error OrderNotOwned(RestingOrderId orderId, uint32 userId);

    /// @notice Thrown when the order cannot be cancelled (already filled or cancelled)
    error OrderCannotBeCancelled(RestingOrderId orderId);

    /// @notice Thrown when the price is invalid
    error InvalidPrice(uint256 price);

    /// @notice Thrown when a post-only order is matched
    error PostOnlyOrderMatched();

    /// @notice Thrown when the net fee (maker + taker) is negative, which would create unbacked rebates
    error NegativeNetFee(int16 makerFeeBps, int16 takerFeeBps);

    /// @notice Thrown when the builder fee bps is invalid (exceeds cap or negative)
    error InvalidBuilderFeeBps(uint16 builderFeeBps);

    /// @notice Thrown when a fill-or-kill order is not filled
    error FillOrKillOrderNotFilled(uint256 size, uint256 filledSize);

    /// @notice Thrown when epoch config inputs are invalid
    error InvalidEpochConfig(uint32 genesisTimestamp, uint32 epochDuration, uint16 maxBucketSize);

    /// @notice Thrown when a tick level exceeds its maximum sequence ID capacity
    error TickLevelCapacityExceeded(Tick tick, uint32 nextSeqId);

    /// @notice Thrown when the new header version is not strictly greater than the current version.
    error InvalidHeaderVersion();

    /// @notice Emitted when an order is placed
    event PlaceOrder(
        address indexed protocol,
        uint16 indexed marketId,
        WideOrderId indexed orderId,
        PlaceOrderParams orderParams,
        OrderFee fee
    );

    /// @notice Emitted when an order is cancelled (resting or ephemeral — STP, IOC, manual cancel)
    event CancelOrder(address indexed protocol, uint16 indexed marketId, WideOrderId indexed orderId);

    /// @notice Emitted when an order is matched
    event MatchOrder(
        address indexed protocol,
        uint16 indexed marketId,
        RestingOrderId indexed makerOrderId,
        WideOrderId takerOrderId,
        uint128 matchedSize
    );

    /// @notice Emitted when a protocol registers its hook bitmap
    event HooksRegistered(address indexed hookAddress, bytes32 hookBitmap);

    /// @notice Registers the caller's hook permission bitmap (access restricted via AccessManager)
    /// @param hookBitmap The bitmap indicating which hooks the caller implements
    function registerHooks(
        bytes32 hookBitmap
    ) external;

    /// @notice Places a new order (access restricted via AccessManager)
    /// @param params The compact place order parameters
    /// @param userId The userId placing the order (from AccountRegistry)
    /// @param makerFeeBps The maker fee in basis points
    /// @param takerFeeBps The taker fee in basis points
    /// @param builderFeeBps The builder fee in basis points (stored for per-fill computation)
    /// @param fundingSnapshotX128 Funding rate snapshot (Q128) for deferred fill segments; 0 for spot
    /// @return orderId The wide order ID (resting or ephemeral) of the placed order
    function placeOrder(
        PlaceOrderParams calldata params,
        uint32 userId,
        int16 makerFeeBps,
        int16 takerFeeBps,
        uint16 builderFeeBps,
        int128 fundingSnapshotX128
    ) external returns (WideOrderId orderId);

    /// @notice Returns the taker context cached in transient storage during placeOrder
    /// @return The taker context for the current placeOrder execution
    function getTakerContext() external view returns (TakerContext memory);

    /// @notice Cancels orders by their IDs (access restricted via AccessManager)
    /// @param marketId The market ID
    /// @param orderIds The resting order IDs to cancel
    /// @param userId The userId that owns the orders (from AccountRegistry)
    function cancelOrders(
        uint16 marketId,
        RestingOrderId[] calldata orderIds,
        uint32 userId
    ) external;

    /// @notice Returns the total size until the specified price
    /// @param protocol The protocol address whose orderbook to query
    function getTotalSizeUntilPrice(
        address protocol,
        uint16 marketId,
        OrderSide side,
        uint256 price,
        uint64 stepPrice
    ) external view returns (uint256);

    /// @notice Returns best price for a side in a market
    /// @param protocol The protocol address whose orderbook to query
    function getBestPrice(
        address protocol,
        uint16 marketId,
        OrderSide side,
        uint64 stepPrice
    ) external view returns (uint256);

    /// @notice Returns orderbook checksum for a market
    /// @param protocol The protocol address whose orderbook to query
    function computeOrderbookChecksum(
        address protocol,
        uint16 marketId,
        uint256 maxLevels
    ) external view returns (bytes32);

    /// @notice Returns impact prices for a market
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param indexPrice The index price to use as fallback for empty order book
    /// @notice Computes impact bid and ask prices using a hardcoded base notional scaled by market leverage
    /// @dev Impact notional = 500 USDC * maxLeverage
    ///      Impact bid = average fill price for market sell of impact notional
    ///      Impact ask = average fill price for market buy of impact notional
    /// @param protocol The protocol address
    /// @param marketId The market ID
    /// @param indexPrice The index price (fallback when book is empty)
    /// @return impactBidPrice The volume-weighted average price for selling
    /// @return impactAskPrice The volume-weighted average price for buying
    function computeImpactPrices(
        address protocol,
        uint16 marketId,
        uint256 indexPrice
    ) external view returns (uint256 impactBidPrice, uint256 impactAskPrice);

    /// @notice Returns order for a market
    /// @param protocol The protocol address whose orderbook to query
    /// @param orderId The resting order ID to query
    function getOrder(
        address protocol,
        uint16 marketId,
        RestingOrderId orderId
    ) external view returns (Order memory);

    /// @notice Returns the total number of open orders for a user in a market
    /// @dev In deferred mode, excludes fully-consumed orders (openSteps == 0).
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param userId The user ID
    function getTotalOpenOrders(
        address protocol,
        uint16 marketId,
        uint32 userId
    ) external view returns (uint256);

    /// @notice Returns open orders for a user in a market with pagination
    /// @dev In deferred mode, excludes fully-consumed orders (openSteps == 0).
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param userId The user ID
    /// @param startIndex The starting index for pagination
    /// @param limit The maximum number of orders to return
    function getOpenOrders(
        address protocol,
        uint16 marketId,
        uint32 userId,
        uint256 startIndex,
        uint256 limit
    ) external view returns (RestingOrderId[] memory);

    /// @notice Returns all open order IDs for a user in a market
    /// @dev Returns the raw bitmap contents WITHOUT deferred filtering. Fully-consumed
    ///      deferred orders (openSteps == 0, pendingSteps > 0) are included because
    ///      position/margin projection (LibDeferredProjection) must see them to account
    ///      for unsettled fills. Use getTotalOpenOrders/getOpenOrders for UI-facing queries
    ///      that exclude dead orders.
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param userId The user ID
    function getAllOpenOrders(
        address protocol,
        uint16 marketId,
        uint32 userId
    ) external view returns (RestingOrderId[] memory);

    /// @notice Returns the hook bitmap for an address
    /// @param hookAddress The address to query
    function getHookBitmap(
        address hookAddress
    ) external view returns (bytes32);

    /// @notice Sets the book configuration for a market (access restricted via AccessManager)
    /// @param marketId The market ID
    /// @param config The book configuration (stepSize, stepPrice)
    function setBookConfig(
        uint16 marketId,
        Config calldata config
    ) external;

    /// @notice Returns the book configuration for a market
    /// @param protocol The protocol address
    /// @param marketId The market ID
    function getBookConfig(
        address protocol,
        uint16 marketId
    ) external view returns (Config memory);

    /// @notice Sets a new header version for the calling protocol, recording the block from which it applies.
    ///         Applies globally to all markets of the protocol.
    /// @param version The new header version (must be strictly greater than current)
    function setHeaderVersion(
        uint8 version
    ) external;

    /// @notice Returns the header version active at a given block number for a protocol.
    ///         Header versions are global across all markets of a protocol.
    /// @param protocol The protocol address whose orderbook to query
    /// @param blockNumber The block number to look up
    /// @return The header version active at that block
    function getHeaderVersion(
        address protocol,
        uint64 blockNumber
    ) external view returns (uint8);

    /// @notice Enables or disables deferred maker settlement for a market (access restricted via AccessManager)
    /// @param marketId The market ID
    /// @param enabled True to enable deferred settlement, false for synchronous settlement
    function setDeferredMode(
        uint16 marketId,
        bool enabled
    ) external;

    /// @notice Returns whether deferred maker settlement is enabled for a market
    /// @param protocol The protocol address
    /// @param marketId The market ID
    /// @return True if deferred settlement is enabled
    function isDeferredMode(
        address protocol,
        uint16 marketId
    ) external view returns (bool);

    /// @notice Returns pending (cursor-consumed but unsettled) maker steps and order info.
    /// @dev pendingSteps = claimableSteps - claimedSteps, computed from internal deferred state.
    ///      Returns (0, 0, 0) when no deferred state exists or nothing is pending.
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market identifier
    /// @param orderId The resting order ID to query
    /// @return pendingSteps Steps consumed by cursor but not yet settled
    /// @return tick The order's tick
    /// @return feeBps The order's fee in basis points
    function getDeferredPending(
        address protocol,
        uint16 marketId,
        RestingOrderId orderId
    ) external view returns (uint32 pendingSteps, uint24 tick, int16 feeBps);

    /// @notice Per-segment fill data for exact deferred settlement projection
    /// @dev Each chunk corresponds to one `onSettleMakerChunk` dispatch that would occur during pump.
    ///      Returned in settlement order (FIFO within each tick, ticks in pumpForUser iteration order).
    struct ProjectedFillChunk {
        uint128 claimSize;
        uint128 claimQuoteAmount;
        int128 fundingSnapshotX128;
        int16 feeBps;
        OrderSide side;
    }

    /// @notice Returns per-segment fill chunks for a user's pending settlements in settlement order
    /// @dev Simulates the pump path as a view: for each (tick, side) with pending work, walks FIFO
    ///      order and simulates segment consumption to produce the exact chunk sequence that
    ///      onSettleMakerChunk would receive during actual pump.
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market identifier
    /// @param userId The user ID to project settlements for
    /// @return chunks Array of fill chunks in settlement order
    function getProjectedFillChunks(
        address protocol,
        uint16 marketId,
        uint32 userId
    ) external view returns (ProjectedFillChunk[] memory chunks);

    /// @notice Returns the account registry used for address ↔ userId mapping
    function getAccountRegistry() external view returns (IAccountRegistry);

    /// @notice Returns tick-level diagnostic info for a market
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param tick The tick to query
    /// @return orderIdsLength The current length of the orderIds array
    /// @return liveOrders The number of non-tombstoned entries
    /// @return totalSizeSteps The aggregate unfilled size in steps from the sum tree
    function getTickLevelInfo(
        address protocol,
        uint16 marketId,
        Tick tick
    ) external view returns (uint256 orderIdsLength, uint16 liveOrders, uint64 totalSizeSteps);

    /// @notice Returns the seqId for a specific resting order
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param orderId The resting order ID to query
    /// @return seqId The 1-based sequence ID (0 if the order has been cancelled/filled)
    function getOrderSeqId(
        address protocol,
        uint16 marketId,
        RestingOrderId orderId
    ) external view returns (uint16 seqId);

    /// @notice Returns the total steps in a user's self-size tree at a tick
    /// @param protocol The protocol address whose orderbook to query
    /// @param marketId The market ID
    /// @param tick The tick to query
    /// @param userId The user ID to query
    /// @return selfSizeSteps The total steps in the user's self-size tree
    function getUserSelfSizeSteps(
        address protocol,
        uint16 marketId,
        Tick tick,
        uint32 userId
    ) external view returns (uint64 selfSizeSteps);
}
