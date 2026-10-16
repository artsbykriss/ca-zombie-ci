// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Exact on-chain replication of GPXHooks.checkRebalance() math (Base, deployed 0x4519e2b0...EaA8).
// Uses the same v4-core libraries as the verified hook source bundle (TickMath/FullMath/LiquidityAmounts).

import {TickMath} from "v4-core-min/libraries/TickMath.sol";
import {FullMath} from "v4-core-min/libraries/FullMath.sol";
import {LiquidityAmounts} from "v4-core-min/libraries/LiquidityAmounts.sol";

interface IExtsload {
    function extsload(bytes32 slot) external view returns (bytes32);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

interface IHookState {
    function gpxReserves() external view returns (uint256);
    function positionId() external view returns (uint256);
    function lowerTick() external view returns (int24);
    function lastRebalance() external view returns (uint256);
}

interface IPOSMInfo {
    function positionInfo(uint256 tokenId) external view returns (uint256);
}

struct PoolKey5 {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

contract GPXSim {
    address public constant PM = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address public constant POSM = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    address public constant HOOK = 0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8;
    address public constant GPX = 0x454F8c3f1FC79a98363DB6104A20AC59A02A3133;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant TREASURY = 0xa76b99311bc399d5fA7AeEd3bed0644eEd652866;

    int24 public constant MAX_TICK = 887272;
    int24 public constant MIN_SPREAD = 9624;
    uint256 public constant Q96 = 1 << 96;

    function poolIdOf(PoolKey5 memory key) public pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }

    function poolState(bytes32 poolId) public view returns (uint160 sqrtPriceX96, int24 tick, uint128 liquidity) {
        bytes32 base = keccak256(abi.encode(poolId, uint256(6)));
        bytes32 s0 = IExtsload(PM).extsload(base);
        sqrtPriceX96 = uint160(uint256(s0));
        tick = int24(uint24(uint256(s0) >> 160));
        liquidity = uint128(uint256(IExtsload(PM).extsload(bytes32(uint256(base) + 3))));
    }

    /// @dev Mirrors GPXHooks.checkRebalance(gpxPoolKey) exactly, reading live state.
    function simulate()
        external
        view
        returns (
            bool rebalance,
            int24 simulatedTick,
            uint256 gpxInsideUniswap,
            uint256 usdcInsideUniswap,
            uint256 gpxCirculatingSupply,
            int24 currentTick,
            int24 currentLowerTick
        )
    {
        PoolKey5 memory key = PoolKey5({currency0: GPX, currency1: USDC, fee: 0, tickSpacing: 1, hooks: HOOK});
        bytes32 id = poolIdOf(key);
        (uint160 sqrtPriceX96, int24 tick_, uint128 liquidity) = poolState(id);
        currentTick = tick_;

        // getCurrentState()
        uint256 totalGPXSupply = IERC20Min(GPX).totalSupply();
        uint256 currentGPXReserves = IHookState(HOOK).gpxReserves();
        uint256 gpxInsideTreasury = IERC20Min(GPX).balanceOf(TREASURY);

        uint256 positionId_ = IHookState(HOOK).positionId();
        uint256 pi = IPOSMInfo(POSM).positionInfo(positionId_);
        currentLowerTick = int24(uint24(pi >> 8)); // PositionInfoLibrary.tickLower
        int24 pTickUpper = int24(uint24(pi >> 32));

        uint160 spLo = TickMath.getSqrtPriceAtTick(currentLowerTick);
        uint160 spHi = TickMath.getSqrtPriceAtTick(pTickUpper);
        gpxInsideUniswap = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceX96, spHi, liquidity);
        usdcInsideUniswap = LiquidityAmounts.getAmount1ForLiquidity(spLo, sqrtPriceX96, liquidity);
        gpxCirculatingSupply = totalGPXSupply - currentGPXReserves - gpxInsideUniswap - gpxInsideTreasury;

        if (gpxCirculatingSupply == 0 || usdcInsideUniswap == 0) {
            return (false, 0, gpxInsideUniswap, usdcInsideUniswap, gpxCirculatingSupply, currentTick, currentLowerTick);
        }

        uint256 aX96 = FullMath.mulDiv(usdcInsideUniswap << 192, 1, gpxCirculatingSupply * sqrtPriceX96);
        if (aX96 < 4295128739) {
            simulatedTick = type(int24).min;
        } else {
            simulatedTick = TickMath.getTickAtSqrtPrice(uint160(aX96));
        }

        if (simulatedTick <= currentLowerTick || simulatedTick >= currentTick) {
            return (false, simulatedTick, gpxInsideUniswap, usdcInsideUniswap, gpxCirculatingSupply, currentTick, currentLowerTick);
        }

        int24 proposedLowerTick = currentLowerTick + 1;
        if (proposedLowerTick + MIN_SPREAD > currentTick) {
            return (false, simulatedTick, gpxInsideUniswap, usdcInsideUniswap, gpxCirculatingSupply, currentTick, currentLowerTick);
        }

        // enoughGPX()
        uint160 sqrtPriceAX96 = TickMath.getSqrtPriceAtTick(proposedLowerTick);
        uint128 newLiquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtPriceAX96, sqrtPriceX96, usdcInsideUniswap);
        uint256 gpxNeeded = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceX96, spHi, newLiquidity);
        bool enough = gpxNeeded <= currentGPXReserves + gpxInsideUniswap;

        return (enough, simulatedTick, gpxInsideUniswap, usdcInsideUniswap, gpxCirculatingSupply, currentTick, currentLowerTick);
    }

    /// @dev Exact re-arm threshold (price-independent): trigger <=> treasuryGPX > N' - x_pool - (L*Q96/spLo - L*Q96/sp)
    ///      where N' = circulating + x_pool + treasury (all non-reserve GPX).
    function rearmThreshold()
        external
        view
        returns (uint256 thresholdTreasury, uint256 nonReserveGPX, uint256 treasuryToday)
    {
        PoolKey5 memory key = PoolKey5({currency0: GPX, currency1: USDC, fee: 0, tickSpacing: 1, hooks: HOOK});
        (uint160 sqrtPriceX96,, uint128 liquidity) = poolState(poolIdOf(key));

        uint256 positionId_ = IHookState(HOOK).positionId();
        int24 currentLowerTick = int24(uint24(IPOSMInfo(POSM).positionInfo(positionId_) >> 8));
        uint160 spLo = TickMath.getSqrtPriceAtTick(currentLowerTick);
        uint160 spHi = TickMath.getSqrtPriceAtTick(MAX_TICK);

        uint256 gpxIn = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceX96, spHi, liquidity);
        uint256 treasuryBal = IERC20Min(GPX).balanceOf(TREASURY);
        uint256 circ = IERC20Min(GPX).totalSupply() - IHookState(HOOK).gpxReserves() - gpxIn - treasuryBal;
        nonReserveGPX = circ + gpxIn + treasuryBal;

        uint256 lOverLo = FullMath.mulDiv(uint256(liquidity), Q96, spLo);
        uint256 lOverSp = FullMath.mulDiv(uint256(liquidity), Q96, sqrtPriceX96);
        thresholdTreasury = nonReserveGPX - gpxIn - lOverLo + lOverSp;
        treasuryToday = treasuryBal;
    }
}
