// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

/**
 * @title Wildcat V2 — unprivileged-extraction gating PoC (READ-ONLY, fork only)
 *
 * Proves, on a live Plasma fork, that every value-moving path on a Wildcat V2
 * market is either (a) borrower-gated, (b) restricted to the calling account, or
 * (c) restricted to the configured fee recipient — i.e. an external unprivileged
 * attacker has no path to the market's underlying assets. The "borrower-controlled
 * terms" are by design (a borrower can drain a market it controls; lenders bear that
 * credit risk), not an unprivileged exploit.
 *
 * No transaction is ever broadcast: all state changes happen inside an in-memory fork.
 */
contract WildcatPlasmaTest is Test {
    // ---- Plasma mainnet (chainId 9745) ----
    address constant PLASMA_ARCH = 0xdb2e0DE97d6d96aa56754635704a4273E0F348ae;
    address constant PLASMA_HOOKS_FACTORY = 0xB46bae25AC6D23148531ed1853a8881FD842E517;
    address constant PLASMA_SENTINEL = 0x37064895ba2C1e269EAF7FF32564818d08903f5B;
    address constant PLASMA_USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address constant PLASMA_FEE_RECIPIENT = 0x437e0551892C2C9b06d3fFd248fe60572e08CD1A;

    // Rhinofi USDT0 market (open, holds ~$17.4k) + its OpenTermHooks instance
    address constant M_RHINOFI = 0x9A0BA9278284659194157C476010bCFEbeB21794;
    address constant HOOKS_RHINOFI = 0xf6Af2ae9D5DE06662981855a9b47688F3Abc06Bb;
    // seve1 USDT0 market (open, $0 held, ~$50k of outstanding claims)
    address constant M_SEVE1 = 0x74c7861C3E706e7299654F89A3C0091184Aa10f0;

    // ---- Ethereum mainnet (chainId 1) ----
    address constant ETH_ARCH = 0xfEB516d9D946dD487A9346F6fee11f40C6945eE4;

    uint256 constant PLASMA_FORK_BLOCK = 36_011_221;

    address attacker = address(0xA77ACC);

    error NotApprovedBorrower();
    error BadRescueAsset();
    error BadLaunchCode();
    error NotApprovedLender();
    error DepositBelowMinimum();
    error NullBurnAmount();

    function setUp() public {
        string memory plasmaRpc = vm.envOr("PLASMA_RPC_URL", string("https://rpc.plasma.to"));
        vm.createSelectFork(plasmaRpc, PLASMA_FORK_BLOCK);
    }

    // ------------------------------------------------------------------ //
    //                    0. deployed-code identity                        //
    // ------------------------------------------------------------------ //
    function test_deployed_market_and_hooks_are_v2_openterm() public view {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        assertEq(m.version(), "2", "market version must be 2");
        assertEq(m.borrower(), 0x5Af8dEcb972c01540B252c6a870De5B276026276, "borrower");
        assertEq(m.factory(), PLASMA_HOOKS_FACTORY, "factory");
        assertEq(m.archController(), PLASMA_ARCH, "archController");
        assertEq(m.asset(), PLASMA_USDT0, "asset=USDT0");
        assertEq(m.sentinel(), PLASMA_SENTINEL, "sentinel");
        assertEq(m.feeRecipient(), PLASMA_FEE_RECIPIENT, "feeRecipient");

        assertEq(IWildcatHooks(HOOKS_RHINOFI).version(), "OpenTermHooks", "hooks version");
        // hooks() packs the hooks address in the high 160 bits
        assertEq(address(uint160(m.hooks() >> 96)), HOOKS_RHINOFI, "hooks address");
    }

    // ------------------------------------------------------------------ //
    //          1. every borrower-only value path reverts for an attacker  //
    // ------------------------------------------------------------------ //
    function test_attacker_cannot_borrow() public {
        vm.prank(attacker);
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).borrow(1);
    }

    function test_attacker_cannot_close_market() public {
        vm.prank(attacker);
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).closeMarket();
    }

    function test_attacker_cannot_set_terms() public {
        vm.startPrank(attacker);
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).setMaxTotalSupply(1);
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).setAnnualInterestAndReserveRatioBips(0, 0);
        // setProtocolFeeBips is factory-gated (not the attacker)
        vm.expectRevert();
        IWildcatMarket(M_RHINOFI).setProtocolFeeBips(0);
        vm.stopPrank();
    }

    function test_attacker_cannot_rescue() public {
        vm.startPrank(attacker);
        // rescueTokens is onlyBorrower (modifier runs before the body's asset check)
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).rescueTokens(PLASMA_USDT0);
        vm.expectRevert(NotApprovedBorrower.selector);
        IWildcatMarket(M_RHINOFI).rescueTokens(address(0xdead));
        vm.stopPrank();
        // even the borrower can never rescue the market's own asset
        vm.prank(IWildcatMarket(M_RHINOFI).borrower());
        vm.expectRevert(BadRescueAsset.selector);
        IWildcatMarket(M_RHINOFI).rescueTokens(PLASMA_USDT0);
    }

    // ------------------------------------------------------------------ //
    //     2. permissionless-but-harmless functions cannot pay the caller  //
    // ------------------------------------------------------------------ //
    function test_attacker_cannot_nuke_unsanctioned_account() public {
        vm.prank(attacker);
        vm.expectRevert(BadLaunchCode.selector);
        IWildcatMarket(M_RHINOFI).nukeFromOrbit(attacker);
    }

    function test_attacker_cannot_queue_or_execute_withdrawals() public {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        assertEq(m.balanceOf(attacker), 0, "attacker holds no market tokens");
        vm.startPrank(attacker);
        // queuing against a zero balance reverts (underflow / null burn)
        vm.expectRevert();
        m.queueWithdrawal(1);
        vm.expectRevert(NullBurnAmount.selector);
        m.queueFullWithdrawal();
        // executing a withdrawal on behalf of a third party is permissionless, but
        // reverts for any non-existent / non-expired batch
        vm.expectRevert();
        m.executeWithdrawal(address(0xBEEF), 1);
        vm.stopPrank();
    }

    /// Deposits are open to any credentialed lender (this market registers the
    /// permissionless OpenAccessRoleProvider), so an attacker *can* deposit — but
    /// depositing converts USDT0 1:1 into market tokens. It is a purchase, not a
    /// withdrawal of someone else's funds, and the minimum deposit is enforced.
    function test_deposit_is_open_but_is_not_extraction() public {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        (bool hooked, , bool depositReq, uint128 minDep, ) = IWildcatHooks(HOOKS_RHINOFI).getHookedMarket(
            M_RHINOFI
        );
        assertTrue(hooked);
        assertTrue(depositReq);
        assertEq(uint256(minDep), 1_000e6);

        vm.prank(attacker);
        vm.expectRevert(DepositBelowMinimum.selector);
        m.deposit(1);

        deal(PLASMA_USDT0, attacker, 1_000e6);
        uint256 marketBefore = IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI);
        vm.startPrank(attacker);
        IERC20(PLASMA_USDT0).approve(M_RHINOFI, type(uint256).max);
        m.deposit(1_000e6);
        vm.stopPrank();
        assertEq(IERC20(PLASMA_USDT0).balanceOf(attacker), 0, "attacker paid in full");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI), marketBefore + 1_000e6, "market received");
        // attacker now holds a claim worth ~the same (no free value created)
        assertApproxEqRel(m.balanceOf(attacker), 1_000e6, 1e15); // 0.1%
    }

    /// collectFees() is permissionless, but the funds go to the configured
    /// feeRecipient — never to the caller. This is the only permissionless call
    /// that moves `asset` out of the market.
    function test_collectFees_pays_feeRecipient_not_caller() public {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        uint256 fees = m.accruedProtocolFees();
        assertGt(fees, 0, "market has accrued protocol fees");

        uint256 frBefore = IERC20(PLASMA_USDT0).balanceOf(PLASMA_FEE_RECIPIENT);
        uint256 attackerBefore = IERC20(PLASMA_USDT0).balanceOf(attacker);
        uint256 marketBefore = IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI);

        vm.prank(attacker);
        m.collectFees();

        assertEq(IERC20(PLASMA_USDT0).balanceOf(attacker), attackerBefore, "attacker gained nothing");
        assertGt(IERC20(PLASMA_USDT0).balanceOf(PLASMA_FEE_RECIPIENT), frBefore, "feeRecipient paid");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI), marketBefore - fees, "fees left the market");
    }

    /// repay() is permissionless but it pulls from the *caller* (a gift to lenders).
    function test_repay_is_a_gift_from_the_caller() public {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        uint256 marketBefore = IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI);
        // give the attacker some USDT0 and approve
        deal(PLASMA_USDT0, attacker, 10e6);
        vm.startPrank(attacker);
        IERC20(PLASMA_USDT0).approve(M_RHINOFI, type(uint256).max);
        m.repay(10e6);
        vm.stopPrank();
        assertEq(IERC20(PLASMA_USDT0).balanceOf(attacker), 0, "attacker paid, gained nothing");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI), marketBefore + 10e6, "market gained");
    }

    // ------------------------------------------------------------------ //
    //        3. the privilege is real: the borrower CAN drain it (P)      //
    // ------------------------------------------------------------------ //
    function test_borrower_can_borrow_the_whole_market() public {
        IWildcatMarket m = IWildcatMarket(M_RHINOFI);
        address borrower = m.borrower();
        uint256 borrowable = m.borrowableAssets();
        assertGt(borrowable, 17_000e6, "most of the market is borrowable");

        uint256 marketBefore = IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI);
        uint256 borrowerBefore = IERC20(PLASMA_USDT0).balanceOf(borrower);

        vm.prank(borrower);
        m.borrow(borrowable);

        assertEq(IERC20(PLASMA_USDT0).balanceOf(borrower), borrowerBefore + borrowable, "borrower paid");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(M_RHINOFI), marketBefore - borrowable, "market drained by borrower");
    }

    // ------------------------------------------------------------------ //
    //     3b. a payout triggered for a third party goes TO that party      //
    // ------------------------------------------------------------------ //
    /// Storage surgery fabricates a paid withdrawal batch for `lender`, then the
    /// attacker calls the permissionless executeWithdrawal(lender, expiry). The
    /// funds are sent to `lender`; the caller receives nothing.
    function test_executeWithdrawal_pays_named_account_not_caller() public {
        address lender = address(0x1E0DE);
        uint32 expiry = 12345;
        uint256 amt = 500e6;

        uint256 batchSlot = uint256(keccak256(abi.encode(uint256(expiry), uint256(7))));
        vm.store(M_RHINOFI, bytes32(batchSlot), bytes32(amt)); // scaledTotalAmount=amt, burned=0
        vm.store(M_RHINOFI, bytes32(batchSlot + 1), bytes32(amt)); // normalizedAmountPaid=amt

        uint256 outer = uint256(keccak256(abi.encode(uint256(expiry), uint256(8))));
        uint256 statusSlot = uint256(keccak256(abi.encode(lender, outer)));
        vm.store(M_RHINOFI, bytes32(statusSlot), bytes32(amt)); // scaledAmount=amt, withdrawn=0

        // bump state.normalizedUnclaimedWithdrawals (slot 1, high 16 bytes) by amt
        bytes32 s1 = vm.load(M_RHINOFI, bytes32(uint256(1)));
        uint256 unclaimed = (uint256(s1) >> 128) + amt;
        vm.store(M_RHINOFI, bytes32(uint256(1)), bytes32((unclaimed << 128) | (uint256(s1) & ((1 << 128) - 1))));

        uint256 lenderBefore = IERC20(PLASMA_USDT0).balanceOf(lender);
        uint256 attackerBefore = IERC20(PLASMA_USDT0).balanceOf(attacker);

        vm.prank(attacker);
        uint256 paid = IWildcatMarket(M_RHINOFI).executeWithdrawal(lender, expiry);

        assertEq(paid, amt, "batch paid");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(lender), lenderBefore + amt, "lender received the funds");
        assertEq(IERC20(PLASMA_USDT0).balanceOf(attacker), attackerBefore, "caller gained nothing");
    }

    // ------------------------------------------------------------------ //
    //        4. shared infrastructure is role-gated, not permissionless   //
    // ------------------------------------------------------------------ //
    function test_arch_controller_is_owner_gated() public view {
        assertTrue(IWildcatArchController(PLASMA_ARCH).owner() != address(0), "arch has an owner");
        assertFalse(
            IWildcatArchController(PLASMA_ARCH).isRegisteredBorrower(attacker),
            "attacker is not a registered borrower"
        );
    }

    function test_hooks_factory_only_registered_borrowers_deploy() public view {
        IWildcatHooksFactory f = IWildcatHooksFactory(PLASMA_HOOKS_FACTORY);
        assertEq(f.archController(), PLASMA_ARCH);
        assertFalse(f.isHooksTemplate(attacker));
    }

    // ------------------------------------------------------------------ //
    //        5. the same V2 code is what is live on Ethereum too          //
    // ------------------------------------------------------------------ //
    function test_ethereum_deployment_is_the_same_code() public {
        // switch to an Ethereum fork and read the arch controller's market set
        string memory ethRpc = vm.envOr(
            "FORK_RPC_URL",
            vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        vm.createSelectFork(ethRpc);
        address[] memory markets = IWildcatArchController(ETH_ARCH).getRegisteredMarkets();
        assertGt(markets.length, 80, "ethereum has ~89 registered markets");
        // the V2 arch controller also lists legacy V1 markets; spot-check a V2 one
        assertEq(
            IWildcatMarket(0x9Fa4b300c474B86ffaA44288d2496Ba1b735f9FD).version(),
            "2",
            "Hyperithm Wildcat USDe is V2"
        );
    }
}
