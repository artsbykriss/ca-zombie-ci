// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import { CiphertextDigestInfo, CtHandleContractPair } from "../SpaceBridgeTypes.sol";

/**
 * @title Interface for the ACL (Access Control List) contract.
 */
interface IACL {
    function isAllowed(bytes32 handle, address account) external view returns (bool);
    function isAllowedForDecryption(bytes32 handle) external view returns (bool);
}

/**
 * @title Interface for the Decryption contract.
 */
interface IDecryption {
    /**
     * @notice A struct that specifies information about the contracts to be used in the decryption.
     */
    struct ContractsInfo {
        /// @notice The chain ID of the contracts to be used in the decryption
        uint256 chainId;
        /// @notice The list of contract addresses to be used in the decryption
        address[] addresses;
    }
    /// @notice A struct that specifies the validity period of a request
    struct RequestValidity {
        /// @notice The start timestamp (UTC Time) of the user decryption request. 
        uint256 startTimestamp;

        /// @notice The duration in days for the user decryption to be processed.
        uint256 durationDays;
    }

    /// @notice Emitted when the Payment contract address is configured or updated.
    /// @param paymentAddress The address of the Payment contract.
    event PaymentConfigured(address indexed paymentAddress);

    /// @notice Emitted when the ACL contract address is configured or updated.
    /// @param aclAddress The address of the ACL contract.
    event ACLConfigured(address indexed aclAddress);

    /// @notice Error indicating that the ACL contract has not been configured.
    /// @dev Decryption requests are rejected until an ACL contract address is set
    ///      via {configureACL}, so access control can never be silently bypassed.
    error ACLNotConfigured();

    /// @notice Error indicating that a ciphertext handle is not allowed for public decryption.
    /// @param ctHandle The handle that is not allowed for public decryption.
    error ACLNotAllowedForDecryption(bytes32 ctHandle);

    /// @notice Error indicating that an account is not allowed to access a ciphertext handle.
    /// @param ctHandle The handle that the account is not allowed to access.
    /// @param account The account that was denied access.
    error ACLNotAllowed(bytes32 ctHandle, address account);

    /// @notice Emitted when a new decryption request is submitted.
    /// @dev This event logs all relevant metadata for tracking and handling
    ///      a decryption request, including its unique identifiers, ciphertexts,
    ///      caller address, and the callback selector for asynchronous result delivery.
    /// @param requestID Unique identifier assigned to this specific decryption request.
    /// @param cts Array of ciphertext handles requested for decryption.
    /// @param contractCaller Address of the contract initiating the decryption request.
    /// @param callbackSelector Function selector in `contractCaller` to receive the decrypted results.
    event DecryptionRequest(
        uint256 indexed requestID, 
        bytes32[] cts, 
        address contractCaller, 
        bytes4 callbackSelector
    );

    /// @notice Emitted when an public decryption request is made.
    /// @param requestID Unique identifier assigned to this specific decryption request.
    /// @param ciphertextDigestInfo The handles, and SNS ciphertexts to decrypt.
    /// @param contractCaller Address of the contract initiating the decryption request.
    /// @param extraData Generic bytes metadata for versioned payloads. 
    event PublicDecryptionRequest(
        uint256 indexed requestID,
        CiphertextDigestInfo[] ciphertextDigestInfo,
        address contractCaller, 
        bytes extraData
    );

    /**
     * @notice Emitted when a KMS connector responds to a public decryption request.
     * @param requestID The decryption request ID associated with the response.
     * @param decryptedResult The decrypted result.
     * @param signature The signature of the KMS connector that responded.
     * @param kmsTxSender The transaction sender of the KMS connector that responded.
     * @param extraData Generic bytes metadata for versioned payloads. First byte is for the version.
     */
    event PublicDecryptionResponseCall(
        uint256 indexed requestID,
        bytes decryptedResult,
        bytes signature,
        address kmsTxSender,
        bytes extraData
    );
    /// @notice Emitted when an public decryption response is made.
    /// @param requestID The decryption request ID associated with the response.
    /// @param decryptedResult The decrypted result.
    /// @param signatures The signatures of all the KMS connectors that responded.
    /// @param extraData Generic bytes metadata for versioned payloads. 
    event PublicDecryptionResponse(
        uint256 indexed requestID, 
        bytes decryptedResult, 
        bytes[] signatures,
        bytes extraData
    );

    /// @notice Emitted when a user decryption request is made.
    /// @param requestID The decryption request ID associated with the response.
    /// @param ciphertextDigestInfo The handles, and SNS ciphertexts to decrypt.
    /// @param userAddress The user's address.
    /// @param publicKey The user's public key for used encryption plaintext.
    /// @param extraData Generic bytes metadata for versioned payloads.
    event UserDecryptionRequest(
        uint256 indexed requestID,
        CiphertextDigestInfo[] ciphertextDigestInfo,
        address userAddress,
        bytes publicKey,
        bytes extraData
    );

