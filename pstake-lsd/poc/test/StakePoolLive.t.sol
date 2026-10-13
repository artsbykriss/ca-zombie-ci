// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/**
 * pSTAKE LSD (stkBNB) — live-state extraction proof (read-only; fork only).
 *
 * Target: BSC StakePool proxy 0xC228CefDF841dEfDbD5B3a18dFD414cC0dbfa0D8
 *         stkBNB token        0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16
 *
 * The pool holds the entire remaining claim reserve in native BNB. The tests:
 *   1. verify live state (paused=false, roles, token mint/burn gated),
 *   2. show that a fresh unprivileged attacker has NO path that pays them
 *      (every candidate call reverts; claimAll is a no-op),
 *   3. show the holder redemption path works (H-O) and that a
 *      deposit->withdraw->claim round trip is lossy (no arbitrage loop),
 *   4. show the privileged path (pause + withdrawBNB) can sweep the whole
 *      balance (P category), quantified separately.
 */

interface IStakePool {
    function paused() external view returns (bool);
    function claimReserve() external view returns (uint256);
    function bnbToUnbond() external view returns (int256);
    function bnbUnbonding() external view returns (uint256);
    function getDeposits() external view returns (uint256);
    function exchangeRate() external view returns (uint256 totalWei, uint256 poolTokenSupply);
    function getTotalValidators() external view returns (uint256);
    function getClaimRequestCount(address user) external view returns (uint256);
    function getPaginatedClaimRequests(address user, uint256 from, uint256 to)
        external
        view
        returns (uint256[] memory);
    function claim(uint256 index) external;
    function claimAll() external;
    function deposit() external payable;
    function withdrawBNB(address payable to) external;
    function triggerRebalance() external;
    function epochUpdate() external;
    function initiateDelegation(address[] calldata operators, uint256[] calldata amounts) external;
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
    function pause() external;
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function BOT_ROLE() external view returns (bytes32);
    function addressStore() external view returns (address);
}

interface IAddressStore {
    function getStkBNB() external view returns (address);
    function getFeeVault() external view returns (address);
    function getStakePool() external view returns (address);
    function getUndelegationHolder() external view returns (address);
}

interface IStkBNB {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function send(address recipient, uint256 amount, bytes calldata data) external;
    function mint(address account, uint256 amount, bytes calldata userData, bytes calldata operatorData)
        external;
    function burn(uint256 amount, bytes calldata data) external;
    function paused() external view returns (bool);
    function getOwner() external view returns (address);
}

