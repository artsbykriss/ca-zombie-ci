// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IVault, IStrategy, IERC20, Unauthorized, TimelockNotExpired} from "../src/Interfaces.sol";

/// @title Valos / AccountableAsyncRedeemVault — live-state + fresh-attacker gate tests (fork only)
/// @notice Read-only fork verification of the Z3-H14 finding. No mainnet transactions.
///         Pinned fork block: 113,775,837 (Monad mainnet, chain id 143).
contract ValosLiveTest is Test {
    address constant VAULT = 0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365;
    address constant STRATEGY = 0x8dCE15fc6a98484C995Fc702cBfBdA14A30454af;
    address constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address constant FRESH = 0x00000000000000000000000000000000000f00D1; // never whitelisted
    address constant FRESH2 = 0x00000000000000000000000000000000000F00d2;
    address constant EULER_EVK = 0xD8ec5b4917FeF9058545e7D1dc2aC17F1D26305D; // whitelisted, holds 75.88M shares
    address constant BORROWER = 0xB83986E9F33a6De4624B18DA69cb474F6f94fc7C; // EOA == investmentManager
    address constant TREASURY = 0x4B07AaA370189E5603DF56C84f59c5A59181BFB1; // 2-of-3 Safe, holds fee shares, NOT whitelisted
    uint256 constant FORK_BLOCK = 113775837;

    IVault vault = IVault(VAULT);
    IStrategy strategy = IStrategy(STRATEGY);

    function _fork() internal {
        // Public, keyless Monad RPCs only. CI has no MONAD_RPC_URL unless set.
        string[3] memory urls = [
            vm.envOr("MONAD_RPC_URL", string("https://rpc.monad.xyz")),
            string("https://monad.drpc.org"),
            string("https://rpc1.monad.xyz")
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i], FORK_BLOCK) {
                return;
            } catch {}
        }
        revert("no working Monad RPC");
    }

    function setUp() public {
        _fork();
    }

    /// 1. Live structural state at the pinned block.
    function test_01_live_state() public {
        assertEq(vault.permissionLevel(), 2, "permissionLevel must be Whitelist(2)");
        assertEq(vault.precision(), 1e36, "precision");
        assertEq(vault.decimals(), 6, "decimals");
        assertEq(strategy.loanState(), 3, "loanState must be OngoingDynamic(3)");
        assertEq(strategy.paused(), false, "strategy not paused");
        assertEq(vault.totalQueuedShares(), 0, "queue empty");
        assertEq(vault.reservedLiquidity(), 0, "no reserved liquidity");
        assertEq(strategy.accruedAssets(VAULT), 0, "accruedAssets==0 (OpenTerm)");
        assertEq(vault.asset(), AUSD, "asset is AUSD");
        assertEq(vault.strategy(), STRATEGY, "strategy link");

        // whitelist gate live
        assertTrue(vault.allowed(EULER_EVK), "Euler EVK whitelisted");
        assertTrue(vault.allowed(BORROWER), "borrower whitelisted");
        assertFalse(vault.allowed(FRESH), "fresh attacker NOT whitelisted");
        assertFalse(vault.allowed(VAULT), "vault itself not whitelisted");

        // idle liquidity is a tiny fraction of TVL
        uint256 idle = vault.totalAssets();
        assertGt(idle, 0);
        assertLt(idle, 20_000e6, "idle < $20k");
        emit log_named_uint("idle AUSD (6dp)", idle);

        // NAV is debt-inclusive and time-driven; sharePrice <= scaleFactor
        uint256 p = vault.sharePrice();
        uint256 s = strategy.scaleFactor();
        assertGt(p, 1e36, "sharePrice > 1");
        assertLe(p, s, "sharePrice <= scaleFactor");
        emit log_named_uint("sharePrice (1e36)", p);
        emit log_named_uint("scaleFactor (1e36)", s);
        emit log_named_uint("totalSupply", vault.totalSupply());
        emit log_named_uint("convertToAssets(totalSupply)", vault.convertToAssets(vault.totalSupply()));

        // treasury holds fee shares but is NOT whitelisted (cannot requestRedeem itself)
        uint256 tbal = vault.balanceOf(TREASURY);
        assertGt(tbal, 0, "treasury holds fee shares");
        assertFalse(vault.allowed(TREASURY), "treasury not whitelisted");
        emit log_named_uint("treasury fee shares", tbal);

        // min redeem ($90k of shares) exceeds all idle liquidity => instant fill impossible today
        assertGt(vault.convertToAssets(90_000e6), idle, "min-size redeem > idle liquidity");
    }

    /// 2. Fresh unprivileged attacker: every value-moving entry point reverts Unauthorized.
    function test_02_fresh_attacker_all_entry_points_revert() public {
        vm.startPrank(FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.deposit(100_000e6, FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.mint(100_000e6, FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.requestRedeem(100_000e6, FRESH, FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.redeem(1e6, FRESH, FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.withdraw(1e6, FRESH, FRESH);

        vm.expectRevert(Unauthorized.selector);
        vault.cancelRedeemRequest(FRESH, FRESH);

        // even a zero-balance transfer is blocked because `to` is not whitelisted
        vm.expectRevert(Unauthorized.selector);
        vault.transfer(FRESH2, 1);

        // cannot self-whitelist through the vault or the strategy
        address[] memory one = new address[](1);
        bool[] memory yes = new bool[](1);
        one[0] = FRESH;
        yes[0] = true;
        vm.expectRevert(Unauthorized.selector);
        vault.setAllowed(one, yes);

        vm.expectRevert(Unauthorized.selector);
        strategy.setLenders(one, yes);

        // cannot call the strategy hooks directly
        vm.expectRevert(Unauthorized.selector);
        strategy.onRequestRedeem(VAULT, 100_000e6, FRESH, FRESH);

        vm.stopPrank();
    }

    /// 3. Permissionless cranks are callable but pay the caller nothing.
    function test_03_permissionless_cranks_no_profit() public {
        uint256 ausd0 = IERC20(AUSD).balanceOf(FRESH);
        uint256 shares0 = vault.balanceOf(FRESH);
        uint256 v0 = vault.totalAssets();

        vm.startPrank(FRESH);
        strategy.accrueInterest();
        strategy.updateLateStatus();
        uint256 used = strategy.processAvailableWithdrawals();
        vm.stopPrank();

        assertEq(used, 0, "no queue -> nothing processed");
        assertEq(IERC20(AUSD).balanceOf(FRESH), ausd0, "crank: no AUSD gained");
        assertEq(vault.balanceOf(FRESH), shares0, "crank: no shares gained");
        assertEq(vault.totalAssets(), v0, "crank: vault assets unchanged");

        // default path is dead (no _defaultValidAt set)
        vm.prank(FRESH);
        vm.expectRevert(TimelockNotExpired.selector);
        strategy.acceptDefault();
    }

    /// 4. Queue path: a whitelisted min-size request queues (no instant fill possible today);
    ///    the permissionless crank converts idle cash into the queued user's claim — at the same
    ///    share price — and the crank caller gains nothing.
    function test_04_queue_settlement_value_neutral_for_caller() public {
        uint256 reqShares = 91_000e6; // > minRedeem (90,000e6)

        // whitelisted holder (Euler EVK) requests redemption
        vm.prank(EULER_EVK);
        uint256 rid = vault.requestRedeem(reqShares, EULER_EVK, EULER_EVK);
        assertGt(rid, 0, "queued (requestId != 0)");
        assertEq(vault.pendingRedeemRequest(0, EULER_EVK), reqShares, "pending shares");
        assertEq(vault.totalQueuedShares(), reqShares, "queue depth");
        assertEq(vault.reservedLiquidity(), 0, "nothing reserved yet");

        // crank caller has no position; run the permissionless crank
        uint256 caller0 = IERC20(AUSD).balanceOf(FRESH);
        vm.prank(FRESH);
        uint256 used = strategy.processAvailableWithdrawals();

        assertGt(used, 0, "idle cash processed into queue claim");
        assertEq(IERC20(AUSD).balanceOf(FRESH), caller0, "crank caller gained nothing");

        // Euler now has a claimable amount, backed by reserved liquidity
        uint256 claimable = vault.maxWithdraw(EULER_EVK);
        assertGt(claimable, 0, "claimable assets credited to queued user");
        assertEq(vault.reservedLiquidity(), claimable, "reserved == claimable");
        emit log_named_uint("processed assets for queue", used);
        emit log_named_uint("claimable for Euler", claimable);

        // queued user can settle: receives AUSD at the strategy share price
        uint256 before = IERC20(AUSD).balanceOf(EULER_EVK);
        uint256 sharesToClaim = vault.maxRedeem(EULER_EVK);
        vm.prank(EULER_EVK);
        uint256 assetsOut = vault.redeem(sharesToClaim, EULER_EVK, EULER_EVK);
        assertEq(IERC20(AUSD).balanceOf(EULER_EVK) - before, assetsOut, "settled at sharePrice");
        emit log_named_uint("Euler received AUSD", assetsOut);
    }

    /// 5. NAV is a pure function of stored state + block.timestamp (no oracle/pool to manipulate);
    ///    round-trips cannot yield a profit (both directions round toward the vault).
    function test_05_nav_time_driven_and_no_roundtrip_gain() public {
        uint256 p0 = vault.sharePrice();
        vm.warp(block.timestamp + 365 days);
        uint256 p1 = vault.sharePrice();
        assertGt(p1, p0, "NAV grows with time (6.75% p.a. linear interest)");
        emit log_named_uint("sharePrice now", p0);
        emit log_named_uint("sharePrice +365d", p1);

        // deposit-side and redeem-side conversions are floor => no round-trip gain
        uint256 assets = 100_000e6;
        uint256 shares = vault.convertToShares(assets);
        assertLe(vault.convertToAssets(shares), assets, "deposit->redeem cannot gain");
        uint256 sh = 95_000e6;
        uint256 a = vault.convertToAssets(sh);
        assertLe(vault.convertToShares(a), sh, "redeem->deposit cannot gain");

        // strategy price == vault price (single price function)
        assertEq(strategy.sharePrice(VAULT), vault.sharePrice(), "strategy.sharePrice == vault.sharePrice");
    }

    /// 6. P-CLASS DEMO (not E-U): the borrower EOA can take the vault's idle cash by design.
    function test_06_p_class_borrower_takes_idle_cash() public {
        uint256 idle = vault.totalAssets();
        uint256 b0 = IERC20(AUSD).balanceOf(BORROWER);

        vm.prank(BORROWER);
        strategy.borrow(idle);

        assertEq(vault.totalAssets(), 0, "vault idle cash released to borrower");
        assertEq(IERC20(AUSD).balanceOf(BORROWER) - b0, idle, "borrower received idle cash");
        emit log_named_uint("P-class idle cash taken by borrower EOA", idle);
    }
}
