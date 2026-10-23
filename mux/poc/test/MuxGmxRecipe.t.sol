// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IMuxOrderBook, IMuxLiquidityPool, IMyxPool, IERC20, IWETH, PositionOrderExtra} from "../src/Interfaces.sol";
import {
    IMux3OrderBook,
    IMux3CollateralPool,
    ICallbackRegister,
    Mux3AddLiquidityArgs,
    Mux3RemoveLiquidityArgs
} from "../src/Interfaces.sol";

/// A malicious contract used as a MUX sub-account owner (the GMX-v1 "contract as order account" shape).
/// It re-enters the OrderBook from its ETH receive() callback, i.e. from inside the token transfer
/// that happens while the protocol holds mid-update state.
contract ReentrancyProbe {
    IMuxOrderBook public ob;
    bytes32 public subAccountId;

    bool public reentryAttempted;
    bool public reentryOk;

    constructor(IMuxOrderBook _ob) {
        ob = _ob;
    }

    function setSubAccount(bytes32 id) external {
        subAccountId = id;
    }

    function doDeposit(uint256 amt) external payable {
        ob.depositCollateral{value: amt}(subAccountId, amt);
    }

    function doWithdrawAll() external {
        ob.withdrawAllCollateral(subAccountId);
    }

    receive() external payable {
        reentryAttempted = true;
        (bool ok, ) = address(ob).call(
            abi.encodeWithSelector(IMuxOrderBook.withdrawAllCollateral.selector, subAccountId)
        );
        reentryOk = ok;
    }
}

