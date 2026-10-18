// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IFaiyahFactory, IFaiyahPool, IERC20} from "../src/Interfaces.sol";

/// @title Faiyah Staking (Xphere, chainId 20250217) — commingled-principal reward flaw
/// @notice Read-only fork PoC. No mainnet transactions. Fork of Xphere mainnet at a pinned block.
contract FaiyahTest is Test {
    address constant FACTORY = 0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe;
    address constant XEF = 0x80252C2D06bbd85699c555fc3633D5B8eE67C9AD;
    address constant P41 = 0xCa3aAb5282586EFD5C38EdB5083FeD87DA11CcD9; // XEF 2%/yr, ended 2026-10-03
    address constant P42 = 0x895B1761941A3fFE6282dbcD312D45399aC0af4e; // XEF 5%/yr, ends 2027-01-03
    address constant P9 = 0x2A2E7919C9D4eDC815A0754BA4A539A245D864Ad;  // USDT 5000%/yr, unclaimable
    address constant P32 = 0x85427e2f6CA737614E3A771b8DE43E8473161e5e; // USDC 600%/yr, self-dealt

    address constant ATTACKER = address(0xA77ACC);
    uint256 constant YEAR = 31_536_000;

    function setUp() public {
        string memory url = vm.envOr("XPHERE_RPC_URL", string("https://en-bkk.x-phere.com"));
        // The public Xphere RPC is a full (non-archive) node: pinning an old block fails with
        // "missing trie node". Fork latest; every assertion below reads live state dynamically.
        vm.createSelectFork(url);
        emit log_named_uint("fork block", block.number);
        emit log_named_uint("fork timestamp", block.timestamp);
    }

    // ---------------------------------------------------------------- helpers

    function _accrued(uint256 amount, uint256 apr, uint256 elapsed) internal pure returns (uint256) {
        if (elapsed == 0) return 0;
        return amount * apr * elapsed / (10_000 * YEAR);
    }

    /// Fund the attacker with real XEF from a large public holder (fork impersonation; no deal/storage poking).
    function _fund(address to, uint256 amount) internal {
        address whale = 0xc22A3d5642adA0137D764F7f4Dd380EC2ea6961f;
        vm.prank(whale);
        IERC20(XEF).transfer(to, amount);
    }

    function _deficit(address pool) internal view returns (uint256) {
        uint256 debt = IFaiyahPool(pool).rewardDebtTotal();
        uint256 reward = IFaiyahPool(pool).totalReward();
        return debt > reward ? debt - reward : 0;
    }

    function _stake(address pool, uint256 id)
        internal
        view
        returns (address owner, uint256 amount, uint256 stime, uint256 claimed, uint256 settled)
    {
        return IFaiyahPool(pool).stakes(id);
    }

    // ------------------------------------------------------- 1. live ledger

    /// The single commingled balance identity, live: balance = totalStaked + totalReward - rewardDebtTotal.
    /// Pool #41 is already below totalStaked => part of the principal is gone, spent on earlier rewards.
    function test_live_deficit_identity() public {
        IFaiyahPool p = IFaiyahPool(P41);
        uint256 staked = p.totalStaked();
        uint256 reward = p.totalReward();
        uint256 debt = p.rewardDebtTotal();
        uint256 bal = IERC20(XEF).balanceOf(P41);

        assertEq(bal + debt, staked + reward, "identity balance + debt == staked + reward");
        assertEq(reward, 0, "no funded reward bucket");
        assertLt(bal, staked, "pool balance is below totalStaked");
        uint256 deficit = staked - bal;
        assertEq(deficit, debt, "deficit equals lifetime rewards paid from principal");
        assertGt(deficit, 28_000e18, "deficit > 28k XEF");

        // #42, still open: liabilities (principal + accrued) exceed assets.
        IFaiyahPool q = IFaiyahPool(P42);
        uint256 qbal = IERC20(XEF).balanceOf(P42);
        uint256 qdebt = q.rewardDebtTotal();
        // #42 additionally holds a direct XEF donation (650e18 at the wave-2 snapshot); allow it.
        uint256 qdelta = qbal + qdebt - q.totalStaked() - q.totalReward();
        assertGe(qdelta, 0, "p42 no negative identity delta");
        assertLe(qdelta, 1_000e18, "p42 donation is small");
        assertLt(qbal, q.totalStaked(), "p42 balance below principal");
    }

    /// A live claim on #41 pays an entitled reward out of principal: the funded bucket is zero
    /// and the pool is already below totalStaked, yet claimReward succeeds and deepens the hole.
    function test_claim_pays_from_principal() public {
        (address owner, , , , ) = _stake(P41, 1);
        (bool canClaim, uint256 amount) = IFaiyahPool(P41).claimableReward(1);
        assertTrue(canClaim);
        assertGt(amount, 0);

        uint256 balBefore = IERC20(XEF).balanceOf(P41);
        uint256 debtBefore = IFaiyahPool(P41).rewardDebtTotal();
        uint256 staked = IFaiyahPool(P41).totalStaked();

        assertLt(balBefore, staked, "already insolvent before the claim");
        assertEq(IFaiyahPool(P41).totalReward(), 0, "funded bucket is empty");

        vm.prank(owner);
        IFaiyahFactory(FACTORY).claimReward(P41, 1);

        uint256 balAfter = IERC20(XEF).balanceOf(P41);
        uint256 debtAfter = IFaiyahPool(P41).rewardDebtTotal();
        assertEq(balBefore - balAfter, amount, "paid exactly the entitlement");
        assertEq(debtAfter - debtBefore, amount, "debt grows by the same amount");
        assertEq(staked - balAfter, _deficit(P41), "deficit grew by the payout");
        assertLt(balAfter, staked, "principal hole deepened");
    }

    // ---------------------------------------------- 2. live endgame / reverts

    /// Pool #9: unclaimable by construction. 31,451 USDT accrued vs 1,299.58 USDT held.
    /// Both claimReward and unstake revert NotEnoughReward — the stake owner cannot get principal back.
    function test_pool9_claim_and_unstake_revert() public {
        (address owner, uint256 amount, , , ) = _stake(P9, 1);
        (bool canClaim, uint256 accrued) = IFaiyahPool(P9).claimableReward(1);
        uint256 bal = IERC20(IFaiyahPool(P9).stakingToken()).balanceOf(P9);
        assertTrue(canClaim);
        assertGt(accrued, bal, "accrued reward exceeds entire pool balance");

        vm.prank(owner);
        vm.expectRevert(bytes4(0xc9d2c178)); // NotEnoughReward()
        IFaiyahFactory(FACTORY).claimReward(P9, 1);

        vm.prank(owner);
        vm.expectRevert(bytes4(0xc9d2c178));
        IFaiyahFactory(FACTORY).unstake(P9, 1);

        // still there afterwards
        assertEq(IERC20(IFaiyahPool(P9).stakingToken()).balanceOf(P9), bal);
        assertEq(IFaiyahPool(P9).totalStaked(), amount);
    }

    /// Pool #32: deterministic first-come-first-served endgame with three live stakes.
    /// The first claim succeeds; after that the 500-USDC stake's claim/unstake can never be paid.
    function test_pool32_first_come_first_served() public {
        address tok = IFaiyahPool(P32).stakingToken();
        (bool c1, uint256 a1) = IFaiyahPool(P32).claimableReward(1);
        (bool c2, uint256 a2) = IFaiyahPool(P32).claimableReward(2);
        (address o1, , , , ) = _stake(P32, 1);
        (address o2, uint256 amt2, , , ) = _stake(P32, 2);
        assertTrue(c1 && c2);
        assertGt(a1, 0);
        assertGt(a2 + amt2, IERC20(tok).balanceOf(P32), "stake 2 unpayable");

        vm.prank(o1);
        IFaiyahFactory(FACTORY).claimReward(P32, 1);
        uint256 balMid = IERC20(tok).balanceOf(P32);
        assertLt(balMid, a2, "after first claim, second claim no longer payable");

        vm.prank(o2);
        vm.expectRevert(bytes4(0xc9d2c178)); // NotEnoughReward()
        IFaiyahFactory(FACTORY).claimReward(P32, 2);

        vm.prank(o2);
        vm.expectRevert(bytes4(0xc9d2c178));
        IFaiyahFactory(FACTORY).unstake(P32, 2);

        // the first stake can still exit with principal + its (unfunded) reward
        vm.prank(o1);
        IFaiyahFactory(FACTORY).unstake(P32, 1);
        assertEq(IFaiyahPool(P32).totalStaked(), amt2);
    }

    // ------------------------------------------------- 3. fresh-attacker test

    /// Fresh attacker stakes into the only material open XEF pool (#42, ends 2027-01-03).
    /// Result: no over-credit. Claim pays exactly floor-linear APR; principal is locked 180 days;
    /// max 180-day gain is 2.47% while the pool is already 116 XEF short and carries 4.7k XEF of
    /// unfunded claims. Negative-EV / principal-at-risk, not an extraction.
    function test_fresh_attacker_42_no_overcredit() public {
        IFaiyahPool p = IFaiyahPool(P42);
        uint256 apr = p.apr();               // 500 = 5%/yr
        uint256 principal = 10_000e18;
        uint256 staked0 = p.totalStaked();
        uint256 bal0 = IERC20(XEF).balanceOf(P42);
        uint256 id0 = p.nextStakeId();
        uint256 donation = bal0 + p.rewardDebtTotal() - staked0 - p.totalReward();

        _fund(ATTACKER, 200_000e18);
        vm.startPrank(ATTACKER);
        IERC20(XEF).approve(FACTORY, type(uint256).max);
        IERC20(XEF).approve(P42, type(uint256).max);
        IFaiyahFactory(FACTORY).stake(P42, principal);
        vm.stopPrank();

        uint256 id = p.nextStakeId() - 1;
        assertEq(id, id0);
        (address owner, uint256 amount, uint256 stime, , ) = _stake(P42, id);
        assertEq(owner, ATTACKER);
        assertEq(amount, principal);
        assertEq(stime, block.timestamp);
        assertEq(p.totalStaked(), staked0 + principal, "principal added");
        assertEq(IERC20(XEF).balanceOf(P42), bal0 + principal, "balance added");

        (bool can, uint256 amt) = p.claimableReward(id);
        assertFalse(can);
        assertEq(amt, 0, "nothing claimable before claimDelay");

        vm.prank(ATTACKER);
        vm.expectRevert(); // claimDelay not met
        IFaiyahFactory(FACTORY).claimReward(P42, id);

        // one day later: exact floor accrual, nothing more
        vm.warp(stime + 86_401);
        (can, amt) = p.claimableReward(id);
        assertTrue(can);
        assertEq(amt, _accrued(principal, apr, 86_401), "wei-exact day-1 accrual");

        uint256 attackerBefore = IERC20(XEF).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IFaiyahFactory(FACTORY).claimReward(P42, id);
        uint256 paid = IERC20(XEF).balanceOf(ATTACKER) - attackerBefore;
        assertEq(paid, amt, "paid exactly the entitlement (fee=0)");

        (, uint256 rest) = p.claimableReward(id);
        assertEq(rest, 0, "no double-claim");

        // cannot exit principal early
        vm.prank(ATTACKER);
        vm.expectRevert(); // unstakeDelay (180d) not met
        IFaiyahFactory(FACTORY).unstake(P42, id);

        // at maturity the attacker gets principal + exact residual accrual
        uint256 maturity = stime + p.unstakeDelay();
        vm.warp(maturity + 1);
        uint256 totalAccrued = _accrued(principal, apr, maturity + 1 - stime);
        uint256 residual = totalAccrued - paid;
        uint256 b2 = IERC20(XEF).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IFaiyahFactory(FACTORY).unstake(P42, id);
        uint256 out = IERC20(XEF).balanceOf(ATTACKER) - b2;
        assertEq(out, principal + residual, "principal + exact residual only");

        uint256 profit = out - principal;
        assertGt(profit, 0);
        assertLt(profit, principal * 3 / 100, "180d gain < 3%: advertised APR, no over-credit");
        // the direct donation recorded at the start must still be the only identity delta
        assertEq(IERC20(XEF).balanceOf(P42) + p.rewardDebtTotal() - p.totalReward() - donation,
                 p.totalStaked(), "identity holds");
    }

    // ----------------------------------------------------- 4. gating checks

    function test_cannot_touch_other_stakes() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes4(0xea8e4eb5)); // NotAuthorized()
        IFaiyahFactory(FACTORY).claimReward(P41, 1);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes4(0xea8e4eb5));
        IFaiyahFactory(FACTORY).unstake(P41, 1);
    }

    function test_cannot_stake_in_ended_pool_41() public {
        _fund(ATTACKER, 1_000e18); // fund first, otherwise transferFrom fails before the time-range check
        vm.startPrank(ATTACKER);
        IERC20(XEF).approve(FACTORY, type(uint256).max);
        vm.expectRevert(bytes4(0x536a71af)); // InvalidTimeRange()
        IFaiyahFactory(FACTORY).stake(P41, 1_000e18);
        vm.stopPrank();
    }

    function test_no_free_stake() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes4(0x7939f424)); // TransferFromFailed()
        IFaiyahFactory(FACTORY).stake(P42, 1e18);
    }

    function test_pool_admin_gates() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x118cdaa7), ATTACKER)); // OwnableUnauthorizedAccount(address)
        IFaiyahPool(P42).emergencyClose();

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(bytes4(0x118cdaa7), ATTACKER));
        IFaiyahPool(P42).emergencyWithdrawStakingToken(new address[](0), new uint256[](0));
    }

    // ------------------------------------------------------- 5. view math

    /// claimableReward(id) == max(0, floor(amount*apr*(now-stime)/ (1e4*YEAR)) - claimed)
    function test_view_math_exact_41() public {
        (uint256 amount, uint256 stime, uint256 claimed) = _stakeAmount(P41, 1);
        uint256 apr = IFaiyahPool(P41).apr();
        uint256 exp = _accrued(amount, apr, block.timestamp - stime);
        exp = exp > claimed ? exp - claimed : 0;
        (, uint256 got) = IFaiyahPool(P41).claimableReward(1);
        assertEq(got, exp, "view == exact floor formula");
    }

    function _stakeAmount(address pool, uint256 id)
        internal
        view
        returns (uint256 amount, uint256 stime, uint256 claimed)
    {
        (, amount, stime, claimed, ) = IFaiyahPool(pool).stakes(id);
    }
}
