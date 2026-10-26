// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Swap} from "./Swap.sol";
import {FeeMath} from "./FeeMath.sol";
import {TickMath} from "../../libraries/TickMath.sol";
import {Constants} from "../Constants.sol";
import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../../interfaces/IUniswapV3Factory.sol";
import {IDexFiVaultFactory} from "../../../../../core/interfaces/IDexFiVaultFactory.sol";
import {LiquidityManagement} from "./LiquidityManagement.sol";
import {LiquidityAmounts, FullMath} from "../../libraries/LiquidityAmounts.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";

library PriceManagement {
    using FullMath for uint256;
    using LiquidityAmounts for uint160;
    using FeeMath for uint256;
    using Swap for Swap.SwapPair[];

    struct PriceRangesData {
        int24 tickLower;
        int24 tickUpper;
        uint256 sqrtPriceX96Low;
        uint256 sqrtPriceX96Up;
        uint256 sqrtPriceX96LowLimit;
        uint256 sqrtPriceX96UpLimit;
        uint256 approxToRangeLimitLowPercent;
        uint256 approxToRangeLimitUpPercent;
        uint256 deviationPercentLow;
        uint256 deviationPercentUp;
        uint256 defaultDeviationPercentLow;
        uint256 defaultDeviationPercentUp;
    }

    error ApproxToRangeLimitLowPercentPercentZero();
    error ApproxToRangeLimitUpPercentPercentZero();
    error DeviationPercentLowZero();
    error DeviationPercentUpZero();
    error LowPercentGtPrecision(uint256 percent);
    error TokensPositionInvalid(address token0, address token1);
    error TickIsInvalid(int24 low, int24 up, int24 current);
    error SqrtPriceX96IsInvalid(uint256 low, uint256 up, uint256 current);

    function updatePriceRanges(PriceRangesData storage self, IUniswapV3Pool pool) external {
        uint256 precision = Constants.PRECISION;
        uint256 lowShift = self.defaultDeviationPercentLow;
        uint256 upShift = self.defaultDeviationPercentUp;
        if (self.deviationPercentLow > 0 && self.deviationPercentUp > 0) {
            lowShift = self.deviationPercentLow;
            upShift = self.deviationPercentUp;
        }
        (uint256 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();
        uint256 amountToken1PerToken0 = calculateRatioToken0ToToken1(precision, uint256(sqrtPriceX96));
        uint256 rateShiftLow = (amountToken1PerToken0 * lowShift) / precision;
        uint256 rateShiftUp = (amountToken1PerToken0 * upShift) / precision;
        self.sqrtPriceX96Low = calculateSqrtPriceX96FromPrice(amountToken1PerToken0 - rateShiftLow);
        if (self.sqrtPriceX96Low < TickMath.MIN_SQRT_RATIO) self.sqrtPriceX96Low = TickMath.MIN_SQRT_RATIO;
        self.sqrtPriceX96Up = calculateSqrtPriceX96FromPrice(amountToken1PerToken0 + rateShiftUp);
        if (self.sqrtPriceX96Up >= TickMath.MAX_SQRT_RATIO) self.sqrtPriceX96Up = TickMath.MAX_SQRT_RATIO - 1;
        self.tickLower = (TickMath.getTickAtSqrtRatio(uint160(self.sqrtPriceX96Low)) / tickSpacing) * tickSpacing;
        self.tickUpper = (TickMath.getTickAtSqrtRatio(uint160(self.sqrtPriceX96Up)) / tickSpacing) * tickSpacing;
        if (self.tickLower > currentTick) self.tickLower -= tickSpacing;
        if (self.tickUpper < currentTick) self.tickUpper += tickSpacing;
        self.sqrtPriceX96Low = TickMath.getSqrtRatioAtTick(self.tickLower);
        self.sqrtPriceX96Up = TickMath.getSqrtRatioAtTick(self.tickUpper);
        self.sqrtPriceX96LowLimit = calculateSqrtPriceX96FromPrice(
            amountToken1PerToken0 - rateShiftLow + (rateShiftLow * self.approxToRangeLimitLowPercent) / precision
        );
        self.sqrtPriceX96UpLimit = calculateSqrtPriceX96FromPrice(
            amountToken1PerToken0 + rateShiftUp - (rateShiftUp * self.approxToRangeLimitUpPercent) / precision
        );
    }

    function calculateRatioToken1ToToken0(uint256 amount, uint256 sqrtPriceX96) external pure returns (uint256) {
        return amount.mulDiv(1 << 192, uint256(sqrtPriceX96) ** 2);
    }

    function calculateRateTokensPerLiquidity(
        uint160 sqrtPriceX96,
        uint256 sqrtPriceX96Low,
        uint256 sqrtPriceX96Up,
        uint256 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(sqrtPriceX96Low),
            uint160(sqrtPriceX96Up),
            uint128(liquidity)
        );
    }

    function calculateNewLiquidityFromOldPosition(
        IDexFiUniversalRouterBytes universalRouter,
        INonfungiblePositionManager positionManager,
        uint256 fromTokenId,
        uint256 toTokenId,
        Swap.SwapPair[] memory swapsToken0ToNative,
        Swap.SwapPair[] memory swapsToken1ToNative
    ) external returns (uint256 liquidity) {
        (
            ,
            ,
            address fromToken0,
            address fromToken1,
            uint24 fromFee,
            int24 fromTickLower,
            int24 fromTickUpper,
            uint256 fromLiquidity,
            ,
            ,
            ,

        ) = positionManager.positions(fromTokenId);
        (
            ,
            ,
            address toToken0,
            address toToken1,
            uint24 toFee,
            int24 toTickLower,
            int24 toTickUpper,
            ,
            ,
            ,
            ,

        ) = positionManager.positions(toTokenId);
        IUniswapV3Pool fromPool = IUniswapV3Pool(
            IUniswapV3Factory(positionManager.factory()).getPool(fromToken0, fromToken1, fromFee)
        );
        IUniswapV3Pool toPool = IUniswapV3Pool(
            IUniswapV3Factory(positionManager.factory()).getPool(toToken0, toToken1, toFee)
        );
        if (fromToken0 != toToken0 || fromToken1 != toToken1) revert TokensPositionInvalid(fromToken0, fromToken1);
        uint256 precision_ = Constants.PRECISION;
        uint160 toSqrtPriceX96Low = uint160(TickMath.getSqrtRatioAtTick(toTickLower));
        uint160 toSqrtPriceX96Up = uint160(TickMath.getSqrtRatioAtTick(toTickUpper));
        (uint160 toSqrtPriceX96, , , , , , ) = toPool.slot0();
        (uint256 amount0, uint256 amount1) = toSqrtPriceX96.getAmountsForLiquidity(
            toSqrtPriceX96Low,
            toSqrtPriceX96Up,
            uint128(precision_)
        );
        uint256 token1Rate = (amount1 * precision_) /
            (calculateRatioToken0ToToken1(amount0, uint256(toSqrtPriceX96)) + amount1);
        (uint160 fromSqrtPriceX96, int24 fromCurrentTick, , , , , ) = fromPool.slot0();
        (amount0, amount1) = fromSqrtPriceX96.getAmountsForLiquidity(
            uint160(TickMath.getSqrtRatioAtTick(fromTickLower)),
            uint160(TickMath.getSqrtRatioAtTick(fromTickUpper)),
            uint128(fromLiquidity)
        );
        (uint256 amount0Fee, uint256 amount1Fee) = fromTokenId.calculateUnclaimedFeeByPositionId(
            fromPool,
            positionManager,
            fromTickLower,
            fromTickUpper,
            fromCurrentTick,
            fromPool.feeGrowthGlobal0X128(),
            fromPool.feeGrowthGlobal1X128()
        );
        amount0 += amount0Fee;
        amount1 += amount1Fee;
        uint256 nativeAmount = swapsToken0ToNative.getAmountOut(universalRouter, amount0) +
            swapsToken1ToNative.getAmountOut(universalRouter, amount1);
        uint256 amount1Rate = (nativeAmount * token1Rate) / precision_;
        amount1 = swapsToken1ToNative.reverseSwapPath().getAmountOut(universalRouter, amount1Rate);
        amount0 = swapsToken0ToNative.reverseSwapPath().getAmountOut(universalRouter, nativeAmount - amount1Rate);
        liquidity = toSqrtPriceX96.getLiquidityForAmounts(toSqrtPriceX96Low, toSqrtPriceX96Up, amount0, amount1);
    }

    function validateTick(int24 low, int24 up, int24 current) external pure {
        if (low > current || up < current) revert TickIsInvalid(low, up, current);
    }

    function validateSqrtPriceX96(uint256 low, uint256 up, uint256 current) external pure {
        if (low > current || up < current) revert SqrtPriceX96IsInvalid(low, up, current);
    }

    function validateDeviationPercent(uint256 lowPercent, uint256 upPercent) external pure {
        if (lowPercent == 0) revert DeviationPercentLowZero();
        if (lowPercent > Constants.PRECISION) revert LowPercentGtPrecision(lowPercent);
        if (upPercent == 0) revert DeviationPercentUpZero();
    }

    function validateApproxToRangeLimitPercent(uint256 lowPercent, uint256 upPercent) external pure {
        if (lowPercent > Constants.PRECISION) revert ApproxToRangeLimitLowPercentPercentZero();
        if (upPercent > Constants.PRECISION) revert ApproxToRangeLimitUpPercentPercentZero();
    }

    function calculateSqrtPriceX96FromPrice(uint256 price) public pure returns (uint256) {
        return price.mulDiv(1 << 192, Constants.PRECISION).sqrt();
    }

    function calculateRatioToken0ToToken1(uint256 amount, uint256 sqrtPriceX96) public pure returns (uint256) {
        return amount.mulDiv(uint256(sqrtPriceX96) ** 2, 1 << 192);
    }
}
