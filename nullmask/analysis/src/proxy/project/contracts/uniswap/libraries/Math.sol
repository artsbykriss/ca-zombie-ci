// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @title Math Library
/// @notice Basic math operations for Uniswap V2
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /// @notice Babylonian method for square root
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
