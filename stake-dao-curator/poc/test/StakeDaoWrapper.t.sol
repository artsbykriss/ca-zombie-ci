// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IStrategyWrapper, IMorpho, IRewardVault, IERC20Min} from "../src/Interfaces.sol";

/// @title Stake DAO MorphoStrategyWrapper — Pashov C-02 (stale checkpoints) fork verification
/// @notice Read-only fork tests. No mainnet transactions.
contract StakeDaoWrapperTest is Test {
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    // Older-generation wrapper (frxUSD/OUSD): retains the pre-fix checkpoint pattern and
    // is the wrapper with live liquidation history (14 `Liquidated` events).
    IStrategyWrapper constant W_OLD = IStrategyWrapper(0x95B2b136eb0Bf075072D0c759e475453711A33f5);
    // v3 generation wrapper (USD3/frxUSD): hardened (adds the off-track clamp + version()).
    IStrategyWrapper constant W_V3 = IStrategyWrapper(0x3009e8e60Ee13Eccc3234406571E33664C2ECad7);

    bytes32 constant MID_OLD = 0xb7d1981ca0657c42bf003aca966f6a873ade2ae55d472d019a4ea03bc74f29f0;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA401); // fresh, unprivileged attacker

    // Largest live RewardVault holder (on-chain Transfer logs) — used only to source
    // RewardVault shares for the test actors via vm.prank impersonation.
    address constant RV_WHALE = 0x56DBc69208044748aF4D33392E25fC9336F11931;

    function forkUrl() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(forkUrl());
    }

    /// @dev Locate the wrapper's internal checkpoint balance for `user` by scanning the
    ///      `userCheckpoints[user].balance` mapping slot (the struct's first field).
    function checkpointStorage(address user) internal view returns (uint256 val, uint256 baseSlot) {
        for (uint256 s = 0; s < 30; s++) {
            uint256 v = uint256(vm.load(address(W_OLD), keccak256(abi.encode(user, s))));
            if (v != 0) return (v, s);
        }
        return (0, type(uint256).max);
    }

    /// @dev The older generation's `claimLiquidation` returns nothing while v3 returns
    ///      `uint256`; use a raw call so both ABIs are handled.
    function callClaimLiquidation(address liquidator, address victim, uint256 amt)
        internal
        returns (bool ok, bytes memory ret)
    {
        (ok, ret) = address(W_OLD).call(
            abi.encodeWithSignature("claimLiquidation(address,address,uint256)", liquidator, victim, amt)
        );
    }

    // ------------------------------------------------------------------
    // 1. C-02 impact 3 (fungibility) — deployed wrapper is NON-TRANSFERABLE:
    //    a fresh EOA cannot move wrapper tokens, so the "transfer breaks
    //    checkpoints" vector is closed by construction.
    // ------------------------------------------------------------------
    function test_C02_transfer_is_locked_to_lending_protocol() public {
        vm.prank(carol);
        vm.expectRevert(bytes4(0x11717f12)); // TransferUnauthorized()
        W_OLD.transfer(bob, 1);

        vm.prank(carol);
        vm.expectRevert(bytes4(0x11717f12));
        W_OLD.transferFrom(alice, bob, 1);

        vm.prank(carol);
        vm.expectRevert(bytes4(0x11717f12));
        W_V3.transfer(bob, 1);
    }

    // ------------------------------------------------------------------
    // 2. A fresh caller cannot claim rewards on behalf of someone else.
    // ------------------------------------------------------------------
    function test_C02_claim_for_other_reverts() public {
        vm.prank(carol);
        vm.expectRevert(bytes4(0x82b42900)); // Unauthorized()
        W_OLD.claim(alice);

        vm.prank(carol);
        vm.expectRevert(bytes4(0x82b42900));
        W_OLD.claimExtraRewards(alice);
    }

    // ------------------------------------------------------------------
    // 3. Generation check: v3 exposes version()==3; the older generation
    //    predates version() but still carries claimLiquidation (the
    //    acknowledged C-02 mitigation).
    // ------------------------------------------------------------------
    function test_generations_and_claimLiquidation_surface() public {
        assertEq(W_V3.version(), 3, "v3 wrapper version");
        vm.expectRevert();
        W_OLD.version();
        (bool ok,) = address(W_OLD).staticcall(
            abi.encodeWithSignature("claimLiquidation(address,address,uint256)", carol, alice, 1)
        );
        assertFalse(ok, "claimLiquidation present but reverts without an off-track balance");
    }

    // ------------------------------------------------------------------
    // 4. The C-02 path on the live contracts: deposit -> collateral in
    //    Morpho -> collateral withdrawn to a DIFFERENT receiver (== a
    //    liquidation from the wrapper's point of view).
    //    (a) victim checkpoint persists (impact 2)
    //    (b) receiver cannot `withdraw` (impact 1)
    //    (c) fresh attacker cannot call claimLiquidation
    //    (d) claimLiquidation resynchronises; value-conserving.
    // ------------------------------------------------------------------
    function test_C02_stale_checkpoint_and_liquidation_resync() public {
        uint256 amount = 1e18;

        address rv = W_OLD.REWARD_VAULT();
        vm.prank(RV_WHALE);
        IERC20Min(rv).transfer(alice, amount);
        vm.startPrank(alice);
        IERC20Min(rv).approve(address(W_OLD), amount);
        W_OLD.depositShares(amount, alice);
        vm.stopPrank();

        (uint256 cpAfterDeposit, uint256 slotIdx) = checkpointStorage(alice);
        assertEq(cpAfterDeposit, amount, "checkpoint written on deposit");
        console2.log("checkpoint storage slot index:", slotIdx);

        IMorpho.MarketParams memory p = IMorpho(MORPHO).idToMarketParams(MID_OLD);
        assertEq(p.collateralToken, address(W_OLD), "market collateral is the wrapper");
        assertEq(IMorpho(MORPHO).position(MID_OLD, alice).collateral, uint128(amount), "collateral supplied");

        // --- simulate a liquidation / withdraw-to-different-receiver ---
        vm.prank(alice);
        IMorpho(MORPHO).withdrawCollateral(p, amount, alice, bob);

        assertEq(W_OLD.balanceOf(bob), amount, "bob physically holds the wrapper tokens");
        assertEq(IMorpho(MORPHO).position(MID_OLD, alice).collateral, 0, "alice collateral gone");

        // C-02 impact 2: the victim's checkpoint survives the seizure.
        (uint256 cpStale,) = checkpointStorage(alice);
        assertEq(cpStale, amount, "STALE: alice checkpoint persists after seizure");
        console2.log("alice stale-checkpoint pending main reward:", W_OLD.getPendingRewards(alice));
        vm.prank(alice);
        W_OLD.claim(alice); // victim can still claim on tokens she no longer owns

        // C-02 impact 1: the receiver cannot `withdraw` (checkpoint underflow).
        vm.prank(bob);
        vm.expectRevert();
        W_OLD.withdraw(amount);

        // (c) a fresh attacker cannot call claimLiquidation without off-track tokens.
        (bool okCarols, bytes memory retCarols) = callClaimLiquidation(carol, alice, amount);
        assertFalse(okCarols, "fresh caller cannot claimLiquidation");
        assertEq(bytes4(retCarols), bytes4(0x85914873), "InvalidLiquidation()");

        // (d) the acknowledged mitigation: bob unwraps via claimLiquidation.
        uint256 rvBefore = IERC20Min(rv).balanceOf(bob);
        (bool okBob,) = callClaimLiquidation(bob, alice, amount);
        assertTrue(okBob, "liquidator claimLiquidation succeeds");
        (uint256 cpResync,) = checkpointStorage(alice);
        assertEq(cpResync, 0, "checkpoint resynchronised");
        assertEq(IERC20Min(rv).balanceOf(bob) - rvBefore, amount, "bob received underlying shares");
    }

    // ------------------------------------------------------------------
    // 5. claimLiquidation never unwraps more than the victim's hole.
    //    The older generation has no clamp: an over-request simply
    //    reverts (safe); the exact amount succeeds. (v3 clamps instead.)
    // ------------------------------------------------------------------
    function test_claimLiquidation_no_overclaim() public {
        uint256 amount = 1e18;
        address rv = W_OLD.REWARD_VAULT();
        vm.prank(RV_WHALE);
        IERC20Min(rv).transfer(alice, amount);
        vm.startPrank(alice);
        IERC20Min(rv).approve(address(W_OLD), amount);
        W_OLD.depositShares(amount, alice);
        vm.stopPrank();

        IMorpho.MarketParams memory p = IMorpho(MORPHO).idToMarketParams(MID_OLD);
        vm.prank(alice);
        IMorpho(MORPHO).withdrawCollateral(p, amount, alice, bob);

        // over-request -> revert (never over-unwraps)
        (bool okOver, bytes memory retOver) = callClaimLiquidation(bob, alice, amount * 10);
        assertFalse(okOver, "over-request reverts");
        assertEq(bytes4(retOver), bytes4(0x85914873), "InvalidLiquidation()");

        // exact amount -> succeeds
        (bool okExact,) = callClaimLiquidation(bob, alice, amount);
        assertTrue(okExact, "exact hole unwrapped");
    }

    // ------------------------------------------------------------------
    // 6. A fresh, unprivileged attacker (carol) with no protocol role and
    //    no off-track balance cannot extract anything. Net = 0.
    // ------------------------------------------------------------------
    function test_fresh_attacker_has_no_path() public {
        uint256 start = carol.balance;

        vm.prank(carol);
        vm.expectRevert(bytes4(0x11717f12));
        W_OLD.transfer(carol, 1);

        vm.prank(carol);
        vm.expectRevert(bytes4(0x82b42900));
        W_OLD.claim(bob);

        (bool okLiq, bytes memory retLiq) = callClaimLiquidation(carol, alice, 1e18);
        assertFalse(okLiq, "no off-track -> cannot claimLiquidation");
        assertEq(bytes4(retLiq), bytes4(0x85914873));

        vm.prank(carol);
        vm.expectRevert();
        W_OLD.initialize(bytes32(uint256(1)));

        assertEq(carol.balance, start, "no value extracted");
    }
}
