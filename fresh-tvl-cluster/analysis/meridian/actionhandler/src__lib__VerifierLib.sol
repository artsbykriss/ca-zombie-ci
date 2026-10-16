// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC1271} from "../interface/IERC1271.sol";
import {InvalidSignature} from "../share/Errors.sol";
import {ActionId} from "../share/UserDefinedTypes.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

library VerifierLib {
    /// @dev EIP-1271 magic value for valid signatures
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /// @dev Calculated based on Safe with quorum of 20 signatures
    /// gas(n) = 26000 + 70000 * n = 166k ~ 179k
    /// n = number of signatures needed to hit quorum
    /// reference: https://help.safe.global/en/articles/40828-gas-estimation
    uint256 internal constant EIP1271_MAX_GAS_LIMIT = 179_000;

    /// @notice Verifies a signature (EOA or SCW) and reverting on invalid signature.
    /// @param sender Expected signer (EOA or SCW)
    /// @param digest Hash that was signed (already domain/prefix hashed as needed)
    /// @param signature Signature bytes
    /// @param id Action ID for error reporting
    function verifySignature(address sender, bytes32 digest, bytes memory signature, ActionId id) internal view {
        _verifySignature(sender, digest, signature, id, true);
    }

    /// @notice Verifies a signature (EOA or SCW) without reverting.
    /// @param sender Expected signer (EOA or SCW)
    /// @param digest Hash that was signed (already domain/prefix hashed as needed)
    /// @param signature Signature bytes
    /// @param id Action ID for error reporting
    /// @return isValid True if signature is valid, false otherwise
    function isValidSignature(address sender, bytes32 digest, bytes memory signature, ActionId id)
        internal
        view
        returns (bool)
    {
        return _verifySignature(sender, digest, signature, id, false);
    }

    /// @notice Core signature verification logic with revert control.
    /// @dev Checks code length to branch between ECDSA (EOA) and EIP-1271 (SCW).
    /// @param sender Expected signer (EOA or SCW)
    /// @param digest Hash that was signed (already domain/prefix hashed as needed)
    /// @param signature Signature bytes
    /// @param id Action ID for error reporting
    /// @param shouldRevert Whether to revert on invalid signature or return false
    /// @return isValid True if signature is valid, false otherwise (only when shouldRevert is false)
    function _verifySignature(address sender, bytes32 digest, bytes memory signature, ActionId id, bool shouldRevert)
        internal
        view
        returns (bool)
    {
        // If the account is not an EoA, we assume is a smart contract wallet that supports EIP-1271
        //
        // NOTE: We explictly _DO NOT_ support EIP7702 edge cases here.
        if (sender.code.length > 0) {
            return _verifyEip1271Signature(sender, digest, signature, id, shouldRevert);
        } else {
            return _verifyEcdsaSignature(sender, digest, signature, id, shouldRevert);
        }
    }

    /// @notice Verifies an ECDSA signature by recovering the signer from the digest and signature.
    /// @param sender Expected signer (EOA)
    /// @param digest Hash that was signed
    /// @param signature Signature bytes
    /// @param id Action ID for error reporting
    /// @param shouldRevert Whether to revert on invalid signature or return false
    /// @return isValid True if signature is valid, false otherwise (only when shouldRevert is false)
    /// @custom:reverts InvalidSignature if shouldRevert is true and signature is invalid
    function _verifyEcdsaSignature(
        address sender,
        bytes32 digest,
        bytes memory signature,
        ActionId id,
        bool shouldRevert
    ) internal view returns (bool) {
        address recovered = ECDSA.tryRecover(digest, signature);
        bool isValid = recovered == sender && recovered != address(0);
        if (!isValid && shouldRevert) {
            revert InvalidSignature(id, sender, recovered, signature);
        }
        return isValid;
    }

    /// @notice Verifies an EIP-1271 signature by calling isValidSignature on the sender contract.
    /// @param sender Expected signer contract (SCW)
    /// @param digest Hash that was signed
    /// @param signature Signature bytes
    /// @param id Action ID for error reporting
    /// @param shouldRevert Whether to revert on invalid signature or return false
    /// @return isValid True if signature is valid, false otherwise (only when shouldRevert is false)
    /// @custom:reverts InvalidSignature if shouldRevert is true and signature is invalid
    function _verifyEip1271Signature(
        address sender,
        bytes32 digest,
        bytes memory signature,
        ActionId id,
        bool shouldRevert
    ) internal view returns (bool) {
        bytes memory callData = abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, signature);
        uint64 bytesToCopy = 0x04; // MAGIC VALUE is 4 bytes
        bytes memory returnData = new bytes(bytesToCopy);
        bool success;

        assembly {
            // Referenced from https://github.com/nomad-xyz/ExcessivelySafeCall/blob/81cd99ce3e69117d665d7601c330ea03b97acce0/src/ExcessivelySafeCall.sol#L91
            success := staticcall(
                EIP1271_MAX_GAS_LIMIT,
                sender,
                add(callData, 0x20), // inloc
                mload(callData), // inlen
                0x0, // outloc
                0x0 // outlen
            )

            // Require enough return data to safely copy the 4-byte magic value.
            success := and(success, gt(returndatasize(), 3))

            if success {
                // store length of copied bytes
                mstore(returnData, bytesToCopy)
                // copy the bytes from returndata[0:4], ignore the rest of the return data
                returndatacopy(add(returnData, 0x20), 0, bytesToCopy)
            }
        }
        if (success) {
            bytes4 magicValue = bytes4(returnData);
            bool isValid = magicValue == EIP1271_MAGIC_VALUE;
            if (!isValid && shouldRevert) {
                revert InvalidSignature(id, sender, sender, signature);
            }
            return isValid;
        } else {
            if (shouldRevert) {
                revert InvalidSignature(id, sender, sender, signature);
            }
            return false;
        }
    }
}
