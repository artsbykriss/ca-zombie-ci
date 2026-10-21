// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { Tick } from "src/libraries/order-book/price-level-queue/LibTick.sol";
import { RestingOrderId } from "src/libraries/types/RestingOrderId.sol";
import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

struct Fees {
    int256 maker;
    int256 taker;
    int256 liquidation;
}

/// @title IPerpsHooks
/// @notice Interface for PerpsManager hook callbacks from OrdersManager
interface IPerpsHooks {
    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not the OrdersManager
    error NotOrdersManager(address caller);

    /// @notice Thrown when the account has insufficient margin
    error InsufficientMargin(uint256 available, uint256 required);

    /// @notice Thrown when the account is unhealthy
    error UnhealthyAccount(address account);

    /// @notice Thrown when a reduce-only order is not reducing the position
    error ReduceOnlyOrderNotReducingPosition();

    /// @notice Thrown when the number of open orders exceeds the limit
    error OpenOrdersExceedsLimit(uint256 numOpenOrders);

    /// @notice Thrown when the account has negative cross margin balance after placing order
    error NegativeCrossMarginBalance(int256 balance);

    /// @notice Thrown when the account has negative isolated margin balance
    error NegativeIsolatedMarginBalance(int256 balance);

    /// @notice Thrown when open interest would exceed the limit
    error OpenInterestLimitExceeded(uint256 currentOI, uint256 limit);

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when positions are settled after a match (legacy per-fill event)
    /// @dev maker/taker addresses and takerSide are derivable from the order IDs
    event OnMatch(
        uint16 indexed marketId,
        RestingOrderId indexed makerOrderId,
        WideOrderId indexed takerOrderId,
        Tick tickLevel,
        uint128 matchedSize,
        Fees fees,
        int128 accumulatedFundingPayment
    );

    /// @notice Emitted when a taker level is settled during matching
    event OnTakeLevel(
        uint16 indexed marketId,
        WideOrderId indexed takerOrderId,
        Tick tickLevel,
        uint128 matchedSize,
        int256 takerFee,
        int256 liquidationFee,
        int128 accumulatedFundingPayment
    );

    /// @notice Emitted when a deferred maker chunk is settled
    event OnSettleMakerChunk(
        uint16 indexed marketId,
        RestingOrderId indexed makerOrderId,
        Tick tickLevel,
        uint128 claimSize,
        int256 makerFee,
        int128 accumulatedFundingPayment,
        bool makerFullyClaimed
    );
}