contract StakePoolLiveTest is Test {
    address constant POOL = 0xC228CefDF841dEfDbD5B3a18dFD414cC0dbfa0D8;
    address constant STKBNB = 0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16;
    address constant ADDRESS_STORE = 0x4a6b3127A1D295878d8790F6ece0776F65FEc121;

    address attacker = address(0xA11CE);
    uint256 forkBlock;

    IStakePool pool = IStakePool(POOL);
    IStkBNB stk = IStkBNB(STKBNB);
    IAddressStore store = IAddressStore(ADDRESS_STORE);

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            rpc = "https://bsc-rpc.publicnode.com";
        }
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        vm.deal(attacker, 100 ether);
        vm.deal(address(this), 100 ether);
        emit log_named_uint("fork block", forkBlock);
    }

    // ------------------------------------------------------------------
    // 1. live state
    // ------------------------------------------------------------------
    function test_live_state() public {
        assertFalse(pool.paused(), "pool paused");
        assertFalse(stk.paused(), "token paused");
        assertEq(store.getStakePool(), POOL, "addressStore stakePool");
        assertEq(store.getStkBNB(), STKBNB, "addressStore stkBNB");

        (uint256 totalWei, uint256 supply) = pool.exchangeRate();
        emit log_named_uint("pool BNB balance", POOL.balance);
        emit log_named_uint("claimReserve", pool.claimReserve());
        emit log_named_int("bnbToUnbond", pool.bnbToUnbond());
        emit log_named_uint("bnbUnbonding", pool.bnbUnbonding());
        emit log_named_uint("getDeposits", pool.getDeposits());
        emit log_named_uint("exchangeRate.totalWei", totalWei);
        emit log_named_uint("exchangeRate.poolTokenSupply", supply);
        emit log_named_uint("stkBNB.totalSupply", stk.totalSupply());
        emit log_named_uint("stkBNB.balanceOf(pool)", stk.balanceOf(POOL));
        emit log_named_uint("stkBNB.balanceOf(feeVault)", stk.balanceOf(store.getFeeVault()));

        // the whole balance is reserved for claims (modulo dust)
        assertGe(POOL.balance, pool.claimReserve(), "balance < claimReserve");
        assertApproxEqAbs(POOL.balance, pool.claimReserve(), 1e15, "balance != claimReserve");
        // tracked stkBNB backing (still unbondable / redeemable via pool)
        assertGt(totalWei, 0, "no tracked backing");
        assertEq(supply, stk.totalSupply(), "rate supply mismatch");

        // roles
        bytes32 adminRole = pool.DEFAULT_ADMIN_ROLE();
        uint256 admins = pool.getRoleMemberCount(adminRole);
        emit log_named_uint("DEFAULT_ADMIN_ROLE count", admins);
        for (uint256 i = 0; i < admins; i++) {
            emit log_named_address("admin", pool.getRoleMember(adminRole, i));
        }
        emit log_named_uint("BOT_ROLE count", pool.getRoleMemberCount(pool.BOT_ROLE()));
        assertEq(admins, 2, "unexpected admin count");
    }

    // ------------------------------------------------------------------
    // 2. fresh attacker: every value-moving path reverts / is a no-op
    // ------------------------------------------------------------------
    function test_attacker_no_extraction_path() public {
        uint256 balBefore = attacker.balance;

        // 2a. claim of a non-existent request
        vm.prank(attacker);
        vm.expectRevert();
        pool.claim(0);

        // 2b. claimAll is a no-op for an account with no requests
        assertEq(pool.getClaimRequestCount(attacker), 0, "attacker has requests?");
        vm.prank(attacker);
        pool.claimAll();
        assertEq(attacker.balance, balBefore, "claimAll paid something");

        // 2c. call the ERC777 hook directly -> not the token
        vm.prank(attacker);
        vm.expectRevert();
        pool.tokensReceived(attacker, attacker, POOL, 1e12, "", "");

        // 2d. send stkBNB the attacker does not have
        vm.prank(attacker);
        vm.expectRevert();
        stk.send(POOL, 1e12, "");

        // 2e. mint / burn stkBNB directly -> only StakePool
        vm.prank(attacker);
        vm.expectRevert();
        stk.mint(attacker, 1e18, "", "");
        vm.prank(attacker);
        vm.expectRevert();
        stk.burn(1e18, "");

        // 2f. admin-only sweeps
        vm.prank(attacker);
        vm.expectRevert();
        pool.withdrawBNB(payable(attacker));
        vm.prank(attacker);
        vm.expectRevert();
        pool.triggerRebalance();
        vm.prank(attacker);
        vm.expectRevert();
        pool.initiateDelegation(new address[](0), new uint256[](0));

        // 2g. permissionless epochUpdate: reverts while validator earnings are 0;
        //     even if it succeeds it mints fee tokens to the FeeVault, never to caller
        vm.prank(attacker);
        try pool.epochUpdate() {} catch {}
        assertEq(attacker.balance, balBefore, "epochUpdate paid attacker");

        // 2h. under-minimum deposit is rejected
        vm.prank(attacker);
        vm.expectRevert();
        pool.deposit{value: 1}();
        assertEq(attacker.balance, balBefore, "attacker lost funds");
    }

    // ------------------------------------------------------------------
    // 3. holder path (H-O) and no profitable round trip
    // ------------------------------------------------------------------
    /// @dev value of stkBNB at the pool's own (floored) redemption rate
    function stkValue(uint256 tokens) internal view returns (uint256) {
        (uint256 tw, uint256 ts) = pool.exchangeRate();
        if (ts == 0) return 0;
        return (tokens * tw) / ts;
    }

    function test_holder_redemption_and_roundtrip_loss() public {
        uint256 principal = 5 ether; // multiple of minBNBDeposit (1e12)
        uint256 start = attacker.balance;

        for (uint256 i = 0; i < 3; i++) {
            uint256 before = attacker.balance + stkValue(stk.balanceOf(attacker));
            vm.prank(attacker);
            pool.deposit{value: principal}();
            uint256 minted = stk.balanceOf(attacker);
            assertGt(minted, 0, "no stkBNB minted");

            uint256 dust = minted % 1e12; // minTokenWithdrawal = 1e12
            uint256 withdrawable = minted - dust;
            if (dust > 0) {
                // full-balance send is rejected by the pool's min/dust rule
                vm.prank(attacker);
                vm.expectRevert(abi.encodeWithSignature("DustNotAllowed(uint256)", dust));
                stk.send(POOL, minted, "");
            }

            // send a valid (multiple of 1e12) amount -> withdraw + immediate claim
            vm.prank(attacker);
            stk.send(POOL, withdrawable, "");

            uint256 totalAfter = attacker.balance + stkValue(stk.balanceOf(attacker));
            emit log_named_uint("iteration", i);
            emit log_named_uint("deposited", principal);
            emit log_named_uint("bnb received", attacker.balance - (before - principal));
            emit log_named_uint("stkBNB dust left", stk.balanceOf(attacker));
            emit log_named_uint("total value after (BNB + dust@rate)", totalAfter);
            assertLe(totalAfter, before, "round trip created value");
        }
        uint256 endValue = attacker.balance + stkValue(stk.balanceOf(attacker));
        assertLe(endValue, start, "overall round trip created value");
        emit log_named_uint("total loss (wei)", start - endValue);
    }

    // ------------------------------------------------------------------
    // 4. existing pending claimant can still claim (H-O live)
    // ------------------------------------------------------------------
    function test_existing_pending_claimant_can_claim() public {
        address[] memory candidates = _candidates();
        address claimant;
        uint256 count;
        for (uint256 i = 0; i < candidates.length; i++) {
            count = pool.getClaimRequestCount(candidates[i]);
            if (count > 0) {
                claimant = candidates[i];
                break;
            }
        }
        if (claimant == address(0)) {
            emit log("no pending claim candidate found at fork block (all already claimed)");
            return;
        }
        emit log_named_address("claimant", claimant);
        emit log_named_uint("pending requests", count);
        uint256 balBefore = claimant.balance;
        vm.prank(claimant);
        pool.claim(0);
        uint256 received = claimant.balance - balBefore;
        emit log_named_uint("claimed wei", received);
        assertGt(received, 0, "claim did not pay");
    }

    // ------------------------------------------------------------------
    // 5. privileged path (P): admin can pause + sweep everything
    // ------------------------------------------------------------------
    function test_admin_can_sweep_when_paused() public {
        address admin = pool.getRoleMember(pool.DEFAULT_ADMIN_ROLE(), 0);
        vm.startPrank(admin);
        pool.pause();
        assertTrue(pool.paused(), "pause failed");
        uint256 poolBal = POOL.balance;
        uint256 adminBefore = admin.balance;
        pool.withdrawBNB(payable(admin));
        vm.stopPrank();
        emit log_named_uint("swept wei", poolBal);
        assertEq(POOL.balance, 0, "pool not swept");
        assertEq(admin.balance, adminBefore + poolBal, "admin did not receive");
    }

    // candidate pending claimants observed in the 2026-10-13 event scan
    // (users whose claim requests were still open at scan time)
    function _candidates() internal pure returns (address[] memory a) {
        a = new address[](8);
        a[0] = 0xF015Be891E04dFa508AC2AFEcc59AfBEf41a503B;
        a[1] = 0xa3d445C9f35Cac1dAE94C780D213a495529aef95;
        a[2] = 0x4E5b2447077fBbe3bD3d69BEE701344e9cA7A8Dc;
        a[3] = 0x4Fb067d8cC1DFc09e23797b8271BB9D9939Aa474;
        a[4] = 0x53F555EE4a4e1F0E61888fA712C3F7099B9FC73e;
        a[5] = 0x54354342ab98fC43B5177e1c6C1C8bed4E1e9817;
        a[6] = 0x56C3816413943De58C3899Ca60DEbac39Cf617Cb;
        a[7] = 0x5b16e2642382cc45d0548E52001efD8efC43FF07;
    }
}
