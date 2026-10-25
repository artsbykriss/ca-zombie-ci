// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import "../SpaceBridgeTypes.sol";

/**
 * @title Interface for the CiphertextDigests contract.
 * @notice The CiphertextDigests contract stores ciphertext digests for EVM-compatible chains.
 */
interface ICiphertextDigests {
    /**
     * @notice Emitted when a alphatrion transaction sender requests to add a ciphertext digest.
     * @param ctHandle The handle of the added ciphertext.
     * @param ciphertextDigest The digest of the regular ciphertext.
     * @param alphatrionTxSender The transaction sender of the alphatrion that has called the function.
     */
    event CiphertextDigestAdded(
        bytes32 indexed ctHandle,
        bytes32 ciphertextDigest,
        address alphatrionTxSender
    );

    /**
     * @notice Emitted when a consensus for the ciphertext digest addition is reached.
     * @param ctHandle The handle of the added ciphertext.
     * @param ciphertextDigest The digest of the regular ciphertext.
     * @param alphatrionTxSenders The list of alphatrion transaction sender addresses
     * that were part of the consensus when adding the ciphertext.
     */
    event CiphertextDigestConsensusConfirm(
        bytes32 indexed ctHandle,
        bytes32 ciphertextDigest,
        address[] alphatrionTxSenders
    );

    /**
     * @notice Error indicating that the given alphatrion transaction sender has already added the handle.
     * @param ctHandle The handle of the already added ciphertext.
     * @param txSender The transaction sender address of the alphatrion that has already added the handle.
     */
    error AlphatrionAlreadyAdded(bytes32 ctHandle, address txSender);

    /**
     * @notice Error indicating that the given ciphertext digest represented by the given handle has not
     * been added in the contract.
     * @param ctHandle The handle of the ciphertext.
     */
    error CiphertextDigestNotFound(bytes32 ctHandle);

    /**
     * @notice Error indicating that the list of handles is empty.
     */
    error EmptyCiphertextHandles();

    /**
     * @notice Adds a new ciphertext digest to the state. 
     * @param ctHandle The handle of the ciphertext.
     * @param ciphertextDigest The digest of the regular ciphertext.
     */
    function addCiphertextDigest(
        bytes32 ctHandle,
        bytes32 ciphertextDigest
    ) external;

    /**
     * @notice Adds some ciphertext digests to the state.
     * @param ctHandles The handle of the ciphertexts.
     * @param ciphertextDigests The digest of the regular ciphertexts.
     */
    function addCiphertextDigests(
        bytes32[] memory ctHandles,
        bytes32[] memory ciphertextDigests
    ) external;

    /**
     * @notice Retrieves the list of regular ciphertext digests for the given handles.
     * @param ctHandles The list of handles to retrieve.
     * @return The list of regular ciphertext digests.
     */
    function getCiphertextDigests(bytes32[] calldata ctHandles) external view returns (CiphertextDigestInfo[] memory);

    /**
     * @notice Indicates if the ciphertext digest represented by the handle has been added in the contract.
     * @param ctHandleOrJobId The handle or job to check.
     */
    function isCiphertextDigestAdded(bytes32 ctHandleOrJobId) external view returns (bool);

    /**
     * @notice Indicates if the ciphertext digests represented by the given handles have all been added in
     * the contract. Returns false as soon as one of them has not been added.
     * @param ctHandlesOrJobIds The list of handles or job ids to check.
     */
    function isCiphertextDigestAdded(bytes32[] calldata ctHandlesOrJobIds) external view returns (bool);

    /**
     * @notice Returns the alphatrion transaction sender addresses that were involved in the consensus.
     * @param ctHandleOrJobId The handle or job Id to retrieve the alphatrion transaction sender addresses for.
     * @return The list of alphatrion transaction sender addresses.
     */
    function getCiphertextDigestConsensusTxSenders(bytes32 ctHandleOrJobId) external view returns (address[] memory);

    /**
     * @notice Returns the versions of the CiphertextDigests contract in SemVer format.
     */
    function getVersion() external pure returns (string memory);
}