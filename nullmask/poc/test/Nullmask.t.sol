// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {INullmask, INullmaskProxy, ISafe, IAdminUpgradeController, IHonkVerifier} from "../src/INullmask.sol";
import {MaliciousImpl} from "../src/MaliciousImpl.sol";

/// @title Nullmask (Base) — adversarial, read-only-on-mainnet fork verification
/// @notice Every test forks Base at the live head and does eth_call-equivalent calls from a
///         fresh, unprivileged EOA (0x...dEaD). Nothing is broadcast; this runs on a local fork.
///         The goal is to PROVE the negative: no external-unprivileged path moves value out of
///         the pool, and to characterise the privileged (P-class) risk that does exist.
contract NullmaskTest is Test {
    // ---- live Base addresses (verified on-chain at the fork block) ----
    address constant POOL = 0xd64EF1417EB047ed0b54736a5a41F01178C391c6;
    address constant GUARD = 0x0558E584846D1c913205c33588575CF5a20Bf856;
    address constant CONTROLLER = 0xcD12496c9821075fD807c3488F3E0020715DED27;
    address constant SAFE = 0xb2b1A7b415DBDf38308ba8206B0aED433Ed0706F;
    address constant TREASURY = 0xDD85F4AfDE114dc7c480b012Feaa83152a0C0D09;
    address constant WHITELIST_MGR = 0x51429d3A233579e7a46E3848E331dd0FD34674e0;
    address constant WITHDRAWAL_VERIFIER = 0x8eF11508eE2Bdb615AF89a10e9f8b020c9c28d2d;
    address constant TRANSFER_VERIFIER = 0x56eEFC4fd0B1464d4A17BB95d6D2d6fefdeA477C;
    address constant SWAP_VERIFIER = 0xec5700f2Cf0fe43C1F6c2a226FA323583F9453a6;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // whitelisted on Base
    address constant FRESH = 0x000000000000000000000000000000000000dEaD; // unprivileged attacker

    struct GasFee {
        bytes32 maxPriorityFeePerGas;
        bytes32 maxFeePerGas;
        bytes32 gasLimit;
    }
    struct ShieldedWithdrawalParams {
        bytes32[6] noteNullifiers;
        bytes32 txNullifier;
        bytes32 root;
        bytes32 noteChangeCommitment;
        bytes32 noteFeeChangeCommitment;
        bytes32 value;
        bytes32 recipientAddress;
        bytes32 coinId;
        bytes32[9] ciphertextChange;
        bytes32[9] ciphertextFeeChange;
        GasFee gasFee;
        bytes32 nullifiersHash;
        bytes32 fee;
        bytes32 feeTokenAddress;
    }
    struct ShieldedTransferParams {
        bytes32[6] noteNullifiers;
        bytes32 txNullifier;
        bytes32 root;
        bytes32 rkRoot;
        bytes32 noteOutCommitment;
        bytes32 noteChangeCommitment;
        bytes32 noteFeeChangeCommitment;
        bytes32[9] ciphertextOut;
        bytes32[9] ciphertextChange;
        bytes32[9] ciphertextFeeChange;
        GasFee gasFee;
        bytes32 nullifiersHash;
        bytes32 fee;
        bytes32 feeTokenAddress;
    }

    INullmask pool;

    function setUp() public {
        // The CI env injects BASE_RPC_URL but may leave it empty; fall back to a keyless public RPC.
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://base-rpc.publicnode.com";
        vm.createSelectFork(rpc);
        pool = INullmask(POOL);
        console2.log("fork block", block.number);
    }

    // ------------------------------------------------------------------ helpers

    /// @dev Calls POOL as FRESH and returns whether it succeeded and the 4-byte revert selector.
    function _probe(bytes memory data) internal returns (bool ok, bytes4 sel) {
        vm.prank(FRESH);
        bytes memory ret;
        (ok, ret) = POOL.call(data);
        if (!ok && ret.length >= 4) {
            assembly {
                sel := mload(add(ret, 32))
            }
        }
    }

    function _expectRevertSelector(bytes memory data, bytes4 expected, string memory label) internal {
        (bool ok, bytes4 sel) = _probe(data);
        console2.logBytes4(sel);
        console2.log(label);
        assertFalse(ok, string.concat(label, ": call unexpectedly SUCCEEDED for a fresh EOA"));
        assertEq(sel, expected, string.concat(label, ": unexpected revert selector"));
    }

    // ------------------------------------------------------------------ 1. live state

    function test_live_state_snapshot() public view {
        console2.log("== Nullmask Base live state ==");
        console2.log("block", block.number);
        console2.log("pool native balance", POOL.balance);
        console2.log("guard", pool.guard());
        console2.log("controller", pool.upgradeController());
        console2.log("treasury", pool.treasury());
        console2.log("whitelistManager", pool.whitelistManager());
        console2.log("withdrawal verifier", pool.shieldedWithdrawalVerifier());
        console2.log("noteTreeSize", pool.noteTreeSize());
        console2.log("keyRegistrySize", pool.keyRegistrySize());
        console2.log("VIRTUAL_CHAIN_ID", pool.VIRTUAL_CHAIN_ID());
        console2.log("depositFeeBps", pool.depositFeeBps());
        console2.log("withdrawalFeeBps", pool.withdrawalFeeBps());
        console2.log("protocolFeesAccrued(ETH)", pool.protocolFeesAccrued(address(0)));
        console2.log("USDC held", IERC20(USDC).balanceOf(POOL));

        assertEq(pool.guard(), GUARD);
        assertEq(pool.upgradeController(), CONTROLLER);
        assertEq(pool.treasury(), TREASURY);
        assertFalse(pool.paused());
        assertFalse(pool.withdrawalsPaused());
        assertEq(pool.VIRTUAL_CHAIN_ID(), 43618); // Base virtual chain id
        assertGt(POOL.balance, 1 ether, "pool should hold meaningful ETH");
        assertGt(pool.noteTreeSize(), 10_000, "pool should have a populated note tree");
        assertEq(uint256(pool.tokenWhitelist(address(0))), 1); // NATIVE_TOKEN whitelisted
    }

    // ------------------------------------------------------------------ 2. privileged surface reverts for a stranger

    function test_privileged_selectors_revert_for_fresh_eoa() public {
        bytes4 notAuth = INullmask.UpgradeNotAuthorized.selector;
        bytes4 notCtrl = INullmask.NotUpgradeController.selector;
        bytes4 notGuard = INullmask.NotGuard.selector;
        bytes4 notMgr = INullmask.NotWhitelistManager.selector;

        _expectRevertSelector(abi.encodeWithSignature("setGuard(address)", FRESH), notAuth, "setGuard");
        _expectRevertSelector(abi.encodeWithSignature("setRelayer(address,bool)", FRESH, true), notAuth, "setRelayer");
        _expectRevertSelector(abi.encodeWithSignature("setTreasury(address)", FRESH), notAuth, "setTreasury");
        _expectRevertSelector(
            abi.encodeWithSignature("setVerifiers(address,address,address)", FRESH, FRESH, FRESH), notAuth, "setVerifiers"
        );
        _expectRevertSelector(abi.encodeWithSignature("setWhitelistManager(address)", FRESH), notAuth, "setWhitelistManager");
        _expectRevertSelector(abi.encodeWithSignature("setUpgradeController(address)", FRESH), notCtrl, "setUpgradeController");
        _expectRevertSelector(abi.encodeWithSignature("setFeeConfig(uint16,uint16,bool,uint32)", 100, 100, true, 0), notAuth, "setFeeConfig");
        _expectRevertSelector(abi.encodeWithSignature("setTokenParams(address,uint256,uint256,uint256)", address(0), 0, 0, 0), notAuth, "setTokenParams");
        _expectRevertSelector(abi.encodeWithSignature("setDepositLimits(address,uint256,uint256)", address(0), 0, 0), notAuth, "setDepositLimits");
        _expectRevertSelector(abi.encodeWithSignature("setTokenWhitelist(address,uint8)", USDC, 0), notMgr, "setTokenWhitelist");
        _expectRevertSelector(abi.encodeWithSignature("setPaused(bool)", true), notGuard, "setPaused");
        _expectRevertSelector(abi.encodeWithSignature("setWithdrawalsPaused(bool)", true), notAuth, "setWithdrawalsPaused");
        _expectRevertSelector(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", FRESH, bytes("")), notAuth, "upgradeToAndCall");
        _expectRevertSelector(
            abi.encodeWithSignature("approveDeposit(uint256,address,address,uint256,address,uint256,uint256,uint256,uint256)",
                uint256(0), FRESH, address(0), uint256(0), FRESH, uint256(0), uint256(0), uint256(0), uint256(0)),
            notGuard, "approveDeposit");
        _expectRevertSelector(
            abi.encodeWithSignature("rejectDeposit(uint256,address,address,uint256,address,uint256,uint256)",
                uint256(0), FRESH, address(0), uint256(0), FRESH, uint256(0), uint256(0)),
            notGuard, "rejectDeposit");
    }

    // ------------------------------------------------------------------ 3. user paths

    function test_initialize_cannot_be_recalled() public {
        bytes4 invalidInit = bytes4(keccak256("InvalidInitialization()"));
        _expectRevertSelector(
            abi.encodeWithSignature("initialize(address,address,address,address,address)", FRESH, FRESH, FRESH, FRESH, FRESH),
            invalidInit, "initialize");
    }

    function test_withdraw_pending_deposit_is_depositor_scoped() public {
        // index 0 has no pending deposit for FRESH -> DepositNotPending(0)
        bytes4 notPending = INullmask.DepositNotPending.selector;
        _expectRevertSelector(
            abi.encodeWithSignature("withdrawPendingDeposit(uint256,address,address,uint256,uint256)",
                uint256(0), FRESH, address(0), uint256(0), uint256(0)),
            notPending, "withdrawPendingDeposit");
    }

    function test_deposit_without_receiving_key_reverts() public {
        bytes4 noKey = INullmask.ReceivingKeyNotFound.selector;
        _expectRevertSelector(
            abi.encodeWithSignature("deposit(uint256,address)", uint256(1e16), address(0)),
            noKey, "deposit");
    }

    function test_register_receiving_key_requires_address_preimage() public {
        bytes4 notOwner = INullmask.NotAccountOwner.selector;
        _expectRevertSelector(
            abi.encodeWithSignature("registerReceivingKey((bytes32,bytes32,bytes32,bytes32,bytes32,bytes32))",
                bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)),
            notOwner, "registerReceivingKey");
    }

    // ------------------------------------------------------------------ 4. shielded ops require root + proof

    function _emptyWithdrawal(bytes32 root) internal pure returns (ShieldedWithdrawalParams memory p) {
        p.root = root;
        // noteNullifiers, commitments, ciphertexts, gasFee all default to zero
    }

    function test_shielded_withdrawal_requires_known_root() public {
        bytes4 badRoot = INullmask.InvalidNoteTreeRoot.selector;
        bytes memory data = abi.encodeWithSignature(
            "shieldedWithdrawal((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32[9],bytes32[9],(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)",
            _emptyWithdrawal(bytes32(0)), bytes(""));
        _expectRevertSelector(data, badRoot, "shieldedWithdrawal/zero-root");
    }

    function test_shielded_withdrawal_requires_valid_proof() public {
        bytes32 root = bytes32(pool.noteTreeRoot());
        assertTrue(pool.isKnownNoteTreeRoot(uint256(root)), "current root must be known");
        bytes memory data = abi.encodeWithSignature(
            "shieldedWithdrawal((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32[9],bytes32[9],(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)",
            _emptyWithdrawal(root), hex"deadbeef");
        (bool ok,) = _probe(data);
        assertFalse(ok, "shieldedWithdrawal with a garbage proof must revert (verifier rejects it)");
    }

    function test_shielded_transfer_requires_known_key_root() public {
        bytes4 badKeyRoot = INullmask.InvalidKeyRegistryRoot.selector;
        ShieldedTransferParams memory p;
        p.root = bytes32(pool.noteTreeRoot());
        bytes memory data = abi.encodeWithSignature(
            "shieldedTransfer((bytes32[6],bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32[9],bytes32[9],bytes32[9],(bytes32,bytes32,bytes32),bytes32,bytes32,bytes32),bytes)",
            p, hex"deadbeef");
        _expectRevertSelector(data, badKeyRoot, "shieldedTransfer/zero-rkRoot");
    }

    function test_verifiers_reject_garbage_proofs() public {
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = bytes32(uint256(1));
        // UltraHonk verifiers revert with ProofLengthWrongWithLogN on a 4-byte proof.
        vm.expectRevert();
        IHonkVerifier(WITHDRAWAL_VERIFIER).verify(hex"deadbeef", inputs);
        vm.expectRevert();
        IHonkVerifier(TRANSFER_VERIFIER).verify(hex"deadbeef", inputs);
        vm.expectRevert();
        IHonkVerifier(SWAP_VERIFIER).verify(hex"deadbeef", inputs);
    }

    // ------------------------------------------------------------------ 5. the one permissionless value function

    function test_sweep_protocol_fees_only_pays_treasury() public {
        uint256 accrued = pool.protocolFeesAccrued(address(0));
        console2.log("accrued ETH fees", accrued);
        uint256 treasuryBefore = TREASURY.balance;
        uint256 attackerBefore = FRESH.balance;

        vm.prank(FRESH);
        pool.sweepProtocolFees(address(0)); // anyone may call

        assertEq(TREASURY.balance, treasuryBefore + accrued, "fees must land at the treasury");
        assertEq(FRESH.balance, attackerBefore, "the caller must receive nothing");
        assertEq(pool.protocolFeesAccrued(address(0)), 0, "fee counter must be zeroed");
    }

    // ------------------------------------------------------------------ 6. proxy / upgrade wiring

    function test_proxy_implementation_is_locked() public {
        bytes4 already = INullmaskProxy.ImplementationAlreadySet.selector;
        vm.prank(FRESH);
        (bool ok, bytes memory ret) = POOL.call(
            abi.encodeWithSignature("setImplementationAndCall(address,bytes)", FRESH, bytes(""))
        );
        assertFalse(ok, "setImplementationAndCall must revert once set");
        bytes4 sel;
        assembly {
            sel := mload(add(ret, 32))
        }
        assertEq(sel, already);
    }

    function test_controller_admin_is_2of3_safe_and_gates_upgrades() public view {
        assertEq(IAdminUpgradeController(CONTROLLER).admin(), SAFE);
        assertTrue(IAdminUpgradeController(CONTROLLER).canUpgrade(SAFE, address(0)));
        assertFalse(IAdminUpgradeController(CONTROLLER).canUpgrade(FRESH, address(0)));
        assertEq(ISafe(SAFE).getThreshold(), 2);
        address[] memory owners = ISafe(SAFE).getOwners();
        assertEq(owners.length, 3);
        assertEq(ISafe(SAFE).VERSION(), "1.5.0");
        // none of the three owners is the attacker
        for (uint256 i; i < owners.length; i++) {
            assertTrue(owners[i] != FRESH);
            console2.log("safe owner", owners[i]);
        }
    }

    // ------------------------------------------------------------------ 7. P-class: 2-of-3 Safe can upgrade -> drain

    function test_P_class_safe_can_upgrade_and_drain_all_chains_local() public {
        // This is a PRIVILEGED demonstration (P-class), NOT an external-unprivileged path.
        // It shows what the 2-of-3 admin Safe can do once 2 keys sign. No stranger can do this.
        uint256 poolBalance = POOL.balance;
        assertGt(poolBalance, 1 ether);

        MaliciousImpl mal = new MaliciousImpl();
        address attacker = address(0xA11CE);

        vm.prank(SAFE); // simulate the Safe executing upgradeToAndCall
        INullmask(POOL).upgradeToAndCall(address(mal), bytes(""));

        // Now delegatecalls to the hostile impl, in the proxy's context.
        MaliciousImpl(payable(POOL)).drainNative(payable(attacker));
        assertEq(attacker.balance, poolBalance, "P-class upgrade drained the pool");

        // Same trick empties the whitelisted ERC-20 the pool holds.
        uint256 usdc = IERC20(USDC).balanceOf(POOL);
        if (usdc > 0) {
            MaliciousImpl(payable(POOL)).drainToken(USDC, attacker);
            assertEq(IERC20(USDC).balanceOf(POOL), 0);
        }
        console2.log("P-class drain native", poolBalance);
        console2.log("P-class drain USDC", usdc);
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}
