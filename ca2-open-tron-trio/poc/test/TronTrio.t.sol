// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Runtimes} from "../src/Runtimes.sol";

/// @notice EVM etch harness for three Tron mainnet runtimes (read-only analysis).
///
/// TVM-only opcodes CALLTOKENID / CALLTOKENVALUE were replaced by PUSH0 in the
/// runtime constants (length-preserving); for TRX-denominated calls both push 0.
/// Storage slots were recovered from the disassembly and cross-checked with the
/// on-chain getters. These tests model the deployed code, not a Tron fork.
contract TronTrioTest is Test {
    address constant CHERRY =
        address(uint160(0xa47F67a77159307e5DD2Aa0A40ac21D9Bc09565f));
    address constant POKER =
        address(uint160(0x071FefcDC8B960436F96Af0EBC9c996E310Cd913));
    address constant FIRE =
        address(uint160(0x41C68Db76ef6DC3cdc765483ABd949A7210569d5));

    // real on-chain role holders (public addresses; no keys used)
    address constant POKER_OWNER =
        address(uint160(0x391A93476f1325c549716EFaB3aFB893e5bd3D1F));

    function setUp() public {
        vm.etch(CHERRY, Runtimes.CHERRY);
        vm.etch(POKER, Runtimes.POKER);
        vm.etch(FIRE, Runtimes.FIRE);
        vm.deal(CHERRY, 1000 ether);
        vm.deal(POKER, 1000 ether);
        vm.deal(FIRE, 1000 ether);
        // Cherry constructor state: slot0 "unlocked" == true; slot7 tracks the
        // global pledge total and is decremented (SafeMath) on payout.
        vm.store(CHERRY, bytes32(uint256(0)), bytes32(uint256(1)));
        vm.store(CHERRY, bytes32(uint256(7)), bytes32(uint256(1000 ether)));
    }

    function _callFrom(address target, bytes memory data, address from)
        internal
        returns (bool ok, bytes memory ret)
    {
        vm.prank(from);
        (ok, ret) = target.call{gas: 2_000_000}(data);
    }

    // ---------------------------------------------------------------- CherryPool
    function _cherrySlot(address user) internal pure returns (bytes32) {
        // tokenUserAmountOf(token,user) -> mapping[token][user] at slot 11;
        // withdrawTronAll reads mapping[address(0)][msg.sender].
        bytes32 inner = keccak256(abi.encode(uint256(0), uint256(11)));
        return keccak256(abi.encode(uint256(uint160(user)), inner));
    }

    function test_cherry_withdrawTronAll_pays_only_senders_own_claim() public {
        address user = address(0xBEEF01);
        vm.store(CHERRY, _cherrySlot(user), bytes32(uint256(123 ether)));
        uint256 before = user.balance;

        (bool ok, bytes memory ret) =
            _callFrom(CHERRY, abi.encodeWithSignature("withdrawTronAll()"), user);
        assertTrue(ok, "call failed");
        assertEq(abi.decode(ret, (bool)), true, "expected true");
        assertEq(user.balance, before + 123 ether, "paid stored claim");
        assertEq(CHERRY.balance, 877 ether, "rest untouched");
        assertEq(uint256(vm.load(CHERRY, _cherrySlot(user))), 0, "claim zeroed");
    }

    function test_cherry_withdrawTronAll_fresh_caller_gets_zero() public {
        address user = address(0xBEEF02);
        uint256 before = user.balance;
        (bool ok, bytes memory ret) =
            _callFrom(CHERRY, abi.encodeWithSignature("withdrawTronAll()"), user);
        assertTrue(ok, "call failed");
        assertEq(abi.decode(ret, (bool)), false, "expected false");
        assertEq(user.balance, before, "no payout");
        assertEq(CHERRY.balance, 1000 ether, "balance untouched");
    }

    // ------------------------------------------------------------------- PokerGame
    function _pokerBalSlot(address user) internal pure returns (bytes32) {
        // balance_of mapping at slot 14.
        return keccak256(abi.encode(uint256(uint160(user)), uint256(14)));
    }

    function test_poker_withdraw_pays_only_balance_of_sender() public {
        address user = address(0xBEEF03);
        vm.store(POKER, _pokerBalSlot(user), bytes32(uint256(50 ether)));
        uint256 before = user.balance;
        (bool ok,) = _callFrom(POKER, abi.encodeWithSignature("withdraw()"), user);
        assertTrue(ok, "call failed");
        assertEq(user.balance, before + 50 ether, "paid balance_of");
        assertEq(POKER.balance, 950 ether, "rest untouched");
        assertEq(uint256(vm.load(POKER, _pokerBalSlot(user))), 0, "balance zeroed");
    }

    function test_poker_withdraw_fresh_caller_early_returns() public {
        address user = address(0xBEEF04);
        uint256 before = user.balance;
        (bool ok,) = _callFrom(POKER, abi.encodeWithSignature("withdraw()"), user);
        assertTrue(ok, "call failed");
        assertEq(user.balance, before, "no payout");
        assertEq(POKER.balance, 1000 ether, "balance untouched");
    }

    function test_poker_withdrawAllBalance_owner_only() public {
        address user = address(0xBEEF05);
        (bool ok1,) =
            _callFrom(POKER, abi.encodeWithSignature("withdrawAllBalance()"), user);
        assertFalse(ok1, "non-owner must revert");

        vm.store(POKER, bytes32(uint256(5)), bytes32(uint256(uint160(POKER_OWNER))));
        uint256 before = POKER_OWNER.balance;
        (bool ok2,) =
            _callFrom(POKER, abi.encodeWithSignature("withdrawAllBalance()"), POKER_OWNER);
        assertTrue(ok2, "owner call failed");
        assertEq(POKER_OWNER.balance, before + 1000 ether, "owner drains all (P)");
        assertEq(POKER.balance, 0, "emptied");
    }

    // --------------------------------------------------------------------- FireFull
    function _fireField8Slot(address user) internal pure returns (bytes32) {
        // players mapping at slot 15; withdraw() pays field offset 8.
        bytes32 base = keccak256(abi.encode(uint256(uint160(user)), uint256(15)));
        return bytes32(uint256(base) + 8);
    }

    function test_firefull_withdraw_pays_only_players_field8() public {
        address user = address(0xBEEF06);
        vm.store(FIRE, _fireField8Slot(user), bytes32(uint256(77 ether)));
        uint256 before = user.balance;
        (bool ok,) = _callFrom(FIRE, abi.encodeWithSignature("withdraw()"), user);
        assertTrue(ok, "call failed");
        assertEq(user.balance, before + 77 ether, "paid field8");
        assertEq(FIRE.balance, 923 ether, "rest untouched");
        assertEq(uint256(vm.load(FIRE, _fireField8Slot(user))), 0, "field zeroed");
    }

    function test_firefull_withdraw_fresh_caller_gets_zero() public {
        address user = address(0xBEEF07);
        uint256 before = user.balance;
        (bool ok,) = _callFrom(FIRE, abi.encodeWithSignature("withdraw()"), user);
        assertTrue(ok, "call failed");
        assertEq(user.balance, before, "no payout");
        assertEq(FIRE.balance, 1000 ether, "balance untouched");
    }

    function _fireSuperSlot(address user, uint256 field) internal pure returns (bytes32) {
        // superPlayerList mapping at slot 14, struct fields 0..3.
        bytes32 base = keccak256(abi.encode(uint256(uint160(user)), uint256(14)));
        return bytes32(uint256(base) + field);
    }

    function test_firefull_superPlayerWithdraw_gated_and_holder_only() public {
        address user = address(0xBEEF08);
        (bool ok1,) =
            _callFrom(FIRE, abi.encodeWithSignature("superPlayerWithdraw()"), user);
        assertFalse(ok1, "fresh caller must revert");

        // model a real super player: players[user].superPlayer=true (field12) and
        // superPlayerList[user] = (true, -, 100 ether profit, 41 team members)
        bytes32 base15 = keccak256(abi.encode(uint256(uint160(user)), uint256(15)));
        vm.store(FIRE, base15, bytes32(uint256(1)));              // players.joined
        vm.store(FIRE, bytes32(uint256(base15) + 12), bytes32(uint256(1)));
        vm.store(FIRE, _fireSuperSlot(user, 0), bytes32(uint256(1)));
        vm.store(FIRE, _fireSuperSlot(user, 2), bytes32(uint256(100 ether)));
        vm.store(FIRE, _fireSuperSlot(user, 3), bytes32(uint256(41)));
        vm.store(FIRE, bytes32(uint256(3)), bytes32(uint256(200 ether)));  // global checkpoint > field2
        uint256 before = user.balance;
        (bool ok2, bytes memory ret2) =
            _callFrom(FIRE, abi.encodeWithSignature("superPlayerWithdraw()"), user);
        if (!ok2) emit log_bytes(ret2);
        assertTrue(ok2, "super player call failed");
        assertGt(user.balance, before, "super player receives TRX (H-O)");
    }

    function test_firefull_sedimentaryAssetWithdraw_owners_only() public {
        address user = address(0xBEEF09);
        (bool ok1,) =
            _callFrom(FIRE, abi.encodeWithSignature("sedimentaryAssetWithdraw()"), user);
        assertFalse(ok1, "non-owner must revert");

        bytes32 ownersSlot =
            keccak256(abi.encode(uint256(uint160(user)), uint256(17)));
        vm.store(FIRE, ownersSlot, bytes32(uint256(1)));
        vm.store(FIRE, bytes32(uint256(4)), bytes32(uint256(1 ether)));
        uint256 before = user.balance;
        (bool ok2,) =
            _callFrom(FIRE, abi.encodeWithSignature("sedimentaryAssetWithdraw()"), user);
        assertTrue(ok2, "owner call failed");
        assertEq(user.balance, before + 1 ether, "owner receives sedimentaryAsset (P)");
    }
}
