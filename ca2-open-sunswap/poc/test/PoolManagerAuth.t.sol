// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IPoolManager, MockERC20, Attacker, MockHook} from "../src/Harness.sol";

/// Fork-free harness: the real Tron PoolManager runtime (28,686 bytes, code_hash
/// ebf6db59…, deployed at TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br) is etched at its
/// Tron 20-byte address and exercised on a local EVM (Cancun has TLOAD/TSTORE,
/// which this runtime uses). No mainnet state, no Tron node, no funds.
contract PoolManagerAuthTest is Test {
    address PM;

    IPoolManager pm;
    MockERC20 token;
    Attacker atk;
    address victim = address(0xBEEF);

    bytes4 constant NO_LOCKER = 0x05185ab0; // NoLocker()
    bytes4 constant NOT_SETTLED = 0x5212cba1; // CurrencyNotSettled()
    bytes4 constant LOCKER_SET = 0xc6742a3f; // LockerAlreadySet(address)
    bytes4 constant CLEAR_EXACT = 0xbda73abf; // MustClearExactPositiveDelta()
    bytes4 constant INVALID_CALLER = 0x48f5c3ed; // InvalidCaller()
    bytes4 constant HOOK_PERMS = 0x1dd09583; // HookPermissionsValidationError()

    function setUp() public {
        // Deploy the real creation code so the constructor runs (the runtime has
        // a constructor-set immutable used by noDelegateCall; a bare vm.etch
        // leaves it zero and every call reverts DelegateCallNotAllowed).
        bytes memory creation = vm.parseBytes(vm.readFile("./test/poolmanager_creation.hex"));
        PM = _deploy(creation);
        require(PM != address(0), "deploy failed");
        pm = IPoolManager(PM);

        token = new MockERC20();
        atk = new Attacker(pm, token, victim);
        token.mint(address(atk), 1000e18);
        token.mint(PM, 10000e18);
        vm.deal(address(pm), 10 ether);
        vm.deal(address(atk), 10 ether);
    }

    function _deploy(bytes memory code) internal returns (address addr) {
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }
    }

    function test_runtime_size_and_state() public view {
        assertEq(PM.code.length, 28686, "runtime size");
        assertEq(pm.owner(), address(this), "constructor set owner");
        assertEq(pm.paused(), false, "not paused");
        assertEq(pm.poolCount(), 0, "empty pool count");
    }

    function test_take_outside_lock_reverts() public {
        vm.expectRevert(NO_LOCKER);
        pm.take(address(token), address(this), 1);
    }

    function test_mint_outside_lock_reverts() public {
        vm.expectRevert(NO_LOCKER);
        pm.mint(address(this), address(token), 1);
    }

    function test_clear_outside_lock_reverts() public {
        vm.expectRevert(NO_LOCKER);
        pm.clear(address(token), 1);
    }

    /// The canonical V4 unlock-callback drain: take inside lock, never settle.
    function test_take_inside_lock_without_settle_reverts() public {
        atk.setAction(1);
        vm.expectRevert(NOT_SETTLED);
        atk.attack();
    }

    /// Same for native TRX: the PM holds 10 ether, take succeeds, lock must revert.
    function test_take_native_inside_lock_without_settle_reverts() public {
        atk.setAction(5);
        vm.expectRevert(NOT_SETTLED);
        atk.attack();
    }

    /// mint() debits the caller; without settlement the lock must revert.
    function test_mint_inside_lock_without_payment_reverts() public {
        atk.setAction(3);
        vm.expectRevert(NOT_SETTLED);
        atk.attack();
    }

    /// Pay-then-take is the legitimate path and must succeed with zero net PM gain.
    function test_settle_then_take_succeeds() public {
        atk.setAction(2);
        uint256 before = token.balanceOf(address(atk));
        atk.attack();
        assertEq(token.balanceOf(address(atk)), before, "attacker net zero");
        assertEq(token.balanceOf(PM), 10000e18, "PM net zero change");
        assertEq(pm.getUnsettledDeltasCount(), 0, "deltas settled");
    }

    /// A negative delta cannot be cleared (clear is positive-only).
    function test_clear_negative_delta_reverts() public {
        atk.setAction(8);
        vm.expectRevert(CLEAR_EXACT);
        atk.attack();
    }

    function test_nested_lock_reverts() public {
        atk.setAction(6);
        vm.expectPartialRevert(LOCKER_SET);
        atk.attack();
    }

    function test_burn_other_without_allowance_reverts() public {
        atk.setAction(7);
        atk.attack(); // fully paid mint of 10 claims to victim
        assertEq(pm.balanceOf(victim, address(token)), 10, "victim claim minted");

        atk.setAction(4);
        vm.expectRevert();
        atk.attack();
    }

    function test_transfer_from_without_allowance_reverts() public {
        atk.setAction(7);
        atk.attack();
        vm.expectRevert();
        atk.stealClaim();
    }

    function test_collect_protocol_fees_non_controller_reverts() public {
        vm.expectRevert(INVALID_CALLER);
        pm.collectProtocolFees(address(this), address(token), 1);
    }

    function test_set_protocol_fee_controller_non_owner_reverts() public {
        vm.prank(address(0xCAFE));
        vm.expectRevert();
        pm.setProtocolFeeController(address(this));
    }

    function test_initialize_rejects_hook_permission_mismatch() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0),
            currency1: address(token),
            hooks: address(1), // low bits 0x1, but parameters flags are 0
            fee: 3000,
            parameters: bytes32(uint256(0x10000))
        });
        vm.expectRevert();
        pm.initialize(key, 79228162514264337593543950336);
    }

    function test_initialize_valid_pool() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0),
            currency1: address(token),
            hooks: address(0),
            fee: 3000,
            parameters: bytes32(uint256(0x10000))
        });
        pm.initialize(key, 79228162514264337593543950336);
        assertEq(pm.poolCount(), 1, "pool created");
    }

    function test_initialize_with_hook_bitmap_mismatch_reverts() public {
        MockHook hook = new MockHook(0);
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0),
            currency1: address(token),
            hooks: address(hook),
            fee: 3000,
            parameters: bytes32(uint256(0x10020)) // tickSpacing 1, flag 0x2000
        });
        vm.expectRevert(bytes4(0x7f7506dc)); // HookConfigValidationError()
        pm.initialize(key, 79228162514264337593543950336);
    }

    function test_swap_outside_lock_reverts() public {
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: address(0),
            currency1: address(token),
            hooks: address(0),
            fee: 3000,
            parameters: bytes32(uint256(0x10000))
        });
        IPoolManager.SwapParams memory p =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 1e18, sqrtPriceLimitX96: 0});
        vm.expectRevert(NO_LOCKER);
        pm.swap(key, p, "");
    }
}
