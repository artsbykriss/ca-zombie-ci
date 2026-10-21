// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";

interface IPerpsMarketConfig {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct PerpsMarketConfig {
        // ── dynamic slot ───────────────────────────────────────
        string name;
        // ── packed slot: unlock check warms mmFactor + leverage ─
        address quote;
        bool unlocked;
        uint8 maxLeverage;
        uint80 maintenanceMarginFactor;
        // ── step slot ──────────────────────────────────────────
        uint32 minOrderStep;
        uint32 maxOrderStep;
        uint32 oiLimitSteps;
        uint64 stepSize;
        uint64 stepPrice;
    }

    struct PerpsMarket {
        PerpsMarketConfig config;
        /// @dev Packed slot: openInterest (16B) + pendingMakerUpper (16B) = 32B
        uint128 openInterest;
        /// @notice Conservative upper-bound delta for deferred maker settlement that may still increase OI.
        /// @dev Added on all deferred taker matches and consumed on deferred maker settlement chunks.
        uint128 pendingMakerUpper;
    }

    /// @notice Request parameters to open a new market
    struct OpenMarketParams {
        PerpsMarketConfig perpsConfig;
        IOrdersManager.Config bookConfig;
        bytes32 markPriceId;
        bytes32 indexPriceId;
    }
    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the quote is invalid. Only support USDC as quote for now
    error InvalidQuote(address quote);

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a market is opened
    event OpenMarket(uint16 indexed marketId, PerpsMarketConfig perpsConfig);

    /// @notice Emitted when a market lock status is changed
    event SetMarketLock(uint16 indexed marketId, bool unlocked);

    /// @notice Emitted when a market config is updated
    event UpdateMarketConfig(uint16 indexed marketId, PerpsMarketConfig oldConfig, PerpsMarketConfig newConfig);

    /// @notice Emitted when open interest limit is set for a market
    event SetOpenInterestLimit(uint16 indexed marketId, uint32 oldLimit, uint32 newLimit);

    /// @notice Emitted when deferred settlement mode is set for a market
    event SetDeferredMode(uint16 indexed marketId, bool enabled);

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Opens a new market
    /// @dev Emits a {OpenMarket} event
    /// @param params The parameters for opening the market
    /// @return marketId The market ID
    function openMarket(
        OpenMarketParams calldata params
    ) external returns (uint16 marketId);

    /// @notice Sets market lock state
    /// @dev Emits a {SetMarketLock} event
    /// @param marketId The market ID
    /// @param unlocked True to unlock, false to lock
    function setMarketLock(
        uint16 marketId,
        bool unlocked
    ) external;

    /// @notice Updates an existing market's configuration
    /// @dev Emits a {UpdateMarketConfig} event
    /// @param marketId The market ID
    /// @param perpsConfig The new market configuration
    function updateMarketConfig(
        uint16 marketId,
        PerpsMarketConfig calldata perpsConfig
    ) external;

    /// @notice Sets the open interest limit for a market
    /// @dev Emits a {SetOpenInterestLimit} event
    /// @param marketId The market ID
    /// @param limit The new open interest limit
    function setOpenInterestLimit(
        uint16 marketId,
        uint32 limit
    ) external;

    /// @notice Enables or disables deferred maker settlement for a market
    /// @dev Emits a {SetDeferredMode} event. Delegates to OrdersManager.setDeferredMode.
    /// @param marketId The market ID
    /// @param enabled True to enable deferred settlement, false for synchronous settlement
    function setDeferredMode(
        uint16 marketId,
        bool enabled
    ) external;

    /// @notice Ensures the market is valid and unlocked
    /// @param marketId The market ID
    function ensureMarketUnlocked(
        uint16 marketId
    ) external view;

    /// @notice Returns total markets
    function getTotalMarkets() external view returns (uint256);

    /// @notice Returns the market configuration
    /// @param marketId The market ID
    function getMarketConfig(
        uint16 marketId
    ) external view returns (PerpsMarketConfig memory);

    /// @notice Returns open interest for a market
    /// @param marketId The market ID
    function getOpenInterest(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Returns conservative upper-bound OI including unsettled deferred maker fills
    /// @dev During deferred settlement, settled OI may lag behind actual matched fills.
    ///      This returns settled OI + pending maker delta to give a complete picture.
    /// @param marketId The market ID
    function getOpenInterestUpperBound(
        uint16 marketId
    ) external view returns (uint256);
}
