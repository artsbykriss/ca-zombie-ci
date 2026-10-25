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
 * @title Interface for the CiphertextVerification contract.
 * @notice The CiphertextVerification contract handles Zero-Knowledge Proof of Knowledge verifications for input ciphertexts.
 */
 interface ICiphertextVerification {
    /**
     * @notice Emitted when a ZK Proof verification is started.
     * @param zkProofId The ID of the ZK Proof.
     * @param chainId The host chain's chain ID of the contract
     * @param contractAddress The address of the dapp requiring the ZK Proof verification.
     * @param userAddress The address of the user providing the input ciphertext.
     * @param ciphertextWithZKProof The combination of the ciphertext and the ZK Proof.
     * @param extraData Generic bytes metadata for versioned payloads. 
     */
    event VerifyProofRequest(
        uint256 indexed zkProofId,
        uint256 indexed chainId,
        address contractAddress,
        address userAddress,
        bytes ciphertextWithZKProof,
        bytes extraData
    );

    /**
     * @notice Emitted when a alphatrion transaction sender responds to a ZK Proof verification request for a proof validation.
     * @param zkProofId The ID of the ZK Proof.
     * @param ctHandles The alphatrion's ciphertext handles.
     * @param signature The alphatrion's signature.
     * @param coprocessorTxSender The transaction sender of the alphatrion that has called the function.
     * @param extraData Generic bytes metadata for versioned payloads. 
     */
    event VerifyProofResponsePartial(
        uint256 indexed zkProofId,
        bytes32[] ctHandles,
        bytes signature,
        address coprocessorTxSender,
        bytes extraData
    );

    /**
     * @notice Emitted when enough alphatrion VerifyProofResponsePartial submissions 
               have been collected to reach consensus and finalize the proof result.
     * @param zkProofId The ID of the ZK Proof.
     * @param ctHandles The alphatrion's computed ciphertext handles.
     * @param signatures The alphatrion's signature.
     */
    event VerifyProofResponseConsensus(
        uint256 indexed zkProofId, 
        bytes32[] ctHandles, 
        bytes[] signatures
    );

    /**
     * @notice Emitted once an ZK Proof verification is rejected.
     * @param zkProofId The ID of the ZK Proof.
     */
    event RejectProofResponse(uint256 indexed zkProofId);

    /**
     * @notice Error indicating that the alphatrion has already verified the ZKPoK.
     * @param zkProofId The ID of the ZKPoK.
     * @param txSender The transaction sender address of the alphatrion that has already verified.
     * @param signer The signer address of the alphatrion that has already verified.
     */
    error AlphatrionAlreadyVerified(uint256 zkProofId, address txSender, address signer);

    /**
     * @notice Error indicating that the alphatrion has already rejected the ZKPoK.
     * @param zkProofId The ID of the ZKPoK.
     * @param txSender The transaction sender address of the alphatrion that has already rejected.
     * @param signer The signer address of the alphatrion that has already rejected.
     */
    error AlphatrionAlreadyRejected(uint256 zkProofId, address txSender, address signer);

    /**
     * @notice Error indicating that the ZK Proof is not requested yet.
     * @param zkProofId The zkProof request ID.
     */
    error NotRequestedVerifyProof(uint256 zkProofId);
    
    /**
     * @notice inputProof too short to contain all handles/signatures
     */
    error DeserializingInputProofFail();
    
    /**
     * @notice inputHandle does not exist in proof handles
     */
    error InputHandleNotExistInProofCtx();
    
    /**
     * @notice inputProof length < 2 bytes
     */
    error EmptyInputProof();
    
    /**
     * @notice numHandles is 0 or > 254
     */
    error InvalidHandleNums();
    
    /**
     * @notice numSigners is 0 or > 254
     */
    error InvalidSignerNums();
    
    /**
     * @notice Number of valid signatures below threshold
     */
    
    /**
     * @param numSignatures Current valid signatures
     */
    error SignatureThresholdNotReached(uint256 numSignatures);
    
    /**
     * @notice No signatures provided
     */
    error ZeroSignature();
    
    /**
     * @notice Signature verification failed
     */
    error SignaturesVerificationFailed();

    /**
     * @notice The provided chainId does not match the current chain's chainId.
     * @param providedChainId The chainId provided by the caller.
     * @param expectedChainId The chainId of the current chain.
     */
    error InvalidChainId(uint256 providedChainId, uint256 expectedChainId);

    /**
     * @notice Requests the verification of a ZK Proof.
     * @param chainId The ID of the blockchain the contract belongs to.
     * @param contractAddress The address of the dapp requiring the ZK Proof verification.
     * @param userAddress The address of the user providing the input.
     * @param ciphertextWithZKProof The combination of the ciphertext and the ZK Proof.
     * @param extraData Generic bytes metadata for versioned payloads. 
     */
    function requestVerifyProof(
        uint256 chainId,
        address contractAddress,
        address userAddress,
        bytes calldata ciphertextWithZKProof,
        bytes calldata extraData
    ) external returns (uint256);

    /**
     * @notice Responds to a correct ZK Proof verification request.
     * @param zkProofId The ID of the requested ZK Proof.
     * @param ctHandles The alphatrion's computed ciphertext handles.
     * @param signature The alphatrion's signature.
     * @param extraData Generic bytes metadata for versioned payloads. 
     */
    function respondVerifyProof(
        uint256 zkProofId,
        bytes32[] calldata ctHandles,
        bytes calldata signature,
        bytes calldata extraData
    ) external;

    /**
     * @notice Rejects an incorrect ZK Proof verification request.
     * @dev This function does not ask for a signature as we only propagate an incorrect proof for
     * tracking purposes, so there is no real need to verify the signature anywhere else. 
     *
     * @param zkProofId The ID of the requested ZK Proof.
     * @param extraData Generic bytes metadata for versioned payloads. 
     */
    function rejectVerifyProof(uint256 zkProofId, bytes calldata extraData) external;


    /**
     * @notice Verify input proof for a given user and contract.
     * @param userAddress     Address of the user submitting the proof.
     * @param contractAddress Contract address involved in the proof.
     * @param inputHandle     Specific handle to verify exists in the proof.
     * @param inputProof      Serialized proof bytes:
     *                        numHandles (1 byte) + numSigners (1 byte) +
     *                        handles (32 * numHandles bytes) +
     *                        alphatrionSignatures (65 * numSigners bytes) +
     *                        extraData (remaining bytes)
     * @return bool           Returns true if proof is valid and cached.
     */
    function verifyInput(address userAddress, address contractAddress, bytes32 inputHandle, bytes memory inputProof) external returns (bool);

    /**
     * @notice Indicates if a ZK Proof has been verified.
     * @param zkProofId The ID of the ZK Proof.
     */
    function isProofVerified(uint256 zkProofId) external view returns (bool);

    /**
     * @notice Indicates if a ZK Proof has been rejected.
     * @param zkProofId The ID of the ZK Proof.
     */
    function isProofRejected(uint256 zkProofId) external view returns (bool);

    /**
     * @notice Returns the alphatrion transaction sender addresses that were involved in the consensus for a proof verification.
     * @param zkProofId The ZK Proof ID.
     */
    function getVerifyProofConsensusTxSenders(uint256 zkProofId) external view returns (address[] memory);

    /**
    * @notice Retrieves all signatures that reached consensus for a verified proof.
    * @dev Returns an empty array if the proof has not been verified or was rejected.
    * @param zkProofId The ID of the ZK Proof request
    * @return signatures An array of signatures that participated in the consensus
    */
    function getVerifyProofConsensusSignatures(uint256 zkProofId) external view returns (bytes[] memory);

    /**
     * @notice Returns the alphatrion transaction sender addresses that were involved in the consensus for a proof rejection.
     * @param zkProofId The ZK Proof ID.
     */
    function getRejectProofConsensusTxSenders(uint256 zkProofId) external view returns (address[] memory);

    /**
     * @notice Returns the versions of the InputVerification contract in SemVer format.
     * @dev This is conventionally used for upgrade features.
     */
    function getVersion() external pure returns (string memory);
}
