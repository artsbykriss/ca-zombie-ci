// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IAccessManaged } from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import { IRISExStork } from "src/interfaces/oracles/IRISExStork.sol";
import { LibBlockEMA } from "src/libraries/misc/LibBlockEMA.sol";
import { LibMarkOracle } from "src/libraries/oracles/LibMarkOracle.sol";

interface IRISExOracle is IAccessManaged {
    /// @dev Market oracle config with independent fallback sources and index price block EMA.
    ///   Slot 0: indexFallbackSource (20B) + deviationThresholdBps (2B)
    ///   Slot 1: markFallbackSource (20B)
    ///   Slot 2: EmaState — ema (uint128) + lastBlock (uint64) + updateCount (uint64)
    ///   Slot 3: indexAlpha (uint64/8B) + indexMinBlocks (uint16/2B)
    struct MarketOracleConfig {
        address indexFallbackSource;
        uint16 deviationThresholdBps;
        address markFallbackSource;
        LibBlockEMA.EmaState indexEma;
        uint64 indexAlpha;
        uint16 indexMinBlocks;
    }

    /// @dev Packed per-token oracle state (3 slots):
    ///   Slot 0: EmaState — ema (uint128) + lastBlock (uint64) + updateCount (uint64)
    ///   Slot 1: fallbackSource (address/20B) + alpha (uint64/8B) + minBlocks (uint16/2B) + deviationThresholdBps (uint16/2B)
    ///   Slot 2: expectedPeg (uint128/16B) + maxPegDeviationBPS (uint16/2B)
    struct TokenOracleConfig {
        LibBlockEMA.EmaState ema;
        address fallbackSource;
        uint64 alpha;
        uint16 minBlocks;
        uint16 deviationThresholdBps;
        uint128 expectedPeg;
        uint16 maxPegDeviationBPS;
    }

    /// @dev State for mark price oracle per market
    /// @dev Combines EMA state and configuration
    struct MarketMarkOracleState {
        LibMarkOracle.TimeEMAState emaState;
        LibMarkOracle.Config config;
    }

    /// @notice Emitted when a fallback oracle source for index price is set for a market
    event SetFallbackOracleSource(uint16 indexed marketId, address indexed fallbackSource);

    /// @notice Emitted when a fallback oracle source for external mark price is set for a market
    event SetMarkFallbackOracleSource(uint16 indexed marketId, address indexed fallbackSource);

    /// @notice Emitted when a fallback oracle source is set for a token
    event SetTokenFallbackOracleSource(address indexed token, address indexed fallbackSource);

    /// @notice Emitted when the default deviation threshold is updated
    event SetDeviationThreshold(uint16 oldThresholdBps, uint16 newThresholdBps);

    /// @notice Emitted when a market-specific deviation threshold is updated
    event SetMarketDeviationThreshold(uint16 indexed marketId, uint16 oldThresholdBps, uint16 newThresholdBps);

    /// @notice Emitted when per-token EMA configuration is updated
    event SetTokenEMAConfig(address indexed token, uint64 alpha, uint16 minBlocks, uint16 deviationThresholdBps);

    /// @notice Emitted when a stablecoin peg configuration is set for a token
    event SetStablecoinPeg(address indexed token, uint128 expectedPeg, uint16 maxPegDeviationBPS);

    /// @notice Emitted when per-market index EMA configuration is updated
    event SetIndexEMAConfig(uint16 indexed marketId, uint64 alpha, uint16 minBlocks);

    /// @notice Emitted when mark oracle configuration is updated for a market
    event SetMarkOracleConfig(
        uint16 indexed marketId, uint32 timeConstantSeconds, uint32 minUpdateInterval, uint16 maxPremiumBps
    );

    /// @notice Emitted when oracle data is published on-chain for off-chain indexing
    event OracleData(uint16 indexed marketId, uint256 markPrice, uint256 indexPrice);

    /// @notice Stablecoin price deviated beyond the configured peg threshold
    error StablecoinDepegDetected(address token, uint256 currentPrice, uint256 expectedPeg, uint256 deviationBPS);

    /// @notice Thrown when a configuration parameter is out of valid range
    error InvalidParameter();

