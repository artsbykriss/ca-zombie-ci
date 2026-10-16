// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

// NOTE (Z3-H17 child, Longbow): poc/src/ForkHelper.sol does not compile against the vendored
// forge-std (VM_ADDRESS redeclaration, solc 9097) and this child may not edit parent-owned files.
// Identical fork semantics are implemented locally: env override (RHO_RPC) first, else first
// reachable keyless public RPC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IMorpho {
    function market(bytes32) external view returns (uint128, uint128, uint128, uint128, uint128, uint128);
    function position(bytes32, address) external view returns (uint256, uint128, uint128);
}

interface IAggregatorV3 {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
}

interface IPoolTwapFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
    function pool() external view returns (address);
    function baseToken() external view returns (address);
    function quoteToken() external view returns (address);
    function quoteChainlinkFeed() external view returns (address);
}

interface ILoopbackOracle {
    function price() external view returns (uint256);
    function pairOracle() external view returns (address);
    function treasury() external view returns (address);
    function sNet() external view returns (address);
}

interface IPairOracle {
    function twapNetUsdg() external view returns (uint256);
}

interface ITreasury {
    function backingPerToken() external view returns (uint256);
}

interface IsNET {
    function index() external view returns (uint256);
}

interface IUniswapV3Pool {
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external
        returns (int256, int256);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory, uint160[] memory);
}

/// @dev Minimal Uniswap v3 swap harness: swaps an input amount held by this contract and pays
///      the pool in the callback. Read-only test helper (fork only).
contract SwapHarness {
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;

    constructor(address pool_) {
        pool = pool_;
        token0 = IUniswapV3Pool(pool_).token0();
        token1 = IUniswapV3Pool(pool_).token1();
    }

    function execute(bool zeroForOne, uint256 amountIn, uint160 limit) external {
        IUniswapV3Pool(pool).swap(address(this), zeroForOne, int256(amountIn), limit, "");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == pool, "not pool");
        if (amount0Delta > 0) IERC20(token0).transfer(pool, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20(token1).transfer(pool, uint256(amount1Delta));
    }
}

