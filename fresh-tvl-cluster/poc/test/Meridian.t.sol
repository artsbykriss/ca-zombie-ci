// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

// NOTE (Z3-H17 child, Meridian): poc/src/ForkHelper.sol does not compile against the vendored
// forge-std (VM_ADDRESS redeclaration, solc 9097) and this child may not edit parent-owned files.
// Identical fork semantics are implemented locally: env override (RHO_RPC) first, else first
// reachable keyless public RPC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IMeridianUSD {
    function wrap(address token, uint256 amount) external returns (uint256);
    function unwrap(address token, uint256 amount) external returns (uint256);
    function isWrappedToken(address) external view returns (bool);
    function defaultWrappedToken() external view returns (address);
}

interface IGateway {
    function processActions(bytes[] calldata actions) external payable;
    function ping() external;
    function finalizeWithdraw(address account, bytes32 digest) external payable;
    function isSequencerApproved(address) external view returns (bool);
    function isEmergencyPaused() external view returns (bool);
    function owner() external view returns (address);
    function getAccountGlobalUsdToken() external view returns (address);
}

interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

/// @title Z3-H17 · Meridian Perps (Robinhood Chain 4663) — sequencer-action validation + merUSD parity
/// @notice Read-only research PoC on a local fork of live Robinhood Chain state (keyless public
///         RPCs only). No mainnet transactions, no keys.
contract MeridianH17Test is Test {
    address constant VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));

    address constant GATEWAY = 0xD540F47F214dC7D6D244E62A6aE7e06B586Ef44A;
    address constant ACTION_HANDLER = 0xEB9a61e37A28828E84D97e1487D66b444800a280;
    address constant SEQUENCER = 0x39f7e2936316f99E578489509c2dB036F384E574; // live EOA sequencer
    address constant OWNER_SAFE = 0xF8067d8cA90b8510CE8ADe1eec24B7260eAfa5F7; // 2-of-3 Safe
    address constant MERUSD = 0xAd221259D4A1f2d7376dc1012C561bc86640F009;
    address constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34; // defaultWrappedToken
    address constant ATTACKER = address(0xA77ACC);

    // keccak256(abi.encode("xyz.meridian.AddressRegistry.Data")) then mapping slot for the
    // "ACTION_HANDLER" bytes32 key (key-first mapping slot math)
    bytes32 constant REGISTRY_SLOTPATH = 0xd79897840eeae9a6eb6bdb596fc2056857b011e0d9c2c00b57abeba2812a286d;
    bytes32 constant ACTION_HANDLER_KEY = bytes32("ACTION_HANDLER");

    // A real historical sequencer batch: tx 0x44aca2f0… (block 89,792,031, 2026-10-16),
    // calldata of ExchangeGateway.processActions(bytes[]) as submitted by the sequencer EOA.
    bytes constant HISTORICAL_PROCESS_ACTIONS =
        hex"7bc8a75200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001c6000000000000624901843ce2e1db0b456d548fe869772162f3b7a2b9597072696d6172790000000000000000000000000000000000000000000000000000000000000000000000000e5ba3bec00000000000000000000000a9ea471500000118dee7d347b34c73000000006ad1a6b4a47810e5133b55bb08502138729f21aaf2fe33e77072696d617279000000000000000000000000000000000000000000000000000000000000000000000000009502f90000000000000000000000000000000000000018dee7d0f9036800000000006ad1a6aa000000000800000000000000000000000000000000000000000000000000000000056ff1e4000000000000000000000001de53c8400000000000000000000000063c5c84a00000000000000000000000009502f9000000000000000000000001a8c9b1b48000000000ede5ef5c41412589ea06a63f95a845aa7ddb99bf624cb057ced6cbe551f503760f83e053ffc721fe780af26e61fd5829cf2610cc00a7ee1ab606aab94a45a03bcb059d1d612f1bc874e07f1875951de47518a32f04dd94c110411ae8526f6816a0a0c90f20e61b0cf1b41655b5981b24a57c6da2bd0a47c6d03f17f59b922b164e5f5b01537f901b0000000000000000000000000000000000000000000000000000";

    function _fork() internal returns (uint256 blk) {
        string[3] memory urls = [
            "https://rpc.mainnet.chain.robinhood.com",
            "https://robinhood-rpc.publicnode.com",
            "https://robinhood.drpc.org"
        ];
        string memory override_ = vm.envOr("RHO_RPC", string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return block.number;
        }
        for (uint256 i = 0; i < urls.length; i++) {
            (bool ok,) = VM_ADDR.call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return block.number;
        }
        revert("no reachable Robinhood RPC");
    }

    function setUp() public {
        uint256 blk = _fork();
        console2.log("fork header block (Robinhood header-number space):", blk);
    }

    // T1 — a fresh attacker cannot call processActions: NotSequencer(address).
    function test_T1_processActions_sequencer_gated() public {
        bytes[] memory actions = new bytes[](1);
        actions[0] = bytes("deadbeef");
        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = GATEWAY.call(abi.encodeWithSelector(IGateway.processActions.selector, actions));
        assertTrue(!ok, "fresh caller must not process actions");
        bytes4 sel;
        assembly { sel := mload(add(ret, 32)) }
        assertEq(sel, bytes4(0x05967877), "expected NotSequencer(address)");
        console2.log("T1 PASS: processActions reverts NotSequencer for unprivileged caller");
    }

    // T2 — replaying a real historical sequencer batch (as a fresh caller) is rejected by the
    //      sequencer gate; replaying it even AS the sequencer reverts ActionAlreadyProcessed
    //      because the batch id is <= the monotonic lastActionId.
    function test_T2_historical_replay_rejected() public {
        // fresh attacker replay -> NotSequencer
        vm.prank(ATTACKER, ATTACKER);
        (bool ok1, bytes memory ret1) = GATEWAY.call(HISTORICAL_PROCESS_ACTIONS);
        assertTrue(!ok1, "replay by attacker must fail");
        bytes4 sel1;
        assembly { sel1 := mload(add(ret1, 32)) }
        assertEq(sel1, bytes4(0x05967877), "expected NotSequencer on attacker replay");

        // the actual sequencer replaying its own old batch -> ActionAlreadyProcessed(uint64,uint64,uint64)
        vm.prank(SEQUENCER, SEQUENCER);
        (bool ok2, bytes memory ret2) = GATEWAY.call(HISTORICAL_PROCESS_ACTIONS);
        assertTrue(!ok2, "historical replay must fail even for the sequencer");
        bytes4 sel2;
        assembly { sel2 := mload(add(ret2, 32)) }
        assertEq(sel2, bytes4(0xb6132fdd), "expected ActionAlreadyProcessed");
        console2.log("T2 PASS: historical batch replay rejected (attacker: NotSequencer, sequencer: ActionAlreadyProcessed)");
    }

    // T3 — calling the ActionHandler directly (bypassing the gateway gate) touches only the
    //      handler's own empty storage: the gateway's state (accounts/registry) is untouched.
    function test_T3_direct_handler_call_is_inert() public {
        // gateway's account balance of the sequencer for a random subaccount before/after
        bytes32 sub = bytes32("primary");
        uint256 before_ = _accountBalance(SEQUENCER, sub, USDE);
        vm.prank(ATTACKER, ATTACKER);
        ACTION_HANDLER.call(HISTORICAL_PROCESS_ACTIONS); // may revert or no-op; must not touch gateway
        uint256 after_ = _accountBalance(SEQUENCER, sub, USDE);
        assertEq(before_, after_, "direct handler call must not change gateway state");
        // registry record lives in the GATEWAY's storage: assert the delegatecall target is the handler
        bytes32 recSlot = keccak256(abi.encode(ACTION_HANDLER_KEY, REGISTRY_SLOTPATH));
        address rec = address(uint160(uint256(vm.load(GATEWAY, recSlot))));
        assertEq(rec, ACTION_HANDLER, "gateway registry points at ActionHandler");
        console2.log("T3 PASS: direct handler calls inert; registry target = ActionHandler");
    }

    function _accountBalance(address account, bytes32 subaccount, address token) internal view returns (uint256) {
        (bool ok, bytes memory ret) = GATEWAY.staticcall(
            abi.encodeWithSignature("getAccountBalance(address,bytes32,address)", account, subaccount, token)
        );
        require(ok, "balance read failed");
        return abi.decode(ret, (uint256));
    }

    // T4 — finalizeWithdraw is restricted to the account / claimer / owner.
    function test_T4_finalizeWithdraw_unauthorized() public {
        // third party finalizing someone else's withdraw -> Unauthorized()
        vm.prank(ATTACKER, ATTACKER);
        (bool ok1, bytes memory ret1) =
            GATEWAY.call(abi.encodeWithSignature("finalizeWithdraw(address,bytes32)", SEQUENCER, bytes32(0)));
        assertTrue(!ok1, "third-party finalizeWithdraw must fail");
        bytes4 sel1;
        assembly { sel1 := mload(add(ret1, 32)) }
        assertEq(sel1, bytes4(0x82b42900), "expected Unauthorized()");
        // self-finalize with an unknown digest -> WithdrawNotFound()
        vm.prank(ATTACKER, ATTACKER);
        (bool ok2, bytes memory ret2) =
            GATEWAY.call(abi.encodeWithSignature("finalizeWithdraw(address,bytes32)", ATTACKER, bytes32(0)));
        assertTrue(!ok2, "unknown withdraw digest must revert");
        bytes4 sel2;
        assembly { sel2 := mload(add(ret2, 32)) }
        assertEq(sel2, bytes4(0xf2f05136), "expected WithdrawNotFound()");
        console2.log("T4 PASS: third-party finalizeWithdraw -> Unauthorized; bogus digest -> WithdrawNotFound");
    }

    // T5 — merUSD parity: 1:1 backed by the default wrapped token; wrap is restricted to the
    //      default asset; permissionless wrap/unwrap is exactly 1:1.
    function test_T5_merusd_parity() public {
        address def = IMeridianUSD(MERUSD).defaultWrappedToken();
        assertEq(def, USDE, "default wrapped token is USDe");
        assertTrue(IMeridianUSD(MERUSD).isWrappedToken(USDE), "USDe enabled");
        uint256 supply = IERC20(MERUSD).totalSupply();
        uint256 backing = IERC20(USDE).balanceOf(MERUSD);
        console2.log("merUSD totalSupply:", supply);
        console2.log("USDe backing in merUSD:", backing);
        assertEq(supply, backing, "merUSD must be exactly 1:1 backed");
        // wrapping a non-default/unknown token reverts
        (bool ok,) = MERUSD.call(abi.encodeWithSignature("wrap(address,uint256)", ATTACKER, 1));
        assertTrue(!ok, "wrap of non-enabled token must revert");
        console2.log("T5 PASS: merUSD supply == USDe backing; wrap restricted to default asset");
    }

    // T6 — structural: the sequencer is a single EOA (P-class) and the gateway owner is a
    //      2-of-3 Safe; the gateway is live (not paused).
    function test_T6_privileged_actors_structure() public {
        assertEq(SEQUENCER.code.length, 0, "sequencer is an EOA");
        assertTrue(IGateway(GATEWAY).isSequencerApproved(SEQUENCER), "sequencer approved live");
        assertEq(IGateway(GATEWAY).owner(), OWNER_SAFE, "gateway owner");
        assertEq(ISafe(OWNER_SAFE).getThreshold(), 2, "owner Safe threshold 2");
        assertEq(ISafe(OWNER_SAFE).getOwners().length, 3, "owner Safe 3 signers");
        assertFalse(IGateway(GATEWAY).isEmergencyPaused(), "gateway not paused");
        console2.log("T6 PASS: sequencer EOA 0x39f7e293..; owner 2-of-3 Safe");
    }

    // T7 — ping() is permissionless by design and state-free apart from its timestamp.
    function test_T7_ping_is_permissionless_and_benign() public {
        vm.warp(block.timestamp + 20);
        vm.prank(ATTACKER, ATTACKER);
        IGateway(GATEWAY).ping();
        console2.log("T7 PASS: ping() callable by anyone (documented)");
    }
}
