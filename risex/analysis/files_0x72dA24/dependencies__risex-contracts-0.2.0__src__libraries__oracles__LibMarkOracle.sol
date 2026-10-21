// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

/// @title LibMarkOracle
/// @notice Lighter-inspired mark price oracle using time-based EMA and median of three prices.
/// @dev Computes mark price as median(P1, P2, P3) where:
///      P1 = IndexPrice + clamp(EMA(ImpactPrice - IndexPrice), ±maxPremiumBps)
///      P2 = ImpactPrice (raw impact price from book depth)
///      P3 = ExternalPrice (from external oracle like Stork)
///
///      The EMA tracks raw, unclamped premiums. Clamping occurs only when computing P1 to prevent
///      extreme deviations from dominating the mark price while preserving EMA signal integrity.
///
///      Impact price is computed by simulating fills through the book for a target notional
///      amount scaled by leverage: impactNotional = baseNotional * maxLeverage.
///
///      The EMA uses continuous time-based decay rather than block-based smoothing to prevent
///      manipulation via block timing control on L2 sequencers.
library LibMarkOracle {
    using FixedPointMathLib for uint256;

    /// @notice Time-weighted EMA state for tracking premium/discount over time.
    /// @dev Uses continuous exponential decay: ema = numerator / denominator
    ///      numerator = numerator_old * exp(-dt/τ) + sample * dt
    ///      denominator = denominator_old * exp(-dt/τ) + dt
    ///      Premium is stored as signed int256 to represent both premium (positive) and discount (negative).
    ///      Using int256/uint256 (not int128/uint128) to prevent overflow when dt is large or after many updates.
    struct TimeEMAState {
        int256 numerator;
        uint256 denominator;
        uint64 lastUpdateTime;
    }

    /// @notice Configuration parameters for mark price computation.
    /// @dev All parameters are governance-updatable per market to adapt to changing liquidity conditions.
    struct Config {
        uint32 timeConstantSeconds;
        uint32 minUpdateInterval;
        uint16 maxPremiumBps;
    }

    /// @notice Updates the premium EMA with a new sample using time-weighted exponential decay.
    /// @dev On first update (denominator == 0), initializes the EMA to the sample value.
    ///      For subsequent updates, applies exponential decay based on elapsed time:
    ///      - Computes decay factor: exp(-dt/τ)
    ///      - Updates numerator: numerator_old * decay + sample * dt
    ///      - Updates denominator: denominator_old * decay + dt
    ///      The premium is stored raw without clamping to preserve signal integrity.
    ///      Clamping occurs at read time in computePriceInputs.
    ///      Note: minUpdateInterval gating is enforced by the caller (e.g. RISExOracle.syncMarkPriceEMA).
    /// @param emaState The EMA state storage pointer
    /// @param config The oracle configuration containing time constant
    /// @param premium The current raw premium (impactPrice - indexPrice), can be negative
    function updatePremiumEMA(
        TimeEMAState storage emaState,
        Config memory config,
        int256 premium
    ) internal {
        uint256 currentTime = block.timestamp;

        if (emaState.lastUpdateTime == 0) {
            emaState.numerator = premium;
            emaState.denominator = 1;
            emaState.lastUpdateTime = uint64(currentTime);
            return;
        }

        uint256 dt = currentTime - emaState.lastUpdateTime;

        int256 exponent = -int256((dt * FixedPointMathLib.WAD) / config.timeConstantSeconds);
        uint256 decay = uint256(FixedPointMathLib.expWad(exponent));

        int256 decayedNumerator = (emaState.numerator * int256(decay)) / int256(FixedPointMathLib.WAD);
        int256 newNumerator = decayedNumerator + (premium * int256(dt));

        uint256 decayedDenominator = (emaState.denominator * decay) / FixedPointMathLib.WAD;
        uint256 newDenominator = decayedDenominator + dt;

        emaState.numerator = newNumerator;
        emaState.denominator = newDenominator;
        emaState.lastUpdateTime = uint64(currentTime);
    }

    /// @notice Returns the current EMA premium value.
    /// @dev Returns 0 if EMA is uninitialized (denominator == 0).
    ///      The returned value can be negative (discount) or positive (premium).
    /// @param emaState The EMA state storage pointer
    /// @return The current EMA premium in WAD units
    function getEMAPremium(
        TimeEMAState storage emaState
    ) internal view returns (int256) {
        if (emaState.denominator == 0) return 0;
        return emaState.numerator / int256(emaState.denominator);
    }

    /// @notice Clamps a value between minimum and maximum bounds.
    /// @dev Used to limit premium deviation from index price as a circuit breaker.
    ///      Prevents extreme book manipulation from creating unbounded mark price deviation.
    /// @param value The value to clamp
    /// @param min The minimum bound
    /// @param max The maximum bound
    /// @return The clamped value
    function clamp(
        int256 value,
        int256 min,
        int256 max
    ) internal pure returns (int256) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    /// @notice Returns the median of three values.
    /// @dev Used to compute mark price as median(P1, P2, P3).
    ///      Median provides robustness: requires 2/3 inputs to be corrupted for manipulation.
    ///      Handles all permutations of ordering without branches.
    /// @param a First value
    /// @param b Second value
    /// @param c Third value
    /// @return The median value
    function median3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        if (a > b) {
            if (b > c) return b;
            if (a > c) return c;
            return a;
        } else {
            if (a > c) return a;
            if (b > c) return c;
            return b;
        }
    }

    /// @notice Computes the two internal price inputs for mark price calculation.
    /// @dev P1 = indexPrice + clamp(EMA(premium), ±maxPremiumBps)
    ///      P2 = impactPrice (raw)
    ///      The EMA tracks raw premiums. Clamping occurs here at read time to prevent
    ///      extreme book manipulation from dominating the mark price while preserving
    ///      the EMA's ability to track genuine market trends.
    /// @param indexPrice The index price from external oracle
    /// @param impactPrice The impact price computed from book depth
    /// @param emaPremium The current raw EMA premium from state
    /// @param maxPremiumBps The maximum allowed premium deviation in basis points
    /// @return p1 Index-anchored premium price
    /// @return p2 Raw impact price
    function computePriceInputs(
        uint256 indexPrice,
        uint256 impactPrice,
        int256 emaPremium,
        uint16 maxPremiumBps
    ) internal pure returns (uint256 p1, uint256 p2) {
        p2 = impactPrice;

        int256 signedIndexPrice = int256(indexPrice);
        int256 maxDeviation = (signedIndexPrice * int256(uint256(maxPremiumBps))) / 10_000;
        int256 clampedPremium = clamp(emaPremium, -maxDeviation, maxDeviation);

        p1 = uint256(signedIndexPrice + clampedPremium);
    }
}