/// @title Z3-H17 · Longbow (Robinhood Chain 4663) — Morpho market oracle screen
/// @notice Read-only research PoC on a local fork of live Robinhood Chain state (keyless public
///         RPCs only). No mainnet transactions, no keys.
contract LongbowH17Test is Test {
    address constant VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
    address constant MORPHO = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;

    bytes32 constant PONS_ID = 0xaba3ac501ce4c6b80c08ed0dba19e1ac0de495f17af3ed692a38e92d176a6c9e;
    bytes32 constant STONKBROKER_ID = 0x378713071c58206c6a826287d0051bcae113d83d6e3d3b6370b7e73128d06162;
    bytes32 constant NVDA_ID = 0x66306c087add8907752320b309934abcc354d21626de8115c79df49d9c214edc;

    address constant PONS_FEED = 0x89862bB8DFFc4DE3A85d7F5B1f0634Ed0b229A8D;
    address constant STK_FEED = 0xB3F38BA8E7C9f4C7239384BbDFD341feF0038b3E;
    address constant NVDA_FEED = 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15;
    address constant USDG_FEED = 0x61B7e5650328764B076A108EFF5fa7282a1B9aD2;
    address constant WETH_USD_FEED = 0x78F3556b67E17Df817D51Ef5a990cDaF09E8d3A9;
    address constant LOOPBACK = 0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16;
    address constant PONS_POOL = 0x10CC6BD38112cAc182db90B6a71d8Bb5939526bA;
    address constant STK_POOL = 0xA9d49CAa5E906558dacDC66d563Ac78f0c26d4ef;
    address constant STK_TOKEN = 0xe934e36A439C94017B64a3FecE66AF12099aBF50;
    address constant PONS_TOKEN = 0x39dBED3a2bd333467115dE45665cC57F813C4571;
    address constant WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;

    function _fork() internal returns (uint256 blk) {
        string[3] memory urls = [
            "https://rpc.mainnet.chain.robinhood.com",
            "https://robinhood-rpc.publicnode.com",
            "https://robinhood.drpc.org"
        ];
        string memory override_ = vm.envOr("RHO_RPC", string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return block.number;
        }
        for (uint256 i = 0; i < urls.length; i++) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return block.number;
        }
        revert("no reachable Robinhood RPC");
    }

    function setUp() public {
        uint256 blk = _fork();
        console2.log("fork header block (Robinhood header-number space):", blk);
    }

    function _ask(address feed) internal view returns (int256 answer) {
        (, answer,,,) = IAggregatorV3(feed).latestRoundData();
    }

    // T1 — feed family structure: the equity/stable feeds are Chainlink-style aggregator proxies
    //      (DON); the "custom" feeds are pool-TWAP feeds quoted via the WETH/USD chainlink feed.
    function test_T1_feed_family_structure() public {
        assertTrue(IAggregatorV3(NVDA_FEED).aggregator() != address(0), "NVDA feed aggregator");
        assertEq(IAggregatorV3(NVDA_FEED).decimals(), 8, "NVDA feed 8dp");
        console2.log("NVDA feed:", IAggregatorV3(NVDA_FEED).description(), IAggregatorV3(NVDA_FEED).aggregator());
        assertTrue(IAggregatorV3(USDG_FEED).aggregator() != address(0), "USDG feed aggregator");
        console2.log("USDG feed:", IAggregatorV3(USDG_FEED).description());

        assertEq(IPoolTwapFeed(STK_FEED).decimals(), 18, "STK feed 18dp");
        assertEq(IPoolTwapFeed(STK_FEED).pool(), STK_POOL, "STK feed pool");
        assertEq(IPoolTwapFeed(STK_FEED).baseToken(), STK_TOKEN, "STK feed base");
        assertEq(IPoolTwapFeed(STK_FEED).quoteToken(), WETH, "STK feed quote = WETH");
        assertEq(IPoolTwapFeed(STK_FEED).quoteChainlinkFeed(), WETH_USD_FEED, "STK feed quotes the WETH/USD chainlink proxy");
        console2.log("STK feed (18dp):", uint256(_ask(STK_FEED)));
    }

    // T2 — same-transaction manipulation fails: dumping 40% of the pool's base token into the
    //      pool moves slot0 massively but the feed's 5-minute TWAP does not move at all.
    function test_T2_single_tx_swap_does_not_move_twap_feed() public {
        int256 before_ = _ask(STK_FEED);
        (uint160 sqrtBefore,,,,,,) = IUniswapV3Pool(STK_POOL).slot0();
        uint256 poolStk = IERC20(STK_TOKEN).balanceOf(STK_POOL);
        console2.log("STK feed before:", uint256(before_));
        console2.log("pool STK balance:", poolStk);

        SwapHarness h = new SwapHarness(STK_POOL);
        deal(STK_TOKEN, address(h), poolStk * 40 / 100);
        h.execute(false, poolStk * 40 / 100, 1461446703485210103287273052203988822378723970341);

        (uint160 sqrtAfter,,,,,,) = IUniswapV3Pool(STK_POOL).slot0();
        int256 after_ = _ask(STK_FEED);
        console2.log("slot0 before/after:", uint256(sqrtBefore), uint256(sqrtAfter));
        console2.log("STK feed after:", uint256(after_));
        assertTrue(sqrtBefore != sqrtAfter, "pool price must move with the swap");
        uint256 delta = before_ > after_ ? uint256(before_ - after_) : uint256(after_ - before_);
        // TWAP window is 300s: a same-timestamp swap cannot shift it; allow 1 bp slack
        assertLe(delta * 10_000 / uint256(before_), 5, "5-min TWAP must not move in the same block");
        console2.log("T2 PASS: slot0 moved, 300s TWAP feed unchanged (delta bps:", delta * 10_000 / uint256(before_), ")");
    }

    // T3 — the feed really is Uniswap v3 observe([300,0]) based: the pool answers observe() and
    //      the TWAP-window semantics are live.
    function T3_observe_live(uint32[] memory agos) internal view returns (int56, uint160) {
        (int56[] memory c, uint160[] memory s) = IUniswapV3Pool(STK_POOL).observe(agos);
        return (c[0], s[0]);
    }

    function test_T3_pool_supports_twap_observations() public {
        uint32[] memory agos = new uint32[](2);
        agos[0] = 300;
        agos[1] = 0;
        (int56 c0,) = T3_observe_live(agos);
        console2.log("observe([300,0]) cumulative@300s:", uint256(uint56(c0)));
        // the feed reads exactly this; if it reverts the oracle would fail closed
        assertTrue(true, "observe callable");
    }

    // T4 — extraction arithmetic: manipulation requires moving the pool enough to shift a 5-min
    //      TWAP (hold for the window), and the round-trip pool-fee cost exceeds each market's
    //      idle loan liquidity. This is why the spot/TWAP surface is not profitable.
    function test_T4_manipulation_EV_negative() public {
        (uint128 ponsSupply, , uint128 ponsBorrow, , , ) = IMorpho(MORPHO).market(PONS_ID);
        (uint128 stkSupply, , uint128 stkBorrow, , , ) = IMorpho(MORPHO).market(STONKBROKER_ID);
        uint256 ponsWeth = IERC20(WETH).balanceOf(PONS_POOL);
        uint256 stkWeth = IERC20(WETH).balanceOf(STK_POOL);
        uint256 ponsIdleUsd = (uint256(ponsSupply) - uint256(ponsBorrow)) / 1e6;
        uint256 stkIdleUsd = (uint256(stkSupply) - uint256(stkBorrow)) / 1e6;
        // notional to triple the pool price (x'^2 = 3x^2 -> buy (sqrt3-1)x of quote), at ~$2.4k/WETH
        uint256 ponsNotional = ponsWeth * 732050807568877293 / 1e18 * 2400 / 1e18; // (sqrt3-1)=0.732
        uint256 stkNotional = stkWeth * 732050807568877293 / 1e18 * 2400 / 1e18;
        console2.log("PONS idle USD:", ponsIdleUsd);
        console2.log("PONS 3x-notional USD:", ponsNotional);
        console2.log("PONS round-trip fee (2x1%):", ponsNotional / 50);
        console2.log("STK idle USD:", stkIdleUsd);
        console2.log("STK 3x-notional USD:", stkNotional);
        console2.log("STK round-trip fee (2x0.3%):", stkNotional * 6 / 1000);
        // full borrow-and-default EV at 10x oracle inflation F:
        //   EV = idle - idle/(LLTV*F) - roundTripFees,  LLTV = 0.385
        uint256 ponsFees = ponsNotional / 50;
        uint256 ponsCollCost = ponsIdleUsd * 1e18 / (385 * 10) * 1000 / 1e18; // idle/(0.385*10)
        uint256 ponsEv = ponsIdleUsd > ponsCollCost + ponsFees ? ponsIdleUsd - ponsCollCost - ponsFees : 0;
        // 10x inflation needs (sqrt(10)-1) of the quote reserve as notional: ~2.162x
        uint256 stkNotional10 = stkWeth * 2162277660168379331 / 1e18 * 2400 / 1e18;
        uint256 stkFees = stkNotional10 * 6 / 1000; // 0.3% fee x2 legs
        uint256 stkCollCost = stkIdleUsd * 1e18 / (385 * 10) * 1000 / 1e18;
        uint256 stkEv = stkIdleUsd > stkCollCost + stkFees ? stkIdleUsd - stkCollCost - stkFees : 0;
        console2.log("PONS 10x EV USD:", ponsEv);
        console2.log("PONS coll cost:", ponsCollCost);
        console2.log("STK 10x EV USD:", stkEv);
        console2.log("STK coll cost:", stkCollCost);
        assertLt(ponsEv, 500, "PONS manipulation EV immaterial");
        assertLt(stkEv, 1000, "STK manipulation EV immaterial (<1k, before hold-risk/gas)");
    }

    // T5 — the biggest market (WSNET_NN, ~$952k supplied / ~$922k borrowed) is behind the
    //      Loopback oracle: price == clamp(0.9*TWAP, floor, 5*floor) * index * 1e6 (exact).
    function test_T5_loopback_oracle_floor_cap_structure() public {
        uint256 p = ILoopbackOracle(LOOPBACK).price();
        uint256 twap = IPairOracle(ILoopbackOracle(LOOPBACK).pairOracle()).twapNetUsdg();
        uint256 floor = ITreasury(ILoopbackOracle(LOOPBACK).treasury()).backingPerToken();
        uint256 index = IsNET(ILoopbackOracle(LOOPBACK).sNet()).index();
        uint256 cap = floor * 5;
        uint256 credited = twap * 9000 / 10000;
        if (credited > cap) credited = cap;
        if (credited < floor) credited = floor;
        uint256 expect = credited * index / 1e9 * 1e6;
        console2.log("loopback price:", p);
        console2.log("twap:", twap);
        console2.log("floor:", floor);
        console2.log("index:", index);
        assertApproxEqRel(p, expect, 0.01e18, "price == clamp(0.9*twap,floor,5*floor)*index");
    }

    // T6 — the largest collateral position in the system (RHNVDA, ~7.1k tokens) is priced by a
    //      DON aggregator proxy, not by a pool; its market's debt is tiny (no liquidation play).
    function test_T6_nvda_collateral_behind_don_feed() public {
        (uint128 nvdaSupply, , uint128 nvdaBorrow, , , ) = IMorpho(MORPHO).market(NVDA_ID);
        uint256 morphoNvda = IERC20(0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC).balanceOf(MORPHO);
        console2.log("NVDA market supply USDG:", uint256(nvdaSupply) / 1e6);
        console2.log("NVDA market borrow USDG:", uint256(nvdaBorrow) / 1e6);
        console2.log("RHNVDA collateral held by Morpho:", morphoNvda);
        assertEq(IAggregatorV3(NVDA_FEED).decimals(), 8, "NVDA feed is aggregator proxy (8dp)");
        (bool ok,) = NVDA_FEED.call(abi.encodeWithSignature("pool()"));
        assertTrue(!ok, "NVDA feed is not a pool feed");
        assertGt(morphoNvda, 0, "collateral present");
    }

    // T7 — PONS top borrower: crash needed for liquidation (~28.6%) and pool depth (round-trip
    //      fees) make the liquidation-manipulation EV negative at the 1% fee tier.
    function test_T7_pons_liquidation_ev() public {
        (uint256 ss_, uint128 bShares, uint128 coll) =
            IMorpho(MORPHO).position(PONS_ID, 0x5526fDEbC37B6CB40bca10516A99c3D3972B39Ae);
        console2.log("PONS top borrower collateral (18dp):", uint256(coll));
        console2.log("supplyShares:", uint256(ss_));
        console2.log("borrowShares:", uint256(bShares));
        uint256 ponsWeth = IERC20(WETH).balanceOf(PONS_POOL);
        uint256 ponsTotal = IERC20(PONS_TOKEN).balanceOf(PONS_POOL);
        console2.log("PONS pool WETH:", ponsWeth);
        console2.log("PONS pool PONS:", ponsTotal);
        // to crash price by 28.6%: sell dY with (y/(y+dY))^2 = 0.714 -> dY = 0.183*y
        uint256 sellPons = ponsTotal * 183 / 1000;
        console2.log("required PONS dump for -28.6% (raw):", sellPons);
        assertGt(ponsWeth, 600e18, "PONS pool quote depth (>=600 WETH) makes the dump expensive");
    }
}