contract MuxGmxRecipeTest is Test {
    // ---- Arbitrum mainnet addresses (MUX Leveraged Trading Protocol) ----
    IMuxOrderBook constant OB = IMuxOrderBook(0xa19fD5aB6C8DCffa2A295F78a5Bb4aC543AAF5e3); // OrderBook (TransparentProxy)
    IMuxLiquidityPool constant POOL = IMuxLiquidityPool(0x3e0199792Ce69DC29A0a36146bFa68bd7C8D6633); // LiquidityPool (chained proxy)
    IMyxPool constant MYX_POOL = IMyxPool(0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851); // <- pass5 "MUX Pool" is actually MYX Protocol's Pool impl

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // assetId 3
    address constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // assetId 0
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // assetId 1
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; // assetId 4
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548; // assetId 10

    address constant ATTACKER = address(0xBAd0000000000000000000000000000000000Bad);
    uint256 constant FORK_BLOCK = 517_471_662; // pinned Arbitrum block (2026-10-23)

    function setUp() public {
        string memory rpc = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            rpc = vm.envOr("ARBITRUM_RPC_URL", string(""));
        }
        if (bytes(rpc).length == 0) {
            rpc = "https://arb1.arbitrum.io/rpc";
        }
        // Fork at latest: keyless public RPCs do not serve deep-archive state.
        // The exact block is asserted/logged in test_live_state.
        vm.createSelectFork(rpc);
    }

    function _subAccount(address owner, uint8 collateralId, uint8 assetId, bool isLong) internal pure returns (bytes32) {
        return bytes32(
            (uint256(uint160(owner)) << 96) | (uint256(collateralId) << 88) | (uint256(assetId) << 80) | (isLong ? (uint256(1) << 72) : 0)
        );
    }

    // ------------------------------------------------------------------
    // 1. Live state
    // ------------------------------------------------------------------
    function test_live_state() public {
        emit log_named_uint("arb_fork_block", block.number);
        emit log_named_uint("orderBook.getOrderCount", OB.getOrderCount());
        emit log_named_address("orderBook.owner", OB.owner());
        emit log_named_address("orderBook.maintainer", OB.maintainer());
        emit log_named_string("orderBook.brokers[attacker]", OB.brokers(ATTACKER) ? "true" : "false");
        emit log_named_string("isPositionOrderPaused", OB.isPositionOrderPaused() ? "true" : "false");
        emit log_named_string("isLiquidityOrderPaused", OB.isLiquidityOrderPaused() ? "true" : "false");

        emit log_named_uint("pool USDC.e", IERC20(USDCE).balanceOf(address(POOL)));
        emit log_named_uint("pool USDT", IERC20(USDT).balanceOf(address(POOL)));
        emit log_named_uint("pool WETH", IERC20(WETH).balanceOf(address(POOL)));
        emit log_named_uint("pool WBTC", IERC20(WBTC).balanceOf(address(POOL)));
        emit log_named_uint("pool ARB", IERC20(ARB).balanceOf(address(POOL)));

        emit log_named_uint("MYX pool positionManager", uint160(MYX_POOL.positionManager()));
        emit log_named_uint("MYX pool feeCollector", uint160(MYX_POOL.feeCollector()));
        emit log_named_uint("MYX pool pairsIndex", MYX_POOL.pairsIndex());

        assertEq(OB.brokers(ATTACKER), false, "attacker must not be a broker");
        assertEq(uint160(MYX_POOL.positionManager()), 0, "MYX pool uninitialized");
    }

    // ------------------------------------------------------------------
    // 2. GMX-v1 precondition A: a PUBLIC, unprivileged order-execution entry point.
    //    Every execution/fill path is `onlyBroker`.
    // ------------------------------------------------------------------
    function test_fill_position_not_public() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BKR"));
        OB.fillPositionOrder(0, 1e18, 1e18, 1e18);
    }

    function test_fill_liquidity_not_public() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BKR"));
        OB.fillLiquidityOrder(0, 1e18, 1e18, 0, 0);
    }

    function test_fill_withdrawal_not_public() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BKR"));
        OB.fillWithdrawalOrder(0, 1e18, 1e18, 1e18);
    }

    function test_liquidate_not_public() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BKR"));
        OB.liquidate(bytes32(uint256(1)), 0, 1e18, 1e18, 1e18);
    }

    // ------------------------------------------------------------------
    // 3. GMX-v1 precondition B: the attacker must be able to mutate the pool's
    //    average-price / total-size state (the thing GMX's recipe manipulated).
    //    openPosition/closePosition/liquidate are `onlyOrderBook`.
    // ------------------------------------------------------------------
    function test_pool_openPosition_only_orderbook() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BOK"));
        POOL.openPosition(bytes32(uint256(1)), 1e18, 1e18, 1e18);
    }

    function test_pool_closePosition_only_orderbook() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BOK"));
        POOL.closePosition(bytes32(uint256(1)), 1e18, 0, 1e18, 1e18, 1e18);
    }

    function test_pool_liquidate_only_orderbook() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("BOK"));
        POOL.liquidate(bytes32(uint256(1)), 0, 1e18, 1e18, 1e18);
    }

    // ------------------------------------------------------------------
    // 4. Admin gates: attacker cannot self-grant broker / aggregator / callback-whitelist.
    // ------------------------------------------------------------------
    function test_addBroker_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("S!M"));
        OB.addBroker(ATTACKER);
    }

    function test_setAggregator_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert(); // OwnableUpgradeable: caller is not the owner
        OB.setAggregator(ATTACKER, true);
    }

    function test_setCallbackWhitelist_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        OB.setCallbackWhitelist(ATTACKER, true);
    }

    function test_pause_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("S!M"));
        OB.pause(true, true);
    }

    // ------------------------------------------------------------------
    // 5. Real re-entrancy test: a contract sub-account owner receives ETH while the
    //    protocol is mid-`withdrawAllCollateral`, and re-enters from receive().
    //    The pool zeroes the sub-account collateral BEFORE the external transfer,
    //    so the re-entry reverts "C=0" and no double-withdraw is possible.
    // ------------------------------------------------------------------
    function test_reentrancy_no_double_withdraw() public {
        ReentrancyProbe probe = new ReentrancyProbe(OB);
        bytes32 id = _subAccount(address(probe), 3, 3, true); // collateralId=3 (WETH), assetId=3 (ETH)
        probe.setSubAccount(id);

        vm.deal(address(probe), 1 ether);
        probe.doDeposit{value: 0.05 ether}(0.05 ether);

        (uint96 collBefore, uint96 sizeBefore, , , ) = POOL.getSubAccount(id);
        assertEq(sizeBefore, 0, "no position");
        assertGt(collBefore, 0, "collateral deposited");

        uint256 ethBefore = address(probe).balance;
        uint256 wethBefore = IERC20(WETH).balanceOf(address(probe));
        probe.doWithdrawAll();
        uint256 gained = (address(probe).balance - ethBefore) + (IERC20(WETH).balanceOf(address(probe)) - wethBefore);

        // The callback either ran and was rejected, or never ran because the
        // NativeUnwrapper caps the ETH callback at 50k gas. Either way: exactly one payout.
        emit log_named_string("callback body executed", probe.reentryAttempted() ? "yes" : "no (50k gas cap)");
        emit log_named_uint("probe payout (wei, ETH+WETH)", gained);
        assertFalse(probe.reentryOk(), "re-entry must not succeed");
        assertEq(gained, 0.05 ether, "exactly one payout - no double withdraw");

        // Second, explicit withdraw of the same sub-account must revert (collateral already zeroed).
        vm.expectRevert(bytes("C=0"));
        probe.doWithdrawAll();
    }

    // ------------------------------------------------------------------
    // 6. Signed-fee path: the pass5 "MUX Pool" (0x45de...) is MYX Protocol's Pool
    //    *implementation*, uninitialised and unfunded. Every signed-fee setter is
    //    role-gated; an unprivileged caller reverts.
    // ------------------------------------------------------------------
    function test_myx_signed_fee_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("opmof"));
        MYX_POOL.setLPStableProfit(1, -1);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("only fc"));
        MYX_POOL.givebackTradingFee(1, 1);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("opm"));
        MYX_POOL.updateAveragePrice(1, 1);
    }

    // The *live* MYX Pool (Arbitrum) is 0x8932aA60..., not the 0x45de... impl named by pass5.
    function test_myx_live_pool_signed_fee_gated() public {
        IMyxPool live = IMyxPool(0x8932aA60A7b5EfEFA8Ec3ee899Fd238D029d10c6);
        assertTrue(live.positionManager() != address(0), "MYX live pool is initialized");
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("opmof"));
        live.setLPStableProfit(1, -1);
    }

    // ------------------------------------------------------------------
    // 7. MUX3 (perps v3) — where the $8.6M collateral actually sits.
    //    The MUX3 OrderBook fill is broker-gated and nonReentrant; the collateral
    //    pools' fund-moving functions are onlyOrderBook/onlyCore; callbacks are
    //    restricted to the registered tranche proxies.
    // ------------------------------------------------------------------
    IMux3OrderBook constant MUX3_OB = IMux3OrderBook(0x8ec387586a709ECE1a9Ea83c6163c3616D8E16b4);
    IMux3CollateralPool constant MUX3_CP = IMux3CollateralPool(0x13BB10542Aa9C0792d6FFe56bf123cE20A159A20);
    ICallbackRegister constant CB_REG = ICallbackRegister(0xd2Df81619E20C6699B7f2153f8A2395e5Bb2C74C);

    function test_mux3_fill_position_not_public() public {
        vm.prank(ATTACKER);
        vm.expectRevert(); // AccessControl: missing BROKER_ROLE
        MUX3_OB.fillPositionOrder(1);
    }

    function test_mux3_callback_not_registered_for_attacker() public {
        assertFalse(CB_REG.isCallbackRegistered(ATTACKER), "attacker not a registered callback");
    }

    function test_mux3_collateral_pool_addLiquidity_gated() public {
        Mux3AddLiquidityArgs memory a = Mux3AddLiquidityArgs({account: ATTACKER, rawCollateralAmount: 1, isUnwrapWeth: false});
        vm.prank(ATTACKER);
        vm.expectRevert(); // custom error UnauthorizedCaller(address)
        MUX3_CP.addLiquidity(a);
    }

    function test_mux3_collateral_pool_removeLiquidity_gated() public {
        Mux3RemoveLiquidityArgs memory a =
            Mux3RemoveLiquidityArgs({account: ATTACKER, shares: 1, token: WETH, isUnwrapWeth: true, extraFeeCollateral: 0});
        vm.prank(ATTACKER);
        vm.expectRevert(); // custom error UnauthorizedCaller(address)
        MUX3_CP.removeLiquidity(a);
    }
}
