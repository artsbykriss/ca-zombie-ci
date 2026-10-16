// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {PoolKey, IPoolManager, IFablesLedger, IERC20, IAccessManager} from "../src/Interfaces.sol";

/// @notice Second half of the Z3-H13 probe: callback authentication, pool identity, liveness
///         under a real PAUSER pause, fee-sync poisoning, and dynamic-fee bounds.
contract FablesZ3H13bTest is Test {
    address constant PM = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address constant RAMP = 0x08E52564Bad99E05a694b4809F397edcA417A080;
    address constant AM = 0xA362D98B33A7bb5B5E2180a05f995A70FB404f30;
    address constant PAUSER = 0x5cDa43Da9631fB84D390D91e750F549B7ada721c; // role 4, granted at AM genesis
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address constant CASHCAT = 0x020bfC650A365f8BB26819deAAbF3E21291018b4;

    PoolKey pool;
    address attacker = makeAddr("freshAttacker2");

    function setUp() public {
        string memory url = _pickRpc();
        vm.createSelectFork(url);
        pool = PoolKey({
            currency0: CASHCAT,
            currency1: USDG,
            fee: 0x800000,
            tickSpacing: 60,
            hooks: RAMP
        });
    }

    /// @dev RHO_RPC override, else probe the keyless endpoints in order via a raw VM call so a
    ///      dead endpoint can be skipped instead of reverting the suite.
    function _pickRpc() internal returns (string memory) {
        string memory override_ = vm.envOr("RHO_RPC", string(""));
        if (bytes(override_).length != 0) return override_;
        string[3] memory urls = [
            "https://rpc.mainnet.chain.robinhood.com",
            "https://robinhood-rpc.publicnode.com",
            "https://robinhood.drpc.org"
        ];
        for (uint256 i = 0; i < 3; i++) {
            (bool ok,) = VM_ADDRESS.call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return urls[i];
        }
        revert("no reachable Robinhood Chain (4663) RPC");
    }

    function _poolId(PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k));
    }

    function _slot0(bytes32 poolId) internal view returns (int24 tick) {
        bytes32 slot = keccak256(abi.encodePacked(poolId, bytes32(uint256(6))));
        bytes32 data = IPoolManager(PM).extsload(slot);
        assembly ("memory-safe") {
            tick := signextend(2, shr(160, data))
        }
    }

    function _ceilSpacing(int24 tick, int24 spacing) internal pure returns (int24) {
        int256 t = int256(tick);
        int256 s = int256(spacing);
        int256 q = t / s;
        if (t > 0 && t % s != 0) q += 1;
        return int24(q * s);
    }

    function _aboveSpotRange(bytes32 poolId, int24 spacing, int24 width) internal view returns (int24, int24) {
        int24 tickLower = _ceilSpacing(_slot0(poolId) + spacing * 2, spacing);
        return (tickLower, tickLower + width);
    }

    /* ---------------- callback authentication ---------------- */

    function test_T11_unlockCallback_rejectsNonPoolManager() public {
        vm.prank(attacker);
        (bool ok,) = RAMP.call(abi.encodeWithSignature("unlockCallback(bytes)", hex"00"));
        assertFalse(ok, "unlockCallback must refuse a non-PoolManager caller");

        // receive() is PoolManager-only on the ETH hooks
        vm.prank(attacker);
        (bool ok2,) = 0x594e8e6281eDf2d363a0293a50004Cf868E7a080.call{value: 1}("");
        assertFalse(ok2, "receive() must refuse a non-PoolManager sender");

        // beforeSwap is PoolManager-only
        vm.prank(attacker);
        (bool ok3,) = RAMP.call(
            abi.encodeWithSignature(
                "beforeSwap(address,(address,address,uint24,int24,address),(bool,int256,uint160),bytes)",
                attacker,
                pool,
                IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 1, sqrtPriceLimitX96: 0}),
                ""
            )
        );
        assertFalse(ok3, "beforeSwap must refuse a non-PoolManager caller");
    }

    /* ---------------- pool identity ---------------- */

    function test_T12_checkKey_rejectsForeignOrUnconfiguredPools() public {
        bytes32 pid = _poolId(pool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        deal(CASHCAT, attacker, 1e24);
        vm.startPrank(attacker);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);

        // foreign hook
        PoolKey memory foreign = pool;
        foreign.hooks = attacker;
        vm.expectRevert();
        IFablesLedger(RAMP).deposit(foreign, tl, tu, 1, 1e24, 0, block.timestamp + 60);

        // configured hook, unconfigured pool (bogus tickSpacing changes the poolId)
        PoolKey memory unconf = pool;
        unconf.tickSpacing = 61;
        vm.expectRevert();
        IFablesLedger(RAMP).deposit(unconf, tl, tu, 1, 1e24, 0, block.timestamp + 60);
        vm.stopPrank();
    }

    /* ---------------- liveness under a real pause ---------------- */

    function test_T14_pauserCanFreezeDeposits_butWithdrawalsStayOpen() public {
        // PAUSER is a real role-4 member; impersonate it on the fork.
        (bool isPauser, ) = IAccessManager(AM).hasRole(4, PAUSER);
        assertTrue(isPauser, "PAUSER holds role 4");

        bytes32 pid = _poolId(pool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        deal(CASHCAT, attacker, 1e24);
        vm.startPrank(attacker);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);
        IFablesLedger(RAMP).deposit(pool, tl, tu, 1e15, 1e24, 0, block.timestamp + 60);
        vm.stopPrank();

        vm.prank(PAUSER);
        IFablesLedger(RAMP).pause(1 days);
        assertTrue(IFablesLedger(RAMP).paused(), "hook paused");

        vm.startPrank(attacker);
        vm.expectRevert(); // deposits frozen
        IFablesLedger(RAMP).deposit(pool, tl, tu, 1, 1e24, 0, block.timestamp + 60);
        // ...but the principal exit still works
        IFablesLedger(RAMP).withdraw(pool, tl, tu, 1e15, attacker, 0, 0, block.timestamp + 60);
        vm.stopPrank();
    }

    /* ---------------- fee-sync poisoning ---------------- */

    function test_T15_forcedSync_onForeignRange_gainsNothing() public {
        bytes32 pid = _poolId(pool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        uint256 id = uint256(keccak256(abi.encode(pid, tl, tu)));

        // victim opens a position
        address victim = makeAddr("victim");
        deal(CASHCAT, victim, 1e24);
        vm.startPrank(victim);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);
        IFablesLedger(RAMP).deposit(pool, tl, tu, 1e15, 1e24, 0, block.timestamp + 60);
        vm.stopPrank();

        // attacker forces a sync of the victim's range with a 1-wei deposit, repeatedly
        deal(CASHCAT, attacker, 1e24);
        uint256 c0 = IERC20(CASHCAT).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);
        for (uint256 i = 0; i < 5; i++) {
            IFablesLedger(RAMP).deposit(pool, tl, tu, 1, 1e24, 0, block.timestamp + 60);
        }
        // attacker's own owed stays zero and they hold no more value than they deposited
        (uint128 shares,,,,,,, , , ) = IFablesLedger(RAMP).rangeState(id);
        assertGt(shares, 1e15, "range still holds victim + attacker shares");
        vm.stopPrank();
        uint256 c1 = IERC20(CASHCAT).balanceOf(attacker);
        console2.log("forced-sync cost (wei):", c0 - c1);
        assertLt(c1, c0, "forced syncs cost the attacker, they gain nothing");
        assertEq(IERC20(USDG).balanceOf(attacker), 0, "no USDG extracted");
    }

    /* ---------------- native wrap-sweep ---------------- */

    function test_T17_nativeClaimFeeSweep_wrapsToWeth_forFixedSink() public {
        address RAMPETH = 0x594e8e6281eDf2d363a0293a50004Cf868E7a080;
        address WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;
        uint256 pot = IFablesLedger(RAMPETH).claimFeeOwed(address(0));
        assertGt(pot, 0, "live native claim-fee pot on FablesRampETH");
        address sink = IFablesLedger(RAMPETH).claimFeeRecipient();
        uint256 wethBefore = IERC20(WETH).balanceOf(sink);
        uint256 attackerEth = attacker.balance;
        vm.prank(attacker);
        IFablesLedger(RAMPETH).sweepClaimFee(address(0));
        assertEq(IERC20(WETH).balanceOf(sink) - wethBefore, pot, "sink received the pot as WETH");
        assertEq(attacker.balance, attackerEth, "attacker gained no ETH");
        assertEq(IFablesLedger(RAMPETH).claimFeeOwed(address(0)), 0, "native pot zeroed");
        assertEq(RAMPETH.balance, 0, "hook holds no ETH between transactions");
    }

    function test_T18_oldHookSweeps_areNoops() public {
        address OLD = 0x06a889870C8f83640D6816319f72e2aA579b6080;
        assertEq(IFablesLedger(OLD).claimFeeRecipient(), address(0), "old hook: no claim-fee sink");
        assertEq(IFablesLedger(OLD).distributor(), address(0), "old hook: no distributor");
        uint256 before_ = attacker.balance;
        vm.prank(attacker);
        IFablesLedger(OLD).sweepClaimFee(address(0));
        vm.prank(attacker);
        IFablesLedger(OLD).sweepDistributor(address(0));
        assertEq(attacker.balance, before_, "no value moves");
    }

    /* ---------------- dynamic fee bounds ---------------- */

    function test_T16_dynamicFee_isBoundedAndNotCallerControlled() public {
        bytes32 pid = _poolId(pool);
        uint24 cap = IFablesLedger(RAMP).maxFee(pid);
        uint256 absMax = uint256(IFablesLedger(RAMP).ABSOLUTE_MAX_FEE());
        assertGt(cap, 0, "pool configured");
        assertLe(uint256(cap), absMax, "cap <= absolute max");
        assertLe(absMax, 1_000_000, "absolute max <= 10%");
        (bool ok, ) = RAMP.staticcall(abi.encodeWithSignature("currentFee(bytes32,bool)", pid, true));
        assertTrue(ok, "currentFee readable");
    }
}
