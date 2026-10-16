// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {
    PoolKey,
    IPoolManager,
    IFablesLedger,
    IAccessManager,
    IERC20,
    IERC6909
} from "../src/Interfaces.sol";

/// @title L6 — Fables (Robinhood Chain 4663) live-extractability re-probe
/// @notice Read-only fork tests at TODAY's block. Goal: (1) confirm no state drift since Z3-H13,
///         (2) re-falsify every unprivileged value path against current state, (3) measure today's
///         pots and re-prove the destination-locked sweeps, (4) prove the old-hook park defect is
///         inert today and quantify exactly what re-arms it.
contract L6FablesTest is Test {
    address constant PM = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address constant RAMP = 0x08E52564Bad99E05a694b4809F397edcA417A080;
    address constant RWA = 0x5Eb87F69bE00Df39981622Fd60A8De4b7837e080;
    address constant RAMPETH = 0x594e8e6281eDf2d363a0293a50004Cf868E7a080;
    address constant RWAETH = 0xcA89f079AF00f752bfD3C345358Dc38d4d73e080;
    address constant OLDRAMPETH = 0x06a889870C8f83640D6816319f72e2aA579b6080;
    address constant AM = 0xA362D98B33A7bb5B5E2180a05f995A70FB404f30;
    address constant SAFE = 0x9F887B9930E9e716286333Bd8e291f64a8710F6f;
    address constant REGISTRY = 0x159A113E012593D9B3cC63ad45E30F0467e13Ef3;
    address constant WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;

    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168; // 6dp
    address constant CASHCAT = 0x020bfC650A365f8BB26819deAAbF3E21291018b4; // 18dp
    address constant PONS = 0x39dBED3a2bd333467115dE45665cC57F813C4571;

    PoolKey cashatPool;
    PoolKey oldEthPool;
    PoolKey newEthPool;
    PoolKey rwaethPool; // ETH/AMC on RWAETH (0xca89f079...)

    address attacker = makeAddr("freshAttackerL6");

    function setUp() public {
        string memory url = _pickRpc();
        vm.createSelectFork(url);
        console2.log("L6 fork block", block.number);

        cashatPool = PoolKey({currency0: CASHCAT, currency1: USDG, fee: 0x800000, tickSpacing: 60, hooks: RAMP});
        oldEthPool = PoolKey({currency0: address(0), currency1: USDG, fee: 0x800000, tickSpacing: 10, hooks: OLDRAMPETH});
        newEthPool = PoolKey({currency0: address(0), currency1: PONS, fee: 0x800000, tickSpacing: 60, hooks: RAMPETH});
        rwaethPool = PoolKey({currency0: address(0), currency1: 0x05a3d1Cd21d0C88145E82600E62e7E496e0F222B, fee: 0x800000, tickSpacing: 60, hooks: RWAETH});
    }

    /* ------------------------------ helpers ------------------------------ */

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

    function _slot0Tick(bytes32 poolId) internal view returns (int24 tick) {
        bytes32 slot = keccak256(abi.encodePacked(poolId, bytes32(uint256(6))));
        bytes32 data = IPoolManager(PM).extsload(slot);
        assembly ("memory-safe") {
            tick := signextend(2, shr(160, data))
        }
    }

    function _floorSpacing(int24 tick, int24 spacing) internal pure returns (int24) {
        int256 t = int256(tick);
        int256 s = int256(spacing);
        int256 q = t / s;
        if (t < 0 && t % s != 0) q -= 1;
        return int24(q * s);
    }

    function _aboveSpotRange(bytes32 poolId, int24 spacing, int24 width) internal view returns (int24 tl, int24 tu) {
        int24 lower = _floorSpacing(_slot0Tick(poolId), spacing) + spacing * 2;
        return (lower, lower + width);
    }

    /* ---------------- F1: state drift vs Z3-H13 (block 89,740,322) ---------------- */

    function test_L6_F1_stateDrift() public view {
        // registry count still 68; no new pools/hooks
        (bool ok, bytes memory ret) = REGISTRY.staticcall(abi.encodeWithSignature("poolCount()"));
        assertTrue(ok, "poolCount reads");
        assertEq(abi.decode(ret, (uint256)), 68, "still 68 pools - no new deployments");

        // sinks unchanged on the main hooks
        assertEq(IFablesLedger(RAMP).claimFeeRecipient(), SAFE);
        assertEq(IFablesLedger(RWA).claimFeeRecipient(), SAFE);
        assertEq(IFablesLedger(RAMPETH).claimFeeRecipient(), SAFE);
        assertEq(IFablesLedger(RAMP).distributor(), address(0));
        assertEq(IFablesLedger(RWAETH).distributor(), address(0));
        assertEq(IFablesLedger(RAMPETH).ffFeeSink(), address(0));

        // nobody has paused anything
        assertEq(IFablesLedger(RAMP).pausedUntil(), 0);
        assertEq(IFablesLedger(RAMPETH).pausedUntil(), 0);
        assertEq(IFablesLedger(RWAETH).pausedUntil(), 0);

        // code sizes match the deployed revisions
        assertEq(RAMP.code.length, 32997, "FablesRamp code size");
        assertEq(RWA.code.length, 42039, "FablesRWA code size");
        assertEq(RAMPETH.code.length, 34326, "FablesRampETH code size");

        // MONITOR: the pre-fix hook's native balance is still zero -> conditional defect disarmed
        assertEq(OLDRAMPETH.balance, 0, "old hook park monitor: 0 ETH (disarmed)");

        console2.log("FablesRampETH claimFeeOwed[ETH]  ", IFablesLedger(RAMPETH).claimFeeOwed(address(0)));
        console2.log("FablesRWAETH claimFeeOwed[ETH]  ", IFablesLedger(RWAETH).claimFeeOwed(address(0)));
        console2.log("FablesRamp   claimFeeOwed[USDG] ", IFablesLedger(RAMP).claimFeeOwed(USDG));
    }

    /* ---------------- F2: permissionless native sweep -> Safe only ---------------- */

    function test_L6_F2_nativeSweeps_payOnlySafe() public {
        uint256 potRampEth = IFablesLedger(RAMPETH).claimFeeOwed(address(0));
        uint256 potRwaEth = IFablesLedger(RWAETH).claimFeeOwed(address(0));
        assertGt(potRampEth, 0, "live native pot on FablesRampETH");
        assertGt(potRwaEth, 0, "live native pot on FablesRWAETH");

        uint256 safeWethBefore = IERC20(WETH).balanceOf(SAFE);
        uint256 attackerEthBefore = attacker.balance;
        uint256 attackerWethBefore = IERC20(WETH).balanceOf(attacker);

        // ANY unprivileged caller can trigger the sweep - it is destination-locked
        vm.startPrank(attacker);
        IFablesLedger(RAMPETH).sweepClaimFee(address(0));
        IFablesLedger(RWAETH).sweepClaimFee(address(0));
        vm.stopPrank();

        uint256 safeGain = IERC20(WETH).balanceOf(SAFE) - safeWethBefore;
        console2.log("Safe WETH gain (wei):", safeGain);
        console2.log("  pot RampETH:", potRampEth, " pot RWAETH:", potRwaEth);
        assertEq(safeGain, potRampEth + potRwaEth, "Safe received EXACTLY both pots (as WETH)");
        assertEq(attacker.balance, attackerEthBefore, "attacker ETH unchanged");
        assertEq(IERC20(WETH).balanceOf(attacker), attackerWethBefore, "attacker WETH unchanged");
        assertEq(IFablesLedger(RAMPETH).claimFeeOwed(address(0)), 0, "pot cleared");
        assertEq(IFablesLedger(RWAETH).claimFeeOwed(address(0)), 0, "pot cleared");
        assertEq(RAMPETH.balance, 0, "hook ETH balance drained to zero by design");
    }

    /* ---------------- F3: old-hook park defect - inert today, conditional ---------------- */

    function test_L6_F3_oldHookPark_inertToday_conditionalOnInflow() public {
        // (a) TODAY: zero balance -> nothing to capture
        assertEq(OLDRAMPETH.balance, 0, "no park today");
        vm.deal(attacker, 1 ether);
        bytes32 pid = _poolId(oldEthPool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 10, 600);
        uint256 a0 = attacker.balance;
        vm.prank(attacker);
        IFablesLedger(OLDRAMPETH).deposit{value: 10_000}(oldEthPool, tl, tu, 1, 10_000, 0, block.timestamp + 60);
        int256 gainToday = int256(attacker.balance) - int256(a0);
        console2.log("attacker net (wei) with NO park:", gainToday);
        assertLt(gainToday, int256(10_000), "no park => no gain (only own remainder returned)");

        // (b) CONDITIONAL: simulate an external mistake (someone else parks ETH) via vm.deal.
        //     Re-arms the race exactly as documented; nothing about TODAY's state provides it.
        uint256 park = 1 ether;
        vm.deal(OLDRAMPETH, park);
        uint256 a1 = attacker.balance;
        vm.prank(attacker);
        IFablesLedger(OLDRAMPETH).deposit{value: 10_000}(oldEthPool, tl, tu, 1, 10_000, 0, block.timestamp + 60);
        int256 gainWithPark = int256(attacker.balance) - int256(a1);
        console2.log("attacker net (wei) WITH a 1 ETH external park:", gainWithPark);
        assertGt(gainWithPark, int256(park) - 1e6, "external park is captured by next depositor (conditional)");
        assertEq(OLDRAMPETH.balance, 0, "old hook drained");
    }

    /* ---------------- F4: round-trip (deposit+withdraw) is not profitable ---------------- */

    function test_L6_F4_roundTrip_notProfitable() public {
        bytes32 pid = _poolId(cashatPool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        deal(CASHCAT, attacker, 1e24);
        deal(USDG, attacker, 1000e6);
        vm.startPrank(attacker);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);
        IERC20(USDG).approve(RAMP, type(uint256).max);
        uint256 c0 = IERC20(CASHCAT).balanceOf(attacker);
        uint256 u0 = IERC20(USDG).balanceOf(attacker);
        IFablesLedger(RAMP).deposit(cashatPool, tl, tu, 1e15, 1e24, 0, block.timestamp + 60);
        IFablesLedger(RAMP).withdraw(cashatPool, tl, tu, 1e15, attacker, 0, 0, block.timestamp + 60);
        uint256 c1 = IERC20(CASHCAT).balanceOf(attacker);
        uint256 u1 = IERC20(USDG).balanceOf(attacker);
        vm.stopPrank();
        int256 d0 = int256(c1) - int256(c0);
        int256 d1 = int256(u1) - int256(u0);
        console2.log("round-trip net c0 (wei):", d0);
        console2.log("round-trip net c1 (wei):", d1);
        assertLe(d0, 0, "no gain on leg0");
        assertLe(d1, 0, "no gain on leg1");
        assertLe(d0 + d1 * 1e12, 0, "net is non-positive after normalising (loss or zero)");
    }

    /* ---------------- F5: every pot is backed by the hook's ERC-6909 claims ---------------- */

    function test_L6_F5_potsBacked() public view {
        address[10] memory hooks = [
            RAMP, RWA, RAMPETH, RWAETH, OLDRAMPETH,
            0x66622f77B797D506e5376F7798b67ab288966080, 0xA0E8fBFf13E24Af2b5e61A72800E08a161bDe080,
            0x79576FBAD6e83915630BBB5D5658483F05532080, 0x70a9A88402989226847Ec122043CE5e7FF462080,
            0x67D86050d22D574Df046F3D90F722045F714e080
        ];
        address[3] memory curs = [address(0), USDG, CASHCAT];
        for (uint256 i = 0; i < hooks.length; i++) {
            for (uint256 j = 0; j < curs.length; j++) {
                uint256 pot = IFablesLedger(hooks[i]).claimFeeOwed(curs[j]);
                uint256 owed = IFablesLedger(hooks[i]).distributorOwed(curs[j]);
                if (pot + owed == 0) continue;
                uint256 claims = IERC6909(PM).balanceOf(hooks[i], uint256(uint160(curs[j])));
                assertGe(claims, pot + owed, "claims back the pots");
            }
        }
    }

    /* ---------------- F6: restricted surface closed for a fresh caller ---------------- */

    function test_L6_F6_rolesClosed() public {
        (bool ok1,) = IAccessManager(AM).canCall(attacker, RAMP, bytes4(keccak256("pokeFee(bytes32,uint24,uint24,uint40)")));
        assertFalse(ok1, "pokeFee not callable by fresh caller");
        (bool ok2,) = IAccessManager(AM).canCall(attacker, RAMPETH, bytes4(keccak256("setClaimFee((address,address,uint24,int24,address),address[],uint16,address)")));
        assertFalse(ok2, "setClaimFee not callable");
        (bool ok3,) = IAccessManager(AM).canCall(attacker, REGISTRY, bytes4(keccak256("register((address,address,uint24,int24,address))")));
        assertFalse(ok3, "registry.register not callable");
        vm.startPrank(attacker);
        vm.expectRevert();
        IFablesLedger(RAMP).pokeFee(_poolId(cashatPool), 1, 1, 60);
        vm.stopPrank();
    }
}
