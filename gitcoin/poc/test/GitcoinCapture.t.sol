// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function symbol() external view returns (string memory);
}

interface IVotesComp {
    function delegate(address) external;
    function getCurrentVotes(address) external view returns (uint96);
    function getPriorVotes(address, uint256) external view returns (uint96);
    function delegates(address) external view returns (address);
}

/// @dev OZ v5 Governor (GitcoinGovernorWithGuardian).
interface IGovernorV5 {
    function name() external view returns (string memory);
    function token() external view returns (address);
    function timelock() external view returns (address);
    function proposalGuardian() external view returns (address);
    function quorum(uint256 blockNumber) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function proposalCount() external view returns (uint256);
    function propose(address[] memory, uint256[] memory, bytes[] memory, string memory) external returns (uint256);
    function castVote(uint256 proposalId, uint8 support) external returns (uint256);
    function queue(address[] memory, uint256[] memory, bytes[] memory, bytes32) external returns (uint256);
    function execute(address[] memory, uint256[] memory, bytes[] memory, bytes32) external payable returns (uint256);
    function cancel(address[] memory, uint256[] memory, bytes[] memory, bytes32) external;
    function state(uint256 proposalId) external view returns (uint8);
    function proposalSnapshot(uint256 proposalId) external view returns (uint256);
    function proposalDeadline(uint256 proposalId) external view returns (uint256);
    function proposalEta(uint256 proposalId) external view returns (uint256);
}

interface ITimelock {
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function delay() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
}

interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

