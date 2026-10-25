// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import { Alphatrion, KmsNode } from "../SpaceBridgeTypes.sol";

/**
 * @title Interface for the SpaceBridgeConfig contract.
 * @notice The SpaceBridgeConfig contract is responsible for being a point of truth for all contracts and
 * components from the FHETransform SpaceBridge.
 */
interface ISpaceBridgeConfig {
    /**
     * @notice Emitted when the SpaceBridgeConfig initialization is completed.
     * @param alphatrions List of alphatrions.
     * @param alphatrionThreshold The Alphatrion threshold.
     * @param kmsNodes List of KMS nodes.
     * @param publicDecryptionThreshold The public decryption threshold.
     * @param userDecryptionThreshold The user decryption threshold.
     */
    event InitializeSpaceBridgeConfig(
        Alphatrion[] alphatrions,
        uint256 alphatrionThreshold,
        KmsNode[] kmsNodes,
        uint256 publicDecryptionThreshold,
        uint256 userDecryptionThreshold
    );

    /**
     * @notice Emitted when the alphatrions have been updated.
     * @param newAlphatrions The new alphatrions.
     * @param newAlphatrionThreshold The new alphatrions threshold.
     */
    event UpdateAlphatrions(Alphatrion[] newAlphatrions, uint256 newAlphatrionThreshold);

    /**
     * @notice Emitted when the alphatrion threshold has been updated.
     * @param newAlphatrionThreshold The new alphatrion threshold.
     */
    event UpdateAlphatrionThreshold(uint256 newAlphatrionThreshold);

    /**
     * @notice Emitted when the KMS nodes have been updated.
     * @param newKmsNodes The new KMS nodes.
     * @param newPublicDecryptionThreshold The new public decryption threshold.
     * @param newUserDecryptionThreshold The new user decryption threshold.
     */
    event UpdateKmsNodes(
        KmsNode[] newKmsNodes,
        uint256 newPublicDecryptionThreshold,
        uint256 newUserDecryptionThreshold
    );

    /**
     * @notice Emitted when the public decryption threshold has been updated.
     * @param newPublicDecryptionThreshold The new public decryption threshold.
     */
    event UpdatePublicDecryptionThreshold(uint256 newPublicDecryptionThreshold);

    /**
     * @notice Emitted when the user decryption threshold has been updated.
     * @param newUserDecryptionThreshold The new user decryption threshold.
     */
    event UpdateUserDecryptionThreshold(uint256 newUserDecryptionThreshold);

    /**
     * @notice Emitted when a pausable dependent contract has been registered.
     * @param contractAddress The registered contract address.
     */
    event PausableContractAdded(address contractAddress);

    /**
     * @notice Emitted when a pausable dependent contract has been removed from the registry.
     * @param contractAddress The removed contract address.
     */
    event PausableContractRemoved(address contractAddress);

    /**
     * @notice Emitted after a coordinated pause of registered dependent contracts.
     * @param contracts The contracts that were paused by this call (already-paused ones are excluded).
     */
    event ContractsPaused(address[] contracts);

    /**
     * @notice Emitted after a coordinated unpause of registered dependent contracts.
     * @param contracts The contracts that were unpaused by this call (already-unpaused ones are excluded).
     */
    event ContractsUnpaused(address[] contracts);

    /**
     * @notice Error emitted when the alphatrions list is empty.
     */
    error EmptyAlphatrions();

    /**
     * @notice Error emitted when the alphatrion transaction sender is already registered.
     * @param alphatrionTxSenderAddress The alphatrion transaction sender address.
     */
    error AlphatrionTxSenderAlreadyRegistered(address alphatrionTxSenderAddress);

    /**
     * @notice Error emitted when the alphatrion signer is already registered.
     * @param alphatrionSignerAddress The alphatrion signer address.
     */
    error AlphatrionSignerAlreadyRegistered(address alphatrionSignerAddress);

    /**
     * @notice Error emitted when the alphatrion transaction sender address is zero.
     */
    error InvalidAlphatrionTxSenderAddress();

    /**
     * @notice Error emitted when the alphatrion signer address is zero.
     */
    error InvalidAlphatrionSignerAddress();

    /**
     * @notice Error emitted when the alphatrion threshold is invalid.
     */
    error InvalidAlphatrionThreshold();

    /**
     * @notice Error emitted when the alphatrion threshold is strictly greater than the number of alphatrions.
     * @param alphatrionThreshold The alphatrion threshold.
     * @param nAlphatrions The number of alphatrions.
     */
    error InvalidHighAlphatrionThreshold(uint256 alphatrionThreshold, uint256 nAlphatrions);

