// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface INativeV3PriceOracleValidator {
    function validatePrice(
        uint256 liveSqrtPriceX96,
        uint256 deviation,
        address pool
    ) external view returns (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1);

    function arithmeticMeanSqrtPriceX96(address pool) external view returns (int24 meanTick, uint256 meanSqrtPriceX96);
}
