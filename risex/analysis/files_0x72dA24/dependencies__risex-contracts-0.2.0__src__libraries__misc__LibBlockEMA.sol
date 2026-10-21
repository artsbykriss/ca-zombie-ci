// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";

/// @title LibBlockEMA
/// @notice Gas-efficient exponential moving average for sub-second L2 chains.
/// @dev Single storage slot (~5K gas per update), immune to single-block manipulation.
///      Alpha and minBlocks are configurable per-deployment; callers pass them in.
/// @custom:security-contact security@risex.io
library LibBlockEMA {
    using SafeCastLib for *;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18;
    uint256 internal constant BPS = 10_000;

    /// @dev Default EMA smoothing factor: alpha = 0.1 * WAD = 1e17 (10% weight to new price)
    uint64 internal constant DEFAULT_ALPHA = 1e17;

    /// @dev Default minimum blocks before EMA is considered reliable for validation
    uint16 internal constant DEFAULT_MIN_BLOCKS = 20;

    /// @dev Maximum confidence score
    uint256 internal constant MAX_CONFIDENCE = 100;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Spot price deviated too far from EMA
    error PriceDeviationTooHigh(uint256 spotPrice, uint256 ema, uint256 deviationBPS);

    /*//////////////////////////////////////////////////////////////
                              DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @dev Per-token EMA configuration: alpha (8B) + minBlocks (2B) + deviationThresholdBps (2B) = 12 bytes in 1 slot
    struct Config {
        uint64 alpha; // EMA smoothing factor (WAD scaled, 0 = use DEFAULT_ALPHA)
        uint16 minBlocks; // Minimum update count for reliability (0 = use DEFAULT_MIN_BLOCKS)
        uint16 deviationThresholdBps; // Max EMA deviation in BPS (0 = use global default)
    }

    /// @dev Packed into single 256-bit slot for gas efficiency
    /// Layout: [ema: 128 bits][lastBlock: 64 bits][updateCount: 64 bits]
    struct EmaState {
        uint128 ema; // Current EMA value (WAD scaled)
        uint64 lastBlock; // Last update block (uint64 safe: 584B years at 1 block/sec)
        uint64 updateCount; // Number of updates (for bootstrap detection)
    }

    /*//////////////////////////////////////////////////////////////
                              CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update EMA with new price observation.
    /// @dev Called on every price fetch. ~5K gas (single SSTORE). Skips if same block.
    /// @param $ Storage pointer to EMA state
    /// @param newPrice New price observation (WAD scaled)
    /// @param alpha EMA smoothing factor (WAD scaled, 0 < alpha < WAD)
    function update(
        EmaState storage $,
        uint256 newPrice,
        uint64 alpha
    ) internal {
        // Skip if same block (no new information)
        if (block.number == $.lastBlock) return;

        uint128 currentEma = $.ema;

        if (currentEma == 0) {
            // Bootstrap: first price becomes EMA
            $.ema = newPrice.toUint128();
        } else {
            // EMA = alpha * newPrice + (1 - alpha) * oldEMA
            uint256 oneMinusAlpha = WAD - alpha;
            uint256 newEma = (alpha * newPrice + oneMinusAlpha * currentEma) / WAD;
            $.ema = newEma.toUint128();
        }

        $.lastBlock = block.number.toUint64();

        // Safe increment (will overflow after 2^64 updates - practically never)
        unchecked {
            $.updateCount++;
        }
    }

    /// @notice Get current EMA value.
    /// @param $ Storage pointer to EMA state
    /// @return Current EMA (0 if not initialized)
    function get(
        EmaState storage $
    ) internal view returns (uint256) {
        return $.ema;
    }

    /// @notice Check if EMA has sufficient history for reliable validation.
    /// @param $ Storage pointer to EMA state
    /// @param minBlocks Minimum update count for reliability
    /// @return True if enough updates have occurred
    function isReliable(
        EmaState storage $,
        uint16 minBlocks
    ) internal view returns (bool) {
        return $.updateCount >= minBlocks;
    }

    /// @notice Validate spot price against EMA. Reverts if deviation exceeds threshold.
    /// @dev During bootstrap (< minBlocks updates), validation passes.
    /// @param $ Storage pointer to EMA state
    /// @param spotPrice Current spot price to validate (WAD)
    /// @param maxDeviationBPS Maximum allowed deviation in basis points (e.g., 500 = 5%)
    /// @param minBlocks Minimum update count before validation enforced
    function validate(
        EmaState storage $,
        uint256 spotPrice,
        uint256 maxDeviationBPS,
        uint16 minBlocks
    ) internal view {
        uint256 ema = $.ema;

        // Allow any price during bootstrap (insufficient history)
        if (ema == 0 || $.updateCount < minBlocks) {
            return;
        }

        uint256 deviationBPS = calculateDeviationBPS(spotPrice, ema);

        require(deviationBPS <= maxDeviationBPS, PriceDeviationTooHigh(spotPrice, ema, deviationBPS));
    }

    /// @notice Get full EMA state for external queries.
    /// @param $ Storage pointer to EMA state
    /// @param minBlocks Minimum update count for reliability
    /// @return ema Current EMA value
    /// @return lastBlock Last update block
    /// @return updateCount Total updates
    /// @return reliable Whether EMA has sufficient history
    function getState(
        EmaState storage $,
        uint16 minBlocks
    ) internal view returns (uint256 ema, uint64 lastBlock, uint64 updateCount, bool reliable) {
        ema = $.ema;
        lastBlock = $.lastBlock;
        updateCount = $.updateCount;
        reliable = updateCount >= minBlocks;
    }

    /*//////////////////////////////////////////////////////////////
                          CONFIG-ACCEPTING OVERLOADS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update EMA using Config (resolves alpha from config with default fallback)
    /// @param $ Storage pointer to EMA state
    /// @param newPrice New price observation (WAD scaled)
    /// @param config Per-token EMA configuration
    function update(
        EmaState storage $,
        uint256 newPrice,
        Config memory config
    ) internal {
        update($, newPrice, effectiveAlpha(config.alpha));
    }

    /// @notice Validate spot price against EMA using Config (resolves minBlocks from config)
    /// @param $ Storage pointer to EMA state
    /// @param spotPrice Current spot price to validate (WAD)
    /// @param maxDeviationBPS Maximum allowed deviation in basis points
    /// @param config Per-token EMA configuration
    function validate(
        EmaState storage $,
        uint256 spotPrice,
        uint256 maxDeviationBPS,
        Config memory config
    ) internal view {
        validate($, spotPrice, maxDeviationBPS, effectiveMinBlocks(config.minBlocks));
    }

    /// @notice Check if EMA is reliable using Config (resolves minBlocks from config)
    /// @param $ Storage pointer to EMA state
    /// @param config Per-token EMA configuration
    /// @return True if enough updates have occurred
    function isReliable(
        EmaState storage $,
        Config memory config
    ) internal view returns (bool) {
        return isReliable($, effectiveMinBlocks(config.minBlocks));
    }

    /// @notice Get full EMA state using Config (resolves minBlocks from config)
    /// @param $ Storage pointer to EMA state
    /// @param config Per-token EMA configuration
    function getState(
        EmaState storage $,
        Config memory config
    ) internal view returns (uint256 ema, uint64 lastBlock, uint64 updateCount, bool reliable) {
        return getState($, effectiveMinBlocks(config.minBlocks));
    }

    /// @notice Resolves the effective EMA alpha, falling back to default when zero
    /// @param tokenAlpha The token-specific alpha (0 = use default)
    function effectiveAlpha(
        uint64 tokenAlpha
    ) internal pure returns (uint64) {
        return tokenAlpha > 0 ? tokenAlpha : DEFAULT_ALPHA;
    }

    /// @notice Resolves the effective EMA minBlocks, falling back to default when zero
    /// @param tokenMinBlocks The token-specific minBlocks (0 = use default)
    function effectiveMinBlocks(
        uint16 tokenMinBlocks
    ) internal pure returns (uint16) {
        return tokenMinBlocks > 0 ? tokenMinBlocks : DEFAULT_MIN_BLOCKS;
    }

    /// @notice Calculate absolute deviation between two prices in basis points
    /// @param price1 First price (WAD)
    /// @param price2 Second price (WAD)
    /// @return Deviation in basis points (0 if price2 is zero)
    function calculateDeviationBPS(
        uint256 price1,
        uint256 price2
    ) internal pure returns (uint256) {
        if (price2 == 0) return 0;

        uint256 deviation;
        if (price1 > price2) {
            deviation = price1 - price2;
        } else {
            deviation = price2 - price1;
        }

        return (deviation * BPS) / price2;
    }
}