    /**
     * @notice Error emitted when the alphatrion threshold is below the majority quorum of the alphatrions.
     * @param alphatrionThreshold The alphatrion threshold.
     * @param minThreshold The minimum threshold required (`floor(nAlphatrions / 2) + 1`).
     */
    error InvalidLowAlphatrionThreshold(uint256 alphatrionThreshold, uint256 minThreshold);

    /// @notice Error emitted when the KMS nodes list is empty.
    error EmptyKmsNodes();

    /// @notice Error emitted when the KMS node transaction sender is already registered.
    error KmsTxSenderAlreadyRegistered(address kmsTxSenderAddress);

    /// @notice Error emitted when the KMS node signer is already registered.
    error KmsSignerAlreadyRegistered(address kmsSignerAddress);

    /// @notice Error emitted when the KMS node transaction sender address is zero.
    error InvalidKmsTxSenderAddress();

    /// @notice Error emitted when the KMS node signer address is zero.
    error InvalidKmsSignerAddress();

    /// @notice Error emitted when the public decryption threshold is zero.
    error InvalidNullPublicDecryptionThreshold();

    /// @notice Error emitted when the public decryption threshold exceeds the number of registered KMS nodes.
    error InvalidHighPublicDecryptionThreshold(uint256 publicDecryptionThreshold, uint256 nKmsNodes);

    /// @notice Error emitted when the public decryption threshold is below the majority quorum of the KMS nodes.
    error InvalidLowPublicDecryptionThreshold(uint256 publicDecryptionThreshold, uint256 minThreshold);

    /// @notice Error emitted when the user decryption threshold is zero.
    error InvalidNullUserDecryptionThreshold();

    /// @notice Error emitted when the user decryption threshold exceeds the number of registered KMS nodes.
    error InvalidHighUserDecryptionThreshold(uint256 userDecryptionThreshold, uint256 nKmsNodes);

    /// @notice Error emitted when the user decryption threshold is below the majority quorum of the KMS nodes.
    error InvalidLowUserDecryptionThreshold(uint256 userDecryptionThreshold, uint256 minThreshold);

    /// @notice Error emitted when the pausable contract address is zero.
    error InvalidPausableContractAddress();

    /// @notice Error emitted when the pausable contract is already registered.
    error PausableContractAlreadyRegistered(address contractAddress);

    /// @notice Error emitted when the pausable contract is not registered.
    error PausableContractNotRegistered(address contractAddress);

    /// @notice Error emitted when the pausable contracts list is empty.
    error EmptyPausableContracts();

    // ----------------------------------------------------------------------------------------------
    // Alphatrion functions
    // ----------------------------------------------------------------------------------------------
    /**
     * @notice Update the list of alphatrions and their threshold.
     * @param newAlphatrions The new alphatrions.
     * @param newAlphatrionThreshold The new alphatrion threshold.
     */
    function updateAlphatrions(Alphatrion[] calldata newAlphatrions, uint256 newAlphatrionThreshold) external;

    /**
     * @notice Update the alphatrion threshold.
     * @dev The new threshold must verify `1 <= t <= n`, with `n` the number of alphatrions currently registered.
     * @param newAlphatrionThreshold The new alphatrion threshold.
     */
    function updateAlphatrionThreshold(uint256 newAlphatrionThreshold) external;

    /**
     * @notice Indicates if an address is a registered alphatrion transaction sender.
     * @param alphatrionTxSenderAddress The address to check.
     */
    function isAlphatrionTxSender(address alphatrionTxSenderAddress) external view returns (bool);

    /**
     * @notice Indicates if an address is a registered alphatrion signer.
     * @param signerAddress The address to check.
     */
    function isAlphatrionSigner(address signerAddress) external view returns (bool);

    /**
     * @notice Get the metadata of the alphatrion with the given transaction sender address.
     * @param alphatrionTxSenderAddress The address of alphatrion tx sender.
     * @return The alphatrion's metadata.
     */
    function getAlphatrion(address alphatrionTxSenderAddress) external view returns (Alphatrion memory);

     /**
     * @notice Get the list of all alphatrion's transaction sender addresses currently registered.
     * @return The list of alphatrion's transaction sender addresses.
     */
    function getAlphatrionTxSenders() external view returns (address[] memory);

    /**
     * @notice Get the list of all alphatrions's signer addresses currently registered.
     * @return The list of alphatroins's signer addresses.
     */
    function getAlphatrionSigners() external view returns (address[] memory);