    /// @notice Emitted when an user decryption response is made.
    /// @param requestID The decryption request ID associated with the response.
    /// @param indexData The index of the share associated with the decryption.
    /// @param userDecryptedData The decryption data reencrypted with the user's public key.
    /// @param signature The signature of the TEE(alphatrion) that responded.
    /// @param extraData Generic bytes metadata for versioned payloads. 
    event UserDecryptionResponse(
        uint256 indexed requestID,
        uint256 indexData,
        bytes userDecryptedData,
        bytes signature,
        bytes extraData
    );

    /**
     * @notice Emitted when the number of user decryption response received reaches the threshold.
     * @param requestID The decryption request ID.
     */
    event UserDecryptionResponseThresholdReached(uint256 indexed requestID);

    /**
     * @notice Error indicating that the list of contract addresses is empty.
     */
    error EmptyContractAddresses();

    /**
     * @notice Error indicating that the number of contract addresses exceeds the maximum allowed.
     * @param maxLength The maximum number of contract addresses allowed.
     * @param actualLength The actual number of contract addresses provided.
     */
    error ContractAddressesMaxLengthExceeded(uint256 maxLength, uint256 actualLength);

    /**
     * @notice Error indicating that the input list of ctHandleContractPairs is empty.
     */
    error EmptyCtHandleContractPairs();

    /// @notice Error indicating that the (public, user, delegated user) decryption is not requested yet.
    /// @param requestID The decryption request ID.
    error NotDecryptionRequested(uint256 requestID);

    /// @notice Error indicating that the durationDays of a user decryption request is invalid.
    error InvalidDurationDays();

    /// @notice Error indicating that the durationDays of a user decryption request exceeds the maximum allowed.
    /// @param maxValue The maximum durationDays allowed.
    /// @param actualValue The actual durationDays requested.
    error MaxDurationDaysExceeded(uint256 maxValue, uint256 actualValue);

    /// @notice Error indicating that the start timestamp of a user decryption request has been set in the future.
    /// @param currentTimestamp The block timestamp at which the user decryption request was made.
    /// @param startTimestamp The start timestamp of the user decryption request.
    error StartTimestampInFuture(uint256 currentTimestamp, uint256 startTimestamp);

    /// @notice Error indicating that the user decryption request has expired.
    /// @param currentTimestamp The block timestamp at which the user decryption request was made.
    /// @param requestValidity The validity period of the user decryption request.
    error UserDecryptionRequestExpired(uint256 currentTimestamp, RequestValidity requestValidity);

    /// @notice Error indicating that the user address is included in the contract addresses list.
    /// @param userAddress The user address that is included in the list.
    /// @param contractAddresses The list of expected contract addresses.
    error UserAddressInContractAddresses(address userAddress, address[] contractAddresses);

    /// @notice Error indicating that the contract address is not included in the contract addresses list.
    /// @param contractAddress The contract address that is not in the list.
    /// @param contractAddresses The list of expected contract addresses.
    error ContractAddressNotInContractAddresses(address contractAddress, address[] contractAddresses);

    /// @notice Error indicating that a KMS node has already signed the decryption response.
    /// @param requestId The decryption request ID.
    /// @param signer The signer address of the KMS node that has already signed.
    error KmsNodeAlreadySigned(uint256 requestId, address signer);

    /**
     * @notice Error emitted when the recovered signer does not match the registered
     * signer address for the given KMS transaction sender.
     * @param txSenderAddress The KMS node's transaction sender address.
     * @param expectedSigner The signer address registered for this transaction sender.
     * @param recoveredSigner The signer address recovered from the signature.
     */
    error KmsSignerMismatch(address txSenderAddress, address expectedSigner, address recoveredSigner);

    /// @notice Error indicating that the given signature for the user decryption request is invalid.
    /// @param signature The invalid signature.
    error InvalidUserSignature(bytes signature);
    
    /// @notice The address recovered from the signature is not a registered KMS signer.
    error KMSInvalidSigner(address recovered);

    /// @notice The decryptionProof byte string is malformed (too short or bad structure).
    error DeserializingDecryptionProofFail();

    /// @notice The decryptionProof is empty.
    error EmptyDecryptionProof();

    /// @notice The number of unique valid KMS signatures is below the public decryption threshold.
    error InsufficientSignatures(uint256 unique, uint256 threshold);

