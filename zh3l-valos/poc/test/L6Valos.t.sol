// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IAccountableVault, IStrategy} from "../src/Interfaces.sol";

/// @title L6 — Valos (Monad, chain 143) "AccountableAsyncRedeemVault" live-extractability re-probe
/// @notice Read-only fork tests at TODAY's block. Mission: re-resolve the entry gate and check the
///         strategy's public doors for a fresh, unprivileged address.
contract L6ValosTest is Test {
    address constant VAULT = 0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365;
    address constant STRATEGY = 0x8dCE15fc6a98484C995Fc702cBfBdA14A30454af;
    address constant ASSET = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address constant MANAGER = 0xB83986E9F33a6De4624B18DA69cb474F6f94fc7C;

    address fresh = 0x1111111111111111111111111111111111111111;

    function setUp() public {
        string memory url = vm.envOr("MONAD_RPC", string("https://rpc.monad.xyz"));
        vm.createSelectFork(url);
        console2.log("L6 Valos fork (header number)", block.number);
    }

    /* --------------- V1: entry gate reads --------------- */

    function test_L6_V1_gate() public view {
        assertEq(IAccountableVault(VAULT).permissionLevel(), 2, "Whitelist(2)");
        assertFalse(IAccountableVault(VAULT).allowed(fresh), "fresh address NOT whitelisted");
        assertTrue(IAccountableVault(VAULT).allowed(MANAGER), "manager is whitelisted");
        assertEq(IAccountableVault(VAULT).strategy(), STRATEGY, "strategy pinned");
        assertEq(IAccountableVault(VAULT).asset(), ASSET, "asset = aUSD");
        assertEq(IStrategy(STRATEGY).vault(), VAULT, "strategy serves exactly this vault");
        assertEq(IStrategy(STRATEGY).dvnPublisher(), address(0), "publishRate dead");
        assertFalse(IStrategy(STRATEGY).paused(), "strategy not paused");
        assertEq(IStrategy(STRATEGY).loanState(), 3, "OngoingDynamic");
        console2.log("vault totalAssets (idle cash)", IAccountableVault(VAULT).totalAssets());
        console2.log("strategy netPrincipal          ", IStrategy(STRATEGY).netPrincipal());
        console2.log("strategy scaleFactor (virtual) ", IStrategy(STRATEGY).scaleFactor());
        console2.log("sharePrice                     ", IStrategy(STRATEGY).sharePrice(VAULT));
    }

    /* --------------- V2: every value entry reverts for the fresh address --------------- */

    function test_L6_V2_entry_blocked() public {
        uint256 a0 = IERC20(ASSET).balanceOf(fresh);
        uint256 s0 = IAccountableVault(VAULT).totalSupply();
        vm.startPrank(fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).deposit(1_000_000, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).mint(1e18, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).requestRedeem(1e18, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).redeem(1e18, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).withdraw(1_000_000, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IAccountableVault(VAULT).cancelRedeemRequest(fresh, fresh);
        vm.stopPrank();
        assertEq(IERC20(ASSET).balanceOf(fresh), a0, "no asset moved");
        assertEq(IAccountableVault(VAULT).totalSupply(), s0, "no shares minted");
    }

    /* --------------- V3: strategy doors are onlyVault / role-gated --------------- */

    function test_L6_V3_strategy_doors() public {
        vm.startPrank(fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IStrategy(STRATEGY).onDeposit(VAULT, 1_000_000, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IStrategy(STRATEGY).onMint(VAULT, 1e18, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IStrategy(STRATEGY).onRequestRedeem(VAULT, 1e18, fresh, fresh);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IStrategy(STRATEGY).proposeInterestRate(1);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        IStrategy(STRATEGY).publishRate(1, 0);
        vm.stopPrank();
    }

    /* --------------- V4: permissionless cranks exist but pay $0 --------------- */

    function test_L6_V4_cranks_pay_zero() public {
        uint256 ta0 = IAccountableVault(VAULT).totalAssets();
        uint256 a0 = IERC20(ASSET).balanceOf(fresh);
        uint256 sp0 = IStrategy(STRATEGY).sharePrice(VAULT);
        vm.startPrank(fresh);
        uint256 used = IStrategy(STRATEGY).processAvailableWithdrawals();
        IStrategy(STRATEGY).accrueInterest();
        IStrategy(STRATEGY).updateLateStatus();
        vm.stopPrank();
        uint256 ta1 = IAccountableVault(VAULT).totalAssets();
        uint256 a1 = IERC20(ASSET).balanceOf(fresh);
        uint256 sp1 = IStrategy(STRATEGY).sharePrice(VAULT);
        console2.log("processAvailableWithdrawals usedAssets", used);
        console2.log("vault totalAssets before/after", ta0, ta1);
        console2.log("fresh asset bal before/after   ", a0, a1);
        console2.log("sharePrice before/after        ", sp0, sp1);
        assertEq(used, 0, "empty queue: crank is a no-op");
        assertEq(a1, a0, "crank pays the caller nothing");
        assertLe(ta1, ta0, "no value created by cranking");
        assertEq(IAccountableVault(VAULT).totalQueuedShares(), 0, "queue empty");
        assertEq(IAccountableVault(VAULT).reservedLiquidity(), 0, "nothing reserved");
        (uint256 pending, uint256 maxW,,,) = IAccountableVault(VAULT).getState(fresh);
        assertEq(pending, 0);
        assertEq(maxW, 0);
    }

    /* --------------- V5: donations can't inflate accounting --------------- */

    function test_L6_V5_donation_no_inflation() public {
        uint256 ta0 = IAccountableVault(VAULT).totalAssets();
        uint256 sp0 = IStrategy(STRATEGY).sharePrice(VAULT);
        uint256 mgr0 = IERC20(ASSET).balanceOf(MANAGER);
        assertGt(mgr0, 1_000e6, "manager holds aUSD");
        // donate via a real transfer (whitelisted sender; provenance does not matter for the point)
        vm.prank(MANAGER);
        IERC20(ASSET).transfer(VAULT, 1_000e6);
        assertEq(IERC20(ASSET).balanceOf(MANAGER), mgr0 - 1_000e6, "donation landed");
        assertEq(IAccountableVault(VAULT).totalAssets(), ta0, "totalAssets is a stored counter");
        assertEq(IStrategy(STRATEGY).sharePrice(VAULT), sp0, "sharePrice unaffected by donation");
        assertEq(IStrategy(STRATEGY).accruedAssets(VAULT), 0, "no accrued/assets() hook on this strategy");
    }
}
