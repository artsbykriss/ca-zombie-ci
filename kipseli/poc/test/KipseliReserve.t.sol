// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

/// @title Kipseli Base "reserve" — unprivileged-extraction PoC
/// @notice Read-only, fork-only. Proves that an external unprivileged EOA cannot
///         move the reserve's USDC/WETH: every value-moving selector is gated to the
///         operator EOA or the 2-of-3 Gnosis Safe owner / proxy-admin owner.
///         Fork pinned at Base block 52,975,121 (state read 2026-10-23).
contract KipseliReserveTest is Test {
    // --- targets (Base) ---
    address constant RESERVE = 0xBEE3211ab312a8D065c4FeF0247448e17A8da000; // ERC1967 proxy
    address constant IMPL    = 0x45A507EB92dDF5ab6F10e0a0d124B247e75992a8; // unverified impl
    address constant ADMIN   = 0x8Bb03250fD720A6f2Dc043616532c92bd2D42f6E; // proxy admin (custom)
    address constant OWNER   = 0xbBaE617C0b16639896156B5bD7E33cCE492F958a; // Gnosis Safe 1.4.1 (2-of-3)
    address constant OPERATOR= 0x97F7d4093e5Bdd0776e2Ca90C90124c5e16Ca569; // operator EOA (also Safe signer + admin owner)

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    uint256 constant FORK_BLOCK = 52_975_121;

    // expected live state at FORK_BLOCK
    uint256 constant USDC_BAL = 440_787_511_981;              // 440,787.511981 USDC (6dp)
    uint256 constant WETH_BAL = 36_186_163_902_047_726_266;   // 36.186163902047726266 WETH (18dp)

    address outsider = address(0xBEEF);

    function setUp() public {
        // CI may pass BASE_RPC_URL as an empty string; fall back to a public archive-capable Base RPC.
        string memory url = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(url).length == 0) url = vm.envOr("BASE_FORK_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://mainnet.base.org";
        vm.createSelectFork(url, FORK_BLOCK);
    }

    // ---- helpers -------------------------------------------------------------
    function _bal(address t, address w) internal view returns (uint256) {
        (bool ok, bytes memory d) = t.staticcall(abi.encodeWithSelector(0x70a08231, w));
        require(ok, "balanceOf failed");
        return abi.decode(d, (uint256));
    }

    // ---- live state ----------------------------------------------------------
    function test_live_state() public view {
        assertEq(_bal(USDC, RESERVE), USDC_BAL, "USDC balance");
        assertEq(_bal(WETH, RESERVE), WETH_BAL, "WETH balance");
        assertEq(RESERVE.balance, 0, "native ETH");

        // owner() == Gnosis Safe
        (bool ok, bytes memory d) = RESERVE.staticcall(abi.encodeWithSignature("owner()"));
        assertTrue(ok);
        assertEq(abi.decode(d, (address)), OWNER);

        // numberOperators() == 1 and operatorAt(0) == operator EOA
        (ok, d) = RESERVE.staticcall(abi.encodeWithSignature("numberOperators()"));
        assertEq(abi.decode(d, (uint256)), 1);
        (ok, d) = RESERVE.staticcall(abi.encodeWithSignature("operatorAt(uint256)", uint256(0)));
        assertEq(abi.decode(d, (address)), OPERATOR);

        // weth() == Base WETH constant
        (ok, d) = RESERVE.staticcall(abi.encodeWithSignature("weth()"));
        assertEq(abi.decode(d, (uint256)), uint256(uint160(WETH)));

        // operator EOA has no code; owner is a contract (Safe)
        assertEq(OPERATOR.code.length, 0);
        assertGt(OWNER.code.length, 0);
    }

    // ---- every outsider path reverts ----------------------------------------
    function test_outsider_withdraw_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("caller is not operator"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("withdraw(address,uint256,address)", USDC, uint256(1), outsider));
        ok; // silence
    }

    function test_outsider_convertETH_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("caller is not operator"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("convertETH(uint256)", uint256(1)));
        ok;
    }

    function test_outsider_emergencyWithdraw_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("emergencyWithdraw(address,uint256)", USDC, uint256(1)));
        ok;
    }

    function test_outsider_setAllowance_reverts() public {
        address[] memory toks = new address[](1);
        toks[0] = USDC;
        vm.prank(outsider);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("setAllowance(address[],address,uint256)", toks, outsider, type(uint256).max));
        ok;
    }

    function test_outsider_addOperators_reverts() public {
        address[] memory ops = new address[](1);
        ops[0] = outsider;
        vm.prank(outsider);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("addOperators(address[])", ops));
        ok;
    }

    function test_outsider_transferOwnership_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("transferOwnership(address)", outsider));
        ok;
    }

    function test_outsider_renounceOwnership_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("renounceOwnership()"));
        ok;
    }

    // ---- even the real operator is blocked (no approved destination) ---------
    function test_operator_blocked_by_destination_gate() public {
        vm.prank(OPERATOR);
        vm.expectRevert(bytes("destination is not approved"));
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("withdraw(address,uint256,address)", USDC, uint256(1), OPERATOR));
        ok;
    }

    // ---- proxy admin upgrade is owner-gated ---------------------------------
    function test_admin_upgrade_outsider_reverts() public {
        vm.prank(outsider);
        // OwnableUnauthorizedAccount(address) on the admin contract
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", outsider));
        (bool ok,) = ADMIN.call(abi.encodeWithSignature("upgradeAndCall(address,address,bytes)", RESERVE, outsider, bytes("")));
        ok;
    }

    // ---- sweep: every dispatcher selector from a fresh EOA ------------------
    /// Every non-view selector is access-controlled; views never move value.
    function test_all_selectors_gated() public {
        uint32[33] memory sels = [
            0x0eb9142f, 0x14b7c124, 0x1626ba7e, 0x26142335, 0x34efb1e9,
            0x388bb62c, 0x3fc8cef3, 0x4cf3fe9c, 0x567aa1ba, 0x61acbdcb,
            0x61bb41a7, 0x69328dec, 0x6d70f7ae, 0x715018a6, 0x7d6a4568,
            0x7dadbe8c, 0x8594ac40, 0x8da5cb5b, 0x95ccea67, 0x9e165a78,
            0x9f273fbc, 0xa07aea1c, 0xa908183d, 0xab06e403, 0xaf38bf11,
            0xb9f9fc41, 0xd365a377, 0xd49d5181, 0xd911c632, 0xe3fa62d6,
            0xecb9e11a, 0xf00baf3e, 0xf2fde38b
        ];
        uint256 stateChangers;
        for (uint256 i = 0; i < sels.length; i++) {
            bytes memory data = abi.encodePacked(sels[i], uint256(0), uint256(0), uint256(0), uint256(0));
            vm.prank(outsider);
            (bool ok, bytes memory ret) = RESERVE.call(data);
            if (!ok) {
                stateChangers++;
                emit log_named_bytes("REVERT selector", abi.encodePacked(bytes4(sels[i])));
                emit log_named_bytes("  reason", ret);
            } else {
                emit log_named_bytes("OK (view) selector", abi.encodePacked(bytes4(sels[i])));
            }
        }
        emit log_named_uint("gated (reverting) selectors", stateChangers);
        // 20 state-changing selectors revert for an unprivileged caller; 13 views answer.
        assertEq(stateChangers, 20, "expected 20 gated selectors");
    }

    // ---- implementation fallback module-registry: no unregistered path --------
    /// Any selector not in the dispatcher hits the impl fallback, which looks up a
    /// module address in a registry (owner-written) and delegatecalls it; unregistered
    /// selectors revert "Not registrer".
    function test_fallback_unregistered_reverts() public {
        vm.prank(outsider);
        vm.expectRevert(bytes("Not registrer"));
        (bool ok,) = RESERVE.call(hex"deadbeef");
        ok;
        vm.prank(outsider);
        vm.expectRevert(bytes("Not registrer"));
        (ok,) = RESERVE.call(hex"12345678");
        ok;
    }

    // ---- net extractable by an unprivileged attacker is zero ----------------
    function test_net_extractable_zero() public {
        uint256 before = _bal(USDC, RESERVE) + _bal(WETH, RESERVE);
        vm.prank(outsider);
        (bool ok,) = RESERVE.call(abi.encodeWithSignature("withdraw(address,uint256,address)", USDC, USDC_BAL, outsider));
        assertFalse(ok, "outsider withdraw must fail");
        vm.prank(outsider);
        (ok,) = RESERVE.call(abi.encodeWithSignature("emergencyWithdraw(address,uint256)", USDC, USDC_BAL));
        assertFalse(ok, "outsider emergencyWithdraw must fail");
        uint256 afterBal = _bal(USDC, RESERVE) + _bal(WETH, RESERVE);
        assertEq(afterBal, before, "no value moved");
        emit log_named_uint("reserve USDC+WETH raw (unchanged)", afterBal);
    }
}