    /// @notice Requests a public decryption.
    /// @param ctHandles The handles of the ciphertexts to decrypt.
    /// @param extraData Generic bytes metadata for versioned payloads. 
    function requestPublicDecryption(
        bytes32[] calldata ctHandles, 
        bytes calldata extraData
    ) external returns (uint256 requestID);

    /// @notice Responds to a public decryption request.
    /// @param requestID The decryption request ID associated with the response.
    /// @param decryptedResult The decrypted result.
    /// @param signature The signature of the TEE(alphatrion) that responded.
    /// @param extraData Generic bytes metadata for versioned payloads.
    function respondPublicDecryption(
        uint256 requestID, 
        bytes calldata decryptedResult, 
        bytes calldata signature, 
        bytes calldata extraData
    ) external;

    /// @notice Requests a user decryption.
    /// @param ctHandleContractPairs The ciphertexts to decrypt for associated contracts.
    /// @param requestValidity The validity period of the user decryption request.
    /// @param contractsInfo The contracts' information (chain ID, addresses).
    /// @param userAddress The user's address.
    /// @param publicKey The user's public key to encrypt the plaintext.
    /// @param signature The EIP712 signature to verify.
    /// @param extraData Generic bytes metadata for versioned payloads.
    function requestUserDecryption(
        CtHandleContractPair[] calldata ctHandleContractPairs,
        RequestValidity calldata requestValidity,
        ContractsInfo calldata contractsInfo,
        address userAddress,
        bytes calldata publicKey,
        bytes calldata signature,
        bytes calldata extraData
    ) external returns (uint256 requestID);

    /// @notice Responds to a user decryption request.
    /// @param requestID The decryption request ID associated with the response.
    /// @param userDecryptedData The partial decryption share reencrypted with the user's public key.
    /// @param signature The signature of the TEE(alphatrion) that responded.
    /// @param extraData Generic bytes metadata for versioned payloads.
    function respondUserDecryption(
        uint256 requestID,
        bytes calldata userDecryptedData,
        bytes calldata signature,
        bytes calldata extraData
    ) external;

    /// @notice Indicates if handles are ready to be decrypted publicly.
    /// @param ctHandles The ciphertext handles.
    /// @param extraData Generic bytes metadata for versioned payloads.
    function isPublicDecryptionReady(
        bytes32[] calldata ctHandles,
        bytes calldata extraData
    ) external view returns (bool);

    /// @notice Indicates if handles are ready to be decrypted by a user.
    /// @param userAddress The user's address.
    /// @param ctHandleContractPairs The ciphertext handles with associated contract addresses.
    /// @param extraData Generic bytes metadata for versioned payloads. 
    function isUserDecryptionReady(
        address userAddress,
        CtHandleContractPair[] calldata ctHandleContractPairs,
        bytes calldata extraData
    ) external view returns (bool);

    /// @notice Indicates if a public, user decryption is done.
    /// @param decryptionId The decryption request ID.
    function isDecryptionDone(uint256 decryptionId) external view returns (bool);

    /// @notice Returns the KMS transaction sender addresses that were involved in the consensus for a decryption request.
    /// @param decryptionId The decryption request ID.
    function getDecryptionConsensusTxSenders(uint256 decryptionId) external view returns (address[] memory);

    /**
     * @notice Verify the KMS EIP-712 signature over a batch of public decryption results.
     *
     * @dev This function is a stateless oracle: it performs no state changes and returns the
     *      same answer for identical inputs on every call. Replay protection (e.g. marking a
     *      request as fulfilled) is entirely the caller's responsibility.
     *
     *      KMS signers and the public decryption threshold are read from the SpaceBridgeConfig
     *      contract. The proof is valid iff every recovered signer is a registered KMS signer
     *      and the number of unique valid signatures is at least the public decryption threshold.
     *
     *      decryptionProof layout:
     *        Byte 0            : numSigners (uint8)
     *        Bytes 1 .. 65*N   : N × 65-byte ECDSA signatures
     *        Bytes 65*N+1 .. end: extraData
     *
     *      extraData is opaque signed payload: it is included in the EIP-712 digest but is not
     *      otherwise interpreted by this contract.
     *
     * @param handlesList      Ordered list of ciphertext handles that were decrypted.
     * @param decryptedResult  ABI-encoded plaintext values in the same order as handlesList.
     * @param decryptionProof  KMS signature proof bytes in the format described above.
     * @return                 True if the proof carries enough valid KMS signatures to meet the
     *                         public decryption threshold; reverts on any structural or signer
     *                         mismatch error.
     */
    function verifyPublicDecryptionEIP712KMSSignature(
        bytes32[] memory handlesList,
        bytes memory decryptedResult,
        bytes memory decryptionProof
    ) external returns (bool);

    /// @notice Returns the versions of the Payment contract in SemVer format.
    function getVersion() external pure returns (string memory);
}

