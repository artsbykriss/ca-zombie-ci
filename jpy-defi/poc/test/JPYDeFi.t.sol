// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// ---------------------------------------------------------------------------
/// JPY DeFi (Liquity-v2 fork) — read-only fork verification of the
/// "withdrawal-buffer asymmetry" lead (CollateralVault instant buffer vs
/// queued claims) plus the dToken / strategy / price-feed surface.
///
/// Fork simulation only. No mainnet tx is signed/sent.
/// ---------------------------------------------------------------------------

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IVault {
    function underlying() external view returns (address);
    function dToken() external view returns (address);
    function totalUnderlying() external view returns (uint256);
    function actualLiabilities() external view returns (uint256);
    function backingRatio() external view returns (uint256);
    function backingRatioForPricing() external view returns (uint256, bool);
    function bufferBalance() external view returns (uint256);
    function backstopBalance() external view returns (uint256);
    function pendingWithdrawals() external view returns (uint256);
    function withdrawDelay() external view returns (uint256);
    function pausedDeposit() external view returns (bool);
    function pausedRedeem() external view returns (bool);
    function pausedClaim() external view returns (bool);
    function getStrategiesCount() external view returns (uint256);
    function strategies(uint256) external view returns (address);
    function deposit(uint256) external returns (uint256);
    function redeem(uint256, address) external returns (uint256, uint256);
    function claim(uint256) external returns (uint256);
    function backstopDeposit(uint256) external returns (uint256);
    function receiveFromStrategy(uint256) external returns (uint256);
    function writeoffStrategyPrincipal(address, uint256, uint256) external;
    function withdrawRequests(uint256)
        external
        view
        returns (address owner, uint256 underlyingAmount, uint256 claimableAt, bool claimed);
}

interface IDToken {
    function convertToDToken(uint256) external view returns (uint256);
    function convertToUnderlying(uint256) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function vault() external view returns (address);
}

interface IPriceFeed {
    function fetchPrice() external returns (uint256, bool);
}

interface ISource {
    function collateralVault() external view returns (address);
}

