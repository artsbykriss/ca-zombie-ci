// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Swap} from "../../libraries/custom/Swap.sol";
import {Constants} from "../Constants.sol";
import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PriceManagement} from "./PriceManagement.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {INativeV3PriceOracleValidator} from "../../../../utils/nativeV3Utils/interfaces/INativeV3PriceOracleValidator.sol";

library Oracle {
    struct OracleData {
        INativeV3PriceOracleValidator oracle;
        uint256 acceptableDeviationPool;
        uint256 acceptableDeviationSwap;
        uint256 lastValidatePriceTimestamp;
    }

    error DeviationRateLimitLtLiveDeviation(uint256 deviationLimit, uint256 liveDeviation);
    error SwapPriceIsInvalid(uint256 connectorPrice, uint256 swapPrice);
    error DeviationGtPrecision(uint256 deviation);
    error InvalidPath(Swap.SwapPair[] path);
    error DeviationSwapGtPrecision(uint256 deviationSwap);

    function validatePoolPrice(OracleData storage self, IUniswapV3Pool pool) public {
        if (self.lastValidatePriceTimestamp < block.timestamp) {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1) = self.oracle.validatePrice(
                sqrtPriceX96,
                self.acceptableDeviationPool,
                address(pool)
            );
            if (!valid) revert DeviationRateLimitLtLiveDeviation(livePriceToken0ToToken1, meanPriceToken0ToToken1);
            self.lastValidatePriceTimestamp = block.timestamp;
        }
    }

    function validatePoolPriceWithSwap(
        OracleData storage self,
        IUniswapV3Pool pool,
        IDexFiUniversalRouterBytes router,
        uint256 swapAmount,
        Swap.SwapPair[] memory path
    ) external {
        validatePoolPrice(self, pool);
        if (swapAmount > 0) {
            address token0 = pool.token0();
            address token1 = pool.token1();
            address pathTokenIn = path[0].tokenIn;
            address pathTokenOut = path[path.length - 1].tokenOut;
            if (
                (pathTokenIn != token0 && pathTokenIn != token1) ||
                (pathTokenIn == token0 && pathTokenOut != token1) ||
                (pathTokenIn == token1 && pathTokenOut != token0)
            ) revert InvalidPath(path);
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint256 oneToken;
            uint256 connectorPoolPrice;
            if (pathTokenIn == token0) {
                oneToken = 10 ** IERC20Metadata(token0).decimals();
                connectorPoolPrice = PriceManagement.calculateRatioToken0ToToken1(oneToken, sqrtPriceX96);
            } else {
                oneToken = 10 ** IERC20Metadata(token1).decimals();
                connectorPoolPrice = PriceManagement.calculateRatioToken1ToToken0(oneToken, sqrtPriceX96);
            }
            uint256 amountOut = Swap.getAmountOut(path, router, swapAmount);
            uint256 amountOutByRatePool = (amountOut * oneToken) / swapAmount;
            uint256 differenceLiveToMean = connectorPoolPrice > amountOutByRatePool
                ? connectorPoolPrice - amountOutByRatePool
                : amountOutByRatePool - connectorPoolPrice;
            if (differenceLiveToMean > (connectorPoolPrice * self.acceptableDeviationSwap) / Constants.PRECISION)
                revert SwapPriceIsInvalid(connectorPoolPrice, amountOutByRatePool);
        }
    }

    function validateDeviations(uint256 deviation, uint256 deviationSwap) external pure {
        if (deviation > Constants.PRECISION) revert DeviationGtPrecision(deviation);
        if (deviationSwap > Constants.PRECISION) revert DeviationSwapGtPrecision(deviationSwap);
    }
}
