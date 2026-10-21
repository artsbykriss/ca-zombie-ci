// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { LibBitmap } from "solady/src/utils/LibBitmap.sol";
import { RestingOrderId } from "src/libraries/types/RestingOrderId.sol";

/// @title IPerpsAccount
/// @notice Interface for account management and account view functions
interface IPerpsAccount {
    /*//////////////////////////////////////////////////////////////////////////
                                    ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum MarginMode {
        Cross,
        Isolated
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Portfolio {
        LibBitmap.Bitmap crossMarkets;
        LibBitmap.Bitmap isolatedMarkets;
    }

    struct Position {
        // ── slot 0: hot path fields ─────────────────────────
        int128 size;
        int128 quoteAmount;
        // ── slot 1: settlement + config ─────────────────────
        int128 lastFundingPayment;
        uint8 leverage;
        MarginMode marginMode;
        uint112 isolatedUsdcBalance;
    }

    struct OrderMargin {
        uint128 totalMarginAccountableOrderUnfilledSize;
        uint128 totalMarginAccountableOrderNotional;
    }

    struct TradingAccount {
        Position position;
        OrderMargin orderMargin;
    }

    /// @notice Request parameters to update margin mode
    struct UpdateMarginModeParams {
        uint16 marketId;
        MarginMode marginMode;
    }

    /// @notice Request parameters to update leverage
    struct UpdateLeverageParams {
        uint16 marketId;
        uint8 leverage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when margin mode is unchanged
    error MarginModeUnchanged(MarginMode marginMode);

    /// @notice Thrown when there is an open position
    error OpenPositionExists(int256 positionSize);

    /// @notice Thrown when there are open orders (margin mode change)
    error OpenOrdersExistForMarginMode(uint256 numOpenOrders);

    /// @notice Thrown when leverage is invalid
    error InvalidLeverage(uint256 leverage);

    /// @notice Thrown when cross margin balance is insufficient
    error InsufficientCrossMarginBalance(int256 balance, int256 required);

    /// @notice Thrown when isolated margin balance is insufficient
    error InsufficientIsolatedMarginBalance(int256 balance, int256 required);

    /// @notice Thrown when collateral margin balance is insufficient
    error InsufficientCollateralMarginBalance(int256 balance, int256 required);

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emitted when an account updates margin mode in a market
    event UpdateMarginMode(
        address indexed account, uint16 indexed marketId, MarginMode oldMarginMode, MarginMode newMarginMode
    );

    /// @dev Emitted when an account updates leverage in a market
    event UpdateLeverage(address indexed account, uint16 indexed marketId, uint256 oldLeverage, uint256 newLeverage);

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Update margin mode in a market
    function updateMarginMode(
        UpdateMarginModeParams calldata params
    ) external;

    /// @notice Update leverage for an account in a market
    function updateLeverage(
        UpdateLeverageParams calldata params
    ) external;

    /// @notice Returns active markets bitmap for an account
    function getActiveMarkets(
        address account
    ) external view returns (uint256[] memory);

    /// @notice Returns leverage for an account in a market
    function getLeverage(
        uint16 marketId,
        address account
    ) external view returns (uint128);

    /// @notice Returns position for an account in a market
    function getPosition(
        uint16 marketId,
        address account
    ) external view returns (Position memory);

    /// @notice Returns total margin accountable order unfilled size
    function getTotalMarginAccountableOrderUnfilledSize(
        uint16 marketId,
        address account
    ) external view returns (uint256);

    /// @notice Returns total margin accountable order notional
    function getTotalMarginAccountableOrderNotional(
        uint16 marketId,
        address account
    ) external view returns (uint256);

    /// @notice Returns projected open orders for an account, excluding fully-consumed deferred orders
    function getOpenOrders(
        uint16 marketId,
        address account,
        uint256 startIndex,
        uint256 limit
    ) external view returns (RestingOrderId[] memory);

    /// @notice Returns projected total open order count, excluding fully-consumed deferred orders
    function getTotalOpenOrders(
        uint16 marketId,
        address account
    ) external view returns (uint256);
}
