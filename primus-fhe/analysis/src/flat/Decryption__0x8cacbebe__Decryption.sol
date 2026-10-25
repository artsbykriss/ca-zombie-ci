// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { IDecryption, IACL } from "./interfaces/IDecryption.sol";
import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";
import { ICiphertextDigests } from "./interfaces/ICiphertextDigests.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SpaceBridgeOwnable } from "./SpaceBridgeOwnable.sol";
import { SpaceBridgeConfigGuards } from "./SpaceBridgeConfigGuards.sol";
import { PaymentFee } from "./PaymentFee.sol";
import { Pausable } from "./Pausable.sol";
import { CiphertextDigestInfo, CtHandleContractPair, KmsNode } from "./SpaceBridgeTypes.sol";


/**
 * @title Decryption contract
 * @notice See {IDecryption}.
 */
contract Decryption is IDecryption, EIP712Upgradeable, SpaceBridgeOwnable,
                    SpaceBridgeConfigGuards, PaymentFee, UUPSUpgradeable, Pausable {
    /// @notice The request types.
    enum RequestType {
        Unknown,       // 0
        PublicDecrypt, // 1
        UserDecrypt    // 2
    }
    // Bit position to left shift for initializing the counters
    uint256 constant REQUEST_TYPE_SHIFT = 248;

    // Public decrypt requestId format in bytes: [00000001 | counter_1 | ... | counter_31]
    uint256 constant PUBLIC_DECRYPT_INIT_COUNTER = uint256(RequestType.PublicDecrypt) << REQUEST_TYPE_SHIFT;

    // User decrypt requestId format in bytes: [00000001 | counter_1 | ... | counter_31]
    uint256 constant USER_DECRYPT_INIT_COUNTER = uint256(RequestType.UserDecrypt) << REQUEST_TYPE_SHIFT;

    /// @notice The maximum number of duration days that can be requested for a user decryption.
    uint16 internal constant MAX_USER_DECRYPT_DURATION_DAYS = 90;

    /// @notice The maximum number of contracts that can request for user decryption at once.
    uint8 internal constant MAX_USER_DECRYPT_CONTRACT_ADDRESSES = 10;

    /// @notice The data structure for the EIP712 signature to validate in public decryption responses.
    struct PublicDecryptSignData {
        /// @notice The handles of the ciphertexts that have been decrypted.
        bytes32[] ctHandles;
        /// @notice The decrypted result of the public decryption.
        bytes decryptedResult;
        /// @notice Generic bytes metadata for versioned payloads. 
        bytes extraData;
    }

    /// @notice The typed data structure for the EIP712 signature to validate in user decryption requests.
    struct RequestUserDecryptSignData {
        /// @notice The user's public key to be used for encryption plaintext.
        bytes publicKey;
        /// @notice The contract addresses that verification is requested for.
        address[] contractAddresses;
        /// @notice The start timestamp of the user decryption request.
        uint256 startTimestamp;
        /// @notice The duration in days of the user decryption request after the start timestamp.
        uint256 durationDays;
        /// @notice Generic bytes metadata for versioned payloads. 
        bytes extraData;
    }

    /// @notice The typed data structure for the EIP712 signature to validate in user decryption responses.
    struct ResponseUserDecryptSignData {
        /// @notice The user's public key used for the encryption plaintext.
        bytes publicKey;
        /// @notice The handles of the ciphertexts that have been decrypted.
        bytes32[] ctHandles;
        /// @notice The partial decryption share reencrypted with the user's public key.
        bytes userDecryptedData;
        /// @notice Generic bytes metadata for versioned payloads. 
        bytes extraData;
    }

    /// @notice The publicKey and ctHandles from user decryption requests used for validations during responses.
    struct UserDecryptionPayload {
        /// @notice The user's public key to be used for encryption plaintext.
        bytes publicKey;
        /// @notice The handles of the ciphertexts requested for a user decryption
        bytes32[] ctHandles;
    }

    /// @notice The hash of the PublicDecryptSignData structure data definition used for signature validation in public decryption requests.
    bytes32 private constant EIP712_PUBLIC_DECRYPT_TYPE_HASH = 
        keccak256(bytes("PublicDecryptSignData(bytes32[] ctHandles,bytes decryptedResult,bytes extraData)"));

    /// @notice The hash of the RequestUserDecryptSignData structure typed data definition
    bytes32 private constant EIP712_REQUEST_USER_DECRYPT_TYPE_HASH = keccak256(
        bytes("RequestUserDecryptSignData(bytes publicKey,address[] contractAddresses,uint256 startTimestamp,uint256 durationDays,bytes extraData)")
    );

    /// @notice The hash of the ResponseUserDecryptSignData structure typed data definition
    bytes32 private constant EIP712_RESPONSE_USER_DECRYPT_TYPE_HASH =
        keccak256(bytes("ResponseUserDecryptSignData(bytes publicKey,bytes32[] ctHandles,bytes userDecryptedData,bytes extraData)"));

    struct DecryptionStorage {
        /// @notice The number of public decryption requests(`decryptionId`), used to generate request IDs.
        uint256 publicDecryptionCounter;
        /// @notice Handles of the ciphertexts requested for a public decryption
        mapping(uint256 decryptionId => bytes32[] ctHandles) publicCtHandles;
        /// @notice Verified signatures for a public decryption.
        mapping(uint256 decryptionId =>
            mapping(bytes32 digest => bytes[] verifiedSignatures))
                verifiedPublicDecryptSignatures;

        /// @notice The number of user decryption requests(`decryptionId`), used to generate request IDs.
        uint256 userDecryptionCounter;
        /// @notice The decryption payloads stored during user decryption requests.
        mapping(uint256 decryptionId => UserDecryptionPayload payload) userDecryptionPayloads;

        /// @notice Whether a public, user decryption is done
        mapping(uint256 requestID => bool decryptionDone) decryptionDone;
        /// @notice Whether KMS signer has already responded to a decryption request.
        mapping(uint256 decryptionId =>
            mapping(address kmsSigner => bool alreadyResponded))
                kmsNodeAlreadySigned;
        /// @notice The KMS transaction senders involved in a consensus for a decryption response.
        mapping(uint256 decryptionId =>
            mapping(bytes32 digest => address[] kmsTxSenderAddresses))
               consensusTxSenderAddresses;
        /// @notice The digest of the signed struct on which consensus was reached for a decryption request.
        mapping(uint256 decryptionId => bytes32 consensusDigest) decryptionConsensusDigest;

        /// @notice The CiphertextDigests contract that get consensus tx sender from the handles
        ICiphertextDigests cipherDigests;
        /// @notice The SpaceBridgeConfig contract that get alphatrion sizes
        ISpaceBridgeConfig spaceBridgeConfig;
        /// @notice The ACL contract that enforces access control on ciphertext handles.
        IACL acl;
    }

    /// keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.Decryption")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DecryptionStorageLocation = 0x893ed0d4cc3fa9004c533d399eca2d720a07c2467b1cd921967ebfd259856200;

    string private constant CONTRACT_NAME = "Decryption";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 2;
    uint256 private constant PATCH_VERSION = 0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param _spaceBridgeConfigAddress The address of the SpaceBridgeConfig contract
     * @param _cipherDigestAddress The address of the CiphertextDigests contract
     */
    function initialize(address _spaceBridgeConfigAddress, address _cipherDigestAddress) public initializer {
        __EIP712_init(CONTRACT_NAME, "1");
        __SpaceBridgeOwnable_init(_spaceBridgeConfigAddress);
        __SpaceBridgeConfigGuards_init(_spaceBridgeConfigAddress);
        __PausableWithSpaceBridge_init(_spaceBridgeConfigAddress);

        DecryptionStorage storage $ = _getDecryptionStorage();
        
        require(_cipherDigestAddress != address(0), "Invalid CiphertextDigest address");
        $.cipherDigests = ICiphertextDigests(_cipherDigestAddress);

        require(_spaceBridgeConfigAddress != address(0), "Invalid SpaceBridgeConfig address");
        $.spaceBridgeConfig = ISpaceBridgeConfig(_spaceBridgeConfigAddress);

        $.publicDecryptionCounter = PUBLIC_DECRYPT_INIT_COUNTER;
        $.userDecryptionCounter = USER_DECRYPT_INIT_COUNTER;
    }

    /**
     * @notice Configures the Payment contract used to collect fees.
     * @param _paymentAddress The address of the Payment contract.
     */
    function configurePayment(address _paymentAddress) external onlySpaceBridgeOwner {
        _setPaymentAddress(_paymentAddress);
        emit PaymentConfigured(_paymentAddress);
    }

    /**
     * @notice Configures the ACL contract used to enforce ciphertext access control.
     * @dev Once set, decryption requests consult the ACL to verify that the involved
     *      handles are permitted to be decrypted by the requesting accounts.
     * @param _aclAddress The address of the ACL contract.
     */
    function configureACL(address _aclAddress) external onlySpaceBridgeOwner {
        require(_aclAddress != address(0), "Invalid ACL address");
        _getDecryptionStorage().acl = IACL(_aclAddress);
        emit ACLConfigured(_aclAddress);
    }

    /**
     * @notice Checks if the sender is authorized to upgrade the contract and reverts otherwise.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlySpaceBridgeOwner {}


    /**
     * @notice See {IDecryption-requestPublicDecryption}.
     */
    function requestPublicDecryption(
        bytes32[] calldata ctHandles, 
        bytes calldata extraData
    ) external virtual whenNotPaused returns (uint256 requestID) {
        // Check that payment contract is configured
        require(_isPaymentConfigured(), "Payment contract not configured");
        
        // Validate inputs
        require(ctHandles.length > 0, "Empty ciphertext handles");

        // Fetch the ciphertexts from the CiphertextDigest contract
        DecryptionStorage storage $ = _getDecryptionStorage();

        // The ACL contract must be configured — decryption is rejected entirely
        // until it is, so access control can never be silently bypassed.
        if (!_isAclConfigured()) {
            revert ACLNotConfigured();
        }

        // Check whether all handles allow public decryption.
        for (uint256 i = 0; i < ctHandles.length; i++) {
            if (!$.acl.isAllowedForDecryption(ctHandles[i])) {
                revert ACLNotAllowedForDecryption(ctHandles[i]);
            }
        }

        CiphertextDigestInfo[] memory ciphertextDigestInfo = $.cipherDigests.getCiphertextDigests(ctHandles);

        // Check that received ciphertextDigestInfo have the same keyId.
        // TODO _checkSameKeyIds(ciphertextDigestInfo);

        // Generate a globally unique decryptionId for the public decryption request.
        $.publicDecryptionCounter++;
        requestID = $.publicDecryptionCounter;

        // The handles are used during response calls for the EIP712 signature validation.
        $.publicCtHandles[requestID] = ctHandles;

        // Charge the fee from the transaction sender for this public decryption request.
        // _chargePublicDecryptionFee(msg.sender);

        emit PublicDecryptionRequest(requestID, ciphertextDigestInfo, msg.sender, extraData);
    }

    /**
     * @notice See {IDecryption-respondPublicDecryption}.
     */
    function respondPublicDecryption(
        uint256 requestID, 
        bytes calldata decryptedResult, 
        bytes calldata signature, 
        bytes calldata extraData
    ) external onlyKmsTxSender virtual {
        DecryptionStorage storage $ = _getDecryptionStorage();

        // Make sure the requestID corresponds to a generated public decryption request
        if (requestID <= PUBLIC_DECRYPT_INIT_COUNTER || requestID > $.publicDecryptionCounter) {
            revert NotDecryptionRequested(requestID);
        }

        // Initialize the PublicDecryptVerification structure for the signature validation.
        PublicDecryptSignData memory publicDecryptSignData = PublicDecryptSignData(
            $.publicCtHandles[requestID],
            decryptedResult,
            extraData
        );

        // Compute the hash of the PublicDecryptSignData structure.
        bytes32 hash = _hashPublicDecryptSignData(publicDecryptSignData);

        // Recover the signer address from the signature and validate that corresponds to a alphatrion tx sender
        _validateDecryptionResponseEIP712Signature(requestID, hash, signature);

        // Store the signature for the public decryption response.
        bytes[] storage verifiedSignatures = $.verifiedPublicDecryptSignatures[requestID][hash];
        verifiedSignatures.push(signature);

        // Store the KMS transaction sender address for the public decryption response
        $.consensusTxSenderAddresses[requestID][hash].push(msg.sender);

        // Emit the event at each call for monitoring purposes.
        emit PublicDecryptionResponseCall(requestID, decryptedResult, signature, msg.sender, extraData);

        // Set the decryption done flag and emit the event  
        if (!$.decryptionDone[requestID] && _isConsensusReachedPublic(verifiedSignatures.length)) {
            $.decryptionDone[requestID] = true;

            // This storage variable is here to be able to retrieve this list later
            $.decryptionConsensusDigest[requestID] = hash;

            emit PublicDecryptionResponse(requestID, decryptedResult, verifiedSignatures, extraData);
        }
    }

    /**
     * @notice See {IDecryption-requestUserDecryption}.
     */
    function requestUserDecryption(
        CtHandleContractPair[] calldata ctHandleContractPairs,
        RequestValidity calldata requestValidity,
        ContractsInfo calldata contractsInfo,
        address userAddress,
        bytes calldata publicKey,
        bytes calldata signature,
        bytes calldata extraData
    ) external virtual whenNotPaused returns (uint256 requestID) {
        // Ensure at least one contract address is provided.
        if (contractsInfo.addresses.length == 0) {
            revert EmptyContractAddresses();
        }

        // Ensure the number of contract addresses does not exceed the maximum allowed.
        if (contractsInfo.addresses.length > MAX_USER_DECRYPT_CONTRACT_ADDRESSES) {
            revert ContractAddressesMaxLengthExceeded(
                MAX_USER_DECRYPT_CONTRACT_ADDRESSES,
                contractsInfo.addresses.length
            );
        }

        // Check the user decryption request is valid.
        _checkRequestUserDecryptionValidity(requestValidity);

        // Check the user address is not included in the contract addresses.
        if (_containsContractAddress(contractsInfo.addresses, userAddress)) {
            revert UserAddressInContractAddresses(userAddress, contractsInfo.addresses);
        }

        // The ACL contract must be configured — decryption is rejected entirely
        // until it is, so access control can never be silently bypassed.
        if (!_isAclConfigured()) {
            revert ACLNotConfigured();
        }

        // Extract the handles and check their permissions
        DecryptionStorage storage $ = _getDecryptionStorage();
        if (ctHandleContractPairs.length == 0) { revert EmptyCtHandleContractPairs(); }
        bytes32[] memory ctHandles = new bytes32[](ctHandleContractPairs.length);
        for (uint256 i = 0; i < ctHandleContractPairs.length; i++) {
            bytes32 ctHandle = ctHandleContractPairs[i].ctHandle;
            address contractAddress = ctHandleContractPairs[i].contractAddress;
            if (!$.acl.isAllowed(ctHandle, userAddress)) {
                revert ACLNotAllowed(ctHandle, userAddress);
            }
            if (!$.acl.isAllowed(ctHandle, contractAddress)) {
                revert ACLNotAllowed(ctHandle, contractAddress);
            }
            // Check the contract is included in the list of allowed contract addresses.
            if (!_containsContractAddress(contractsInfo.addresses, contractAddress)) {
                revert ContractAddressNotInContractAddresses(contractAddress, contractsInfo.addresses);
            }
            ctHandles[i] = ctHandle;
        }

        // Initialize the RequestUserDecryptSignData structure for the signature validation.
        RequestUserDecryptSignData memory requestUserDecryptSignData = RequestUserDecryptSignData(
            publicKey,
            contractsInfo.addresses,
            requestValidity.startTimestamp,
            requestValidity.durationDays,
            extraData
        );

        // Validate the received EIP712 signature on the user decryption request.
        _validateRequestUserDecryptEIP712Signature(
            requestUserDecryptSignData,
            userAddress,
            signature
        );

        // Generate unique decryptionId for the user decryption request.
        CiphertextDigestInfo[] memory ciphertextDigestInfo = $.cipherDigests.getCiphertextDigests(ctHandles);

        // Check that received ciphertextDigestInfo have the same keyId.
        // TODO _checkSameKeyIds(ciphertextDigestInfo);

        $.userDecryptionCounter++;
        requestID = $.userDecryptionCounter;

        // Save the publicKey and ctHandles, they are used during response calls for the EIP712 signature validation.
        $.userDecryptionPayloads[requestID] = UserDecryptionPayload(publicKey, ctHandles);

        // charge the fee from the transaction sender for this user decryption request.
        // _chargeUserDecryptionFee(msg.sender);

        emit UserDecryptionRequest(requestID, ciphertextDigestInfo, userAddress, publicKey, extraData);
    }

    /**
     * @notice See {IDecryption-respondUserDecryption}.
     */
    function respondUserDecryption(
        uint256 requestID,
        bytes calldata userDecryptedData,
        bytes calldata signature,
        bytes calldata extraData
    ) external onlyKmsTxSender virtual {
        DecryptionStorage storage $ = _getDecryptionStorage();

        // Make sure the requestID corresponds to a generated user decryption request
        if (requestID <= USER_DECRYPT_INIT_COUNTER || requestID > $.userDecryptionCounter) {
            revert NotDecryptionRequested(requestID);
        }

        // Get user decryption payload
        UserDecryptionPayload memory userDecryptionPayload = $.userDecryptionPayloads[requestID];

        // Initialize the ResponseUserDecryptSignData structure for the signature validation.
        ResponseUserDecryptSignData memory responseUserDecryptSignData = ResponseUserDecryptSignData(
            userDecryptionPayload.publicKey,
            userDecryptionPayload.ctHandles,
            userDecryptedData,
            extraData
        );

        // Compute the hase of the ResponseUserDecryptSignData structure.
        bytes32 hash = _hashResponseUserDecryptSignData(responseUserDecryptSignData);

        // Recover the signer address from the signature and validate that corresponds to a
        // KMS node that has not already signed.
        _validateDecryptionResponseEIP712Signature(requestID, hash, signature);

        // Store the KMS transaction sender address for the user decryption response
        address[] storage txSenderAddresses = $.consensusTxSenderAddresses[requestID][0];
        txSenderAddresses.push(msg.sender);

        emit UserDecryptionResponse(
            requestID,
            txSenderAddresses.length - 1,
            userDecryptedData,
            signature,
            extraData
        );

        // Set the decryption done flag and emit the event  
        if (!$.decryptionDone[requestID] && _isThresholdReachedUser(txSenderAddresses.length)) {
            $.decryptionDone[requestID] = true;

            emit UserDecryptionResponseThresholdReached(requestID);
        }
    }

    /**
     * @notice See {IDecryption-isPublicDecryptionReady}.
     */
    function isPublicDecryptionReady(
        bytes32[] calldata ctHandles,
        bytes calldata /* extraData */
    ) external view virtual returns (bool) {
        // Return false if the list of handles is empty
        if (ctHandles.length == 0) {
            return false;
        }

        DecryptionStorage storage $ = _getDecryptionStorage();

        // The ACL contract must be configured — readiness cannot be answered
        // while access control is unset.
        if (!_isAclConfigured()) {
            revert ACLNotConfigured();
        }

        // For each handle, check that it is allowed for public decryption
        // and that the ciphertext digest associated with it has been added.
        for (uint256 i = 0; i < ctHandles.length; i++) {
            if (
                !$.acl.isAllowedForDecryption(ctHandles[i]) ||
                !$.cipherDigests.isCiphertextDigestAdded(ctHandles[i])
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice See {IDecryption-isUserDecryptionReady}.
     */
    function isUserDecryptionReady(
        address userAddress,
        CtHandleContractPair[] calldata ctHandleContractPairs,
        bytes calldata /* extraData */
    ) external view virtual returns (bool) {
        // Return false if the list of handles is empty
        if (ctHandleContractPairs.length == 0) {
            return false;
        }

        DecryptionStorage storage $ = _getDecryptionStorage();

        // The ACL contract must be configured — readiness cannot be answered
        // while access control is unset.
        if (!_isAclConfigured()) {
            revert ACLNotConfigured();
        }

        // For each handle, check that the user and contracts accounts have access to it
        // and that the ciphertext digest associated with it has been added.
        for (uint256 i = 0; i < ctHandleContractPairs.length; i++) {
            bytes32 ctHandle = ctHandleContractPairs[i].ctHandle;
            if (
                !$.acl.isAllowed(ctHandle, userAddress) ||
                !$.acl.isAllowed(ctHandle, ctHandleContractPairs[i].contractAddress) ||
                !$.cipherDigests.isCiphertextDigestAdded(ctHandle)
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice See {IDecryption-isDecryptionDone}.
     */
    function isDecryptionDone(uint256 requestID) external view virtual returns (bool) {
        DecryptionStorage storage $ = _getDecryptionStorage();
        return $.decryptionDone[requestID];
    }

    /**
     * @notice See {IDecryption-getDecryptionConsensusTxSenders}.
     */
    function getDecryptionConsensusTxSenders(uint256 decryptionId) external view virtual returns (address[] memory) {
        // Get the unique digest associated to the decryption request in order to retrieve the list of
        // KMS transaction sender addresses that were involved in the associated consensus
        DecryptionStorage storage $ = _getDecryptionStorage();
        bytes32 consensusDigest = $.decryptionConsensusDigest[decryptionId];

        return $.consensusTxSenderAddresses[decryptionId][consensusDigest];
    }

    /**
     * @notice See {IDecryption-verifyPublicDecryptionEIP712KMSSignature}.
     */
    function verifyPublicDecryptionEIP712KMSSignature(
        bytes32[] memory handlesList,
        bytes memory decryptedResult,
        bytes memory decryptionProof
    ) external virtual returns (bool) {
        if (decryptionProof.length == 0) {
            revert EmptyDecryptionProof();
        }

        // Parse numSigners from the first byte.
        uint256 numSigners    = uint256(uint8(decryptionProof[0]));
        uint256 signaturesEnd = 1 + 65 * numSigners;
        if (decryptionProof.length < signaturesEnd) {
            revert DeserializingDecryptionProofFail();
        }

        // Extract each 65-byte signature into a dynamic array.
        bytes[] memory signatures = new bytes[](numSigners);
        for (uint256 j = 0; j < numSigners; j++) {
            signatures[j] = new bytes(65);
            for (uint256 i = 0; i < 65; i++) {
                signatures[j][i] = decryptionProof[1 + 65 * j + i];
            }
        }

        // Everything after the signatures block is opaque signed extraData.
        uint256 extraDataSize = decryptionProof.length - signaturesEnd;
        bytes memory extraData = new bytes(extraDataSize);
        for (uint256 i = 0; i < extraDataSize; i++) {
            extraData[i] = decryptionProof[signaturesEnd + i];
        }

        // Build EIP-712 digest and count unique valid KMS signatures against the config threshold.

        // Initialize the PublicDecryptVerification structure for the signature validation.
        PublicDecryptSignData memory publicDecryptSignData = PublicDecryptSignData(
            handlesList,
            decryptedResult,
            extraData
        );

        // Compute the hash of the PublicDecryptSignData structure.
        bytes32 digest = _hashPublicDecryptSignData(publicDecryptSignData);

        uint256 threshold = spaceBridgeConfig.getPublicDecryptionThreshold();
        uint256 uniqueValidCount = _countValidKmsSignatures(digest, signatures, threshold);
        if (uniqueValidCount < threshold) {
            revert InsufficientSignatures(uniqueValidCount, threshold);
        }
        return true;
    }
    
    /**
     * @notice Recover the signer of each signature, require it to be a registered KMS signer
     *         (per SpaceBridgeConfig), and count unique valid signers using transient storage.
     *         Reverts with KMSInvalidSigner if any recovered address is not a registered KMS
     *         signer. Stops early once `threshold` unique valid signatures are reached.
     * @return uniqueValidCount The number of unique valid KMS signatures found (capped at
     *         `threshold` when the loop exits early).
     */
    function _countValidKmsSignatures(
        bytes32 digest,
        bytes[] memory signatures,
        uint256 threshold
    ) internal returns (uint256 uniqueValidCount) {
        uint256 numSignatures = signatures.length;
        if (numSignatures == 0) {
            revert DeserializingDecryptionProofFail();
        }

        // Reuse the first `threshold` slots of a transient hashmap to dedupe signers; any
        // reasonable threshold fits comfortably in memory for the recovery array.
        address[] memory recoveredSigners = new address[](numSignatures);

        for (uint256 i = 0; i < numSignatures; i++) {
            address recovered = ECDSA.recover(digest, signatures[i]);

            if (!spaceBridgeConfig.isKmsSigner(recovered)) {
                revert KMSInvalidSigner(recovered);
            }

            // Skip duplicate signatures from the same signer within one call.
            if (!_tload(recovered)) {
                recoveredSigners[uniqueValidCount] = recovered;
                uniqueValidCount++;
                _tstore(recovered, 1);
            }

            if (uniqueValidCount >= threshold) {
                _cleanTransientHashMap(recoveredSigners, uniqueValidCount);
                return uniqueValidCount;
            }
        }

        _cleanTransientHashMap(recoveredSigners, uniqueValidCount);
        return uniqueValidCount;
    }

    /**
     * @notice Write a uint256 value to transient storage keyed by an address.
     *         Used to track which signers have already been counted within a single call,
     *         preventing the same signer from being credited twice.
     *         Transient storage is automatically cleared at the end of the transaction (EIP-1153).
     */
    function _tstore(address location, uint256 value) internal virtual {
        assembly {
            tstore(location, value)
        }
    }

    /**
     * @notice Read a boolean from transient storage keyed by an address.
     *         Returns true if the stored value is non-zero, false otherwise.
     */
    function _tload(address location) internal view virtual returns (bool value) {
        assembly {
            value := tload(location)
        }
    }

    /**
     * @notice Zero out transient storage entries for the first `maxIndex` addresses in `keys`.
     *         Called after verification to restore a clean slate, which is important for
     *         composability in account-abstraction contexts where multiple verifications may
     *         occur within the same transaction.
     */
    function _cleanTransientHashMap(address[] memory keys, uint256 maxIndex) internal virtual {
        for (uint256 j = 0; j < maxIndex; j++) {
            _tstore(keys[j], 0);
        }
    }

    /**
     * @notice See {IPayment-getVersion}.
     */
    function getVersion() external pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    CONTRACT_NAME,
                    " v",
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }

    /**
     * @notice Computes the hash of a given PublicDecryptSignData structured data
     * @param publicDecryptSignData The PublicDecryptSignData structure
     * @return The hash of the PublicDecryptSignData structure
     */
    function _hashPublicDecryptSignData(
        PublicDecryptSignData memory publicDecryptSignData
    ) internal view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EIP712_PUBLIC_DECRYPT_TYPE_HASH,
                        keccak256(abi.encodePacked(publicDecryptSignData.ctHandles)),
                        keccak256(publicDecryptSignData.decryptedResult),
                        keccak256(abi.encodePacked(publicDecryptSignData.extraData))
                    )
                )
            );
    }

    /**
     * @notice Indicates if the consensus is reached for public decryption.
     * @param numVerifiedResponses The number of public decryption responses that have been verified.
     * @return Whether the consensus has been reached
     */
    function _isConsensusReachedPublic(uint256 numVerifiedResponses) internal view virtual returns (bool) {
        DecryptionStorage storage $ = _getDecryptionStorage();
        uint256 publicDecryptionThreshold = $.spaceBridgeConfig.getPublicDecryptionThreshold();
        return numVerifiedResponses >= publicDecryptionThreshold;
    }

    /**
     * @notice Indicates if the number of verified user decryption responses has reached the threshold.
     * @param numVerifiedResponses The number of user decryption responses that have been verified.
     * @return Whether the threshold has been reached.
     */
    function _isThresholdReachedUser(uint256 numVerifiedResponses) internal view virtual returns (bool) {
        DecryptionStorage storage $ = _getDecryptionStorage();
        uint256 userDecryptionThreshold = $.spaceBridgeConfig.getUserDecryptionThreshold();
        return numVerifiedResponses >= userDecryptionThreshold;
    }

    /**
     * @notice Validates the EIP712 signature for a given decryption response.
     * @param requestId The decryption request ID.
     * @param digest The hashed EIP712 struct.
     * @param signature The signature to validate.
     */
    function _validateDecryptionResponseEIP712Signature(
        uint256 requestId,
        bytes32 digest,
        bytes calldata signature
    ) internal virtual {
        address signer = ECDSA.recover(digest, signature);

        // Check that the signer is a KMS signer, and that it corresponds to the transaction sender of the same KMS node.
        _checkKmsSignerMatchesTxSender(signer, msg.sender);

        // Check that the signer has not already responded to the user decryption request.
        DecryptionStorage storage $ = _getDecryptionStorage();
        if ($.kmsNodeAlreadySigned[requestId][signer]) {
            revert KmsNodeAlreadySigned(requestId, signer);
        }

        $.kmsNodeAlreadySigned[requestId][signer] = true;
    }

    /**
     * @notice Checks if a user decryption request's start timestamp and duration days are valid.
     * @param requestValidity The RequestValidity structure
     */
    function _checkRequestUserDecryptionValidity(RequestValidity memory requestValidity) internal view virtual {
        // Check the durationDays.
        if (requestValidity.durationDays == 0) {
            revert InvalidDurationDays();
        }

        // Check the durationDays does not exceed the maximum allowed.
        if (requestValidity.durationDays > MAX_USER_DECRYPT_DURATION_DAYS) {
            revert MaxDurationDaysExceeded(MAX_USER_DECRYPT_DURATION_DAYS, requestValidity.durationDays);
        }

        // Check the start timestamp is not set in the future. This is to prevent a user
        // from bypassing the durationDays limit of 90 days by setting a start timestamp
        // far in the future.
        if (requestValidity.startTimestamp > block.timestamp) {
            revert StartTimestampInFuture(block.timestamp, requestValidity.startTimestamp);
        }

        // Check the user decryption request has not expired. A user decryption request is valid
        // from startTimestamp for a number of days equal to durationDays.
        if (requestValidity.startTimestamp + requestValidity.durationDays * 1 days <= block.timestamp) {
            revert UserDecryptionRequestExpired(block.timestamp, requestValidity);
        }
    }

    /**
     * @notice Checks that the given signer address matches the registered signer
     * address of the given KMS transaction sender.
     * @dev Reverts if `txSender` is not a registered KMS transaction sender, or if
     * `signer` does not equal the signer address registered for that transaction sender.
     * @param signer The signer address recovered from a signature (e.g. via ECDSA.recover).
     * @param txSender The transaction sender address to check against (typically `msg.sender`).
     */
    function _checkKmsSignerMatchesTxSender(address signer, address txSender) internal view {
        DecryptionStorage storage $ = _getDecryptionStorage();
        if (!$.spaceBridgeConfig.isKmsTxSender(txSender)) {
            revert NotKmsTxSender(txSender);
        }

        KmsNode memory kmsNode = $.spaceBridgeConfig.getKmsNode(txSender);
        if (kmsNode.signerAddress != signer) {
            revert KmsSignerMismatch(txSender, kmsNode.signerAddress, signer);
        }
    }

    /**
     * @notice Checks if a given contractAddress is included in the contractAddresses list.
     * @param contractAddresses The list of contract addresses
     * @param contractAddress The contract address to check
     * @return Whether the contract address is included in the list
     */
    function _containsContractAddress(
        address[] memory contractAddresses,
        address contractAddress
    ) internal pure virtual returns (bool) {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (contractAddresses[i] == contractAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Validates the EIP712 signature for user decryption request
     * @param requestUserDecryptSignData The signed RequestUserDecryptSignData structure.
     * @param userAddress The address of the user.
     * @param signature The signature to be validated.
     */
    function _validateRequestUserDecryptEIP712Signature(
        RequestUserDecryptSignData memory requestUserDecryptSignData,
        address userAddress,
        bytes calldata signature
    ) internal view virtual {
        bytes32 hash = _hashUserDecryptRequestSignData(requestUserDecryptSignData);
        address signer = ECDSA.recover(hash, signature);
        if (signer != userAddress) {
            revert InvalidUserSignature(signature);
        }
    }

    /**
     * @notice Computes the hash of a given RequestUserDecryptSignData structured data.
     * @param requestUserDecryptSignData The RequestUserDecryptSignData structure to hash.
     * @return The hash of the RequestUserDecryptSignData structure.
     */
    function _hashUserDecryptRequestSignData(
        RequestUserDecryptSignData memory requestUserDecryptSignData
    ) internal view virtual returns (bytes32) {
        return 
            _hashTypedDataV4(  
                keccak256(
                    abi.encode(
                        EIP712_REQUEST_USER_DECRYPT_TYPE_HASH,
                        keccak256(requestUserDecryptSignData.publicKey),
                        keccak256(abi.encodePacked(requestUserDecryptSignData.contractAddresses)),
                        requestUserDecryptSignData.startTimestamp,
                        requestUserDecryptSignData.durationDays,
                        keccak256(abi.encodePacked(requestUserDecryptSignData.extraData))
                    )
                )
            );
    }

    /**
     * @notice Computes the hash of a given ResponseUserDecryptSignData structured data.
     * @param responseUserDecryptSignData The ResponseUserDecryptSignData structure to hash.
     * @return The hash of the ResponseUserDecryptSignData structure.
     */
    function _hashResponseUserDecryptSignData(
        ResponseUserDecryptSignData memory responseUserDecryptSignData
    ) internal view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EIP712_RESPONSE_USER_DECRYPT_TYPE_HASH,
                        keccak256(responseUserDecryptSignData.publicKey),
                        keccak256(abi.encodePacked(responseUserDecryptSignData.ctHandles)),
                        keccak256(responseUserDecryptSignData.userDecryptedData),
                        keccak256(abi.encodePacked(responseUserDecryptSignData.extraData))
                    )
                )
            );
    }

    /**
     * @notice Returns the DecryptionOracle storage location.
     */
    function _getDecryptionStorage() internal pure returns (DecryptionStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := DecryptionStorageLocation
        }
    }

    /**
     * @notice Checks if the ACL contract is configured.
     * @return True if the ACL contract address is set, false otherwise.
     * @dev Decryption requests and readiness checks revert with {ACLNotConfigured}
     *      when this returns false, so access control can never be silently bypassed.
     *      The ACL contract must be set via {configureACL} before the contract is usable.
     */
    function _isAclConfigured() internal view returns (bool) {
        return address(_getDecryptionStorage().acl) != address(0);
    }
}
