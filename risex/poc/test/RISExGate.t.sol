// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

/// @title RISEx live-surface verification (RISE chain 4153)
/// @notice Read-only fork tests. No mainnet transaction is ever signed or sent.
///         Pins a fork block and proves which selectors an unprivileged EOA can
///         reach on the CollateralManager (CM) and PerpsManager (PM), and that
///         the collateral withdraw path is self-bound.
contract RISExGateTest is Test {
    // ── live addresses (RISE mainnet, chainId 4153) ─────────────────────────
    address constant CM = 0x2C03C7d7e2974C6599b6B108879109281ef3F818;
    address constant PM = 0x53f10fAcFC8965750494E6965F5d6dA39B41d852;
    address constant AM = 0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC;
    address constant USDCe = 0xe436820ba0C69702c1d3E601d421c0eF38262739;
    address constant VAULT = 0xBCf7A882B6A95827B4996055a5018FdC3B95D40c;
    address constant ADAPTER = 0x938a104179a2D23DeC249A968ecd5B4F8B857cac;
    address constant REGISTERED = 0x3D56dB4E3d10E21aFB7A69c0Ba4C367724525FdC;
    address constant ATTACKER = address(0xBEEF);

    uint256 constant PIN = 24_990_257;

    // observed live values at PIN
    uint256 constant CM_USDC_BAL = 20_895_931_492_064; // 20,895,931.492064 USDC.e (6 dec)
    uint256 constant VAULT_TOTAL_ASSETS = 5_001_520_609_168; // 5,001,520.609168 USDC.e

    // engine selectors
    bytes4 constant SEL_PLACE_ORDER = 0xe3ce724f;
    bytes4 constant SEL_LIQUIDATE = 0xff508b4a;
    bytes4 constant SEL_CROSS_TAKEOVER = 0x8aa1c60c;
    bytes4 constant SEL_ISOLATED_TAKEOVER = 0x05f30511;
    bytes4 constant SEL_EXECUTE_ADL = 0x62d0ee3e;
    bytes4 constant SEL_BACKFILL = 0x494f787b;

    struct ADLCounterparty {
        address account;
        uint128 size;
    }

    struct ADLParams {
        uint16 marketId;
        address account;
        ADLCounterparty[] counterparties;
    }

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("RISE_RPC_URL", string("https://rpc.risechain.com")),
            PIN
        );
    }

    // ── helpers ──────────────────────────────────────────────────────────────
    function canCall(address caller, address target, bytes4 sel) internal view returns (bool) {
        (bool ok, bytes memory ret) = AM.staticcall(
            abi.encodeWithSignature("canCall(address,address,bytes4)", caller, target, sel)
        );
        require(ok, "canCall failed");
        return abi.decode(ret, (bool));
    }

    function roleOf(address target, bytes4 sel) internal view returns (uint64) {
        (bool ok, bytes memory ret) = AM.staticcall(
            abi.encodeWithSignature("getTargetFunctionRole(address,bytes4)", target, sel)
        );
        require(ok, "roleOf failed");
        return abi.decode(ret, (uint64));
    }

    // ── 1. AccessManager role map: every engine write path is role-gated ──────
    function test_engine_selectors_are_not_public() public view {
        assertEq(roleOf(PM, SEL_PLACE_ORDER), 14, "placeOrder role");
        assertEq(roleOf(PM, SEL_LIQUIDATE), 9, "liquidate role");
        assertEq(roleOf(PM, SEL_CROSS_TAKEOVER), 10, "crossTakeover role");
        assertEq(roleOf(PM, SEL_EXECUTE_ADL), 11, "executeADL role");

        assertFalse(canCall(ATTACKER, PM, SEL_PLACE_ORDER), "placeOrder public");
        assertFalse(canCall(ATTACKER, PM, SEL_LIQUIDATE), "liquidate public");
        assertFalse(canCall(ATTACKER, PM, SEL_CROSS_TAKEOVER), "crossTakeover public");
        assertFalse(canCall(ATTACKER, PM, SEL_ISOLATED_TAKEOVER), "isolatedTakeover public");
        assertFalse(canCall(ATTACKER, PM, SEL_EXECUTE_ADL), "executeADL public");

        // a *registered* trading account still cannot call the engine
        assertFalse(canCall(REGISTERED, PM, SEL_PLACE_ORDER), "registered placeOrder public");
        assertFalse(canCall(REGISTERED, PM, SEL_LIQUIDATE), "registered liquidate public");
    }

    function test_engine_calls_revert_for_unprivileged() public {
        bytes memory placeOrderData = abi.encodeWithSelector(
            SEL_PLACE_ORDER,
            uint16(2), uint32(1), uint24(1), uint16(0),
            uint8(0), uint8(0), uint8(0), false, false, uint8(0), uint8(0), uint16(0)
        );
        vm.expectRevert(abi.encodeWithSignature("AccessManagedUnauthorized(address)", REGISTERED));
        vm.prank(REGISTERED);
        (bool ok1,) = PM.call(placeOrderData);
        ok1; // expectRevert swallows the revert and returns success to this frame

        bytes memory liqData = abi.encodeWithSelector(
            SEL_LIQUIDATE, uint16(2), REGISTERED, uint128(0), uint128(0), uint8(0)
        );
        vm.expectRevert(abi.encodeWithSignature("AccessManagedUnauthorized(address)", REGISTERED));
        vm.prank(REGISTERED);
        (bool ok2,) = PM.call(liqData);
        ok2;

        ADLCounterparty[] memory cps = new ADLCounterparty[](0);
        bytes memory adlData = abi.encodeWithSelector(
            SEL_EXECUTE_ADL, ADLParams(uint16(2), REGISTERED, cps)
        );
        vm.expectRevert(abi.encodeWithSignature("AccessManagedUnauthorized(address)", REGISTERED));
        vm.prank(REGISTERED);
        (bool ok3,) = PM.call(adlData);
        ok3;
    }

    // ── 2. the one public PM selector (backfillLeverage) writes nothing ──────
    function test_backfillLeverage_is_public_but_noop() public {
        assertTrue(canCall(ATTACKER, PM, SEL_BACKFILL), "backfill not public");

        (bool ok, bytes memory lev0) = PM.staticcall(
            abi.encodeWithSignature("getLeverage(uint16,address)", uint16(2), REGISTERED)
        );
        require(ok, "getLeverage failed");
        uint128 before = abi.decode(lev0, (uint128));
        assertGt(before, 0, "expected leverage set");

        uint32[] memory ids = new uint32[](1);
        ids[0] = 22411; // userId of REGISTERED

        vm.prank(ATTACKER);
        (bool ok2,) = PM.call(
            abi.encodeWithSignature("backfillLeverage(uint16,uint32[])", uint16(2), ids)
        );
        assertTrue(ok2, "backfill reverted");

        (bool ok3, bytes memory lev1) = PM.staticcall(
            abi.encodeWithSignature("getLeverage(uint16,address)", uint16(2), REGISTERED)
        );
        require(ok3, "getLeverage failed");
        assertEq(abi.decode(lev1, (uint128)), before, "backfill changed leverage");
    }

    // ── 3. CollateralManager: deposit is pull-payment, no free credit ────────
    function test_deposit_requires_caller_funds() public {
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        vm.prank(ATTACKER);
        (bool ok,) = CM.call(
            abi.encodeWithSignature("deposit(address,address,uint256)", ATTACKER, USDCe, uint256(1))
        );
        ok;
    }

    // ── 4. withdraw is self-bound: third party cannot name another account ───
    function test_withdraw_from_foreign_account_reverts() public {
        vm.expectRevert(abi.encodeWithSignature("AccountNotRegistered(address)", ATTACKER));
        vm.prank(ATTACKER);
        (bool ok,) = CM.call(
            abi.encodeWithSignature("withdraw(address,address,uint256)", REGISTERED, USDCe, uint256(1))
        );
        ok;
    }

    function test_withdraw_own_funds_to_any_receiver() public {
        uint256 before = IERC20(USDCe).balanceOf(CM);
        vm.prank(ADAPTER);
        (bool ok,) = CM.call(
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)", address(0xdead), USDCe, uint256(1)
            )
        );
        assertTrue(ok, "self withdraw failed");
        assertEq(IERC20(USDCe).balanceOf(CM), before - 1, "CM balance delta");
        assertEq(IERC20(USDCe).balanceOf(address(0xdead)), 1, "receiver credited");
    }

    function test_withdraw_cannot_exceed_balance() public {
        uint256 bal = IERC20(USDCe).balanceOf(CM);
        vm.expectRevert(
            abi.encodeWithSignature(
                "InsufficientSupply(address,uint256,uint256)", USDCe, bal, bal + 1
            )
        );
        vm.prank(ADAPTER);
        (bool ok,) = CM.call(
            abi.encodeWithSignature("withdraw(address,address,uint256)", ADAPTER, USDCe, bal + 1)
        );
        ok;
    }

    // ── 5. live value snapshot (for the report) ──────────────────────────────
    function test_live_holdings() public view {
        assertEq(IERC20(USDCe).balanceOf(CM), CM_USDC_BAL, "CM USDC.e");
        (bool okv, bytes memory vret) = VAULT.staticcall(
            abi.encodeWithSignature("totalAssets()")
        );
        require(okv, "vault totalAssets failed");
        assertEq(abi.decode(vret, (uint256)), VAULT_TOTAL_ASSETS, "vault totalAssets");
        (bool ok, bytes memory ret) = CM.staticcall(
            abi.encodeWithSignature("getAccountEquity(address)", ADAPTER)
        );
        require(ok, "equity failed");
        int256 eq = abi.decode(ret, (int256));
        console.log("adapter equity (WAD)", uint256(eq));
        assertGt(eq, 3_500_000e18, "adapter equity");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}
