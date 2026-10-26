// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {PriceManagement} from "./PriceManagement.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";

library LiquidityManagement {
    using SafeERC20 for IERC20;

    error DecreaseLiquidityAmountGtLiquidity(uint256 amountIn, uint256 liquidityPosition);

    function addLiquidity(
        INonfungiblePositionManager positionManager,
        PriceManagement.PriceRangesData storage priceRangesData,
        IUniswapV3Pool pool,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 positionId, uint256 liquidity) {
        if (validateIncreaseAmountsByRanges(priceRangesData, pool, amount0, amount1)) {
            IERC20(token0).forceApprove(address(positionManager), amount0);
            IERC20(token1).forceApprove(address(positionManager), amount1);
            (positionId, liquidity, , ) = positionManager.mint(
                INonfungiblePositionManager.MintParams(
                    token0,
                    token1,
                    fee,
                    tickLower,
                    tickUpper,
                    amount0,
                    amount1,
                    0,
                    0,
                    address(this),
                    block.timestamp
                )
            );
        }
    }

    function increaseLiquidity(
        INonfungiblePositionManager positionManager,
        PriceManagement.PriceRangesData storage priceRangesData,
        IUniswapV3Pool pool,
        uint256 positionId,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 liquidity, uint256 amountReal0, uint256 amountReal1) {
        if (validateIncreaseAmountsByRanges(priceRangesData, pool, amount0, amount1)) {
            IERC20(token0).forceApprove(address(positionManager), amount0);
            IERC20(token1).forceApprove(address(positionManager), amount1);
            (liquidity, amountReal0, amountReal1) = positionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(positionId, amount0, amount1, 0, 0, block.timestamp)
            );
        }
    }

    function decreaseLiquidity(
        INonfungiblePositionManager positionManager,
        uint256 positionId,
        address recipient,
        uint256 amountIn,
        bool collectAll
    ) external returns (uint256 amountOutReal0, uint256 amountOutReal1) {
        (, , , , , , , uint256 liquidity_, , , , ) = positionManager.positions(positionId);
        if (amountIn > liquidity_) revert DecreaseLiquidityAmountGtLiquidity(amountIn, liquidity_);
        if (liquidity_ > 0) {
            uint256 amountOut0;
            uint256 amountOut1;
            (amountOut0, amountOut1) = positionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams(
                    positionId,
                    uint128(amountIn),
                    0,
                    0,
                    block.timestamp
                )
            );
            if (collectAll) {
                amountOut0 = type(uint128).max;
                amountOut1 = type(uint128).max;
            }
            (amountOutReal0, amountOutReal1) = positionManager.collect(
                INonfungiblePositionManager.CollectParams(
                    positionId,
                    recipient,
                    uint128(amountOut0),
                    uint128(amountOut1)
                )
            );
        }
    }

    function validateIncreaseAmountsByRanges(
        PriceManagement.PriceRangesData storage priceRangesData,
        IUniswapV3Pool pool,
        uint256 amount0,
        uint256 amount1
    ) public view returns (bool) {
        (uint256 sqrtPriceX96, , , , , , ) = pool.slot0();
        return
            (priceRangesData.sqrtPriceX96Low < sqrtPriceX96 &&
                priceRangesData.sqrtPriceX96UpLimit > sqrtPriceX96 &&
                amount0 > 0 &&
                amount1 > 0) ||
            (sqrtPriceX96 <= priceRangesData.sqrtPriceX96Low && amount0 > 0) ||
            (sqrtPriceX96 >= priceRangesData.sqrtPriceX96Up && amount1 > 0);
    }
}
