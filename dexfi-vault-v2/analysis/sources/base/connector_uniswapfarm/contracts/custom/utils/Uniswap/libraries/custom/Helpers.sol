// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Swap} from "./Swap.sol";
import {Oracle} from "./Oracle.sol";
import {Constants} from "../Constants.sol";
import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {PriceManagement} from "./PriceManagement.sol";
import {LiquidityManagement} from "./LiquidityManagement.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";

library Helpers {
    using Swap for Swap.SwapPair[];
    using Oracle for Oracle.OracleData;

    function calculateAndSwapByRatesPosition(
        IDexFiUniversalRouterBytes universalRouter,
        IUniswapV3Pool pool,
        uint256 inputNativeAmount,
        uint256 inputAmount0,
        uint256 inputAmount1,
        Swap.SwapData storage swapData,
        Oracle.OracleData storage oracleData,
        PriceManagement.PriceRangesData storage priceRangesData
    ) external returns (uint256 amount0, uint256 amount1) {
        uint256 precision = Constants.PRECISION;
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        Oracle.validatePoolPrice(oracleData, pool);
        (amount0, amount1) = PriceManagement.calculateRateTokensPerLiquidity(
            sqrtPriceX96,
            priceRangesData.sqrtPriceX96Low,
            priceRangesData.sqrtPriceX96Up,
            precision
        );
        uint256 token1Rate = (amount1 * precision) /
            (PriceManagement.calculateRatioToken0ToToken1(amount0, uint256(sqrtPriceX96)) + amount1);
        address native_ = swapData.swapsNativeToToken0[0].tokenIn;
        address token0 = swapData.swapsToken0ToNative[0].tokenIn;
        if (inputNativeAmount > 0) {
            uint256 amount1Swap = (inputNativeAmount * token1Rate) / precision;
            uint256 amount0Swap = inputNativeAmount - amount1Swap;
            if (native_ == token0 && amount1Swap >= swapData.minSwapAmountNative)
                oracleData.validatePoolPriceWithSwap(pool, universalRouter, amount1Swap, swapData.swapsToken0ToToken1);
            if (native_ == swapData.swapsToken1ToNative[0].tokenIn && amount0Swap >= swapData.minSwapAmountNative)
                oracleData.validatePoolPriceWithSwap(pool, universalRouter, amount0Swap, swapData.swapsToken1ToToken0);
            amount1 = swapData.swapsNativeToToken1.swap(
                universalRouter,
                amount1Swap,
                address(this),
                swapData.minSwapAmountNative
            );
            amount0 = swapData.swapsNativeToToken0.swap(
                universalRouter,
                amount0Swap,
                address(this),
                swapData.minSwapAmountNative
            );
        } else {
            uint256 amount0Native;
            uint256 amount1Native;
            if (inputAmount0 >= swapData.minSwapAmountToken0)
                amount0Native = swapData.swapsToken0ToNative.getAmountOut(universalRouter, inputAmount0);
            if (inputAmount1 >= swapData.minSwapAmountToken1)
                amount1Native = swapData.swapsToken1ToNative.getAmountOut(universalRouter, inputAmount1);
            uint256 totalNative = amount0Native + amount1Native;
            uint256 token1RateCurrent = (amount1Native * precision) / totalNative;
            if (token1RateCurrent > token1Rate) {
                uint256 swapAmount1 = inputAmount1 - (inputAmount1 * token1Rate) / token1RateCurrent;
                amount1 = inputAmount1 - swapAmount1;
                if (swapAmount1 >= swapData.minSwapAmountToken1)
                    oracleData.validatePoolPriceWithSwap(
                        pool,
                        universalRouter,
                        swapAmount1,
                        swapData.swapsToken1ToToken0
                    );
                amount0 =
                    inputAmount0 +
                    swapData.swapsToken1ToToken0.swap(
                        universalRouter,
                        swapAmount1,
                        address(this),
                        swapData.minSwapAmountToken1
                    );
            } else {
                uint256 amount0Rate = (amount0Native * precision) / totalNative;
                uint256 swapAmount0 = inputAmount0 - ((inputAmount0 * (precision - token1Rate)) / amount0Rate);
                amount0 = inputAmount0 - swapAmount0;
                if (swapAmount0 >= swapData.minSwapAmountToken0)
                    oracleData.validatePoolPriceWithSwap(
                        pool,
                        universalRouter,
                        swapAmount0,
                        swapData.swapsToken0ToToken1
                    );
                amount1 =
                    inputAmount1 +
                    swapData.swapsToken0ToToken1.swap(
                        universalRouter,
                        swapAmount0,
                        address(this),
                        swapData.minSwapAmountToken0
                    );
            }
        }
    }
}
