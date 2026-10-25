// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;
import {FheType} from "../core/FheType.sol";
import {IFHEExecutor, IFeeManager, IExecutorView} from "../core/IFHEExecutor.sol";
import {IACL, PermissionType} from "../core/IACL.sol";
import {ISpaceBridgeConfig} from "@primuslabs/spacebridge-contracts/contracts/interfaces/ISpaceBridgeConfig.sol";
import {IDecryption} from "@primuslabs/spacebridge-contracts/contracts/interfaces/IDecryption.sol";
import {IERC20 as _IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct FHEConfig {
    address ACLAddress;
    address FHEExecutorAddress;
}

struct DecryptionRequests {
    uint256 counterRequest;
    mapping(uint256 => bytes32[]) requestedHandles;
}

/**
 * @notice This library is the core implementation for computing FHE operations (e.g. add, sub).
 */
library Impl {
    /// @notice Thrown when ciphertext handles have already been saved for the specified request ID.
    error HandlesAlreadySavedForRequestID();
    /// @notice Thrown when no ciphertext handles are found for the specified request ID.
    error NoHandleFoundForRequestID();
    /// @notice Thrown when the returned signatures fail verification.
    error InvalidSignatures();
    /// @notice Emitted when a decryption request has been successfully fulfilled.
    event DecryptionFulfilled(uint256 indexed requestID);

    /// keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.FHEConfig")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FHEConfigLocation = 0x4cfa3e1fb9bcfec541cee631425fd50f9f621470c87e52e3e01be16093f65300;
    function getFHEConfig() internal pure returns (FHEConfig storage $) {
        assembly {
            $.slot := FHEConfigLocation
        }
    }

    /// keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.decryptionRequests")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant DecryptionRequestsStorageLocation = 0x0f3e0e8dfc45efd0ca6acff60ea051b338b351faa3975412cffbd1ecbccfd100;
    function getDecryptionRequests() internal pure returns (DecryptionRequests storage $) {
        assembly {
            $.slot := DecryptionRequestsStorageLocation
        }
    }

    /**
     * @notice Sets the system contract addresses.
     */
    function setFHEConfig(FHEConfig memory fheConfig) internal {
        FHEConfig storage $ = getFHEConfig();
        $.ACLAddress = fheConfig.ACLAddress;
        $.FHEExecutorAddress = fheConfig.FHEExecutorAddress;
    }

    // =============== USING Decryption BEGIN ==================
    function checkSignatures(uint256 requestID, bytes memory cleartexts, bytes memory decryptionProof) internal {
        bytes32[] memory handlesList = _loadRequestedHandles(requestID);
        bool isVerified = _verifySignatures(handlesList, cleartexts, decryptionProof);
        if (!isVerified) {
            revert InvalidSignatures();
        }
        emit DecryptionFulfilled(requestID);
    }

    /// @notice Reverts if msg.sender is not a registered AlphaTrion tx sender.
    function checkAlphatrionTxSender() internal view {
        FHEConfig storage $ = getFHEConfig();
        address spaceBridgeConfigAddr = IExecutorView($.FHEExecutorAddress).getSpaceBridgeConfigAddress();
        require(ISpaceBridgeConfig(spaceBridgeConfigAddr).isAlphatrionTxSender(msg.sender), "Not authorized alphatrion tx sender");
    }

    function _loadRequestedHandles(uint256 requestID) internal view returns (bytes32[] memory) {
        DecryptionRequests storage $ = Impl.getDecryptionRequests();
        if ($.requestedHandles[requestID].length == 0) {
            revert NoHandleFoundForRequestID();
        }
        return $.requestedHandles[requestID];
    }

    function _saveRequestedHandles(uint256 requestID, bytes32[] memory handlesList) private {
        DecryptionRequests storage $ = Impl.getDecryptionRequests();
        if ($.requestedHandles[requestID].length != 0) {
            revert HandlesAlreadySavedForRequestID();
        }
        $.requestedHandles[requestID] = handlesList;
    }

    function _verifySignatures(bytes32[] memory handlesList, bytes memory cleartexts, bytes memory decryptionProof) internal returns (bool) {
        // Delegate the KMS EIP-712 signature verification to the Decryption contract.
        // It validates that the decryption proof was signed by a registered KMS signer for
        // the resolved context over (handlesList, cleartexts, extraData). It reverts on any
        // structural or signer mismatch, and returns true otherwise.
        FHEConfig storage $ = getFHEConfig();
        address decryptionAddr = IExecutorView($.FHEExecutorAddress).getDecryptionAddress();
        return IDecryption(decryptionAddr).verifyPublicDecryptionEIP712KMSSignature(handlesList, cleartexts, decryptionProof);
    }

    // function requestPublicDecryption(bytes32[] memory ctHandles, bytes calldata extraData) internal returns (uint256 requestID) {
    //     FHEConfig storage $ = getFHEConfig();
    //     address decryptionAddress = IExecutorView($.FHEExecutorAddress).getDecryptionAddress();
    //     requestID = IDecryption(decryptionAddress).requestPublicDecryption(ctHandles, extraData);
    //     _saveRequestedHandles(requestID, ctHandles);
    // }

    // function requestUserDecryption(
    //     bytes32[] memory ctHandles,
    //     IDecryption.RequestValidity calldata requestValidity,
    //     address userAddress,
    //     bytes calldata publicKey,
    //     bytes calldata signature,
    //     bytes calldata extraData
    // ) internal returns (uint256 requestID) {
    //     FHEConfig storage $ = getFHEConfig();
    //     address decryptionAddress = IExecutorView($.FHEExecutorAddress).getDecryptionAddress();
    //     requestID = IDecryption(decryptionAddress).requestUserDecryption(ctHandles, requestValidity, userAddress, publicKey, signature, extraData);
    //     // to-do, add save requestID
    // }
    // =============== USING Decryption END ==================

    function chargeFee(address user, uint256 amount) internal {
        FHEConfig storage $ = getFHEConfig();
        IFeeManager($.FHEExecutorAddress).chargeFee{value: amount}(user);
    }
    // DISABLED
    // function refundFee(address user, uint256 amount) internal {
    //     FHEConfig storage $ = getFHEConfig();
    //     IFeeManager($.FHEExecutorAddress).refundFee(user, amount);
    // }
    // function balanceOfFee(address user) internal view returns (uint256 result) {
    //     FHEConfig storage $ = getFHEConfig();
    //     result = IFeeManager($.FHEExecutorAddress).balanceOfFee(user);
    // }

    function add(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheAdd(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function sub(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheSub(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function mul(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheMul(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function div(bytes32 lhs, bytes32 rhs) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheDiv(lhs, rhs, bytes1(0x01));
    }

    function bit_and(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheBitAnd(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function bit_or(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheBitOr(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function bit_xor(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheBitXor(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function bit_not(bytes32 lhs) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheBitNot(lhs);
    }

    function and(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        result = bit_and(lhs, rhs, scalar);
    }

    function or(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        result = bit_or(lhs, rhs, scalar);
    }

    function xor(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        result = bit_xor(lhs, rhs, scalar);
    }

    function not(bytes32 lhs) internal returns (bytes32 result) {
        result = bit_not(lhs);
    }

    function eq(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheEq(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function ne(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheNe(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function ge(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheGe(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function gt(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheGt(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function le(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheLe(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function lt(bytes32 lhs, bytes32 rhs, bool scalar) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheLt(lhs, rhs, bytes1(scalar ? 1 : 0));
    }

    function select(bytes32 control, bytes32 ifTrue, bytes32 ifFalse) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheIfThenElse(control, ifTrue, ifFalse);
    }

    function verify(bytes32 inputHandle, bytes memory inputData, FheType toType) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).verifyAttestation(inputHandle, msg.sender, inputData, toType);
        IACL($.ACLAddress).accessPolicy(result, msg.sender, PermissionType.Transient);
    }

    function trivialEncrypt(uint256 value, FheType toType) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).trivialEncrypt(value, toType);
    }

    function cast(bytes32 ciphertext, FheType toType) internal returns (bytes32 result) {
        FHEConfig storage $ = getFHEConfig();
        result = IFHEExecutor($.FHEExecutorAddress).fheCast(ciphertext, toType);
    }

    function accessPolicy(bytes32 handle, address account, PermissionType pt) internal {
        FHEConfig storage $ = getFHEConfig();
        IACL($.ACLAddress).accessPolicy(handle, account, pt);
    }

    function allowForDecryption(bytes32 handle) internal {
        bytes32[] memory handlesList = new bytes32[](1);
        handlesList[0] = handle;
        FHEConfig storage $ = getFHEConfig();
        IACL($.ACLAddress).allowForDecryption(handlesList);
    }

    // function cleanTransientStorageACL() internal {
    //     FHEConfig storage $ = getFHEConfig();
    //     IFHEExecutor($.FHEExecutorAddress).cleanTransientStorage();
    // }

    function isAllowed(bytes32 handle, address account) internal view returns (bool) {
        FHEConfig storage $ = getFHEConfig();
        return IACL($.ACLAddress).isAllowed(handle, account);
    }

    function isPubliclyDecryptable(bytes32 handle) internal view returns (bool) {
        FHEConfig storage $ = getFHEConfig();
        return IACL($.ACLAddress).isAllowedForDecryption(handle);
    }
}
