// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

type Tick is uint24;

// solhint-disable code-complexity, no-inline-assembly

/// @title LibTick
/// @notice Converts between discrete tick indices and continuous prices in the order book.
/// @dev A tick is a uint24 index representing a price level. The actual price is computed as
///      tick * stepPrice, where stepPrice is the market's minimum price increment (tick size).
///      This discretization enables compact storage (3 bytes per price vs 32 bytes) and ensures
///      all prices align to the market's tick grid. Tick 0 and type(uint24).max are reserved as
///      sentinel values (used by bitmap traversal for boundary detection), so valid ticks range
///      from MIN_TICK (1) to MAX_TICK (16,777,214). ZERO_TICK is a special case used only for
///      market orders, which have no limit price.
library LibTick {
    using LibTick for Tick;

    /// @notice Thrown when a tick index is outside the valid range [MIN_TICK, MAX_TICK].
    error InvalidTick();

    /// @notice Thrown when a price cannot be converted to a valid tick (not divisible by stepPrice,
    ///         or resulting tick is out of range).
    error InvalidPrice();

    /// @dev Maximum valid tick index. type(uint24).max (16,777,215) is reserved as the "no greater tick"
    ///      sentinel by LibTickBitmap.minGreaterThan.
    uint24 internal constant MAX_TICK = type(uint24).max - 1;

    /// @dev Minimum valid tick index. 0 is reserved as the "no lesser tick" sentinel by
    ///      LibTickBitmap.maxLessThan, and also used as the market order sentinel (ZERO_TICK).
    uint24 internal constant MIN_TICK = type(uint24).min + 1;

    /// @dev Sentinel tick for market orders. Market orders have no limit price, so their tick is 0.
    ///      Must not be passed to toPrice or validateTick (would revert).
    Tick internal constant ZERO_TICK = Tick.wrap(0); // only use for market order, do not pass directly to Tick functions

    /// @notice Validates that a tick index is within the allowed range [MIN_TICK, MAX_TICK].
    /// @dev Reverts with InvalidTick if the tick is 0 (reserved for market orders) or
    ///      type(uint24).max (reserved as bitmap sentinel).
    /// @param tick The tick index to validate
    function validateTick(
        Tick tick
    ) internal pure {
        require(Tick.unwrap(tick) <= MAX_TICK && Tick.unwrap(tick) >= MIN_TICK, InvalidTick());
    }

    /// @notice Converts a WAD-scaled price to a tick index, validating alignment and range.
    /// @dev The price must be an exact multiple of stepPrice (no fractional ticks allowed).
    ///      The resulting tick must fall within [MIN_TICK, MAX_TICK].
    /// @param price The price to convert (WAD-scaled, e.g., 50000e18 for $50,000)
    /// @param stepPrice The market's tick size (WAD-scaled, e.g., 1e14 for $0.0001)
    /// @return The tick index corresponding to the price
    function fromPrice(
        uint256 price,
        uint256 stepPrice
    ) internal pure returns (Tick) {
        uint256 tick = price / stepPrice;
        require(price % stepPrice == 0 && tick <= MAX_TICK && tick >= MIN_TICK, InvalidPrice());
        // forge-lint: disable-next-line(unsafe-typecast)
        return Tick.wrap(uint24(tick));
    }

    /// @notice Converts a tick index to a WAD-scaled price, with tick validation.
    /// @dev Validates the tick range before computing price = tick * stepPrice.
    ///      Used for user-facing operations where the tick origin is untrusted.
    /// @param tick The tick index to convert
    /// @param stepPrice The market's tick size (WAD-scaled)
    /// @return The corresponding price in WAD units
    function toPrice(
        Tick tick,
        uint256 stepPrice
    ) internal pure returns (uint256) {
        validateTick(tick);
        return Tick.unwrap(tick) * stepPrice;
    }

    /// @notice Converts a tick index to a WAD-scaled price without validation.
    /// @dev Skips the range check for gas efficiency. Only safe when the tick is known to be valid,
    ///      e.g., when retrieved from bitmap traversal (which only returns previously-set ticks).
    /// @param tick The tick index to convert (must be known-valid)
    /// @param stepPrice The market's tick size (WAD-scaled)
    /// @return The corresponding price in WAD units
    function toPriceUnchecked(
        Tick tick,
        uint256 stepPrice
    ) internal pure returns (uint256) {
        return Tick.unwrap(tick) * stepPrice;
    }
}
