// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20, IBondingCurveManager} from "../src/Interfaces.sol";

/// @title O12 — Ronin BondingCurveManager: external-unprivileged extraction test
/// @notice Read-only fork test. No transaction is signed or broadcast; everything runs on a
///         local fork of Ronin. Proves the permissionless paths are either gated or
///         value-negative for an attacker with no purchase history.
contract O12_RoninBondingCurve is Test {
    // Ronin mainnet (keyless public RPC; no key in the repo). Overridable by CI env.
    string RONIN_RPC;

    address constant BCM = 0xCF6Aa3d88431D73C76b9650e64a995a5edDb5f54;
    address constant RONKE = 0xf988f63bf26C3Ed3fBf39922149E3E7b1e5c27cB;
    address constant GRAD_MGR = 0x4F36816a9B5BffEeec5348F8152373De195D6EA6;
    address constant FEE_VAULT = 0x648796B45d4CdD2e56f1d5804cF7713add09b776;
    address constant FACTORY = 0x719921f396a87E5505aff65d2eD6dC73CaF633C9;
    address constant OWNER = 0x4b694024F6282420820258B7e7ad9f6fc77Dd257;
    address constant RONKO = 0x269D30254094D88287b8f5E5E5c2E838c3A99054; // a live market token

    address attacker = address(0xA11CE);

    IBondingCurveManager mgr;

    function setUp() public {
        RONIN_RPC = vm.envOr("RONIN_RPC_URL", string("https://ronin.drpc.org"));
        vm.createSelectFork(RONIN_RPC);
        mgr = IBondingCurveManager(BCM);
        // Turn off auto-graduation so the curve keeps its inventory while we round-trip it
        // (auto-graduation would move the market into a Katana pool and close `sell`).
        vm.prank(OWNER);
        mgr.setAutoGraduate(false);
    }

    // ---- live state -----------------------------------------------------------

    function test_live_state() public {
        assertTrue(mgr.markets(RONKO).exists, "RONKO market exists");
        assertEq(mgr.ronke(), RONKE);
        assertEq(mgr.feeVault(), FEE_VAULT);
        assertEq(mgr.graduationManager(), GRAD_MGR);
        assertEq(mgr.factory(), FACTORY);
        // RONKE sits in the curve, destined for graduation / sellers — never a free balance.
        assertGt(IERC20(RONKE).balanceOf(BCM), 0, "curve holds RONKE");
        emit log_named_uint("BCM RONKE balance (wei)", IERC20(RONKE).balanceOf(BCM));
    }

    // ---- the only way value leaves: sell, which requires a prior buy -----------

    /// @dev Round trip: buy with X RONKE then sell every token back. Must never be profitable.
    ///      Deterministic amounts (the high-volume fuzz lives in O12_MathReplica, fork-free) so
    ///      this suite makes a bounded number of RPC calls.
    function test_roundtrip_never_profitable() public {
        uint256[6] memory amts = [uint256(1e18), 1e20, 1e21, 1e22, 1e23, 1e24];
        for (uint256 i; i < amts.length; i++) {
            uint256 snap = vm.snapshotState();
            _roundtrip(amts[i]);
            vm.revertToState(snap);
        }
    }

    function _roundtrip(uint256 amt) internal {
        deal(RONKE, attacker, amt);
        uint256 before = IERC20(RONKE).balanceOf(attacker);

        vm.startPrank(attacker);
        IERC20(RONKE).approve(BCM, amt);
        (uint256 tokensOut,) = mgr.buy(RONKO, amt, 0);
        assertGt(tokensOut, 0, "bought something");
        uint256 bal = IERC20(RONKO).balanceOf(attacker);
        assertGe(bal, tokensOut, "received tokens");

        uint256 back;
        try mgr.sell(RONKO, bal, 0) returns (uint256 out) {
            back = out;
        } catch {
            // Curve filled + graduated within the buy: sell is closed, attacker got nothing back.
            back = 0;
        }
        vm.stopPrank();

        uint256 afterBal = IERC20(RONKE).balanceOf(attacker);
        assertLe(afterBal, before, "round trip must not profit");
        emit log_named_uint("amt", amt);
        emit log_named_uint("out", back);
    }

    /// @dev Drive the partial-fill / Ceil fallback branch: offer more than the curve can sell.
    function test_partial_fill_branch_no_profit() public {
        IBondingCurveManager.MarketState memory m0 = mgr.markets(RONKO);
        uint256 remaining = 1e27 - m0.tokensSold; // curveSupply ~= 7.85e26; use a safe upper bound
        // Price the whole remaining curve off the live reserves, then offer ~that + slack.
        uint256 cost = (m0.virtualRonke * remaining) / (m0.virtualToken - remaining) + 1e21;

        deal(RONKE, attacker, cost);
        uint256 before = IERC20(RONKE).balanceOf(attacker);

        vm.startPrank(attacker);
        IERC20(RONKE).approve(BCM, cost);
        (uint256 tokensOut, uint256 spent) = mgr.buy(RONKO, cost, 0);
        assertGt(tokensOut, 0);
        assertLe(spent, cost, "never charged more than offered");
        uint256 bal = IERC20(RONKO).balanceOf(attacker);

        uint256 back;
        try mgr.sell(RONKO, bal, 0) returns (uint256 out) {
            back = out;
        } catch {
            back = 0;
        }
        vm.stopPrank();

        assertLe(IERC20(RONKE).balanceOf(attacker), before, "no profit from filling the curve");
        emit log_named_uint("spent", spent);
        emit log_named_uint("back", back);
    }

    // ---- every other value path is gated --------------------------------------

    function test_attacker_sell_without_buy_reverts() public {
        deal(RONKO, attacker, 1e18);
        vm.startPrank(attacker);
        IERC20(RONKO).approve(BCM, 1e18);
        vm.expectRevert();
        mgr.sell(RONKO, 1e18, 0);
        vm.stopPrank();
    }

    function test_attacker_buyFor_reverts() public {
        deal(RONKE, attacker, 1e21);
        vm.startPrank(attacker);
        IERC20(RONKE).approve(BCM, 1e21);
        vm.expectRevert();
        mgr.buyFor(RONKO, attacker, 1e21, 0);
        vm.stopPrank();
    }

    function test_attacker_admin_paths_revert() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        mgr.setWiring(attacker, attacker);
        vm.expectRevert();
        mgr.setAutoGraduate(true);
        vm.stopPrank();
    }

    /// @dev `boughtFromCurve` provenance cannot be forged by moving tokens between wallets.
    function test_provenance_ledger_not_transferable() public {
        uint256 amt = 1e21; // 1000 RONKE
        deal(RONKE, attacker, amt);
        vm.startPrank(attacker);
        IERC20(RONKE).approve(BCM, amt);
        (uint256 tokensOut,) = mgr.buy(RONKO, amt, 0);
        assertGt(tokensOut, 0);
        // Move the bought tokens to a fresh wallet: it has zero provenance and cannot sell.
        address mule = address(0xB0B);
        IERC20(RONKO).transfer(mule, tokensOut);
        vm.stopPrank();

        vm.startPrank(mule);
        IERC20(RONKO).approve(BCM, tokensOut);
        vm.expectRevert();
        mgr.sell(RONKO, tokensOut, 0);
        vm.stopPrank();
    }
}
