// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SqrtPriceMath
 * @notice Pure math utility library for sqrt price conversions
 * @dev Provides shared price conversion logic to avoid code duplication across liquidity modules
 */
library SqrtPriceMath {

    using Math for uint256;

    /// @dev Precision scalar for price calculations (18 decimal places)
    /// @notice Used to maintain precision in price conversion calculations
    uint256 private constant PRECISION_SCALAR = 1e18;

    /**
     * @notice Converts price to sqrtPriceX96 format
     * @dev Converts a price value to Uniswap V3 sqrtPriceX96 format
     *      Formula: sqrtPriceX96 = sqrt(price * 2^192 / PRECISION_SCALAR)
     *      where 2^192 accounts for the Q64.96 fixed point representation
     * @param price Price value in PRECISION_SCALAR format (1e18)
     * @return sqrtPriceX96 The price in sqrtPriceX96 format as uint160
     */
    function toSqrtPriceX96(
        uint256 price
    ) internal pure returns (uint160 sqrtPriceX96) {
        return uint160(price.mulDiv(1 << 192, PRECISION_SCALAR).sqrt());
    }

    /**
     * @notice Converts sqrtPriceX96 to price format
     * @dev Converts a sqrtPriceX96 value back to regular price format
     *      Formula: price = (sqrtPriceX96^2 * PRECISION_SCALAR) / 2^192
     *      This is the inverse of toSqrtPriceX96 function
     * @param sqrtPriceX96 Price in sqrtPriceX96 format
     * @return price The price in PRECISION_SCALAR format (1e18)
     */
    function fromSqrtPriceX96(
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 price) {
        return uint256(sqrtPriceX96).mulDiv(uint256(sqrtPriceX96) * PRECISION_SCALAR, 1 << 192);
    }

}