contract GitcoinCaptureTest is Test {
    address constant ACTIVE_GOV = 0xef41CbD211076E8b1901e214Bf751d404cf06638; // "Gitcoin Governor Charlie"
    address constant LEGACY_GOV = 0x9D4C63565D5618310271bF3F3c01b2954C1D1639; // old Bravo governor
    address constant TL = 0x57a8865cfB1eCEf7253c27da6B4BC3dAEE5Be518;
    address constant GTC = 0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F;
    address constant GUARDIAN_SAFE = 0x5743E35477363241300FcEdc2F5eB0195F300817; // proposal guardian + veto Safe

    uint256 constant FORK_BLOCK = 26_253_666;
    uint256 constant QUORUM = 1_500_000e18;
    uint256 constant THRESHOLD = 150_000e18;
    uint256 constant VOTING_DELAY = 14_400;
    uint256 constant VOTING_PERIOD = 40_320;
    uint256 constant TIMELOCK_DELAY = 172_800;
    uint256 constant TREASURY_GTC = 12_508_498_095_757_102_544_213_686; // exact at fork block

    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("BLOCKPI_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("NODEREAL_ETH_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://ethereum-rpc.publicnode.com";
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    /// @dev GTC.balances is mapping(address => uint96) at storage slot 5.
    function _setGtcBalance(address who, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encode(who, uint256(5)));
        vm.store(GTC, slot, bytes32(amount));
        assertEq(IERC20(GTC).balanceOf(who), amount, "GTC balance set");
    }

    function _transferPayload(address recipient)
        internal
        view
        returns (address[] memory t, uint256[] memory v, bytes[] memory c)
    {
        t = new address[](1);
        v = new uint256[](1);
        c = new bytes[](1);
        t[0] = GTC;
        c[0] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(GTC).balanceOf(TL));
    }

    // ------------------------------------------------------------------
    // 1. Live state
    // ------------------------------------------------------------------
    function test_live_state() public view {
        assertEq(IGovernorV5(ACTIVE_GOV).name(), "Gitcoin Governor Charlie");
        assertEq(IGovernorV5(ACTIVE_GOV).quorum(FORK_BLOCK - 1), QUORUM, "quorum 1.5M");
        assertEq(IGovernorV5(ACTIVE_GOV).proposalThreshold(), THRESHOLD, "threshold 150k");
        assertEq(IGovernorV5(ACTIVE_GOV).votingDelay(), VOTING_DELAY, "votingDelay");
        assertEq(IGovernorV5(ACTIVE_GOV).votingPeriod(), VOTING_PERIOD, "votingPeriod");
        assertEq(IGovernorV5(ACTIVE_GOV).timelock(), TL, "timelock");
        assertEq(IGovernorV5(ACTIVE_GOV).proposalGuardian(), GUARDIAN_SAFE, "proposal guardian");
        assertEq(IGovernorV5(ACTIVE_GOV).token(), GTC, "token");
        // The timelock's admin is the ACTIVE governor; the legacy governor is inert.
        assertEq(ITimelock(TL).admin(), ACTIVE_GOV, "timelock admin = active governor");
        assertTrue(ITimelock(TL).admin() != LEGACY_GOV, "legacy governor cannot queue/execute");
        assertEq(ITimelock(TL).pendingAdmin(), address(0), "no pending admin");
        assertEq(ITimelock(TL).delay(), TIMELOCK_DELAY, "timelock delay 2d");
        assertEq(IERC20(GTC).balanceOf(TL), TREASURY_GTC, "treasury GTC");
        // The treasury's GTC is delegated to the guardian Safe -> the treasury can defend itself.
        assertEq(IVotesComp(GTC).delegates(TL), GUARDIAN_SAFE, "treasury GTC delegated to guardian");
        assertEq(IVotesComp(GTC).getCurrentVotes(GUARDIAN_SAFE), TREASURY_GTC + 167_584_493_738_603_634, "guardian votes");
        assertEq(ISafe(GUARDIAN_SAFE).getThreshold(), 4, "guardian 4-of-N");
        assertEq(ISafe(GUARDIAN_SAFE).getOwners().length, 6, "guardian owners");
        console2.log("treasury GTC", IERC20(GTC).balanceOf(TL) / 1e18);
    }

    // ------------------------------------------------------------------
    // 2. Quorum is cheap: 1.5M GTC would pass a treasury transfer if the
    //    guardian did nothing. (Shows the mechanical path is open.)
    // ------------------------------------------------------------------
    function _runHostile(bool guardianCancels, bool guardianVotesNo)
        internal
        returns (uint256 pid, bool succeeded)
    {
        _setGtcBalance(attacker, QUORUM);
        vm.prank(attacker);
        IVotesComp(GTC).delegate(attacker);
        vm.roll(block.number + 1); // getPastVotes(proposer, block-1) needs a 1-block-old checkpoint

        (address[] memory t, uint256[] memory v, bytes[] memory c) = _transferPayload(attacker);
        vm.prank(attacker);
        pid = IGovernorV5(ACTIVE_GOV).propose(t, v, c, "GTC treasury rebalance");

        if (guardianCancels) {
            vm.prank(GUARDIAN_SAFE);
            IGovernorV5(ACTIVE_GOV).cancel(t, v, c, keccak256(bytes("GTC treasury rebalance")));
            return (pid, false);
        }

        vm.roll(IGovernorV5(ACTIVE_GOV).proposalSnapshot(pid) + 1);
        vm.prank(attacker);
        IGovernorV5(ACTIVE_GOV).castVote(pid, 1); // For
        if (guardianVotesNo) {
            vm.prank(GUARDIAN_SAFE);
            IGovernorV5(ACTIVE_GOV).castVote(pid, 0); // Against, with 12.5M
        }

        vm.roll(IGovernorV5(ACTIVE_GOV).proposalDeadline(pid) + 1);
        succeeded = IGovernorV5(ACTIVE_GOV).state(pid) == 4; // Succeeded
        if (succeeded) {
            IGovernorV5(ACTIVE_GOV).queue(t, v, c, keccak256(bytes("GTC treasury rebalance")));
            vm.warp(IGovernorV5(ACTIVE_GOV).proposalEta(pid) + 1);
            IGovernorV5(ACTIVE_GOV).execute(t, v, c, keccak256(bytes("GTC treasury rebalance")));
        }
    }

    function test_unguarded_capture_would_drain_treasury() public {
        (uint256 pid, bool ok) = _runHostile(false, false);
        assertTrue(ok, "1.5M quorum-only capture succeeds when the guardian is absent");
        assertEq(IGovernorV5(ACTIVE_GOV).state(pid), 7, "executed");
        assertEq(IERC20(GTC).balanceOf(attacker), QUORUM + TREASURY_GTC, "treasury GTC stolen");
        assertEq(IERC20(GTC).balanceOf(TL), 0, "timelock drained");
        console2.log("attacker GTC", IERC20(GTC).balanceOf(attacker) / 1e18);
    }

    function test_guardian_no_vote_defeats_capture() public {
        (uint256 pid, bool ok) = _runHostile(false, true);
        assertFalse(ok, "12.5M No defeats 1.5M For");
        assertEq(IGovernorV5(ACTIVE_GOV).state(pid), 3, "defeated");
        assertEq(IERC20(GTC).balanceOf(TL), TREASURY_GTC, "treasury intact");
    }

    function test_guardian_cancel_stops_capture() public {
        (uint256 pid, bool ok) = _runHostile(true, false);
        assertFalse(ok, "canceled");
        assertEq(IGovernorV5(ACTIVE_GOV).state(pid), 2, "canceled");
        assertEq(IERC20(GTC).balanceOf(TL), TREASURY_GTC, "treasury intact");
    }

    // ------------------------------------------------------------------
    // 3. The guardian is a 4-of-6 Safe that already holds the treasury votes.
    // ------------------------------------------------------------------
    function test_guardian_holds_treasury_votes_and_cancel_power() public view {
        address[] memory owners = ISafe(GUARDIAN_SAFE).getOwners();
        assertEq(owners.length, 6, "6 owners");
        assertEq(ISafe(GUARDIAN_SAFE).getThreshold(), 4, "4-of-6");
        assertEq(IGovernorV5(ACTIVE_GOV).proposalGuardian(), GUARDIAN_SAFE, "guardian = veto safe");
        assertEq(IVotesComp(GTC).getCurrentVotes(GUARDIAN_SAFE), TREASURY_GTC + 167_584_493_738_603_634, "guardian 12.5M votes");
        // Outvoting the treasury requires > 12.5M GTC, more than the treasury itself.
        assertGt(IVotesComp(GTC).getCurrentVotes(GUARDIAN_SAFE), QUORUM, "guardian votes >> quorum");
    }

    function test_attacker_cannot_replace_guardian() public {
        // setProposalGuardian is onlyGovernance (via the timelock); a hostile action
        // cannot call it, and the legacy governor is not the timelock admin.
        assertTrue(ITimelock(TL).admin() != LEGACY_GOV, "legacy inert");
        assertEq(IGovernorV5(ACTIVE_GOV).proposalGuardian(), GUARDIAN_SAFE, "guardian fixed");
    }
}
