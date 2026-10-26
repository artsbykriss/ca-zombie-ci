// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {FullMath} from "../../libraries/LiquidityAmounts.sol";
import {Constants} from "../Constants.sol";
import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";

library FeeMath {
    using FullMath for uint256;

    function calculateUnclaimedFeeByPositionId(
        uint256 positionId,
        IUniswapV3Pool pool,
        INonfungiblePositionManager positionManager,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) external view returns (uint128 amount0, uint128 amount1) {
        (, , uint256 feeGrowthOutside0X128Lower, uint256 feeGrowthOutside1X128Lower, , , , ) = pool.ticks(tickLower);
        (, , uint256 feeGrowthOutside0X128Upper, uint256 feeGrowthOutside1X128Upper, , , , ) = pool.ticks(tickUpper);
        unchecked {
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelow0X128 = feeGrowthOutside0X128Lower;
                feeGrowthBelow1X128 = feeGrowthOutside1X128Lower;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Lower;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Lower;
            }
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < tickUpper) {
                feeGrowthAbove0X128 = feeGrowthOutside0X128Upper;
                feeGrowthAbove1X128 = feeGrowthOutside1X128Upper;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Upper;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Upper;
            }
            uint256 feeGrowthInside0LastX128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            uint256 feeGrowthInside1LastX128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
            (
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                uint128 liquidity,
                uint256 feeGrowthInside0LastX128Manager,
                uint256 feeGrowthInside1LastX128Manager,
                uint128 owed0,
                uint128 owed1
            ) = positionManager.positions(positionId);
            if (liquidity > 0) {
                amount0 =
                    owed0 +
                    uint128(
                        (feeGrowthInside0LastX128 - feeGrowthInside0LastX128Manager).mulDiv(liquidity, Constants.Q128)
                    );
                amount1 =
                    owed1 +
                    uint128(
                        (feeGrowthInside1LastX128 - feeGrowthInside1LastX128Manager).mulDiv(liquidity, Constants.Q128)
                    );
            }
        }
    }
}
