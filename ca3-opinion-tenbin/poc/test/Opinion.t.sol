// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IOpinionResolver} from "../src/Interfaces.sol";

/// @notice Fork tests for OPINION DisputeResolver (BNB Chain).
/// Read-only against a forked node; no mainnet transactions are sent.
contract OpinionTest is Test {
    address constant RESOLVER = 0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4; // v5 "auto" resolver
    address constant RESOLVER_V4 = 0x5E09dab0CC6f952c715919a1AbCe81AF918a5985; // v4 "committee" resolver
    address constant OPN = 0x7977BF3e7e0c954D12cdcA3E013ADAf57E0B06E0;
    address constant OPERATOR_EOA = 0xBE39f18621a478354BcA521D89B71770085Fc14e;
    address constant ATTACKER = address(0xA11CE);

    IOpinionResolver resolver = IOpinionResolver(RESOLVER);

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        vm.createSelectFork(rpc);
    }

    function _pickPending() internal view returns (bytes32 q, uint256 deadline) {
        bytes32[] memory ids = resolver.getActiveQuestionIds();
        for (uint256 i = 0; i < ids.length; i++) {
            IOpinionResolver.Resolution memory r = resolver.getResolution(ids[i]);
            if (r.status == 0 && r.rewardAmount > 0) {
                return (ids[i], r.disputeDeadline);
            }
        }
        revert("no pending question");
    }

    /// @notice The unprivileged actor cannot trigger the timeout; only OPERATOR_ROLE can.
    function test_timeoutDispute_unprivileged_reverts() public {
        (bytes32 q,) = _pickPending();
        vm.prank(ATTACKER);
        vm.expectRevert();
        resolver.timeoutDispute(q);
        console2.log("unprivileged timeoutDispute reverted as expected");
    }

    /// @notice L-06 mechanism: a disputor only profits if the privileged operator times out the dispute.
    /// Demonstrates stake -> timeout (privileged) -> claim 2x; and that the disputor alone cannot claim.
    function test_L06_conditional_path_requires_operator() public {
        (bytes32 q, uint256 deadline) = _pickPending();
        IOpinionResolver.Resolution memory r0 = resolver.getResolution(q);
        uint256 reward = r0.rewardAmount;

        // Move to a time inside the dispute window (state is still the forked Pending state).
        vm.warp(deadline - 60);
        deal(OPN, ATTACKER, reward);
        vm.startPrank(ATTACKER);
        IERC20(OPN).approve(RESOLVER, reward);
        resolver.dispute(q, 0);
        vm.stopPrank();

        IOpinionResolver.Resolution memory r1 = resolver.getResolution(q);
        assertEq(uint8(r1.status), 1, "status must be Disputed");
        assertEq(r1.disputor, ATTACKER);
        assertEq(r1.stakedAmount, reward);
        console2.log("disputed; reVoteDeadline", r1.reVoteDeadline);

        // Past the re-vote deadline, the disputor still cannot trigger the timeout.
        vm.warp(r1.reVoteDeadline + 1);
        assertTrue(resolver.isDisputeTimedOut(q));
        vm.prank(ATTACKER);
        vm.expectRevert();
        resolver.timeoutDispute(q);

        // And cannot claim before the privileged timeout.
        vm.prank(ATTACKER);
        vm.expectRevert();
        resolver.claim(q);

        // Only the OPERATOR_ROLE holder (an EOA hot wallet) can mark the timeout.
        assertTrue(resolver.hasRole(resolver.OPERATOR_ROLE(), OPERATOR_EOA), "operator role");
        vm.prank(OPERATOR_EOA);
        resolver.timeoutDispute(q);
        IOpinionResolver.Resolution memory r2 = resolver.getResolution(q);
        assertEq(uint8(r2.status), 4, "status must be TooEarly");
        assertTrue(r2.disputeSucceeded);

        // Disputor now claims stake + reward = 2x.
        uint256 before = IERC20(OPN).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        resolver.claim(q);
        uint256 afterBal = IERC20(OPN).balanceOf(ATTACKER);
        assertEq(afterBal - before, reward * 2, "claim pays 2x");
        console2.log("net disputor profit (OPN)", (afterBal - before) - reward);
    }

    /// @notice Probes whether the v5 resolve() path is callable by an unprivileged actor on a disputed
    /// question. If this ever becomes permissionless it is a direct drain; the test asserts it is gated.
    function test_resolve_on_disputed_is_not_permissionless() public {
        (bytes32 q, uint256 deadline) = _pickPending();
        IOpinionResolver.Resolution memory r0 = resolver.getResolution(q);
        vm.warp(deadline - 60);
        deal(OPN, ATTACKER, r0.rewardAmount);
        vm.startPrank(ATTACKER);
        IERC20(OPN).approve(RESOLVER, r0.rewardAmount);
        resolver.dispute(q, 0);
        vm.stopPrank();

        // Still inside the re-vote window.
        uint256[] memory payouts = new uint256[](2);
        payouts[0] = r0.originalPayouts[1];
        payouts[1] = r0.originalPayouts[0];

        (bool ok, bytes memory ret) = RESOLVER.call(
            abi.encodeWithSignature("resolve(bytes32,uint256[])", q, payouts)
        );
        console2.log("resolve from test contract success?", ok);
        console2.logBytes(ret);
        assertFalse(ok, "resolve() is permissionless on a disputed question");

        // Also probe from the disputor itself (in case auth is disputor-scoped).
        vm.prank(ATTACKER);
        (bool ok2, bytes memory ret2) = RESOLVER.call(
            abi.encodeWithSignature("resolve(bytes32,uint256[])", q, payouts)
        );
        console2.log("resolve from disputor success?", ok2);
        console2.logBytes(ret2);
        assertFalse(ok2, "disputor can self-resolve the dispute");
    }

    /// @notice v4 committee resolver: same OPERATOR_ROLE gate, zero active questions and zero reward balance.
    function test_v4_resolver_is_idle_and_gated() public {
        IOpinionResolver r4 = IOpinionResolver(RESOLVER_V4);
        assertEq(r4.getActiveQuestionIds().length, 0, "v4 has no active questions");
        console2.log("v4 OPN residual", IERC20(OPN).balanceOf(RESOLVER_V4));
        vm.prank(ATTACKER);
        vm.expectRevert();
        r4.timeoutDispute(bytes32(uint256(1)));
    }
}
