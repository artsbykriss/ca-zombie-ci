// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IMasterChefV1, IMiniChefV2, IStrategy, IVotingEscrow, IUniV2Pair} from "../src/Interfaces.sol";

/// Liquid Driver (Fantom) — live extraction tests, fork of Fantom mainnet.
/// READ-ONLY: no transactions are broadcast; all calls are eth_call/static in the fork.
contract LiquidDriverTest is Test {
    // --- Fantom mainnet addresses (verified in analysis/live-state.json) ---
    address constant LQDR = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    address constant XLQDR = 0x3Ae658656d1C526144db371FaEf2Fff7170654eE;
    address constant MASTERCHEF = 0x742474dAE70Fa2AB063aB786b1fBe5704e861a0c;
    address constant MINICHEF = 0x6e2ad6527901c9664f016466b8DA1357a004db0f;
    address constant SHADOW_LQDR_FTM = 0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a;
    address constant SHADOW_LQDR_FTM_2 = 0x59ab3c33e75C91B2B632d51144e57293EF64E556;
    address constant LP_LQDR_FTM = 0x506DdcC751C7d500F983FfdA6DdEfbE458Ba2c33; // spooky pair
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address constant ATTACKER = 0x00000000000000000000000000000000DeaDBeef;

    uint256 forkBlock;

    function _rpc(string memory name, string memory fb) internal view returns (string memory) {
        string memory v = vm.envOr(name, string(""));
        if (bytes(v).length == 0) return fb;
        return v;
    }

    /// safe balanceOf: returns 0 for addresses without code (e.g. pool 26 lpToken = 0x…01)
    function _balOf(address token, address who) internal view returns (uint256) {
        if (token.code.length == 0) return 0;
        (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        if (!ok || ret.length < 32) return 0;
        return abi.decode(ret, (uint256));
    }

    function setUp() public {
        string memory rpc = _rpc("FANTOM_RPC_URL", "https://fantom.drpc.org");
        forkBlock = vm.createSelectFork(rpc);
        console.log("fork block:", forkBlock);
    }

    // ------------------------------------------------------------------
    // 1. MasterChef live state
    // ------------------------------------------------------------------
    function test_masterchef_state() public {
        IMasterChefV1 mc = IMasterChefV1(MASTERCHEF);
        uint256 pl = mc.poolLength();
        console.log("MasterChef poolLength:", pl);
        assertGt(pl, 0, "masterchef should have pools");
        assertEq(mc.lqdrPerBlock(), 0, "emissions stopped (lqdrPerBlock=0)");
        assertEq(mc.lqdr(), LQDR, "reward token is LQDR");
        console.log("lqdrPerBlock:", mc.lqdrPerBlock());
        console.log("LQDR held by MasterChef:", IERC20(LQDR).balanceOf(MASTERCHEF));

        uint256 totalLPStaked;
        for (uint256 i = 0; i < pl; i++) {
            (address lp, uint256 alloc,,, uint16 fee) = mc.poolInfo(i);
            uint256 bal = IERC20(lp).balanceOf(MASTERCHEF);
            if (bal > 0) {
                console.log("pool", i, "chefBal", bal);
                console.log("   lp:", lp);
                console.log("   alloc:", alloc, "depositFeeBP:", uint256(fee));
            }
            totalLPStaked += bal;
        }
        console.log("sum LP units held by MasterChef (all pools):", totalLPStaked);
    }

    // ------------------------------------------------------------------
    // 2. Attacker cannot withdraw other users' LP from MasterChef
    // ------------------------------------------------------------------
    function test_masterchef_foreign_withdraw_reverts() public {
        IMasterChefV1 mc = IMasterChefV1(MASTERCHEF);
        uint256 pl = mc.poolLength();
        for (uint256 pid = 0; pid < pl; pid++) {
            (uint256 amt,) = mc.userInfo(pid, ATTACKER);
            assertEq(amt, 0, "attacker must have no stake");
            (address lp,, uint256 lastReward, uint256 acc, ) = mc.poolInfo(pid);
            // attempt withdraw of 1 wei of LP as attacker
            vm.prank(ATTACKER);
            (bool ok, bytes memory ret) = MASTERCHEF.call(
                abi.encodeWithSignature("withdraw(uint256,uint256)", pid, uint256(1)));
            assertFalse(ok, "withdraw(1) with zero stake must revert");
            // emergencyWithdraw is allowed but must transfer nothing
            uint256 balBefore = _balOf(lp, ATTACKER);
            vm.prank(ATTACKER);
            (bool ok2,) = MASTERCHEF.call(abi.encodeWithSignature("emergencyWithdraw(uint256)", pid));
            assertTrue(ok2, "emergencyWithdraw with zero stake is a no-op");
            assertEq(_balOf(lp, ATTACKER), balBefore, "attacker gained no LP");
            // pending rewards must be zero
            assertEq(mc.pendingLqdr(pid, ATTACKER), 0, "attacker pending = 0");
        }
    }

    // ------------------------------------------------------------------
    // 3. MiniChef: foreign withdraw reverts; harvest pays nothing
    // ------------------------------------------------------------------
    function test_minichef_foreign_withdraw_reverts() public {
        IMiniChefV2 mini = IMiniChefV2(MINICHEF);
        uint256 pl = mini.poolLength();
        assertGt(pl, 0);
        console.log("MiniChef poolLength:", pl);
        for (uint256 pid = 0; pid < pl; pid++) {
            address lp = mini.lpToken(pid);
            address st = mini.strategies(pid);
            (uint256 amt,) = mini.userInfo(pid, ATTACKER);
            assertEq(amt, 0);
            uint256 lpBefore = _balOf(lp, ATTACKER);
            uint256 lqdrBefore = IERC20(LQDR).balanceOf(ATTACKER);
            // withdraw(pid, 1, attacker) must revert
            vm.prank(ATTACKER);
            (bool ok,) = MINICHEF.call(
                abi.encodeWithSignature("withdraw(uint256,uint256,address)", pid, uint256(1), ATTACKER));
            assertFalse(ok, "foreign withdraw must revert");
            // harvest pays the caller only their own pending (zero)
            vm.prank(ATTACKER);
            (bool okH,) = MINICHEF.call(abi.encodeWithSignature("harvest(uint256,address)", pid, ATTACKER));
            // harvest may revert on pools whose rewarder reverts; the security property is no gain
            assertEq(IERC20(LQDR).balanceOf(ATTACKER), lqdrBefore, "harvest paid attacker 0");
            assertEq(_balOf(lp, ATTACKER), lpBefore, "no LP gained");
        }
    }

    // ------------------------------------------------------------------
    // 4. Strategies: gated by depositor; deposit() permissionless but harmless
    // ------------------------------------------------------------------
    function test_strategy_gated() public {
        IMiniChefV2 mini = IMiniChefV2(MINICHEF);
        uint256 pl = mini.poolLength();
        for (uint256 pid = 0; pid < pl; pid++) {
            address st = mini.strategies(pid);
            if (st == address(0)) continue;
            IStrategy s = IStrategy(st);
            address want = s.want();
            // only test strategies that follow the Pickle strategy interface (have depositor())
            (bool okDep,) = st.staticcall(abi.encodeWithSignature("depositor()"));
            if (!okDep) continue;
            uint256 balBefore = IERC20(want).balanceOf(st);
            uint256 atkBefore = IERC20(want).balanceOf(ATTACKER);
            // withdraw(0) from attacker must revert (!depositor)
            vm.prank(ATTACKER);
            (bool ok,) = st.call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
            assertFalse(ok, "strategy.withdraw must be depositor-gated");
            // harvest from attacker must revert (harvester whitelist)
            vm.prank(ATTACKER);
            (bool okH,) = st.call(abi.encodeWithSignature("harvest()"));
            assertFalse(okH, "strategy.harvest must be whitelisted");
            // withdrawAll from attacker must revert
            vm.prank(ATTACKER);
            (bool okW,) = st.call(abi.encodeWithSignature("withdrawAll()"));
            assertFalse(okW, "strategy.withdrawAll must be depositor-gated");
            assertEq(IERC20(want).balanceOf(ATTACKER), atkBefore, "attacker gained nothing");
        }
    }

    // ------------------------------------------------------------------
    // 4b. Proxy admin slots are not the attacker (upgrade gate)
    // ------------------------------------------------------------------
    function test_proxy_admins_not_attacker() public {
        bytes32 SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address[4] memory proxies = [MINICHEF, SHADOW_LQDR_FTM, SHADOW_LQDR_FTM_2,
                                     0x79364E45648Db09eE9314E47b2fD31c199Eb03B9];
        for (uint256 i = 0; i < proxies.length; i++) {
            address admin = address(uint160(uint256(vm.load(proxies[i], SLOT))));
            console.log("proxy", proxies[i], "admin", admin);
            assertTrue(admin != address(0), "admin set");
            assertTrue(admin != ATTACKER, "attacker is not proxy admin");
            // attacker cannot upgrade
            vm.prank(ATTACKER);
            (bool ok,) = proxies[i].call(abi.encodeWithSignature("upgradeTo(address)", ATTACKER));
            assertFalse(ok, "attacker cannot upgrade proxy");
        }
    }

    // ------------------------------------------------------------------
    // 5. Shadow farms (proxies): attacker cannot withdraw
    // ------------------------------------------------------------------
    function test_shadow_farm_foreign_withdraw() public {
        address[2] memory farms = [SHADOW_LQDR_FTM, SHADOW_LQDR_FTM_2];
        for (uint256 i = 0; i < farms.length; i++) {
            address f = farms[i];
            // read lpToken() and strategy() via low-level to survive ABI differences
            (bool okLp, bytes memory retLp) = f.staticcall(abi.encodeWithSignature("lpToken()"));
            assertTrue(okLp, "lpToken() must exist");
            address lp = abi.decode(retLp, (address));
            uint256 farmLpBal = _balOf(lp, f);
            console.log("shadow farm", f);
            console.log("   lpToken:", lp, "farm LP bal:", farmLpBal);
            (bool okSt, bytes memory retSt) = f.staticcall(abi.encodeWithSignature("strategy()"));
            if (okSt) {
                address st = abi.decode(retSt, (address));
                console.log("   strategy:", st, "strategy LP bal:", _balOf(lp, st));
            }
            uint256 atkBefore = _balOf(lp, ATTACKER);
            // try all plausible withdraw signatures from attacker
            vm.prank(ATTACKER);
            (bool ok1,) = f.call(abi.encodeWithSignature("withdraw(uint256)", uint256(1)));
            vm.prank(ATTACKER);
            (bool ok2,) = f.call(abi.encodeWithSignature("withdraw(uint256,address)", uint256(1), ATTACKER));
            vm.prank(ATTACKER);
            (bool ok3,) = f.call(abi.encodeWithSignature("withdrawAll()"));
            vm.prank(ATTACKER);
            (bool ok4,) = f.call(abi.encodeWithSignature("emergencyWithdraw()"));
            assertEq(_balOf(lp, ATTACKER), atkBefore, "attacker gained no LP from shadow farm");
            console.log("   withdraw(1) ok?", ok1, "withdraw(1,atk) ok?", ok2);
            console.log("   withdrawAll ok?", ok3, "emergencyWithdraw ok?", ok4);
        }
    }

    // ------------------------------------------------------------------
    // 6. xLQDR voting escrow: attacker has no lock; withdraw reverts
    // ------------------------------------------------------------------
    function test_xlqdr_state_and_foreign_withdraw() public {
        IVotingEscrow x = IVotingEscrow(XLQDR);
        assertEq(x.token(), LQDR, "xLQDR is a veLQDR for LQDR");
        uint256 supply = x.supply();      // locked LQDR
        uint256 ts = x.totalSupply();     // voting power
        uint256 bal = IERC20(LQDR).balanceOf(XLQDR);
        console.log("xLQDR locked supply (LQDR):", supply);
        console.log("xLQDR voting power:", ts);
        console.log("xLQDR LQDR balance:", bal);
        assertGt(bal, 0, "escrow holds LQDR");
        assertLe(supply, bal + 1, "locked supply backed by balance");
        (int128 amt, uint256 end) = x.locked(ATTACKER);
        assertEq(amt, 0, "attacker has no lock");
        uint256 atkLqdrBefore = IERC20(LQDR).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        (bool ok,) = XLQDR.call(abi.encodeWithSignature("withdraw()"));
        // lockless withdraw() is a no-op (end=0 <= now, value=0) and transfers nothing
        assertEq(IERC20(LQDR).balanceOf(ATTACKER), atkLqdrBefore, "withdraw with no lock transfers nothing");
        console.log("withdraw(no lock) ok?", ok, "delta:", IERC20(LQDR).balanceOf(ATTACKER) - atkLqdrBefore);
        // deposit_for requires an existing lock for the target
        vm.prank(ATTACKER);
        (bool ok2,) = XLQDR.call(abi.encodeWithSignature("deposit_for(address,uint256)", ATTACKER, uint256(1)));
        assertFalse(ok2, "deposit_for on a lockless address reverts");
    }

    // ------------------------------------------------------------------
    // 7. LQDR exit-liquidity ceiling (constant product, sell-all scenario)
    // ------------------------------------------------------------------
    function test_lqdr_exit_liquidity() public {
        IUniV2Pair pair = IUniV2Pair(LP_LQDR_FTM);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        address t0 = pair.token0();
        address t1 = pair.token1();
        (uint256 rWftm, uint256 rLqdr) = t0 == WFTM ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
        console.log("LQDR/FTM pair token0:", t0);
        console.log("   token1:", t1);
        console.log("reserve WFTM:", rWftm);
        console.log("reserve LQDR:", rLqdr);
        console.log("LP totalSupply:", pair.totalSupply());
        // attacker tries to dump the full xLQDR locked balance into this pair (constant product)
        uint256 lockedLqdr = IERC20(LQDR).balanceOf(XLQDR);
        uint256 out = (rWftm * lockedLqdr) / (rLqdr + lockedLqdr);
        console.log("FTM out if dumping ALL xLQDR-locked LQDR into the pair:", out);
        assertLt(out, rWftm, "constant product bound");
    }

    // ------------------------------------------------------------------
    // 8. Net extraction check: attacker portfolio must not increase
    // ------------------------------------------------------------------
    function test_attacker_portfolio_no_increase() public {
        address[] memory tokens = new address[](5);
        tokens[0] = LQDR;
        tokens[1] = WFTM;
        tokens[2] = LP_LQDR_FTM;
        tokens[3] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; // USDC (has code)
        tokens[4] = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE; // BOO (has code)
        uint256[] memory before = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) before[i] = IERC20(tokens[i]).balanceOf(ATTACKER);

        // run every permissionless call an attacker could try, across all major contracts
        vm.startPrank(ATTACKER);
        IMasterChefV1(MASTERCHEF).emergencyWithdraw(0);
        IMasterChefV1(MASTERCHEF).withdraw(0, 0);
        IMasterChefV1(MASTERCHEF).deposit(0, 0);
        IMiniChefV2(MINICHEF).harvest(0, ATTACKER);
        IMiniChefV2(MINICHEF).emergencyWithdraw(0, ATTACKER);
        IMiniChefV2(MINICHEF).withdraw(0, 0, ATTACKER);
        MINICHEF.call(abi.encodeWithSignature("massHarvestFromStrategies()")); // may revert; tolerate
        vm.stopPrank();

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(IERC20(tokens[i]).balanceOf(ATTACKER), before[i], "no token gained");
        }
        console.log("attacker portfolio unchanged after all permissionless attempts");
    }
}
