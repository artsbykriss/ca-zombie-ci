// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;
import {PermissionType} from "../core/IACL.sol";
import {FheType} from "../core/FheType.sol";
import "../core/EncryptedTypes.sol";
import "./Impl.sol";
import {IDecryption} from "@primuslabs/spacebridge-contracts/contracts/interfaces/IDecryption.sol";

library FHE {
    /// @notice Returned if the sender is not allowed to use the handle.
    error SenderNotAllowedToUseHandle(bytes32 handle, address sender);

    /**
     * @notice Sets the system contract addresses.
     */
    function setFHEConfig(FHEConfig memory fheConfig) internal {
        Impl.setFHEConfig(fheConfig);
    }

    // /**
    //  * @notice Cleans the transient storage for the ACL (accounts).
    //  */
    // function cleanTransientStorage() internal {
    //     Impl.cleanTransientStorageACL();
    // }

    // =============== USING Decryption BEGIN ==================
    /**
     * @notice Requests the decryption of a list of handles.
     */
    function requestDecryption(bytes32[] memory ctsHandles, bytes4 callbackSelector) internal returns (uint256 requestID) {
        requestID = requestDecryptionWithCallback(ctsHandles, callbackSelector);
    }

    /**
     * @notice This function must be called inside the dApp contract’s callback.
     */
    function checkSignatures(uint256 requestID, bytes memory cleartexts, bytes memory decryptionProof) internal {
        Impl.checkSignatures(requestID, cleartexts, decryptionProof);
    }

    /**
     * @notice Verifies a decryption proof directly against a caller-supplied list of handles.
     * @param handlesList The list of ciphertext handles the cleartexts correspond to.
     * @param cleartexts The ABI-encoded cleartext values, in the same order as `handlesList`.
     * @param decryptionProof The proof to verify against `(handlesList, cleartexts)`.
     */
    function checkSignatures(
        bytes32[] memory handlesList,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) internal {
        if (!Impl._verifySignatures(handlesList, cleartexts, decryptionProof)) {
            revert Impl.InvalidSignatures();
        }
    }

    /**
     * @notice Reverts unless msg.sender is a registered AlphaTrion tx sender.
     * @dev Use this in a modifier for callback functions.
     */
    function checkAlphatrionTxSender() internal view {
        Impl.checkAlphatrionTxSender();
    }

    function requestDecryptionWithCallback(bytes32[] memory ctHandles, bytes4 callbackSelector) internal returns (uint256 requestID) {
        // requestID = Impl.requestDecryptionWithCallback(ctHandles, callbackSelector);
        requestID = 0;
    }
    function requestPublicDecryption(bytes32[] memory ctHandles, bytes calldata extraData) internal returns (uint256 requestID) {
        // requestID = Impl.requestPublicDecryption(ctHandles, extraData);
        requestID = 0;
    }
    // function requestUserDecryption(
    //     bytes32[] memory ctHandles,
    //     IDecryption.RequestValidity calldata requestValidity,
    //     address userAddress,
    //     bytes calldata publicKey,
    //     bytes calldata signature,
    //     bytes calldata extraData
    // ) internal returns (uint256 requestID) {
    //     requestID = Impl.requestUserDecryption(ctHandles, requestValidity, userAddress, publicKey, signature, extraData);
    // }
    // =============== USING Decryption END ==================

    /**
     * @notice FHE Fee manager.
     */
    function chargeFee(address user, uint256 amount) internal {
        Impl.chargeFee(user, amount);
    }
    // DISABLED
    // function refundFee(address user, uint256 amount) internal {
    //     Impl.refundFee(user, amount);
    // }
    // function balanceOfFee(address user) internal view returns (uint256) {
    //     return Impl.balanceOfFee(user);
    // }

    // The following are auto-generated, between 'AUTO-GENERATED BEGIN' and 'AUTO-GENERATED END'
    // AUTO-GENERATED BEGIN

    /// @notice op:and on type:bool
    function and(ve_bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.and(ve_bool.unwrap(a), ve_bool.unwrap(b), false));
    }
    function and(uve_bool calldata a, ve_bool b) internal returns (ve_bool) {
        return and(fromUnverified(a), b);
    }
    function and(ve_bool a, uve_bool calldata b) internal returns (ve_bool) {
        return and(a, fromUnverified(b));
    }
    function and(uve_bool calldata a, uve_bool calldata b) internal returns (ve_bool) {
        return and(fromUnverified(a), fromUnverified(b));
    }
    function and(ve_bool a, bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.and(ve_bool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }
    function and(bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.and(ve_bool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }
    function and(uve_bool calldata a, bool b) internal returns (ve_bool) {
        return and(fromUnverified(a), b);
    }
    function and(bool a, uve_bool calldata b) internal returns (ve_bool) {
        return and(a, fromUnverified(b));
    }

    /// @notice op:or on type:bool
    function or(ve_bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.or(ve_bool.unwrap(a), ve_bool.unwrap(b), false));
    }
    function or(uve_bool calldata a, ve_bool b) internal returns (ve_bool) {
        return or(fromUnverified(a), b);
    }
    function or(ve_bool a, uve_bool calldata b) internal returns (ve_bool) {
        return or(a, fromUnverified(b));
    }
    function or(uve_bool calldata a, uve_bool calldata b) internal returns (ve_bool) {
        return or(fromUnverified(a), fromUnverified(b));
    }
    function or(ve_bool a, bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.or(ve_bool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }
    function or(bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.or(ve_bool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }
    function or(uve_bool calldata a, bool b) internal returns (ve_bool) {
        return or(fromUnverified(a), b);
    }
    function or(bool a, uve_bool calldata b) internal returns (ve_bool) {
        return or(a, fromUnverified(b));
    }

    /// @notice op:xor on type:bool
    function xor(ve_bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.xor(ve_bool.unwrap(a), ve_bool.unwrap(b), false));
    }
    function xor(uve_bool calldata a, ve_bool b) internal returns (ve_bool) {
        return xor(fromUnverified(a), b);
    }
    function xor(ve_bool a, uve_bool calldata b) internal returns (ve_bool) {
        return xor(a, fromUnverified(b));
    }
    function xor(uve_bool calldata a, uve_bool calldata b) internal returns (ve_bool) {
        return xor(fromUnverified(a), fromUnverified(b));
    }
    function xor(ve_bool a, bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.xor(ve_bool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }
    function xor(bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.xor(ve_bool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }
    function xor(uve_bool calldata a, bool b) internal returns (ve_bool) {
        return xor(fromUnverified(a), b);
    }
    function xor(bool a, uve_bool calldata b) internal returns (ve_bool) {
        return xor(a, fromUnverified(b));
    }

    /// @notice op:not on type:bool
    function not(ve_bool a) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.not(ve_bool.unwrap(a)));
    }
    function not(uve_bool calldata a) internal returns (ve_bool) {
        return not(fromUnverified(a));
    }

    /// @notice op:ne on type:bool
    function ne(ve_bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.ne(ve_bool.unwrap(a), ve_bool.unwrap(b), false));
    }
    function ne(uve_bool calldata a, ve_bool b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_bool a, uve_bool calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_bool calldata a, uve_bool calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_bool a, bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.ne(ve_bool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }
    function ne(bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.ne(ve_bool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }
    function ne(uve_bool calldata a, bool b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(bool a, uve_bool calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:bool
    function eq(ve_bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.eq(ve_bool.unwrap(a), ve_bool.unwrap(b), false));
    }
    function eq(uve_bool calldata a, ve_bool b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_bool a, uve_bool calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_bool calldata a, uve_bool calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_bool a, bool b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEBool(false);
        }
        return ve_bool.wrap(Impl.eq(ve_bool.unwrap(a), bytes32(uint256(b ? 1 : 0)), true));
    }
    function eq(bool a, ve_bool b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEBool(false);
        }
        return ve_bool.wrap(Impl.eq(ve_bool.unwrap(b), bytes32(uint256(a ? 1 : 0)), true));
    }
    function eq(uve_bool calldata a, bool b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(bool a, uve_bool calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:bool
    function select(ve_bool control, ve_bool ifTrue, ve_bool ifFalse) internal returns (ve_bool) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEBool(false);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEBool(false);
        }
        return ve_bool.wrap(Impl.select(ve_bool.unwrap(control), ve_bool.unwrap(ifTrue), ve_bool.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_bool calldata ifTrue, ve_bool ifFalse) internal returns (ve_bool) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_bool ifTrue, uve_bool calldata ifFalse) internal returns (ve_bool) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_bool v) internal pure returns (bool) {
        return ve_bool.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_bool integer.
    function fromUnverified(uve_bool memory input) internal returns (ve_bool) {
        if (input.data.length != 0) {
            return ve_bool.wrap(Impl.verify(input.handle, input.data, FheType.Bool));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEBool(false);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_bool.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_bool integer.
    function asVEBool(bool value) internal returns (ve_bool) {
        return ve_bool.wrap(Impl.trivialEncrypt(value ? 1 : 0, FheType.Bool));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_bool value) internal pure returns (bytes32 ct) {
        ct = ve_bool.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_bool value, address account) internal returns (ve_bool) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_bool value, address account, PermissionType pt) internal returns (ve_bool) {
        Impl.accessPolicy(ve_bool.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_bool value) internal {
        Impl.allowForDecryption(ve_bool.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_bool value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_bool.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_bool value) internal view returns (bool) {
        return Impl.isAllowed(ve_bool.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_bool value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_bool.unwrap(value));
    }

    /// @notice op:add on type:uint8
    function add(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.add(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function add(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.add(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.add(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return add(fromUnverified(a), b);
    }
    function add(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint8
    function sub(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.sub(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function sub(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.sub(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        ve_uint8 aEnc = asVEUint8(a);
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.sub(ve_uint8.unwrap(aEnc), ve_uint8.unwrap(b), false));
    }
    function sub(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint8
    function mul(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.mul(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function mul(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.mul(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.mul(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint8
    function div(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.div(ve_uint8.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint8
    function bit_and(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_and(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function bit_and(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_and(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_and(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint8
    function bit_or(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_or(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function bit_or(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_or(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_or(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint8
    function bit_xor(ve_uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_xor(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function bit_xor(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_uint8) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint8 a, uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_xor(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint8 a, ve_uint8 b) internal returns (ve_uint8) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_xor(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint8 calldata a, uint8 b) internal returns (ve_uint8) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint8 a, uve_uint8 calldata b) internal returns (ve_uint8) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint8
    function bit_not(ve_uint8 a) internal returns (ve_uint8) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.bit_not(ve_uint8.unwrap(a)));
    }
    function bit_not(uve_uint8 calldata a) internal returns (ve_uint8) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint8
    function lt(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function lt(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint8
    function gt(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function gt(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint8
    function le(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function le(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint8
    function ge(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function ge(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint8
    function ne(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function ne(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint8
    function eq(ve_uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint8.unwrap(a), ve_uint8.unwrap(b), false));
    }
    function eq(uve_uint8 calldata a, ve_uint8 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint8 calldata a, uve_uint8 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint8 a, uint8 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint8.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint8 a, ve_uint8 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint8(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint8.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint8 calldata a, uint8 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint8 a, uve_uint8 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint8
    function select(ve_bool control, ve_uint8 ifTrue, ve_uint8 ifFalse) internal returns (ve_uint8) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint8(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint8(0);
        }
        return ve_uint8.wrap(Impl.select(ve_bool.unwrap(control), ve_uint8.unwrap(ifTrue), ve_uint8.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint8 calldata ifTrue, ve_uint8 ifFalse) internal returns (ve_uint8) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint8 ifTrue, uve_uint8 calldata ifFalse) internal returns (ve_uint8) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint8 v) internal pure returns (bool) {
        return ve_uint8.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint8 integer.
    function fromUnverified(uve_uint8 memory input) internal returns (ve_uint8) {
        if (input.data.length != 0) {
            return ve_uint8.wrap(Impl.verify(input.handle, input.data, FheType.Uint8));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint8(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint8.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint8 integer.
    function asVEUint8(uint8 value) internal returns (ve_uint8) {
        return ve_uint8.wrap(Impl.trivialEncrypt(uint8(value), FheType.Uint8));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint8 value) internal pure returns (bytes32 ct) {
        ct = ve_uint8.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint8 value, address account) internal returns (ve_uint8) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint8 value, address account, PermissionType pt) internal returns (ve_uint8) {
        Impl.accessPolicy(ve_uint8.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint8 value) internal {
        Impl.allowForDecryption(ve_uint8.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint8 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint8.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint8 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint8.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint8 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint8.unwrap(value));
    }

    /// @notice op:add on type:uint16
    function add(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.add(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function add(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.add(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.add(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return add(fromUnverified(a), b);
    }
    function add(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint16
    function sub(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.sub(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function sub(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.sub(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        ve_uint16 aEnc = asVEUint16(a);
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.sub(ve_uint16.unwrap(aEnc), ve_uint16.unwrap(b), false));
    }
    function sub(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint16
    function mul(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.mul(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function mul(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.mul(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.mul(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint16
    function div(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.div(ve_uint16.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint16
    function bit_and(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_and(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function bit_and(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_and(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_and(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint16
    function bit_or(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_or(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function bit_or(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_or(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_or(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint16
    function bit_xor(ve_uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_xor(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function bit_xor(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_uint16) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint16 a, uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_xor(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint16 a, ve_uint16 b) internal returns (ve_uint16) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_xor(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint16 calldata a, uint16 b) internal returns (ve_uint16) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint16 a, uve_uint16 calldata b) internal returns (ve_uint16) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint16
    function bit_not(ve_uint16 a) internal returns (ve_uint16) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.bit_not(ve_uint16.unwrap(a)));
    }
    function bit_not(uve_uint16 calldata a) internal returns (ve_uint16) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint16
    function lt(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function lt(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint16
    function gt(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function gt(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint16
    function le(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function le(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint16
    function ge(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function ge(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint16
    function ne(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function ne(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint16
    function eq(ve_uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint16.unwrap(a), ve_uint16.unwrap(b), false));
    }
    function eq(uve_uint16 calldata a, ve_uint16 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint16 calldata a, uve_uint16 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint16 a, uint16 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint16.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint16 a, ve_uint16 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint16(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint16.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint16 calldata a, uint16 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint16 a, uve_uint16 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint16
    function select(ve_bool control, ve_uint16 ifTrue, ve_uint16 ifFalse) internal returns (ve_uint16) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint16(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint16(0);
        }
        return ve_uint16.wrap(Impl.select(ve_bool.unwrap(control), ve_uint16.unwrap(ifTrue), ve_uint16.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint16 calldata ifTrue, ve_uint16 ifFalse) internal returns (ve_uint16) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint16 ifTrue, uve_uint16 calldata ifFalse) internal returns (ve_uint16) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint16 v) internal pure returns (bool) {
        return ve_uint16.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint16 integer.
    function fromUnverified(uve_uint16 memory input) internal returns (ve_uint16) {
        if (input.data.length != 0) {
            return ve_uint16.wrap(Impl.verify(input.handle, input.data, FheType.Uint16));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint16(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint16.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint16 integer.
    function asVEUint16(uint16 value) internal returns (ve_uint16) {
        return ve_uint16.wrap(Impl.trivialEncrypt(uint16(value), FheType.Uint16));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint16 value) internal pure returns (bytes32 ct) {
        ct = ve_uint16.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint16 value, address account) internal returns (ve_uint16) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint16 value, address account, PermissionType pt) internal returns (ve_uint16) {
        Impl.accessPolicy(ve_uint16.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint16 value) internal {
        Impl.allowForDecryption(ve_uint16.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint16 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint16.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint16 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint16.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint16 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint16.unwrap(value));
    }

    /// @notice op:add on type:uint32
    function add(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.add(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function add(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.add(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.add(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return add(fromUnverified(a), b);
    }
    function add(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint32
    function sub(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.sub(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function sub(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.sub(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        ve_uint32 aEnc = asVEUint32(a);
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.sub(ve_uint32.unwrap(aEnc), ve_uint32.unwrap(b), false));
    }
    function sub(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint32
    function mul(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.mul(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function mul(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.mul(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.mul(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint32
    function div(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.div(ve_uint32.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint32
    function bit_and(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_and(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function bit_and(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_and(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_and(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint32
    function bit_or(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_or(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function bit_or(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_or(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_or(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint32
    function bit_xor(ve_uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_xor(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function bit_xor(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_uint32) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint32 a, uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_xor(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint32 a, ve_uint32 b) internal returns (ve_uint32) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_xor(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint32 calldata a, uint32 b) internal returns (ve_uint32) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint32 a, uve_uint32 calldata b) internal returns (ve_uint32) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint32
    function bit_not(ve_uint32 a) internal returns (ve_uint32) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.bit_not(ve_uint32.unwrap(a)));
    }
    function bit_not(uve_uint32 calldata a) internal returns (ve_uint32) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint32
    function lt(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function lt(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint32
    function gt(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function gt(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint32
    function le(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function le(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint32
    function ge(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function ge(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint32
    function ne(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function ne(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint32
    function eq(ve_uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint32.unwrap(a), ve_uint32.unwrap(b), false));
    }
    function eq(uve_uint32 calldata a, ve_uint32 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint32 calldata a, uve_uint32 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint32 a, uint32 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint32.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint32 a, ve_uint32 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint32(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint32.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint32 calldata a, uint32 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint32 a, uve_uint32 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint32
    function select(ve_bool control, ve_uint32 ifTrue, ve_uint32 ifFalse) internal returns (ve_uint32) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint32(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint32(0);
        }
        return ve_uint32.wrap(Impl.select(ve_bool.unwrap(control), ve_uint32.unwrap(ifTrue), ve_uint32.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint32 calldata ifTrue, ve_uint32 ifFalse) internal returns (ve_uint32) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint32 ifTrue, uve_uint32 calldata ifFalse) internal returns (ve_uint32) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint32 v) internal pure returns (bool) {
        return ve_uint32.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint32 integer.
    function fromUnverified(uve_uint32 memory input) internal returns (ve_uint32) {
        if (input.data.length != 0) {
            return ve_uint32.wrap(Impl.verify(input.handle, input.data, FheType.Uint32));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint32(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint32.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint32 integer.
    function asVEUint32(uint32 value) internal returns (ve_uint32) {
        return ve_uint32.wrap(Impl.trivialEncrypt(uint32(value), FheType.Uint32));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint32 value) internal pure returns (bytes32 ct) {
        ct = ve_uint32.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint32 value, address account) internal returns (ve_uint32) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint32 value, address account, PermissionType pt) internal returns (ve_uint32) {
        Impl.accessPolicy(ve_uint32.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint32 value) internal {
        Impl.allowForDecryption(ve_uint32.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint32 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint32.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint32 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint32.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint32 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint32.unwrap(value));
    }

    /// @notice op:add on type:uint64
    function add(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.add(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function add(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.add(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.add(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return add(fromUnverified(a), b);
    }
    function add(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint64
    function sub(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.sub(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function sub(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.sub(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        ve_uint64 aEnc = asVEUint64(a);
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.sub(ve_uint64.unwrap(aEnc), ve_uint64.unwrap(b), false));
    }
    function sub(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint64
    function mul(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.mul(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function mul(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.mul(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.mul(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint64
    function div(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.div(ve_uint64.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint64
    function bit_and(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_and(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function bit_and(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_and(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_and(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint64
    function bit_or(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_or(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function bit_or(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_or(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_or(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint64
    function bit_xor(ve_uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_xor(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function bit_xor(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_uint64) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint64 a, uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_xor(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint64 a, ve_uint64 b) internal returns (ve_uint64) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_xor(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint64 calldata a, uint64 b) internal returns (ve_uint64) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint64 a, uve_uint64 calldata b) internal returns (ve_uint64) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint64
    function bit_not(ve_uint64 a) internal returns (ve_uint64) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.bit_not(ve_uint64.unwrap(a)));
    }
    function bit_not(uve_uint64 calldata a) internal returns (ve_uint64) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint64
    function lt(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function lt(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint64
    function gt(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function gt(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint64
    function le(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function le(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint64
    function ge(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function ge(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint64
    function ne(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function ne(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint64
    function eq(ve_uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint64.unwrap(a), ve_uint64.unwrap(b), false));
    }
    function eq(uve_uint64 calldata a, ve_uint64 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint64 calldata a, uve_uint64 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint64 a, uint64 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint64.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint64 a, ve_uint64 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint64(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint64.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint64 calldata a, uint64 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint64 a, uve_uint64 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint64
    function select(ve_bool control, ve_uint64 ifTrue, ve_uint64 ifFalse) internal returns (ve_uint64) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint64(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint64(0);
        }
        return ve_uint64.wrap(Impl.select(ve_bool.unwrap(control), ve_uint64.unwrap(ifTrue), ve_uint64.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint64 calldata ifTrue, ve_uint64 ifFalse) internal returns (ve_uint64) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint64 ifTrue, uve_uint64 calldata ifFalse) internal returns (ve_uint64) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint64 v) internal pure returns (bool) {
        return ve_uint64.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint64 integer.
    function fromUnverified(uve_uint64 memory input) internal returns (ve_uint64) {
        if (input.data.length != 0) {
            return ve_uint64.wrap(Impl.verify(input.handle, input.data, FheType.Uint64));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint64(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint64.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint64 integer.
    function asVEUint64(uint64 value) internal returns (ve_uint64) {
        return ve_uint64.wrap(Impl.trivialEncrypt(uint64(value), FheType.Uint64));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint64 value) internal pure returns (bytes32 ct) {
        ct = ve_uint64.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint64 value, address account) internal returns (ve_uint64) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint64 value, address account, PermissionType pt) internal returns (ve_uint64) {
        Impl.accessPolicy(ve_uint64.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint64 value) internal {
        Impl.allowForDecryption(ve_uint64.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint64 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint64.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint64 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint64.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint64 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint64.unwrap(value));
    }

    /// @notice op:add on type:uint128
    function add(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.add(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function add(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.add(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.add(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return add(fromUnverified(a), b);
    }
    function add(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint128
    function sub(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.sub(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function sub(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.sub(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        ve_uint128 aEnc = asVEUint128(a);
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.sub(ve_uint128.unwrap(aEnc), ve_uint128.unwrap(b), false));
    }
    function sub(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint128
    function mul(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.mul(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function mul(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.mul(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.mul(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint128
    function div(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.div(ve_uint128.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint128
    function bit_and(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_and(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function bit_and(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_and(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_and(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint128
    function bit_or(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_or(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function bit_or(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_or(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_or(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint128
    function bit_xor(ve_uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_xor(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function bit_xor(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_uint128) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint128 a, uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_xor(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint128 a, ve_uint128 b) internal returns (ve_uint128) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_xor(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint128 calldata a, uint128 b) internal returns (ve_uint128) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint128 a, uve_uint128 calldata b) internal returns (ve_uint128) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint128
    function bit_not(ve_uint128 a) internal returns (ve_uint128) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.bit_not(ve_uint128.unwrap(a)));
    }
    function bit_not(uve_uint128 calldata a) internal returns (ve_uint128) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint128
    function lt(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function lt(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint128
    function gt(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function gt(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint128
    function le(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function le(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint128
    function ge(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function ge(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint128
    function ne(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function ne(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint128
    function eq(ve_uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint128.unwrap(a), ve_uint128.unwrap(b), false));
    }
    function eq(uve_uint128 calldata a, ve_uint128 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint128 calldata a, uve_uint128 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint128 a, uint128 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint128.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint128 a, ve_uint128 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint128(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint128.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint128 calldata a, uint128 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint128 a, uve_uint128 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint128
    function select(ve_bool control, ve_uint128 ifTrue, ve_uint128 ifFalse) internal returns (ve_uint128) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint128(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint128(0);
        }
        return ve_uint128.wrap(Impl.select(ve_bool.unwrap(control), ve_uint128.unwrap(ifTrue), ve_uint128.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint128 calldata ifTrue, ve_uint128 ifFalse) internal returns (ve_uint128) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint128 ifTrue, uve_uint128 calldata ifFalse) internal returns (ve_uint128) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint128 v) internal pure returns (bool) {
        return ve_uint128.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint128 integer.
    function fromUnverified(uve_uint128 memory input) internal returns (ve_uint128) {
        if (input.data.length != 0) {
            return ve_uint128.wrap(Impl.verify(input.handle, input.data, FheType.Uint128));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint128(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint128.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint128 integer.
    function asVEUint128(uint128 value) internal returns (ve_uint128) {
        return ve_uint128.wrap(Impl.trivialEncrypt(uint128(value), FheType.Uint128));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint128 value) internal pure returns (bytes32 ct) {
        ct = ve_uint128.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint128 value, address account) internal returns (ve_uint128) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint128 value, address account, PermissionType pt) internal returns (ve_uint128) {
        Impl.accessPolicy(ve_uint128.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint128 value) internal {
        Impl.allowForDecryption(ve_uint128.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint128 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint128.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint128 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint128.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint128 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint128.unwrap(value));
    }

    /// @notice op:add on type:uint256
    function add(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.add(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function add(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return add(fromUnverified(a), b);
    }
    function add(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return add(a, fromUnverified(b));
    }
    function add(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return add(fromUnverified(a), fromUnverified(b));
    }
    function add(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.add(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function add(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.add(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function add(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return add(fromUnverified(a), b);
    }
    function add(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return add(a, fromUnverified(b));
    }

    /// @notice op:sub on type:uint256
    function sub(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.sub(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function sub(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return sub(fromUnverified(a), b);
    }
    function sub(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return sub(a, fromUnverified(b));
    }
    function sub(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return sub(fromUnverified(a), fromUnverified(b));
    }
    function sub(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.sub(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function sub(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        ve_uint256 aEnc = asVEUint256(a);
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.sub(ve_uint256.unwrap(aEnc), ve_uint256.unwrap(b), false));
    }
    function sub(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return sub(fromUnverified(a), b);
    }
    function sub(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return sub(a, fromUnverified(b));
    }

    /// @notice op:mul on type:uint256
    function mul(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.mul(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function mul(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return mul(fromUnverified(a), b);
    }
    function mul(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return mul(a, fromUnverified(b));
    }
    function mul(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return mul(fromUnverified(a), fromUnverified(b));
    }
    function mul(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.mul(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function mul(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.mul(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function mul(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return mul(fromUnverified(a), b);
    }
    function mul(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return mul(a, fromUnverified(b));
    }

    /// @notice op:div on type:uint256
    function div(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.div(ve_uint256.unwrap(a), bytes32(uint256(b))));
    }
    function div(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return div(fromUnverified(a), b);
    }

    /// @notice op:bit_and on type:uint256
    function bit_and(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_and(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function bit_and(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_and(a, fromUnverified(b));
    }
    function bit_and(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_and(fromUnverified(a), fromUnverified(b));
    }
    function bit_and(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_and(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_and(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_and(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_and(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return bit_and(fromUnverified(a), b);
    }
    function bit_and(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_and(a, fromUnverified(b));
    }

    /// @notice op:bit_or on type:uint256
    function bit_or(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_or(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function bit_or(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_or(a, fromUnverified(b));
    }
    function bit_or(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_or(fromUnverified(a), fromUnverified(b));
    }
    function bit_or(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_or(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_or(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_or(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_or(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return bit_or(fromUnverified(a), b);
    }
    function bit_or(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_or(a, fromUnverified(b));
    }

    /// @notice op:bit_xor on type:uint256
    function bit_xor(ve_uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_xor(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function bit_xor(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_uint256) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_xor(a, fromUnverified(b));
    }
    function bit_xor(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_xor(fromUnverified(a), fromUnverified(b));
    }
    function bit_xor(ve_uint256 a, uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_xor(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function bit_xor(uint256 a, ve_uint256 b) internal returns (ve_uint256) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_xor(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function bit_xor(uve_uint256 calldata a, uint256 b) internal returns (ve_uint256) {
        return bit_xor(fromUnverified(a), b);
    }
    function bit_xor(uint256 a, uve_uint256 calldata b) internal returns (ve_uint256) {
        return bit_xor(a, fromUnverified(b));
    }

    /// @notice op:bit_not on type:uint256
    function bit_not(ve_uint256 a) internal returns (ve_uint256) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.bit_not(ve_uint256.unwrap(a)));
    }
    function bit_not(uve_uint256 calldata a) internal returns (ve_uint256) {
        return bit_not(fromUnverified(a));
    }

    /// @notice op:lt on type:uint256
    function lt(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function lt(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }
    function lt(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return lt(fromUnverified(a), fromUnverified(b));
    }
    function lt(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function lt(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function lt(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return lt(fromUnverified(a), b);
    }
    function lt(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return lt(a, fromUnverified(b));
    }

    /// @notice op:gt on type:uint256
    function gt(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function gt(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }
    function gt(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return gt(fromUnverified(a), fromUnverified(b));
    }
    function gt(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.gt(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function gt(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.lt(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function gt(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return gt(fromUnverified(a), b);
    }
    function gt(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return gt(a, fromUnverified(b));
    }

    /// @notice op:le on type:uint256
    function le(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function le(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }
    function le(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return le(fromUnverified(a), fromUnverified(b));
    }
    function le(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function le(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function le(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return le(fromUnverified(a), b);
    }
    function le(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return le(a, fromUnverified(b));
    }

    /// @notice op:ge on type:uint256
    function ge(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function ge(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }
    function ge(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ge(fromUnverified(a), fromUnverified(b));
    }
    function ge(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ge(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function ge(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.le(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function ge(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return ge(fromUnverified(a), b);
    }
    function ge(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ge(a, fromUnverified(b));
    }

    /// @notice op:ne on type:uint256
    function ne(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function ne(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }
    function ne(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ne(fromUnverified(a), fromUnverified(b));
    }
    function ne(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function ne(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.ne(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function ne(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return ne(fromUnverified(a), b);
    }
    function ne(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return ne(a, fromUnverified(b));
    }

    /// @notice op:eq on type:uint256
    function eq(ve_uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint256.unwrap(a), ve_uint256.unwrap(b), false));
    }
    function eq(uve_uint256 calldata a, ve_uint256 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(ve_uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }
    function eq(uve_uint256 calldata a, uve_uint256 calldata b) internal returns (ve_bool) {
        return eq(fromUnverified(a), fromUnverified(b));
    }
    function eq(ve_uint256 a, uint256 b) internal returns (ve_bool) {
        if (!isInitialized(a)) {
            a = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint256.unwrap(a), bytes32(uint256(b)), true));
    }
    function eq(uint256 a, ve_uint256 b) internal returns (ve_bool) {
        if (!isInitialized(b)) {
            b = asVEUint256(0);
        }
        return ve_bool.wrap(Impl.eq(ve_uint256.unwrap(b), bytes32(uint256(a)), true));
    }
    function eq(uve_uint256 calldata a, uint256 b) internal returns (ve_bool) {
        return eq(fromUnverified(a), b);
    }
    function eq(uint256 a, uve_uint256 calldata b) internal returns (ve_bool) {
        return eq(a, fromUnverified(b));
    }

    /// @notice op:select on type:uint256
    function select(ve_bool control, ve_uint256 ifTrue, ve_uint256 ifFalse) internal returns (ve_uint256) {
        if (!isInitialized(control)) {
            control = asVEBool(false);
        }
        if (!isInitialized(ifTrue)) {
            ifTrue = asVEUint256(0);
        }
        if (!isInitialized(ifFalse)) {
            ifFalse = asVEUint256(0);
        }
        return ve_uint256.wrap(Impl.select(ve_bool.unwrap(control), ve_uint256.unwrap(ifTrue), ve_uint256.unwrap(ifFalse)));
    }
    function select(ve_bool control, uve_uint256 calldata ifTrue, ve_uint256 ifFalse) internal returns (ve_uint256) {
        return select(control, fromUnverified(ifTrue), ifFalse);
    }
    function select(ve_bool control, ve_uint256 ifTrue, uve_uint256 calldata ifFalse) internal returns (ve_uint256) {
        return select(control, ifTrue, fromUnverified(ifFalse));
    }

    /// @notice Returns true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ve_uint256 v) internal pure returns (bool) {
        return ve_uint256.unwrap(v) != 0;
    }
    /// @notice Convert an input.handle with corresponding input.data to a verified encrypted ve_uint256 integer.
    function fromUnverified(uve_uint256 memory input) internal returns (ve_uint256) {
        if (input.data.length != 0) {
            return ve_uint256.wrap(Impl.verify(input.handle, input.data, FheType.Uint256));
        }
        // Empty-data fast path: reuse an already-materialized handle instead of verifying a fresh input.
        if (input.handle == 0) {
            return asVEUint256(0);
        }
        if (!Impl.isAllowed(input.handle, msg.sender)) revert SenderNotAllowedToUseHandle(input.handle, msg.sender);
        return ve_uint256.wrap(input.handle);
    }
    /// @notice Convert a plaintext value to a verified encrypted ve_uint256 integer.
    function asVEUint256(uint256 value) internal returns (ve_uint256) {
        return ve_uint256.wrap(Impl.trivialEncrypt(uint256(value), FheType.Uint256));
    }
    /// @notice Converts handle from its custom type to the underlying bytes32.
    function toBytes32(ve_uint256 value) internal pure returns (bytes32 ct) {
        ct = ve_uint256.unwrap(value);
    }

    /// @notice Allows the use of value for the address account.
    function accessPolicy(ve_uint256 value, address account) internal returns (ve_uint256) {
        return accessPolicy(value, account, PermissionType.Persistent);
    }
    function accessPolicy(ve_uint256 value, address account, PermissionType pt) internal returns (ve_uint256) {
        Impl.accessPolicy(ve_uint256.unwrap(value), account, pt);
        return value;
    }
    /// @notice Makes a handle as publicly decryptable by anyone.
    function makePubliclyDecryptable(ve_uint256 value) internal {
        Impl.allowForDecryption(ve_uint256.unwrap(value));
    }
    /// @notice Returns whether the account is allowed to use the value.
    function isAllowed(ve_uint256 value, address account) internal view returns (bool) {
        return Impl.isAllowed(ve_uint256.unwrap(value), account);
    }
    /// @notice Returns whether the sender is allowed to use the value.
    function isSenderAllowed(ve_uint256 value) internal view returns (bool) {
        return Impl.isAllowed(ve_uint256.unwrap(value), msg.sender);
    }
    /// @notice Returns whether the the value is publicly decryptable.
    function isPubliclyDecryptable(ve_uint256 value) internal view returns (bool) {
        return Impl.isPubliclyDecryptable(ve_uint256.unwrap(value));
    }

    /// @notice Performs the casting to a target type.
    function asVEBool(ve_uint8 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ne(value, 0);
    }
    function asVEBool(ve_uint16 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ne(value, 0);
    }
    function asVEBool(ve_uint32 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ne(value, 0);
    }
    function asVEBool(ve_uint64 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ne(value, 0);
    }
    function asVEBool(ve_uint128 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ne(value, 0);
    }
    function asVEBool(ve_uint256 value) internal returns (ve_bool) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ne(value, 0);
    }
    function asVEUint8(ve_bool value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint8.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint8));
    }
    function asVEUint8(ve_uint16 value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ve_uint8.wrap(Impl.cast(ve_uint16.unwrap(value), FheType.Uint8));
    }
    function asVEUint8(ve_uint32 value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ve_uint8.wrap(Impl.cast(ve_uint32.unwrap(value), FheType.Uint8));
    }
    function asVEUint8(ve_uint64 value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ve_uint8.wrap(Impl.cast(ve_uint64.unwrap(value), FheType.Uint8));
    }
    function asVEUint8(ve_uint128 value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ve_uint8.wrap(Impl.cast(ve_uint128.unwrap(value), FheType.Uint8));
    }
    function asVEUint8(ve_uint256 value) internal returns (ve_uint8) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ve_uint8.wrap(Impl.cast(ve_uint256.unwrap(value), FheType.Uint8));
    }
    function asVEUint16(ve_bool value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint16.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint16));
    }
    function asVEUint16(ve_uint8 value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ve_uint16.wrap(Impl.cast(ve_uint8.unwrap(value), FheType.Uint16));
    }
    function asVEUint16(ve_uint32 value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ve_uint16.wrap(Impl.cast(ve_uint32.unwrap(value), FheType.Uint16));
    }
    function asVEUint16(ve_uint64 value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ve_uint16.wrap(Impl.cast(ve_uint64.unwrap(value), FheType.Uint16));
    }
    function asVEUint16(ve_uint128 value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ve_uint16.wrap(Impl.cast(ve_uint128.unwrap(value), FheType.Uint16));
    }
    function asVEUint16(ve_uint256 value) internal returns (ve_uint16) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ve_uint16.wrap(Impl.cast(ve_uint256.unwrap(value), FheType.Uint16));
    }
    function asVEUint32(ve_bool value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint32.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint32));
    }
    function asVEUint32(ve_uint8 value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ve_uint32.wrap(Impl.cast(ve_uint8.unwrap(value), FheType.Uint32));
    }
    function asVEUint32(ve_uint16 value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ve_uint32.wrap(Impl.cast(ve_uint16.unwrap(value), FheType.Uint32));
    }
    function asVEUint32(ve_uint64 value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ve_uint32.wrap(Impl.cast(ve_uint64.unwrap(value), FheType.Uint32));
    }
    function asVEUint32(ve_uint128 value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ve_uint32.wrap(Impl.cast(ve_uint128.unwrap(value), FheType.Uint32));
    }
    function asVEUint32(ve_uint256 value) internal returns (ve_uint32) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ve_uint32.wrap(Impl.cast(ve_uint256.unwrap(value), FheType.Uint32));
    }
    function asVEUint64(ve_bool value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint64.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint64));
    }
    function asVEUint64(ve_uint8 value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ve_uint64.wrap(Impl.cast(ve_uint8.unwrap(value), FheType.Uint64));
    }
    function asVEUint64(ve_uint16 value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ve_uint64.wrap(Impl.cast(ve_uint16.unwrap(value), FheType.Uint64));
    }
    function asVEUint64(ve_uint32 value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ve_uint64.wrap(Impl.cast(ve_uint32.unwrap(value), FheType.Uint64));
    }
    function asVEUint64(ve_uint128 value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ve_uint64.wrap(Impl.cast(ve_uint128.unwrap(value), FheType.Uint64));
    }
    function asVEUint64(ve_uint256 value) internal returns (ve_uint64) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ve_uint64.wrap(Impl.cast(ve_uint256.unwrap(value), FheType.Uint64));
    }
    function asVEUint128(ve_bool value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint128.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint128));
    }
    function asVEUint128(ve_uint8 value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ve_uint128.wrap(Impl.cast(ve_uint8.unwrap(value), FheType.Uint128));
    }
    function asVEUint128(ve_uint16 value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ve_uint128.wrap(Impl.cast(ve_uint16.unwrap(value), FheType.Uint128));
    }
    function asVEUint128(ve_uint32 value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ve_uint128.wrap(Impl.cast(ve_uint32.unwrap(value), FheType.Uint128));
    }
    function asVEUint128(ve_uint64 value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ve_uint128.wrap(Impl.cast(ve_uint64.unwrap(value), FheType.Uint128));
    }
    function asVEUint128(ve_uint256 value) internal returns (ve_uint128) {
        if (!isInitialized(value)) {
            value = asVEUint256(0);
        }
        return ve_uint128.wrap(Impl.cast(ve_uint256.unwrap(value), FheType.Uint128));
    }
    function asVEUint256(ve_bool value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEBool(false);
        }
        return ve_uint256.wrap(Impl.cast(ve_bool.unwrap(value), FheType.Uint256));
    }
    function asVEUint256(ve_uint8 value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEUint8(0);
        }
        return ve_uint256.wrap(Impl.cast(ve_uint8.unwrap(value), FheType.Uint256));
    }
    function asVEUint256(ve_uint16 value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEUint16(0);
        }
        return ve_uint256.wrap(Impl.cast(ve_uint16.unwrap(value), FheType.Uint256));
    }
    function asVEUint256(ve_uint32 value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEUint32(0);
        }
        return ve_uint256.wrap(Impl.cast(ve_uint32.unwrap(value), FheType.Uint256));
    }
    function asVEUint256(ve_uint64 value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEUint64(0);
        }
        return ve_uint256.wrap(Impl.cast(ve_uint64.unwrap(value), FheType.Uint256));
    }
    function asVEUint256(ve_uint128 value) internal returns (ve_uint256) {
        if (!isInitialized(value)) {
            value = asVEUint128(0);
        }
        return ve_uint256.wrap(Impl.cast(ve_uint128.unwrap(value), FheType.Uint256));
    }

    // AUTO-GENERATED END
}
