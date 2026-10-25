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
import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";
import { ICiphertextVerification } from "./interfaces/ICiphertextVerification.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SpaceBridgeOwnable } from "./SpaceBridgeOwnable.sol";
import { SpaceBridgeConfigGuards } from "./SpaceBridgeConfigGuards.sol";
import { PaymentFee } from "./PaymentFee.sol";
import { Pausable } from "./Pausable.sol";
import { Alphatrion } from "./SpaceBridgeTypes.sol";


/**
 * @title CiphertextVerification contract
 * @notice See {ICiphertextVerification}.
 */
contract CiphertextVerification is 
    Initializable, 
    ICiphertextVerification, 
    EIP712Upgradeable, 
    SpaceBridgeOwnable, 
    SpaceBridgeConfigGuards, 
    PaymentFee, 
    UUPSUpgradeable, 
    Pausable {
     /**
     * @notice The typed data structure for the EIP712 signature to validate in ZK Proof verification responses.
     */
    struct CiphertextVerificationSignData {
        /// @notice The coprocessor's computed ciphertext handles.
        bytes32[] ctHandles;
        /// @notice The address of the user that has provided the input in the ZK Proof verification request.
        address userAddress;
        /// @notice The address of the dapp requiring the ZK Proof verification.
        address contractAddress;
        /// @notice The host chain's chain ID of the contract.
        uint256 chainId;
        /// @notice Generic bytes metadata for versioned payloads. 
        bytes extraData;
    }

    /**
     * @notice The stored structure for the received ZK Proof verification request datas.
     */
    struct ZKProofReqData {
        /// @notice The user address that requested the verification.
        address userAddress;
        /// @notice The contract address that verification is requested for.
        address contractAddress;
        /// @notice The chain ID of the contract address.
        uint256 chainId;
    }

    /**
     * @notice The contract's variable storage struct
     */
    struct CiphertextVerificationStorage {
        /// @notice The counter used for the ZKPoK IDs returned in verification request events.
        uint256 zkProofIdCounter;

        /// @notice The request input datas to be used for signature validation in response calls.
        mapping(uint256 zkProofId => ZKProofReqData zkProofReqData) zkProofReqDatas;
        /// @notice The validated signatures associated to a verified ZKPoK with the given ID.
        mapping(uint256 zkProofId => mapping(bytes32 digest => bytes[] signatures)) zkProofSignatures;
        /// @notice The alphatrion transaction senders involved in a consensus for a proof verification.
        mapping(uint256 zkProofId =>
            mapping(bytes32 digest => address[] alphatrionTxSenderAddresses)) verifyProofConsensusTxSenders;

        /// @notice The request IDs that have been verified.
        mapping(uint256 zkProofId => bool isVerified) verifiedZKProofs;
        /// @notice Whether a alphatrion has signed a ZKPoK verification.
        mapping(uint256 zkProofId => mapping(address alphatrionSigner => bool hasVerified)) signerVerifiedZKProofs;
        /// @notice The digest of the proof verification response that reached consensus for a proof verification request.
        mapping(uint256 zkProofId => bytes32 verifyProofConsensusDigest) verifyProofConsensusDigest;

        /// @notice The request IDs that have been rejected.
        mapping(uint256 zkProofId => bool isRejected) rejectedZKProofs;
        /// @notice The number of alphatrions that have rejected a ZKPoK with the given ID.
        mapping(uint256 zkProofId => uint256 responseCounter) rejectedProofResponseCounter;
        /// @notice Whether a alphatrion has signed a ZKPoK rejection.
        mapping(uint256 zkProofId => mapping(address alphatrionSigner => bool hasRejected)) signerRejectedZKProof;
        /// @notice The alphatrion transaction senders involved in a consensus for a proof rejection.
        mapping(uint256 zkProofId => address[] alphatrionTxSenderAddresses) rejectProofConsensusTxSenders;
    }

    /**
     * @notice The hash of the CiphertextVerificationSignData structure typed data definition used for signature validation.
     */
    bytes32 private constant EIP712_CIPHER_VERIFY_TYPE_HASH = 
        keccak256(bytes("CiphertextVerificationSignData(bytes32[] ctHandles,address userAddress,address contractAddress,uint256 chainId,bytes extraData)"));

    /**
     * @dev The following constants are used for versioning the contract. 
     */
    string private constant CONTRACT_NAME = "CiphertextVerification";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    /**
     * @dev Storage location has been computed using the following command:
     * keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.CiphertextVerification")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 private constant CIPHERTEXT_VERIFICATION_STORAGE_LOCATION =
        0x9a57aa9afdf33210bf08d7cac44395217b1266507ecd1bc53d57f1a286191d00;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Checks if the sender is authorized to upgrade the contract and reverts otherwise.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlySpaceBridgeOwner {}

    /**
     * @notice Initializes the contract
     */
    function initialize(address _spaceBridgeConfigAddress) public initializer {
        require(_spaceBridgeConfigAddress != address(0), "Invalid SpaceBridgeConfig address");
        __EIP712_init(CONTRACT_NAME, "1");
        __SpaceBridgeOwnable_init(_spaceBridgeConfigAddress);
        __SpaceBridgeConfigGuards_init(_spaceBridgeConfigAddress);
        __PausableWithSpaceBridge_init(_spaceBridgeConfigAddress);
    }

    /**
     * @notice See {ICiphertextVerification-requestVerifyProof}.
     */
    function requestVerifyProof(
        uint256 chainId,
        address contractAddress,
        address userAddress,
        bytes calldata ciphertextWithZKProof,
        bytes calldata extraData
    ) external virtual whenNotPaused returns (uint256 zkProofId) {
        if (chainId != block.chainid) {
            revert InvalidChainId(chainId, block.chainid);
        }

        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();

        $.zkProofIdCounter++;
        zkProofId = $.zkProofIdCounter;

        // The following stored req datas are used during response calls for the EIP712 signature validation.
        $.zkProofReqDatas[zkProofId] = ZKProofReqData(userAddress, contractAddress, chainId);

        // Charge the fee from the transaction sender for this ciphertext verification request.
        // _chargeCiphertextVerificationFee(msg.sender);

        // emit VerifyProofRequest event
        emit VerifyProofRequest(
            zkProofId,
            chainId,
            contractAddress,
            userAddress,
            ciphertextWithZKProof,
            extraData
        );
    }

    /**
     * @notice See {ICiphertextVerification-respondVerifyProof}.
     * We restrict this call to Alphatrion transaction senders to ensure that,
     * in case of a reorg, no one else can copy the signature and use it to trigger consensus.
     */
    function respondVerifyProof(
        uint256 zkProofId,
        bytes32[] calldata ctHandles,
        bytes calldata signature,
        bytes calldata extraData
    ) external virtual onlyAlphatrionTxSender {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();

        // Make sure the zkProofId is correct.
        if (zkProofId > $.zkProofIdCounter || zkProofId == 0) {
            revert NotRequestedVerifyProof(zkProofId);
        }

        // Retrieve stored request proof datas.
        ZKProofReqData memory zkProofReqData = $.zkProofReqDatas[zkProofId];

        // Initialize the CiphertextVerificationSignData structure for the signature validation.
        CiphertextVerificationSignData memory ciphertextVerificationSignData = CiphertextVerificationSignData(
            ctHandles,
            zkProofReqData.userAddress,
            zkProofReqData.contractAddress,
            zkProofReqData.chainId,
            extraData
        );

        // Compute the digest of the CiphertextVerificationSignData structure.
        bytes32 digest = _hashCiphertextVerificationSignData(ciphertextVerificationSignData);

        // Recover the signer address from the signature,
        address signerAddress = ECDSA.recover(digest, signature);

        // Check that the signer is a alphatrion signer
        _checkAlphatrionSignerMatchesTxSender(signerAddress, msg.sender);

        // Check that the alphatrion has not already responded to the request.
        _checkAlphatrionAlreadyResponded(zkProofId, signerAddress);

        // Store the signature and update the signer's verification status.
        bytes[] storage currentSignatures = $.zkProofSignatures[zkProofId][digest];
        currentSignatures.push(signature);
        $.signerVerifiedZKProofs[zkProofId][signerAddress] = true;

        // Store the alphatrion transaction sender address for the response
        $.verifyProofConsensusTxSenders[zkProofId][digest].push(msg.sender);

        // Emit the event for monitoring purposes.
        emit VerifyProofResponsePartial(zkProofId, ctHandles, signature, msg.sender, extraData);

        // Send the event if and only if the consensus is reached in the current response call.
        if (
            !$.verifiedZKProofs[zkProofId] &&
            !$.rejectedZKProofs[zkProofId] &&
            _isConsensusReached(currentSignatures.length)
        ) {
            $.verifiedZKProofs[zkProofId] = true;

            // A "late" valid alphatrion could still see its transaction sender address be added to
            // the list after consensus. 
            $.verifyProofConsensusDigest[zkProofId] = digest;

            emit VerifyProofResponseConsensus(zkProofId, ctHandles, currentSignatures);
        }
    }

    /**
     * @notice See {ICiphertextVerification-rejectVerifyProof}.
     */
    function rejectVerifyProof(
        uint256 zkProofId, 
        bytes calldata
    ) external virtual onlyAlphatrionTxSender {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();

        // Make sure the zkProofId is correct.
        if (zkProofId > $.zkProofIdCounter || zkProofId == 0) {
            revert NotRequestedVerifyProof(zkProofId);
        }

        // Retrieve the alphatrion signer address from the SpaceBridgeConfig contract 
        // using the alphatrion transaction sender address.
        Alphatrion memory alphatrion = spaceBridgeConfig.getAlphatrion(msg.sender);
        address alphatrionSignerAddress = alphatrion.signerAddress;

        // Check that the alphatrion has not already responded to the request.
        _checkAlphatrionAlreadyResponded(zkProofId, alphatrionSignerAddress);

        // Mark this signer as having rejected the ZK proof and increment the rejection counter
        $.rejectedProofResponseCounter[zkProofId]++;
        $.signerRejectedZKProof[zkProofId][alphatrionSignerAddress] = true;

        // Store the alphatrion transaction sender address for the rejection response.
        // A "late" valid alphatrion transaction sender address will still be added in the list.
        $.rejectProofConsensusTxSenders[zkProofId].push(msg.sender);

        // Send the event if and only if the consensus is reached in the current response call.
        if (
            !$.verifiedZKProofs[zkProofId] &&
            !$.rejectedZKProofs[zkProofId] &&
            _isConsensusReached($.rejectedProofResponseCounter[zkProofId])
        ) {
            $.rejectedZKProofs[zkProofId] = true;

            emit RejectProofResponse(zkProofId);
        }
    }


    /**
     * @notice See {ICiphertextVerification-verifyInput}.
     * @dev Steps performed in verifyInput:
     * 1. Check if this proof was already cached to avoid redundant verification.
     * 2. Deserialize the first 2 bytes to obtain numHandles and numSigners.
     * 3. Basic sanity checks on numHandles and numSigners.
     * 4. Calculate extraData offset and ensure inputProof is long enough.
     * 5. Deserialize handles and ensure `inputHandle` exists in proof.
     * 6. Deserialize 65-byte ECDSA signatures for all signers.
     * 7. Populate CiphertextVerificationSignData struct for verification.
     * 8. Extract extraData bytes from inputProof.
     * 9. Verify the signatures using _verifyEIP712.
     * 10. Cache the proof to avoid re-verification in future calls.
     */
    function verifyInput(
        address userAddress,
        address contractAddress,
        bytes32 inputHandle,
        bytes memory inputProof
    ) external whenNotPaused returns (bool) {
        // Check if this proof was already verified and cached
        (bool isProofCached, bytes32 cacheKey) = _checkProofCache(userAddress, contractAddress, inputProof);

        uint256 inputProofLen = inputProof.length;
        if (inputProofLen < 2) revert EmptyInputProof();

        // First byte: number of handles, Second byte: number of signers
        uint256 numHandles = uint256(uint8(inputProof[0]));
        uint256 numSigners = uint256(uint8(inputProof[1]));

        // Sanity checks for handle/signers count
        if (numHandles <= 0 || numHandles > 254) revert InvalidHandleNums();
        if (numSigners <= 0 || numSigners > 254) revert InvalidSignerNums();

        // Calculate where extraData starts
        uint256 extraDataOffset = 1 + 1 + 32 * numHandles + 65 * numSigners;

        /// @dev Ensure inputProof length can accommodate handles + signatures
        if (inputProofLen < extraDataOffset) revert DeserializingInputProofFail();

        /// @dev Deserialize handles
        bool handleExist = false;
        bytes32[] memory listHandles = new bytes32[](numHandles);
        for (uint256 i = 0; i < numHandles; i++) {
            bytes32 element;
            assembly {
                // Load 32 bytes per handle from inputProof
                element := mload(add(inputProof, add(34, mul(i, 32))))
            }
            listHandles[i] = element;
            if (inputHandle == element) {
                handleExist = true;
            }
        }

        // Ensure the inputHandle exists in the proof
        if (!handleExist) revert InputHandleNotExistInProofCtx();

        // Return early if proof already cached
        if (isProofCached) {
            return true;
        }
        
        /// @dev Deserialize signatures (65 bytes each)
        bytes[] memory signatures = new bytes[](numSigners);
        for (uint256 j = 0; j < numSigners; j++) {
            signatures[j] = new bytes(65);
            for (uint256 i = 0; i < 65; i++) {
                signatures[j][i] = inputProof[2 + 32 * numHandles + 65 * j + i];
            }
        }

        /// @dev Populate verification struct
        CiphertextVerificationSignData memory ctVerificationData;
        ctVerificationData.ctHandles = listHandles;
        ctVerificationData.userAddress = userAddress;
        ctVerificationData.contractAddress = contractAddress;
        ctVerificationData.chainId = block.chainid;

        /// @dev Extract extraData from inputProof
        uint256 extraDataSize = inputProof.length - extraDataOffset;
        ctVerificationData.extraData = new bytes(extraDataSize);
        for (uint i = 0; i < extraDataSize; i++) {
            ctVerificationData.extraData[i] = inputProof[extraDataOffset + i];
        }

        /// @dev Verify signatures against the serialized struct using EIP-712 digest
        _verifyEIP712(ctVerificationData, signatures);

        /// @dev Cache the proof to avoid repeated verifications
        _cacheProof(cacheKey);

        return true;
    }

    /**
     * @dev Check if proof is already cached
     */
    function _checkProofCache(address userAddress, address contractAddress, bytes memory inputProof)
        internal view virtual returns (bool, bytes32)
    {
        bool isProofCached;
        bytes32 key = keccak256(abi.encodePacked(userAddress, contractAddress, inputProof));
        assembly {
            isProofCached := tload(key)
        }
        return (isProofCached, key);
    }

    /**
     * @dev Store proof in cache
     */
    function _cacheProof(bytes32 proofKey) internal virtual {
        assembly {
            tstore(proofKey, 1)
            let length := tload(0)
            let lengthPlusOne := add(length, 1)
            tstore(lengthPlusOne, proofKey)
            tstore(0, lengthPlusOne)
        }
    }

    /**
     * @dev Internal EIP-712 verification
     *      Currently calls _verifySignaturesDigest after hashing the struct.
     * @param ctVerificationData The struct to verify.
     * @param signatures Array of serialized 65-byte signatures.
     */
    function _verifyEIP712(
        CiphertextVerificationSignData memory ctVerificationData,
        bytes[] memory signatures
    ) internal virtual {
        bytes32 digest = _hashCiphertextVerificationSignData(ctVerificationData);
        if (!_verifySignaturesDigest(digest, signatures)) revert SignaturesVerificationFailed();
    }

    /**
     * @dev Verify signatures against digest, enforcing threshold & uniqueness
     *      - Ensure at least `threshold` unique valid signatures
     *      - Recover signer addresses and check against allowed signers
     * @param digest      EIP-712 digest
     * @param signatures  Array of 65-byte signatures
     * @return bool       True if enough unique valid signatures are found
     */
    function _verifySignaturesDigest(bytes32 digest, bytes[] memory signatures) internal virtual returns (bool) {
        uint256 numSignatures = signatures.length;
        if (numSignatures == 0) revert ZeroSignature();

        uint256 threshold = spaceBridgeConfig.getAlphatrionThreshold();
        if (numSignatures < threshold) revert SignatureThresholdNotReached(numSignatures);

        address[] memory recoveredSigners = new address[](numSignatures);
        uint256 uniqueValidCount = 0;

        for (uint256 i = 0; i < numSignatures; i++) {
            address signerRecovered = ECDSA.recover(digest, signatures[i]);
            _checkIsAlphatrionSigner(signerRecovered);

            // TODO: For large numSigners, this could be gas-intensive. 
            // Using a temporary mapping may be cheaper (mapping from address → bool).

            bool seen = false;
            for (uint256 j = 0; j < uniqueValidCount; j++) {
                if (recoveredSigners[j] == signerRecovered) {
                    seen = true;
                    break;
                }
            }

            if (!seen) {
                recoveredSigners[uniqueValidCount++] = signerRecovered;
                if (uniqueValidCount >= threshold) {
                    return true;
                }
            }
        }
        return false;
    }


    /**
     * @notice See {ICiphertextVerification-isProofVerified}.
     */
    function isProofVerified(uint256 zkProofId) external view virtual returns (bool) {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();
        return $.verifiedZKProofs[zkProofId];
    }

    /**
     * @notice See {ICiphertextVerification-isProofRejected}.
     */
    function isProofRejected(uint256 zkProofId) external view virtual returns (bool) {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();
        return $.rejectedZKProofs[zkProofId];
    }

    /**
     * @notice See {ICiphertextVerification-getVerifyProofConsensusTxSenders}.
     * The list remains empty until the consensus is reached.
     */
    function getVerifyProofConsensusTxSenders(uint256 zkProofId) external view virtual returns (address[] memory) {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();

        // Get the unique digest associated to the request in order to retrieve the list of 
        // alphatrion transaction sender address that were involved in the consensus.
        bytes32 consensusDigest = $.verifyProofConsensusDigest[zkProofId];
        return $.verifyProofConsensusTxSenders[zkProofId][consensusDigest];
    }

    /**
     * @notice See {ICiphertextVerification-getVerifyProofConsensusSignatures}.
     * The list remains empty until the consensus is reached.
     */
    function getVerifyProofConsensusSignatures(uint256 zkProofId) external view virtual returns (bytes[] memory) {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();
        
        // Check if the proof has been verified (consensus reached)
        if (!$.verifiedZKProofs[zkProofId]) {
            // Return empty array if no consensus has been reached
            return new bytes[](0);
        }
        
        // Retrieve the consensus digest for this zkProofId
        bytes32 consensusDigest = $.verifyProofConsensusDigest[zkProofId];
        
        // Return the signatures associated with the consensus digest
        return $.zkProofSignatures[zkProofId][consensusDigest];
    }

    /**
     * @notice See {ICiphertextVerification-getRejectProofConsensusTxSenders}.
     */
    function getRejectProofConsensusTxSenders(uint256 zkProofId) external view virtual returns (address[] memory) {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();
        return $.rejectProofConsensusTxSenders[zkProofId];
    }

    /**
     * @notice See {ICiphertextVerification-getVersion}.
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
     * @notice Checks if the alphatrion has already verified or rejected the request.
     * @param zkProofId The ID of the ZK Proof.
     * @param signerAddress The signer address of the alphatrion.
     */
    function _checkAlphatrionAlreadyResponded(uint256 zkProofId, address signerAddress) internal virtual {
        CiphertextVerificationStorage storage $ = _getCiphertextVerificationStorage();

        if ($.signerVerifiedZKProofs[zkProofId][signerAddress]) {
            revert AlphatrionAlreadyVerified(zkProofId, msg.sender, signerAddress);
        }

        if ($.signerRejectedZKProof[zkProofId][signerAddress]) {
            revert AlphatrionAlreadyRejected(zkProofId, msg.sender, signerAddress);
        }
    }

    /**
     * @notice Checks if the consensus is reached among the alphatrions.
     * @param alphatrionCounter The number of alphatrions that agreed
     * @return Whether the consensus is reached
     */
    function _isConsensusReached(uint256 alphatrionCounter) internal view virtual returns (bool) {
        uint256 consensusThreshold = spaceBridgeConfig.getAlphatrionThreshold();
        return alphatrionCounter >= consensusThreshold;
    }

    /**
     * @notice Computes the hash of a given CiphertextVerificationSignData structured data
     * @param ctVerificationData The CiphertextVerificationSignData structure
     * @return The hash of the CiphertextVerificationSignData structure
     */
    function _hashCiphertextVerificationSignData(
        CiphertextVerificationSignData memory ctVerificationData
    ) internal view virtual returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EIP712_CIPHER_VERIFY_TYPE_HASH,
                        keccak256(abi.encodePacked(ctVerificationData.ctHandles)),
                        ctVerificationData.userAddress,
                        ctVerificationData.contractAddress,
                        ctVerificationData.chainId,
                        keccak256(abi.encodePacked(ctVerificationData.extraData))
                    )
                )
            );
    }

    /**
     * @notice Returns the CiphertextVerification storage location.
     */
    function _getCiphertextVerificationStorage() internal pure returns (CiphertextVerificationStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := CIPHERTEXT_VERIFICATION_STORAGE_LOCATION
        }
    }
}
