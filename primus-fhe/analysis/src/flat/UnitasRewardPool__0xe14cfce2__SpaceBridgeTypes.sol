// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;


/**
 * @notice Struct that represents a AlphaTrion.
 */
struct Alphatrion {
    /// @notice Address of the Alphatrion's transaction sender
    address txSenderAddress;
    /// @notice Address of the Alphatrion's signer (used for signing inputs with EIP712 signatures)
    address signerAddress;
    /// @notice URL address for ciphertext storage
    string ctStoreUrl;
}

/**
 * @notice Struct that represents a KMS node.
 */
struct KmsNode {
    /// @notice Address of the KMS node's transaction sender
    address txSenderAddress;
    /// @notice Address of the KMS node's signer
    address signerAddress;
    /// @notice IP address of the KMS node
    string ipAddress;
    /// @notice URL address of the KMS node' storage where ciphertexts are stored
    string storageUrl;
}

/**
 * @notice Data structure used to transfer a regular ciphertext and some of its metadata between the SpaceBridge contracts.
 */
struct CiphertextDigestInfo {
    /// @notice Unique identifier: either a single ciphertext handle or a job ID for batched ciphertexts
    bytes32 ctHandleOrJobId;
    /// @notice Cryptographic digest of the ciphertext data
    /// @dev If `ctHandleOrJobId` is a ctHandle: hash of that specific ciphertext
    ///      If `ctHandleOrJobId` is a jobId: hash of all (ctHandle, ciphertext) pairs in the job
    bytes32 ciphertextDigest;
    /// @notice List of AlphaTrion addresses that have reached consensus on this ciphertext (identified by ctHandle)
    address[] alphatrionTxSenderAddresses;
}


/**
 * @notice A struct that contains a ciphertext handle and a contract address that is
 * expected to be allowed to decrypt this ciphertext
 */
struct CtHandleContractPair {
    /// @notice The handle of the ciphertext
    bytes32 ctHandle;
    /// @notice The address of the contract
    address contractAddress;
}
