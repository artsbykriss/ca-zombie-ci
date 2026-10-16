// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library DecimalMath {
    uint256 public constant UNIT = 1e9;
    int256 public constant UNIT_INT = int256(UNIT);
    uint256 public constant UNIT_X18 = 1e18;

    /// @dev Multiplies two low precision decimals.
    ///
    /// Since the two numbers are assumed to be fixed point numbers,
    /// (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
    /// the result is divided by UNIT to remove double scaling.
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /// @dev Divides two low precision decimals.
    ///
    /// Since the two numbers are assumed to be fixed point numbers,
    /// (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
    /// x is first scaled up to end up with a decimal representation.
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /// @dev See mulDecimal for uint256.
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /// @dev See divDecimal for uint256.
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /// @dev Returns -1 if x < 0, 0 if x == 0, and 1 if x > 0
    function getSign(int256 x) internal pure returns (int8 result) {
        assembly {
            result := sub(sgt(x, 0), slt(x, 0))
        }
    }

    /// @dev Returns x rounded down to the nearest multiple of the given step size.
    function floorToMultiple(uint256 x, uint256 multiple) internal pure returns (uint256) {
        return x / multiple * multiple;
    }
}
