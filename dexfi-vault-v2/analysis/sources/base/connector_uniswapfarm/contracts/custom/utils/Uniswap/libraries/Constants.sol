// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

library Constants {
    /// @notice Design parameters
    uint256 internal constant PRECISION = 1e18;

    /// @notice FixedPoint96
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    /// @notice FixedPoint128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}
