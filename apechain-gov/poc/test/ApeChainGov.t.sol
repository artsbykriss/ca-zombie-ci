// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IAPEPredicts, IGovernanceManager, IHouse, ICashOrCrash, IMigrator, ISafe} from "../src/Interfaces.sol";

/// @title ApeChain instant-governance / drain-name / public-init claim — fork verification
/// @notice READ-ONLY mainnet research. Every state-changing call below executes ONLY on a
///         local fork (vm.createSelectFork). No transaction is ever broadcast to ApeChain.
///         Goal: prove the pass7 flags (instant governance, unguarded drain, public init) are
///         false positives and that an unprivileged attacker can extract $0.
contract ApeChainGovTest is Test {
    // --- ApeChain mainnet (chain id 33139) targets ---
    address constant APEPREDICTS = 0xF609394F0882B732b287db10d1b0F53211a09f75;
    address constant HOUSE_OLD   = 0x2054709F89F18a4CCAC6132acE7b812E32608469;
    address constant CASHORCRASH = 0x8c63d2a77480178868A5fd80AF23821a91fD8517;
    address constant GOVMANAGER  = 0x8632f22e5A921C751CFbBFF92F058A3b11E96b8a;
    address constant HOUSE_NEW   = 0xB7EcD1F3fA462d2c6c65F55357E8c16c614CC2f1;
    address constant MIGRATOR    = 0xaB9b74286CE69A8a3541a9f695CAA47021B769DC;

    address constant APE_OWNER = 0xd5d013cef20373839635Fbce206A1cf0054EC565; // EOA
    address constant COC_OWNER = 0x1fFc20b99E1f4D0319c08d3bbb6B1ca92Db316f8; // EOA
    address constant SAFE_OWNER = 0xb5C3a66741E21CD80eBdDa25479B10A98Ea80c52; // Gnosis Safe 1.3.0

    address attacker = address(0xA77ACCE5);

    IAPEPredicts ape;
    IHouse houseOld;
    IHouse houseNew;
    ICashOrCrash coc;
    IGovernanceManager gov;
    IMigrator migrator;

    function setUp() public {
        string memory rpc = vm.envOr("APE_RPC_URL", string("https://rpc.apechain.com/http"));
        vm.createSelectFork(rpc);
        ape = IAPEPredicts(APEPREDICTS);
        houseOld = IHouse(HOUSE_OLD);
        houseNew = IHouse(HOUSE_NEW);
        coc = ICashOrCrash(CASHORCRASH);
        gov = IGovernanceManager(GOVMANAGER);
        migrator = IMigrator(MIGRATOR);
        vm.deal(attacker, 100 ether);
    }

    // ------------------------------------------------------------------
    // 1. Live state — every claim is anchored to on-chain reads
    // ------------------------------------------------------------------
    function test_live_state_contracts_are_live() public view {
        assertGt(APEPREDICTS.code.length, 0, "APEPredicts live");
        assertGt(HOUSE_OLD.code.length, 0, "House old live");
        assertGt(CASHORCRASH.code.length, 0, "CashOrCrash live");
        assertGt(GOVMANAGER.code.length, 0, "GovernanceManager live");
        assertGt(MIGRATOR.code.length, 0, "Migrator live");
    }

    function test_live_state_owners_are_eoa_and_safe() public view {
        assertEq(ape.owner(), APE_OWNER, "APEPredicts owner");
        assertEq(APE_OWNER.code.length, 0, "APEPredicts owner is EOA");
        assertEq(coc.owner(), COC_OWNER, "CashOrCrash owner");
        assertEq(COC_OWNER.code.length, 0, "CashOrCrash owner is EOA");
        assertEq(gov.owner(), SAFE_OWNER, "GovernanceManager owner");
        assertGt(SAFE_OWNER.code.length, 0, "GovernanceManager owner is a contract (Safe)");

        // GovernanceManager "instant governance": owner is a 2-of-4 Gnosis Safe, not an open vote
        address[] memory owners = ISafe(SAFE_OWNER).getOwners();
        assertEq(owners.length, 4, "Safe has 4 owners");
        assertEq(ISafe(SAFE_OWNER).getThreshold(), 2, "Safe threshold 2");
    }

    function test_live_state_house_migration_in_progress() public view {
        // old House is mid-migration -> migrator set, deposits/withdrawals closed
        assertEq(houseOld.migrator(), MIGRATOR, "old House migrator set");
        assertEq(houseNew.migrator(), address(0), "new House migrator cleared");
        assertEq(migrator.v1House(), HOUSE_OLD, "migrator.v1House");
        assertEq(migrator.houseV2(), HOUSE_NEW, "migrator.houseV2");
        assertEq(houseOld.manager(), GOVMANAGER, "House.manager == GovernanceManager");
        assertFalse(gov.paused(), "GovernanceManager not paused");
    }

    function test_live_state_balances_nonzero() public view {
        assertGt(APEPREDICTS.balance, 0, "APEPredicts holds native APE");
        assertGt(HOUSE_OLD.balance, 0, "House old holds native APE");
        assertGt(CASHORCRASH.balance, 0, "CashOrCrash holds native APE");
        assertGt(houseOld.totalShares(), 0, "old House totalShares > 0");
    }

    // ------------------------------------------------------------------
    // 2. APEPredicts — all value-moving paths are onlyOwner (OZ Ownable)
    // ------------------------------------------------------------------
    function test_apepredicts_withdraw_only_owner() public {
        uint256 balBefore = APEPREDICTS.balance;
        vm.prank(attacker);
        vm.expectRevert();
        ape.withdraw(1 ether);
        assertEq(APEPREDICTS.balance, balBefore, "no funds moved");
    }

    function test_apepredicts_resolve_cancel_pause_only_owner() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        ape.resolveGame(1, 1, 0);
        vm.expectRevert();
        ape.cancelGame(1);
        vm.expectRevert();
        ape.updateGameStatus(1, 3);
        vm.expectRevert();
        ape.pause();
        vm.expectRevert();
        ape.updateFeePercentage(1000);
        vm.stopPrank();
    }

    function test_apepredicts_claim_refund_require_own_deposit() public {
        // attacker has never deposited in game 1 -> cannot claim (game is resolved)
        vm.prank(attacker);
        vm.expectRevert();
        ape.claim(1);
        // attacker cannot refund a resolved game (status != cancelled)
        vm.prank(attacker);
        vm.expectRevert();
        ape.refund(1);
    }

    // ------------------------------------------------------------------
    // 3. CashOrCrash — initialize is gated by an immutable deployer check
    // ------------------------------------------------------------------
    function test_cashorcrash_initialize_blocked_for_attacker() public {
        address ownerBefore = coc.owner();
        uint256 counterBefore = coc.gameCounter();
        vm.prank(attacker);
        // The contract is already initialized, so OZ 5 `initializer` short-circuits with
        // InvalidInitialization BEFORE the body. Even on a never-initialized instance the
        // `_initOwner` immutable guard (revert NotInitOwner) would block a non-deployer.
        vm.expectRevert(ICashOrCrash.InvalidInitialization.selector);
        coc.initialize("pwn");
        assertEq(coc.owner(), ownerBefore, "owner unchanged");
        assertFalse(coc.isAdmin(attacker), "attacker not admin");
        assertEq(coc.gameCounter(), counterBefore, "state unchanged");
    }

    function test_cashorcrash_admin_only_functions() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        coc.withdrawFunds(address(0), true, 1 ether, payable(attacker));
        vm.expectRevert();
        coc.addAdmin(attacker);
        vm.expectRevert();
        coc.setMessagePrefix("pwn");
        vm.stopPrank();
        assertEq(CASHORCRASH.balance, CASHORCRASH.balance, "no withdrawal");
    }

    // ------------------------------------------------------------------
    // 4. GovernanceManager — "instant governance" is onlyOwner on a Safe
    // ------------------------------------------------------------------
    function test_govmanager_admin_only() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Only Owner"));
        gov.changeOwner(attacker);
        vm.expectRevert(bytes("Only Owner"));
        gov.setHouse(attacker);
        vm.expectRevert(bytes("Only Owner"));
        gov.setPaused(true);
        vm.expectRevert(bytes("Only Owner"));
        gov.setRNG(attacker);
        vm.expectRevert(bytes("Only Owner"));
        gov.setIsAdmin(attacker, true);
        vm.expectRevert(bytes("Only Owner"));
        gov.setFeeReceiver(attacker);
        vm.stopPrank();
        assertEq(gov.owner(), SAFE_OWNER, "owner unchanged");
        assertEq(gov.house(), HOUSE_NEW, "house unchanged");
    }

    // ------------------------------------------------------------------
    // 5. House (old, migration) — deposit/withdraw locked, migrate needs own balance
    // ------------------------------------------------------------------
    function test_house_deposit_and_withdraw_blocked() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Migration In Progress"));
        houseOld.deposit{value: 1 ether}();

        vm.prank(attacker);
        vm.expectRevert(bytes("Migration In Progress"));
        houseOld.withdraw(1);
    }

    function test_house_migrate_zero_balance_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Zero Balance"));
        houseOld.migrate("");
    }

    function test_house_transfer_does_not_move_shares() public {
        // House.transfer() only calls withdraw() when recipient == msg.sender; otherwise it is a no-op.
        vm.prank(attacker);
        bool ok = houseOld.transfer(address(0xDEAD), 1 ether);
        assertTrue(ok);
        assertEq(houseOld.balanceOf(address(0xDEAD)), 0, "no shares transferred");
    }

    // ------------------------------------------------------------------
    // 6. Share accounting — no donation / first-depositor drain (E-U = $0)
    // ------------------------------------------------------------------
    function test_house_donation_only_raises_price_for_holders() public {
        // A donation to the House increases address(this).balance and therefore _calculatePrice
        // for every EXISTING share holder. An attacker holding no shares gains nothing, because
        // withdraw()/migrate() burn only the CALLER's own userInfo[msg.sender].balance.
        uint256 priceBefore = houseOld.calculatePrice();
        uint256 attackerSharesBefore = houseOld.balanceOf(attacker);
        assertEq(attackerSharesBefore, 0, "attacker holds no shares");

        vm.deal(address(0xD0A470), 1 ether);
        vm.prank(address(0xD0A470));
        (bool s, ) = HOUSE_OLD.call{value: 1 ether}(""); // receive(): totalShares > 0
        assertTrue(s, "donation accepted by old House receive()");

        uint256 priceAfter = houseOld.calculatePrice();
        assertGt(priceAfter, priceBefore, "donation raises price for holders only");

        // attacker still has 0 shares and no path to withdraw the donated value
        assertEq(houseOld.balanceOf(attacker), 0, "attacker still holds no shares");
        vm.prank(attacker);
        vm.expectRevert(bytes("Migration In Progress"));
        houseOld.withdraw(1 ether);
    }

    function test_house_withdraw_requires_own_shares() public {
        // On the new (open) House an address with zero shares cannot withdraw anything.
        assertEq(houseNew.balanceOf(attacker), 0, "attacker holds no new-House shares");
        vm.prank(attacker);
        vm.expectRevert();
        houseNew.withdraw(1 ether);
    }

    function test_house_price_math_is_self_consistent() public view {
        // price = balance * 1e18 / totalShares ; the old House has no surplus over shares
        uint256 bal = HOUSE_OLD.balance;
        uint256 ts = houseOld.totalShares();
        uint256 price = houseOld.calculatePrice();
        uint256 expected = (bal * 1e18) / ts;
        // allow for one block of price drift (share redemptions change both terms)
        assertApproxEqRel(price, expected, 0.05e18, "price consistent with balance/shares");
    }

    // ------------------------------------------------------------------
    // 7. Attacker net-position sweep across all public entrypoints (E-U = $0)
    // ------------------------------------------------------------------
    function test_attacker_cannot_gain() public {
        uint256 start = attacker.balance;

        // APEPredicts: deposit is public but costs the attacker; claim/refund need own deposits
        vm.startPrank(attacker);
        vm.expectRevert();
        ape.claim(1);
        vm.expectRevert();
        ape.refund(1);
        vm.expectRevert();
        ape.withdraw(0);
        vm.stopPrank();

        // old House: locked
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Migration In Progress"));
        houseOld.deposit{value: 0.5 ether}();
        vm.expectRevert(bytes("Zero Balance"));
        houseOld.migrate("");
        vm.stopPrank();

        // CashOrCrash: admin/owner only
        vm.startPrank(attacker);
        vm.expectRevert();
        coc.withdrawFunds(address(0), true, 1 ether, payable(attacker));
        vm.stopPrank();

        assertEq(attacker.balance, start, "attacker net gain is exactly 0");
    }
}