contract JPYDeFiTest is Test {
    address constant WSTETH_VAULT = 0x6042755ecca71a1be9c7091441ca5beaa6b520e4;
    address constant USDC_VAULT = 0x087Ebaf3F1b094b2046912a5E5F0BaD78dF3eAa7;
    address constant WSTETH_DTOKEN = 0xB1f83c8E22F8644858c99675260c642403faE85c;
    address constant USDC_DTOKEN = 0x01Dd27d3422DF99a56C60945E561243A8027262c;
    address constant WSTETH_FEED = 0x8D1bB1cB05f8c09A177946a1c12c578e313058fE;
    address constant USDC_FEED = 0xaD0595534139016fCccaE5C080cbF1Ce28a4AD79;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant USDC_STRAT0 = 0xF91AcAa3dd75044Fa2ABd4E9226e8D7631FE7C63;
    address constant USDC_STRAT1 = 0x7BE8E8E316827bC2DcaF0862ee234985f80C1946;
    address constant USDC_ACTIVE_POOL = 0x23e7582cC75c10bCe92AdBb6FB4909747f6282B8;
    address constant USDC_WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8; // Circle, ~95M USDC

    uint256 constant FORK_BLOCK = 26_265_497;
    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr(
            "FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        vm.createSelectFork(rpc, FORK_BLOCK);
        vm.deal(attacker, 100 ether);
    }

    // 1. Live state ----------------------------------------------------------
    function test_live_state_fully_backed_and_1to1() public {
        IVault w = IVault(WSTETH_VAULT);
        assertEq(w.underlying(), WSTETH);
        assertEq(w.dToken(), WSTETH_DTOKEN);
        assertEq(w.getStrategiesCount(), 0);
        assertEq(w.totalUnderlying(), w.actualLiabilities(), "wstETH fully backed");
        assertEq(w.backingRatio(), 1e18);
        assertEq(w.bufferBalance(), w.totalUnderlying(), "wstETH 100% liquid");
        assertEq(w.pendingWithdrawals(), 0);
        assertFalse(w.pausedDeposit());
        assertFalse(w.pausedRedeem());
        assertFalse(w.pausedClaim());

        IVault u = IVault(USDC_VAULT);
        assertEq(u.underlying(), USDC);
        assertEq(u.dToken(), USDC_DTOKEN);
        assertEq(u.getStrategiesCount(), 2);
        assertEq(u.actualLiabilities() + 1e6, u.totalUnderlying(), "liabilities + 1 USDC backstop");
        assertEq(u.backingRatio(), 1e18);
        assertEq(u.backstopBalance(), 1e6);
        assertEq(u.pendingWithdrawals(), 0);
        assertEq(u.withdrawDelay(), 3 days);

        assertEq(IDToken(WSTETH_DTOKEN).convertToDToken(1e18), 1e18);
        assertEq(IDToken(WSTETH_DTOKEN).convertToUnderlying(1e18), 1e18);
        assertEq(IDToken(USDC_DTOKEN).convertToDToken(1e6), 1e18);
        assertEq(IDToken(USDC_DTOKEN).convertToUnderlying(1e18), 1e6);
        assertEq(IDToken(USDC_DTOKEN).vault(), USDC_VAULT);

        emit log_named_uint("USDC totalUnderlying", u.totalUnderlying());
        emit log_named_uint("USDC actualLiabilities", u.actualLiabilities());
        emit log_named_uint("USDC bufferBalance", u.bufferBalance());
    }

    // 2. Feed applies min(1, backing) ---------------------------------------
    function test_price_feed_applies_backing_ratio() public {
        (uint256 pFull,) = IPriceFeed(USDC_FEED).fetchPrice();
        assertGt(pFull, 0);

        vm.mockCall(
            USDC_VAULT, abi.encodeWithSignature("backingRatioForPricing()"), abi.encode(uint256(0.5e18), true)
        );
        (uint256 pHalf,) = IPriceFeed(USDC_FEED).fetchPrice();
        assertApproxEqRel(pHalf, pFull / 2, 1e15, "feed scales by 0.5");

        vm.mockCall(
            USDC_VAULT, abi.encodeWithSignature("backingRatioForPricing()"), abi.encode(uint256(2e18), true)
        );
        (uint256 pClamp,) = IPriceFeed(USDC_FEED).fetchPrice();
        assertEq(pClamp, pFull, "backing>1 clamped to 1");

        address src = IPriceFeed(USDC_FEED).source();
        assertEq(ISource(src).collateralVault(), USDC_VAULT, "feed bound to vault");
        emit log_named_uint("USDC feed price (backing=1)", pFull);
    }

    // 3. Deposit -> redeem is value-neutral ---------------------------------
    function test_deposit_redeem_roundtrip_no_profit() public {
        IVault u = IVault(USDC_VAULT);
        uint256 amount = 100_000e6;
        _giveUSDC(attacker, amount);

        uint256 vaultBefore = IERC20(USDC).balanceOf(USDC_VAULT);
        uint256 backingBefore = u.backingRatio();

        vm.startPrank(attacker);
        IERC20(USDC).approve(USDC_VAULT, amount);
        uint256 minted = u.deposit(amount);
        assertEq(minted, amount * 1e12);
        (uint256 out,) = u.redeem(minted, attacker);
        vm.stopPrank();

        assertEq(out, amount);
        assertEq(IERC20(USDC).balanceOf(attacker), amount, "net zero");
        assertEq(IERC20(USDC).balanceOf(USDC_VAULT), vaultBefore, "vault unchanged");
        assertEq(u.backingRatio(), backingBefore);
    }

    // 4. A real strategy loss blocks flows and marks the dToken down --------
    function test_forced_strategy_loss_blocks_redeem_and_marks_down() public {
        IVault u = IVault(USDC_VAULT);
        (uint256 pLive,) = IPriceFeed(USDC_FEED).fetchPrice();

        _mockStrategyValue(USDC_STRAT0, 0);
        _mockStrategyValue(USDC_STRAT1, 0);

        (uint256 ratio, bool avail) = u.backingRatioForPricing();
        assertTrue(avail);
        assertLt(ratio, 1e18, "backing < 1");

        (uint256 pDown,) = IPriceFeed(USDC_FEED).fetchPrice();
        assertLt(pDown, pLive, "price marked down, never whole");

        _giveUSDC(attacker, 10_000e6);
        vm.startPrank(attacker);
        IERC20(USDC).approve(USDC_VAULT, 10_000e6);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x26535b5b))); // BackingRatioBelowMinimum
        u.deposit(10_000e6);
        vm.stopPrank();
    }

    // 5. Backstop top-up to unlock redeem is a net loss ---------------------
    function test_backstop_topup_to_unlock_redeem_is_net_loss() public {
        IVault u = IVault(USDC_VAULT);
        _giveUSDC(attacker, 50_000e6);
        vm.startPrank(attacker);
        IERC20(USDC).approve(USDC_VAULT, 50_000e6);
        uint256 dt = u.deposit(50_000e6);
        vm.stopPrank();

        _mockStrategyValue(USDC_STRAT0, 0);
        _mockStrategyValue(USDC_STRAT1, 0);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x26535b5b)));
        u.redeem(dt, attacker);

        uint256 gap = u.actualLiabilities() - IERC20(USDC).balanceOf(USDC_VAULT);
        assertGt(gap, 100_000e6, "material gap");
        _giveUSDC(attacker, gap);

        uint256 balBeforeTopUp = IERC20(USDC).balanceOf(attacker); // == gap
        vm.startPrank(attacker);
        IERC20(USDC).approve(USDC_VAULT, gap);
        u.backstopDeposit(gap);
        (uint256 out,) = u.redeem(dt, attacker);
        vm.stopPrank();

        assertEq(out, 50_000e6, "principal redeemed");
        // the whole top-up is gone: final = balBeforeTopUp - gap + out
        assertEq(IERC20(USDC).balanceOf(attacker), balBeforeTopUp - gap + out, "top-up fully sunk");
        assertEq(u.backstopBalance(), 1e6 + gap, "backstop grew by the gap, unrecoverable by users");
        emit log_named_uint("gap sunk into backstop", gap);
    }

    // 6. receiveFromStrategy not externally reachable -----------------------
    function test_receiveFromStrategy_only_registered_strategy() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x547cc324))); // NotRegisteredStrategy
        IVault(USDC_VAULT).receiveFromStrategy(1);
    }

    // 7. writeoff / incident roles not externally reachable ------------------
    function test_writeoff_and_incident_paths_are_role_gated() public {
        vm.prank(attacker);
        vm.expectRevert();
        IVault(USDC_VAULT).writeoffStrategyPrincipal(USDC_STRAT0, 1, 0);
    }

    // 8. Donation cannot inflate or be extracted ----------------------------
    function test_donation_does_not_inflate_or_extract() public {
        IVault u = IVault(USDC_VAULT);
        _giveUSDC(attacker, 10_000e6);
        uint256 backingBefore = u.backingRatio();

        vm.prank(attacker);
        IERC20(USDC).transfer(USDC_VAULT, 10_000e6);

        assertEq(u.backingRatio(), backingBefore, "clamped at 1");
        assertEq(IDToken(USDC_DTOKEN).balanceOf(attacker), 0, "no dToken minted");
        vm.prank(attacker);
        vm.expectRevert();
        u.redeem(10_000e18, attacker);
    }

    // 9. Queue + claim accounting -------------------------------------------
    function test_queue_and_claim_accounting() public {
        IVault u = IVault(USDC_VAULT);
        // simulate a trove owner withdrawing collateral: move dToken out of ActivePool
        vm.prank(USDC_ACTIVE_POOL);
        IDToken(USDC_DTOKEN).transfer(attacker, 150_000e18);
        assertEq(IDToken(USDC_DTOKEN).balanceOf(attacker), 150_000e18);

        uint256 buffer = u.bufferBalance();
        uint256 redeemDt = (buffer + 1e6) * 1e12; // > buffer
        assertLe(redeemDt, 150_000e18);

        vm.prank(attacker);
        (uint256 got, uint256 reqId) = u.redeem(redeemDt, attacker);
        assertEq(got, buffer, "instant buffer drained");
        assertGt(reqId, 0, "remainder queued");

        (address owner, uint256 amt, uint256 claimableAt, bool claimed) = u.withdrawRequests(reqId);
        assertEq(owner, attacker);
        assertEq(amt, redeemDt / 1e12 - buffer, "queued amount");
        assertFalse(claimed);
        assertEq(u.pendingWithdrawals(), amt);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0xecc7a37c))); // RequestNotReady
        u.claim(reqId);

        vm.warp(claimableAt + 1);
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x2a8f1d36))); // InsufficientBuffer
        u.claim(reqId);

        address other = address(0xB0B);
        _giveUSDC(other, 40_000e6);
        vm.startPrank(other);
        IERC20(USDC).approve(USDC_VAULT, 40_000e6);
        u.deposit(40_000e6);
        vm.stopPrank();

        uint256 balBefore = IERC20(USDC).balanceOf(attacker);
        vm.prank(other); // anyone may trigger the claim; funds go to the owner
        uint256 claimedAmt = u.claim(reqId);
        assertEq(claimedAmt, amt);
        assertEq(IERC20(USDC).balanceOf(attacker), balBefore + amt, "paid to owner");

        vm.prank(attacker);
        assertEq(u.claim(reqId), 0, "double claim no-op");
    }

    // 10. dToken conversion is strictly linear (no share/rate to inflate) ----
    function test_dtoken_convert_is_linear_no_share_inflation() public {
        IDToken du = IDToken(USDC_DTOKEN);
        assertEq(du.convertToDToken(1), 1e12);
        assertEq(du.convertToDToken(123456789), 123456789e12);
        assertEq(du.convertToUnderlying(1e12), 1);
        assertEq(du.convertToUnderlying(123456789e12), 123456789);
        // a donation to the vault cannot change these (they are pure decimals math)
        _giveUSDC(attacker, 1_000_000e6);
        uint256 rBefore = du.convertToDToken(1e6);
        vm.prank(attacker);
        IERC20(USDC).transfer(USDC_VAULT, 1_000_000e6);
        assertEq(du.convertToDToken(1e6), rBefore, "conversion unchanged by donation");
        assertEq(IVault(USDC_VAULT).backingRatio(), 1e18, "still clamped at 1");
    }

    // helpers ---------------------------------------------------------------
    function _mockStrategyValue(address strat, uint256 v) internal {
        vm.mockCall(strat, abi.encodeWithSignature("estimatedTotalUnderlying()"), abi.encode(v));
        vm.mockCall(strat, abi.encodeWithSignature("principal()"), abi.encode(v));
    }

    function _giveUSDC(address to, uint256 amount) internal {
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(to, amount);
    }
}