    /// @notice Gets the mark price for a market
    /// @param marketId The ID of the market
    /// @return The mark price
    function getMarkPrice(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Permissionless function that syncs EMAs and emits both mark and index prices for a market
    /// @dev Intended for off-chain indexers that need block-indexed oracle snapshots.
    ///      Calls syncMarkPriceEMA and syncIndexBlockEMA, then emits OracleData with both prices.
    /// @param marketId The ID of the market
    function syncOracleData(
        uint16 marketId
    ) external;

    /// @notice Gets the index price for a market
    /// @param marketId The ID of the market
    /// @return The index price
    function getIndexPrice(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Gets the price for a token with EMA deviation validation
    /// @dev Resolves price from primary/fallback sources, validates against the block EMA.
    ///      Reverts with PriceDeviationTooHigh if deviation exceeds the per-token threshold
    ///      (or global default). During EMA bootstrap, validation is skipped.
    /// @param token The address of the token
    /// @return The resolved and validated price (WAD scaled)
    function getTokenPrice(
        address token
    ) external view returns (uint256);

    /// @notice Checks whether a token's oracle is in degraded state (fallback configured but one source down)
    /// @dev Returns false when no fallback is configured (single-source is accepted by design)
    /// @param token The address of the token
    /// @return True if fallback is configured but only one of primary/fallback sources is available
    function isTokenOracleDegraded(
        address token
    ) external view returns (bool);

    /// @notice Sync the block EMA for a token by fetching the current price and updating the EMA state
    /// @dev Permissionless. Called by keepers alongside the funding rate snapshot to keep EMA fresh.
    ///      The health check reads the EMA without updating it, so this function must be called
    ///      periodically to maintain accurate deviation detection.
    /// @param token The token address to sync
    function syncTokenBlockEMA(
        address token
    ) external;

    /// @notice Gets EMA state for a token
    /// @param token The token address
    /// @return ema Current EMA value
    /// @return lastBlock Last update block
    /// @return updateCount Total updates
    /// @return reliable Whether EMA has sufficient history
    function getTokenEMAState(
        address token
    ) external view returns (uint256 ema, uint64 lastBlock, uint64 updateCount, bool reliable);

    /// @notice Sets the oracle for a market (primary source)
    /// @param marketId The ID of the market
    /// @param markPriceId The ID of the mark price
    /// @param indexPriceId The ID of the index price
    function setStorkOracle(
        uint16 marketId,
        bytes32 markPriceId,
        bytes32 indexPriceId
    ) external;

    /// @notice Sets the oracle for a token (primary source)
    /// @param token The address of the token
    /// @param priceId The ID of the price
    function setTokenOracle(
        address token,
        bytes32 priceId
    ) external;

    /// @notice Returns the RISExStork contract
    function getRisexStork() external view returns (IRISExStork);
    /// @notice Sets a fallback oracle source for a market's index price
    /// @dev The fallback source must implement IRISExStork interface
    /// @param marketId The ID of the market
    /// @param fallbackSource The fallback oracle source (address(0) to disable)
    function setFallbackOracleSource(
        uint16 marketId,
        address fallbackSource
    ) external;

    /// @notice Sets a fallback oracle source for a market's external mark price
    /// @dev Independent from the index fallback so a compromised fallback cannot control
    ///      both index and mark inputs to the median3 computation
    /// @param marketId The ID of the market
    /// @param fallbackSource The fallback oracle source (address(0) to disable)
    function setMarkFallbackOracleSource(
        uint16 marketId,
        address fallbackSource
    ) external;

    /// @notice Sets a fallback oracle source for a token
    /// @dev The fallback source must implement IRISExStork interface
    /// @param token The address of the token
    /// @param fallbackSource The fallback oracle source (address(0) to disable)
    function setTokenFallbackOracleSource(
        address token,
        address fallbackSource
    ) external;

    /// @notice Sets the default deviation threshold for price validation
    /// @dev When both primary and fallback return prices, reverts if deviation exceeds threshold.
    /// This default is used when no market-specific threshold is set.
    /// @param thresholdBps The threshold in basis points (e.g., 500 = 5%, 0 to disable checks)
    function setDeviationThreshold(
        uint16 thresholdBps
    ) external;

    /// @notice Sets a market-specific deviation threshold
    /// @dev Use this to override the default threshold for volatile markets
    /// @param marketId The ID of the market
    /// @param thresholdBps The threshold in basis points (0 = use default threshold)
    function setMarketDeviationThreshold(
        uint16 marketId,
        uint16 thresholdBps
    ) external;

    /// @notice Gets the index fallback oracle source for a market
    /// @param marketId The ID of the market
    /// @return The index fallback oracle source address
    function fallbackOracleSources(
        uint16 marketId
    ) external view returns (address);

    /// @notice Gets the mark fallback oracle source for a market
    /// @param marketId The ID of the market
    /// @return The mark fallback oracle source address
    function markFallbackOracleSources(
        uint16 marketId
    ) external view returns (address);

    /// @notice Gets the fallback oracle source for a token
    /// @param token The address of the token
    /// @return The fallback oracle source address
    function tokenFallbackOracleSources(
        address token
    ) external view returns (address);

    /// @notice Gets the default deviation threshold
    /// @return The default deviation threshold in basis points
    function deviationThresholdBps() external view returns (uint16);

    /// @notice Gets the market-specific deviation threshold
    /// @param marketId The ID of the market
    /// @return The market-specific threshold (0 = uses default)
    function marketDeviationThresholdBps(
        uint16 marketId
    ) external view returns (uint16);

    /// @notice Gets the effective deviation threshold for a market
    /// @dev Returns market-specific threshold if set, otherwise default threshold
    /// @param marketId The ID of the market
    /// @return The effective threshold in basis points
    function getEffectiveDeviationThreshold(
        uint16 marketId
    ) external view returns (uint16);

    /// @notice Configures per-token EMA and deviation parameters
    /// @dev Safe to call at runtime — new values take effect from next getTokenPrice/sync call.
    ///      minBlocks change may temporarily affect reliability status of existing EMAs.
    /// @param token The token address to configure
    /// @param alpha EMA smoothing factor (WAD scaled, 0 < alpha < WAD). e.g., 1e17 = 10% weight to new price
    /// @param minBlocks Minimum update count before EMA is considered reliable for validation
    /// @param deviationThresholdBps_ Max deviation in BPS for EMA and source checks (0 = use global default)
    function configureTokenEMA(
        address token,
        uint64 alpha,
        uint16 minBlocks,
        uint16 deviationThresholdBps_
    ) external;

    /// @notice Gets the EMA configuration for a token
    /// @param token The token address
    /// @return config The EMA configuration (defaults returned if not configured)
    function getTokenEMAConfig(
        address token
    ) external view returns (LibBlockEMA.Config memory config);

    /// @notice Configures a stablecoin peg for a token
    /// @dev When expectedPeg > 0, getTokenPrice will revert if price deviates beyond maxPegDeviationBPS.
    ///      Set expectedPeg = 0 to disable peg checking for a token.
    /// @param token The token address to configure
    /// @param expectedPeg Expected peg price (WAD scaled, e.g., 1e18 for $1). 0 to disable.
    /// @param maxPegDeviationBPS Maximum allowed deviation in basis points (e.g., 200 = 2%)
    function configureStablecoinPeg(
        address token,
        uint128 expectedPeg,
        uint16 maxPegDeviationBPS
    ) external;

    /// @notice Checks if a token has a stablecoin peg configured
    /// @param token The token address to check
    /// @return True if expectedPeg > 0
    function getIsStablecoin(
        address token
    ) external view returns (bool);

    /// @notice Sync the block EMA for a market's index price
    /// @dev Permissionless. Called by keepers alongside syncMarkPriceEMA to keep index EMA fresh.
    /// @param marketId The market ID to sync
    function syncIndexBlockEMA(
        uint16 marketId
    ) external;

    /// @notice Configures per-market index EMA parameters
    /// @param marketId The market ID to configure
    /// @param alpha EMA smoothing factor (WAD scaled, 0 < alpha < WAD)
    /// @param minBlocks Minimum update count before EMA is considered reliable
    function configureIndexEMA(
        uint16 marketId,
        uint64 alpha,
        uint16 minBlocks
    ) external;

    /// @notice Gets the index EMA state for a market
    /// @param marketId The market ID
    /// @return ema Current EMA value
    /// @return lastBlock Last update block
    /// @return updateCount Total updates
    /// @return reliable Whether EMA has sufficient history
    function getIndexEMAState(
        uint16 marketId
    ) external view returns (uint256 ema, uint64 lastBlock, uint64 updateCount, bool reliable);

    /// @notice Gets the index EMA configuration for a market
    /// @param marketId The market ID
    /// @return config The EMA configuration (defaults returned if not configured)
    function getIndexEMAConfig(
        uint16 marketId
    ) external view returns (LibBlockEMA.Config memory config);

    /// @notice Syncs the mark price EMA for a market. Permissionless.
    /// @dev Computes impact price from book depth and updates the premium EMA.
    ///      Skips update if insufficient time has passed since last update.
    ///      Anyone can call this to keep the oracle fresh.
    /// @param marketId The market ID to update
    function syncMarkPriceEMA(
        uint16 marketId
    ) external;

    /// @notice Configures the mark oracle parameters for a market
    /// @dev All parameters are governance-updatable to adapt to changing market conditions.
    ///      Impact notional is hardcoded as 500 USDC * maxLeverage (following Lighter's approach).
    /// @param marketId The market ID to configure
    /// @param timeConstantSeconds EMA time constant τ in seconds (e.g., 450 for 7.5min)
    /// @param minUpdateInterval Minimum seconds between EMA updates (e.g., 10)
    /// @param maxPremiumBps Maximum premium deviation in basis points (e.g., 30 for ±0.3%)
    function configureMarkOracle(
        uint16 marketId,
        uint32 timeConstantSeconds,
        uint32 minUpdateInterval,
        uint16 maxPremiumBps
    ) external;

    /// @notice Gets the mark oracle configuration for a market
    /// @param marketId The market ID to query
    /// @return config The mark oracle configuration
    function getMarkOracleConfig(
        uint16 marketId
    ) external view returns (LibMarkOracle.Config memory config);

    /// @notice Gets the mark price EMA state for a market
    /// @param marketId The market ID to query
    /// @return numerator EMA numerator (signed, can be negative)
    /// @return denominator EMA denominator
    /// @return lastUpdateTime Last update timestamp
    function getMarkEMAState(
        uint16 marketId
    ) external view returns (int256 numerator, uint256 denominator, uint64 lastUpdateTime);
}
