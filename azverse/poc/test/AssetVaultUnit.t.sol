// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// AZverse AssetVault — unit tests of the validator-signature scheme and the
// permissionless expired-withdrawal crank. Mirrors the LIVE configuration:
// 3 validators, powers [20,20,20], required power 40 (= exactly 2-of-3),
// challenge period 86400s, hardCapRatioBps 10000, refillRateMps 12.
// Source under test: poc/src/AssetVault.sol == deployed impl 0x94a99081...
// (verified byte-for-byte, see ci-out/bytecode_verification.json).
//
// NOTE: the contract's two-pointer scan requires signatures in the same order
// as the sorted validator array; the helpers below sign in sorted order.

import {Test} from "forge-std/Test.sol";
import {AssetVault, ValidatorInfo, WithdrawAction} from "../src/AssetVault.sol";
import {MockERC20, TestProxy} from "../src/Mocks.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract AssetVaultUnitTest is Test {
    using MessageHashUtils for bytes32;

    uint256 constant PK1 = 0xA11CE;
    uint256 constant PK2 = 0xB0B;
    uint256 constant PK3 = 0xC0FFEE;
    uint256 constant PK_ATTACKER = 0xBAD;

    uint256 constant CHALLENGE = 86400;
    uint256 constant POWER = 20;
    uint256 constant REQUIRED = 40;

    AssetVault vault;
    MockERC20 token;
    address v1;
    address v2;
    address v3;
    uint256[3] sortedPks; // private keys in ascending-address order
    address attacker = vm.addr(PK_ATTACKER);
    address receiver = address(uint160(0x1234));
    address operator = address(uint160(0x0F0F));
    address thirdParty = address(uint160(0xCA11));

    function setUp() public {
        // sort validators by address ascending; keep the private keys in the same order
        uint256[3] memory pks = [PK1, PK2, PK3];
        address[3] memory vs = [vm.addr(PK1), vm.addr(PK2), vm.addr(PK3)];
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (vs[j] < vs[i]) {
                    (vs[i], vs[j]) = (vs[j], vs[i]);
                    (pks[i], pks[j]) = (pks[j], pks[i]);
                }
            }
        }
        v1 = vs[0];
        v2 = vs[1];
        v3 = vs[2];
        sortedPks = pks;

        AssetVault impl = new AssetVault();
        vault = AssetVault(payable(address(new TestProxy(address(impl), abi.encodeCall(AssetVault.initialize, (CHALLENGE))))));

        // roles
        vault.grantRole(vault.OPERATOR_ROLE(), operator);
        vault.grantRole(vault.VALIDATOR_ROLE(), address(this));
        vault.grantRole(vault.TOKEN_ROLE(), address(this));

        // validator set == live shape: powers 20/20/20, required 40
        ValidatorInfo[] memory set = new ValidatorInfo[](3);
        set[0] = ValidatorInfo(v1, POWER);
        set[1] = ValidatorInfo(v2, POWER);
        set[2] = ValidatorInfo(v3, POWER);
        vault.addValidators(set, REQUIRED);

        // token == live config: hardCapRatioBps 10000, refillRateMps 12
        token = new MockERC20();
        vault.addToken(address(token), 10000, 12);
        token.mint(address(vault), 1_000e6);
    }

    // ---------- helpers ----------

    function _valSet() internal view returns (ValidatorInfo[] memory set) {
        set = new ValidatorInfo[](3);
        set[0] = ValidatorInfo(v1, POWER);
        set[1] = ValidatorInfo(v2, POWER);
        set[2] = ValidatorInfo(v3, POWER);
    }

    function _digest(
        uint256 withdrawalId,
        uint256 chainId,
        address vaultAddr,
        address tokenAddr,
        uint256 amount,
        uint256 fee,
        address rcvr,
        bool isForcePending,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode("requestWithdraw", withdrawalId, chainId, vaultAddr, tokenAddr, amount, fee, rcvr, isForcePending, nonce)
        );
    }

    function _sign(uint256 pk, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
    }

    /// two signatures, in sorted-validator order (valid 2-of-3)
    function _sigTwo(bytes32 d) internal view returns (bytes[] memory sigs) {
        sigs = new bytes[](2);
        sigs[0] = _sign(sortedPks[0], d);
        sigs[1] = _sign(sortedPks[1], d);
    }

    function _request(uint256 id, bool force, uint256 amount, uint256 fee, address rcvr, uint256 nonce, bytes[] memory sigs)
        internal
    {
        WithdrawAction memory action = WithdrawAction(address(token), amount, fee, rcvr);
        vm.prank(operator);
        vault.requestWithdraw(id, force, _valSet(), action, sigs, nonce);
    }

    // ---------- threshold math ----------

    function test_2of3_passes_immediate() public {
        uint256 id = 1;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 7);
        uint256 before = token.balanceOf(receiver);
        _request(id, false, 100e6, 0, receiver, 7, _sigTwo(d));
        assertEq(token.balanceOf(receiver) - before, 100e6, "receiver paid");
        (bool p_, bool pending, bool executed, uint256 a_, address t_, uint256 f_, address r_, uint256 ts_) =
            vault.withdrawals(id);
        assertTrue(executed && !pending, "fast-path executed");
        assertTrue(!p_ && t_ == address(token) && a_ == 100e6 && f_ == 0 && r_ == receiver && ts_ > 0);
    }

    function test_1of3_fails() public {
        uint256 id = 2;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 8);
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = _sign(sortedPks[0], d);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(id, false, 100e6, 0, receiver, 8, sigs);
    }

    function test_duplicate_signature_not_double_counted() public {
        uint256 id = 3;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 9);
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(sortedPks[0], d);
        sigs[1] = _sign(sortedPks[0], d); // same validator twice
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(id, false, 100e6, 0, receiver, 9, sigs);
    }

    function test_nonvalidator_signature_fails() public {
        uint256 id = 4;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 10);
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(PK_ATTACKER, d);
        sigs[1] = _sign(sortedPks[0], d);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(id, false, 100e6, 0, receiver, 10, sigs);
    }

    function test_highS_malleable_signature_rejected() public {
        uint256 id = 5;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 11);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sortedPks[1], d.toEthSignedMessageHash());
        bytes32 sHigh = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141) - uint256(s));
        uint8 vFlip = v == 27 ? 28 : 27;
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(sortedPks[0], d); // one valid
        sigs[1] = abi.encodePacked(r, sHigh, vFlip); // malleable twin of validator #2
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(id, false, 100e6, 0, receiver, 11, sigs);
    }

    function test_eip2098_short_signature_rejected() public {
        uint256 id = 6;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 12);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sortedPks[1], d.toEthSignedMessageHash());
        bytes32 vs = bytes32((uint256(v - 27) << 255) | uint256(s));
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(sortedPks[0], d);
        sigs[1] = abi.encodePacked(r, vs); // 64-byte EIP-2098
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(id, false, 100e6, 0, receiver, 12, sigs);
    }

    // ---------- binding: chainid / contract / fields / nonce ----------

    function test_digest_binds_chainid() public {
        bytes32 here = _digest(1, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 1);
        bytes32 otherChain = _digest(1, 1, address(vault), address(token), 100e6, 0, receiver, false, 1);
        assertTrue(here != otherChain, "chainid is bound");
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = _sign(sortedPks[0], otherChain);
        sigs[1] = _sign(sortedPks[1], otherChain);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(100, false, 100e6, 0, receiver, 13, sigs);
    }

    function test_digest_binds_vault_address() public pure {
        bytes32 here = keccak256(abi.encode("requestWithdraw", uint256(1), uint256(42161), address(0xAAAA), address(0), uint256(1), uint256(0), address(0x1234), false, uint256(1)));
        bytes32 otherVault = keccak256(abi.encode("requestWithdraw", uint256(1), uint256(42161), address(0xDEAD), address(0), uint256(1), uint256(0), address(0x1234), false, uint256(1)));
        assertTrue(here != otherVault, "vault address is bound");
    }

    function test_withdrawalId_is_bound() public {
        bytes32 dForId7 = _digest(7, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 14);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(8, false, 100e6, 0, receiver, 14, _sigTwo(dForId7)); // replay against a different id
    }

    function test_receiver_is_bound() public {
        bytes32 dForA = _digest(9, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 15);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(9, false, 100e6, 0, attacker, 15, _sigTwo(dForA)); // redirect attempt
    }

    function test_amount_is_bound() public {
        bytes32 dForAmount = _digest(10, block.chainid, address(vault), address(token), 100e6, 0, receiver, false, 16);
        vm.expectRevert(AssetVault.NotEnoughValidatorPower.selector);
        _request(10, false, 200e6, 0, receiver, 16, _sigTwo(dForAmount)); // inflate amount
    }

    function test_nonce_replay_reverts() public {
        uint256 id = 11;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 10e6, 0, receiver, false, 17);
        bytes[] memory sigs = _sigTwo(d);
        _request(id, false, 10e6, 0, receiver, 17, sigs);
        vm.expectRevert(AssetVault.NonceAlreadyUsed.selector);
        _request(12, false, 10e6, 0, receiver, 17, sigs);
    }

    // ---------- permissionless crank: executeExpiredPendingWithdrawal ----------

    function _makePending(uint256 id, uint256 amount, uint256 fee, address rcvr, uint256 nonce) internal {
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), amount, fee, rcvr, true, nonce);
        _request(id, true, amount, fee, rcvr, nonce, _sigTwo(d));
    }

    function test_crank_pays_recorded_receiver_only_and_cannot_double_execute() public {
        uint256 id = 20;
        _makePending(id, 50e6, 1e6, receiver, 21);
        vm.warp(block.timestamp + CHALLENGE + 1);

        uint256 recvBefore = token.balanceOf(receiver);
        uint256 callerBefore = token.balanceOf(thirdParty);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
        assertEq(token.balanceOf(receiver) - recvBefore, 49e6, "receiver got amount-fee");
        assertEq(token.balanceOf(thirdParty) - callerBefore, 0, "caller earns nothing");
        assertEq(vault.fees(address(token)), 1e6, "fee credited to protocol");

        vm.expectRevert(AssetVault.WithdrawalAlreadyExecuted.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
    }

    function test_crank_before_expiry_reverts() public {
        uint256 id = 21;
        _makePending(id, 50e6, 0, receiver, 22);
        vm.warp(block.timestamp + CHALLENGE - 1);
        vm.expectRevert(AssetVault.ChallengePeriodNotExpired.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
    }

    function test_crank_paused_reverts() public {
        uint256 id = 22;
        _makePending(id, 50e6, 0, receiver, 23);
        // operator pauses the pending withdrawal (needs validator signatures)
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        bytes32 d = keccak256(abi.encode("batchTogglePendingWithdrawal", ids, block.chainid, address(vault), true, uint256(24)));
        vm.prank(operator);
        vault.batchTogglePendingWithdrawal(ids, true, _valSet(), _sigTwo(d), 24);
        vm.warp(block.timestamp + CHALLENGE + 1);
        vm.expectRevert(AssetVault.WithdrawalPaused.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
    }

    function test_crank_fast_path_withdrawal_reverts() public {
        uint256 id = 23;
        bytes32 d = _digest(id, block.chainid, address(vault), address(token), 10e6, 0, receiver, false, 25);
        _request(id, false, 10e6, 0, receiver, 25, _sigTwo(d)); // executed immediately
        // executed fast-path withdrawal: crank reverts WithdrawalAlreadyExecuted
        vm.expectRevert(AssetVault.WithdrawalAlreadyExecuted.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
    }

    function test_crank_nonexistent_reverts() public {
        vm.expectRevert(AssetVault.WithdrawalExistenceCheckFailed.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(999999);
    }

    // ---------- access control on the gated paths ----------

    function test_attacker_cannot_requestWithdraw() public {
        WithdrawAction memory action = WithdrawAction(address(token), 100e6, 0, attacker);
        bytes[] memory sigs = new bytes[](0);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, vault.OPERATOR_ROLE())
        );
        vm.prank(attacker);
        vault.requestWithdraw(1, false, _valSet(), action, sigs, 1);
    }

    function test_reinitialize_reverts() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vault.initialize(1);
    }

    // ---------- latent ops hazard (documented, not E-U): fee >= amount ----------

    function test_fee_ge_amount_pending_is_permanently_stuck() public {
        uint256 id = 30;
        _makePending(id, 50e6, 50e6, receiver, 31); // operator+validators signed fee == amount
        vm.warp(block.timestamp + CHALLENGE + 1);
        vm.expectRevert(AssetVault.InvalidParameters.selector);
        vm.prank(thirdParty);
        vault.executeExpiredPendingWithdrawal(id);
        // flush path also reverts
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        bytes32 d = keccak256(abi.encode("batchFlushWithdrawals", ids, block.chainid, address(vault), uint256(32)));
        vm.expectRevert(AssetVault.InvalidParameters.selector);
        vm.prank(operator);
        vault.batchFlushWithdrawals(ids, _valSet(), _sigTwo(d), 32);
    }
}