    /**
     * @notice Get the alphatrion threshold
     * @return The alphatrion threshold.
     */
    function getAlphatrionThreshold() external view returns (uint256);

    // ----------------------------------------------------------------------------------------------
    // KMS node functions
    // ----------------------------------------------------------------------------------------------
    /**
     * @notice Update the list of KMS nodes and the decryption consensus thresholds.
     * @param newKmsNodes The new KMS nodes.
     * @param newPublicDecryptionThreshold The new public decryption threshold.
     * @param newUserDecryptionThreshold The new user decryption threshold.
     */
    function updateKmsNodes(
        KmsNode[] calldata newKmsNodes,
        uint256 newPublicDecryptionThreshold,
        uint256 newUserDecryptionThreshold
    ) external;

    /**
     * @notice Update the public decryption threshold.
     * @dev The new threshold must verify `1 <= t <= n`, with `n` the number of KMS nodes currently registered.
     */
    function updatePublicDecryptionThreshold(uint256 newPublicDecryptionThreshold) external;

    /**
     * @notice Update the user decryption threshold.
     * @dev The new threshold must verify `1 <= t <= n`, with `n` the number of KMS nodes currently registered.
     */
    function updateUserDecryptionThreshold(uint256 newUserDecryptionThreshold) external;

    /**
     * @notice Indicates if an address is a registered KMS transaction sender.
     * @param kmsTxSenderAddress The address to check.
     */
    function isKmsTxSender(address kmsTxSenderAddress) external view returns (bool);

    /**
     * @notice Indicates if an address is a registered KMS signer.
     * @param kmsSignerAddress The address to check.
     */
    function isKmsSigner(address kmsSignerAddress) external view returns (bool);

    /**
     * @notice Get the metadata of the KMS node with the given transaction sender address.
     * @param kmsTxSenderAddress The address of the KMS node's transaction sender.
     * @return The KMS node's metadata.
     */
    function getKmsNode(address kmsTxSenderAddress) external view returns (KmsNode memory);

    /**
     * @notice Get the list of all KMS nodes' transaction sender addresses currently registered.
     * @return The list of KMS nodes' transaction sender addresses.
     */
    function getKmsTxSenders() external view returns (address[] memory);

    /**
     * @notice Get the list of all KMS nodes' signer addresses currently registered.
     * @return The list of KMS nodes' signer addresses.
     */
    function getKmsSigners() external view returns (address[] memory);

    /**
     * @notice Get the public decryption threshold.
     * @return The public decryption threshold.
     */
    function getPublicDecryptionThreshold() external view returns (uint256);

    /**
     * @notice Get the user decryption threshold.
     * @return The user decryption threshold.
     */
    function getUserDecryptionThreshold() external view returns (uint256);

    // ----------------------------------------------------------------------------------------------
    // Pausable dependent contracts functions
    // ----------------------------------------------------------------------------------------------
    /**
     * @notice Register dependent contracts that can be paused/unpaused in a coordinated way.
     * @dev Only callable by the owner. Registered contracts must expose the {Pausable} interface
     * (`pause`, `unpause`, `paused`) and authorize this contract to call them.
     * @param contractAddresses The contract addresses to register.
     */
    function addPausableContracts(address[] calldata contractAddresses) external;

    /**
     * @notice Remove a dependent contract from the pausable registry.
     * @dev Only callable by the owner.
     * @param contractAddress The contract address to remove.
     */
    function removePausableContract(address contractAddress) external;

    /**
     * @notice Pause all registered dependent contracts in a single transaction.
     * @dev Only callable by the owner. Contracts that are already paused are skipped; any other
     * failure reverts the whole transaction (atomic). Emits {ContractsPaused} with the contracts
     * that were actually paused.
     */
    function pauseAll() external;

    /**
     * @notice Unpause all registered dependent contracts in a single transaction.
     * @dev Only callable by the owner. Contracts that are not paused are skipped; any other
     * failure reverts the whole transaction (atomic). Emits {ContractsUnpaused} with the contracts
     * that were actually unpaused.
     */
    function unpauseAll() external;

    /**
     * @notice Indicates if an address is a registered pausable dependent contract.
     * @param contractAddress The address to check.
     */
    function isPausableContract(address contractAddress) external view returns (bool);

    /**
     * @notice Get the list of all registered pausable dependent contracts.
     * @return The list of registered contract addresses.
     */
    function getPausableContracts() external view returns (address[] memory);

    /**
     * @notice Returns the versions of the SpaceBridgeConfig contract in SemVer format.
     */
    function getVersion() external pure returns (string memory);
}