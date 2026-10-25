// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Alphatrion, KmsNode } from "./SpaceBridgeTypes.sol";
import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";

/**
 * @title Minimal interface of a pausable dependent contract.
 * @notice Matches the surface exposed by the SpaceBridge {Pausable} module
 * (`pause`, `unpause`) plus OpenZeppelin's `paused()` view.
 */
interface IPausableTarget {
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}

/**
 * @title SpaceBridgeConfig contract
 * @notice See {ISpaceBridgeConfig}.
 */
contract SpaceBridgeConfig is ISpaceBridgeConfig, Initializable, Ownable2StepUpgradeable, UUPSUpgradeable {
    /**
     * @dev The following constants are used for versioning the contract. 
     * They are made private in order to force derived contracts to consider a different version. 
     */
    string private constant CONTRACT_NAME = "SpaceBridgeConfig";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 3;
    uint256 private constant PATCH_VERSION = 0;

    /**
     * @notice The contract's variable storage struct
     */
    struct SpaceBridgeConfigStorage {
        // ----------------------------------------------------------------------------------------------
        // Alphatrions state variables:
        // ----------------------------------------------------------------------------------------------
        /// @notice The alphatrions' transaction sender addresses
        mapping(address alphatrionTxSenderAddress => bool isTxSender) isAlphatrionTxSender;
        /// @notice The alphatrions' signer addresses
        mapping(address alphatrionSignerAddress => bool isSigner) isAlphatrionSigner;
        /// @notice The alphatrions' metadata
        mapping(address alphatrionTxSenderAddress => Alphatrion alphatrion) alphatrions;
        /// @notice The alphatrions' transaction sender address list
        address[] alphatrionTxSenderAddresses;
        /// @notice The alphatrions' signer address list
        address[] alphatrionSignerAddresses;
        
        // ----------------------------------------------------------------------------------------------
        // Alphatrion/KMS threshold state variables:
        // ----------------------------------------------------------------------------------------------
        /// @notice The threshold to consider for alphatrion consensus
        uint256 alphatrionThreshold;
        /// @notice The threshold to consider for public decryption consensus
        uint256 publicDecryptionThreshold;
        /// @notice The threshold to consider for user decryption consensus
        uint256 userDecryptionThreshold;

        // ----------------------------------------------------------------------------------------------
        // KMS nodes state variables:
        // ----------------------------------------------------------------------------------------------
        /// @notice The KMS nodes' transaction sender addresses
        mapping(address kmsTxSenderAddress => bool isTxSender) isKmsTxSender;
        /// @notice The KMS nodes' signer addresses
        mapping(address kmsSignerAddress => bool isSigner) isKmsSigner;
        /// @notice The KMS nodes' metadata
        mapping(address kmsTxSenderAddress => KmsNode kmsNode) kmsNodes;
        /// @notice The KMS nodes' transaction sender address list
        address[] kmsTxSenderAddresses;
        /// @notice The KMS nodes' signer address list
        address[] kmsSignerAddresses;

        // ----------------------------------------------------------------------------------------------
        // Pausable dependent contracts state variables:
        // ----------------------------------------------------------------------------------------------
        /// @notice Whether an address is a registered pausable dependent contract
        mapping(address contractAddress => bool isRegistered) isPausableContract;
        /// @notice The registered pausable dependent contract address list
        address[] pausableContracts;
    }

    /**
     * @dev Storage location has been computed using the following command:
     * keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.SpaceBridgeConfig")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 private constant SPACEBRIDGE_CONFIG_STORAGE_LOCATION =
        0xfbd235e39667dbfa956bb01e1324cd5ed16f5193ade07d93474122312f401a00;
  
    /// constructor
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @param initialAlphatrions List of alphatrions.
     * @param initialAlphatrionThreshold The Alphatrion threshold.
     * @param initialKmsNodes List of KMS nodes.
     * @param initialPublicDecryptionThreshold The public decryption threshold.
     * @param initialUserDecryptionThreshold The user decryption threshold.
     */
    function initialize(
        Alphatrion[] calldata initialAlphatrions,
        uint256 initialAlphatrionThreshold,
        KmsNode[] calldata initialKmsNodes,
        uint256 initialPublicDecryptionThreshold,
        uint256 initialUserDecryptionThreshold
    ) public initializer {
        __Ownable_init(msg.sender);

        // Set the alphatrions and their threshold
        _setAlphatrions(initialAlphatrions, initialAlphatrionThreshold);

        // Set the kms nodes and their threshold
        _setKmsNodes(initialKmsNodes, initialPublicDecryptionThreshold, initialUserDecryptionThreshold);

        // emit InitializeSpaceBridgeConfig
        emit InitializeSpaceBridgeConfig(
            initialAlphatrions,
            initialAlphatrionThreshold,
            initialKmsNodes,
            initialPublicDecryptionThreshold,
            initialUserDecryptionThreshold
        );
    }

    /**
     * @notice Checks if the sender is authorized to upgrade the contract and reverts otherwise.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}

    // ----------------------------------------------------------------------------------------------
    // Alphatrion functions 
    // ----------------------------------------------------------------------------------------------

     /**
     * @notice See {ISpaceBridgeConfig-updateAlphatrions}.
     */
    function updateAlphatrions(
        Alphatrion[] calldata newAlphatrions,
        uint256 newAlphatrionThreshold
    ) external virtual onlyOwner {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();

        // Remove the old alphatrions
        uint256 oldAlphatrionTxSenderAddressesLength = $.alphatrionTxSenderAddresses.length;
        for (uint256 i = 0; i < oldAlphatrionTxSenderAddressesLength; i++) {
            $.isAlphatrionTxSender[$.alphatrionTxSenderAddresses[i]] = false;
            $.isAlphatrionSigner[$.alphatrionSignerAddresses[i]] = false;
            delete $.alphatrions[$.alphatrionTxSenderAddresses[i]];
        }
        delete $.alphatrionTxSenderAddresses;
        delete $.alphatrionSignerAddresses;

        // Set the new alphatrions and their threshold
        _setAlphatrions(newAlphatrions, newAlphatrionThreshold);

        // emit UpdateAlphatrions
        emit UpdateAlphatrions(newAlphatrions, newAlphatrionThreshold);
    }

    /**
     * @notice See {ISpaceBridgeConfig-updateAlphatrionThreshold}.
     */
    function updateAlphatrionThreshold(uint256 newAlphatrionThreshold) external virtual onlyOwner {
        _setAlphatrionThreshold(newAlphatrionThreshold);
        emit UpdateAlphatrionThreshold(newAlphatrionThreshold);
    }

    /**
     * @notice See {ISpaceBridgeConfig-isAlphatrionTxSender}.
     */
    function isAlphatrionTxSender(address txSenderAddress) external view virtual returns (bool) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.isAlphatrionTxSender[txSenderAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-isAlphatrionSigner}.
     */
    function isAlphatrionSigner(address signerAddress) external view virtual returns (bool) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.isAlphatrionSigner[signerAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-getAlphatrion}.
     */
    function getAlphatrion(address alphatrionTxSenderAddress) external view virtual returns (Alphatrion memory) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.alphatrions[alphatrionTxSenderAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-getAlphatrionTxSenders}.
     */
    function getAlphatrionTxSenders() external view virtual returns (address[] memory) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.alphatrionTxSenderAddresses;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getAlphatrionSigners}.
     */
    function getAlphatrionSigners() external view virtual returns (address[] memory) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.alphatrionSignerAddresses;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getAlphatrionThreshold}.
     */
    function getAlphatrionThreshold() external view virtual returns (uint256) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.alphatrionThreshold;
    }

    // ----------------------------------------------------------------------------------------------
    // KMS node functions
    // ----------------------------------------------------------------------------------------------
    
    /**
     * @notice See {ISpaceBridgeConfig-updateKmsNodes}.
     */
    function updateKmsNodes(
        KmsNode[] calldata newKmsNodes,
        uint256 newPublicDecryptionThreshold,
        uint256 newUserDecryptionThreshold
    ) external virtual onlyOwner {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();

        uint256 oldLen = $.kmsTxSenderAddresses.length;
        for (uint256 i = 0; i < oldLen; i++) {
            $.isKmsTxSender[$.kmsTxSenderAddresses[i]] = false;
            $.isKmsSigner[$.kmsSignerAddresses[i]] = false;
            delete $.kmsNodes[$.kmsTxSenderAddresses[i]];
        }
        delete $.kmsTxSenderAddresses;
        delete $.kmsSignerAddresses;

        // Set the new KMS nodes and their thresholds
        _setKmsNodes(newKmsNodes, newPublicDecryptionThreshold, newUserDecryptionThreshold);

        emit UpdateKmsNodes(newKmsNodes, newPublicDecryptionThreshold, newUserDecryptionThreshold);
    }

    /**
     * @notice See {ISpaceBridgeConfig-updatePublicDecryptionThreshold}.
     */
    function updatePublicDecryptionThreshold(uint256 newPublicDecryptionThreshold) external virtual onlyOwner {
        _setPublicDecryptionThreshold(newPublicDecryptionThreshold);
        emit UpdatePublicDecryptionThreshold(newPublicDecryptionThreshold);
    }

    /**
     * @notice See {ISpaceBridgeConfig-updateUserDecryptionThreshold}.
     */
    function updateUserDecryptionThreshold(uint256 newUserDecryptionThreshold) external virtual onlyOwner {
        _setUserDecryptionThreshold(newUserDecryptionThreshold);
        emit UpdateUserDecryptionThreshold(newUserDecryptionThreshold);
    }

    /**
     * @notice See {ISpaceBridgeConfig-isKmsTxSender}.
     */
    function isKmsTxSender(address txSenderAddress) external view virtual returns (bool) {
        return _getSpaceBridgeConfigStorage().isKmsTxSender[txSenderAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-isKmsSigner}.
     */
    function isKmsSigner(address signerAddress) external view virtual returns (bool) {
        return _getSpaceBridgeConfigStorage().isKmsSigner[signerAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-getKmsNode}.
     */
    function getKmsNode(address kmsTxSenderAddress) external view virtual returns (KmsNode memory) {
        return _getSpaceBridgeConfigStorage().kmsNodes[kmsTxSenderAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-getKmsTxSenders}.
     */
    function getKmsTxSenders() external view virtual returns (address[] memory) {
        return _getSpaceBridgeConfigStorage().kmsTxSenderAddresses;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getKmsSigners}.
     */
    function getKmsSigners() external view virtual returns (address[] memory) {
        return _getSpaceBridgeConfigStorage().kmsSignerAddresses;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getPublicDecryptionThreshold}.
     */
    function getPublicDecryptionThreshold() external view virtual returns (uint256) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.publicDecryptionThreshold;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getUserDecryptionThreshold}.
     */
    function getUserDecryptionThreshold() external view virtual returns (uint256) {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        return $.userDecryptionThreshold;
    }

    // ----------------------------------------------------------------------------------------------
    // Pausable dependent contracts functions
    // ----------------------------------------------------------------------------------------------

    /**
     * @notice See {ISpaceBridgeConfig-addPausableContracts}.
     */
    function addPausableContracts(address[] calldata contractAddresses) external virtual onlyOwner {
        if (contractAddresses.length == 0) {
            revert EmptyPausableContracts();
        }

        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            if (contractAddress == address(0)) {
                revert InvalidPausableContractAddress();
            }
            if ($.isPausableContract[contractAddress]) {
                revert PausableContractAlreadyRegistered(contractAddress);
            }
            $.isPausableContract[contractAddress] = true;
            $.pausableContracts.push(contractAddress);

            emit PausableContractAdded(contractAddress);
        }
    }

    /**
     * @notice See {ISpaceBridgeConfig-removePausableContract}.
     */
    function removePausableContract(address contractAddress) external virtual onlyOwner {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        if (!$.isPausableContract[contractAddress]) {
            revert PausableContractNotRegistered(contractAddress);
        }
        $.isPausableContract[contractAddress] = false;

        // Swap-and-pop removal from the registry list
        uint256 length = $.pausableContracts.length;
        for (uint256 i = 0; i < length; i++) {
            if ($.pausableContracts[i] == contractAddress) {
                $.pausableContracts[i] = $.pausableContracts[length - 1];
                $.pausableContracts.pop();
                break;
            }
        }

        emit PausableContractRemoved(contractAddress);
    }

    /**
     * @notice See {ISpaceBridgeConfig-pauseAll}.
     */
    function pauseAll() external virtual onlyOwner {
        _setPausedAll(true);
    }

    /**
     * @notice See {ISpaceBridgeConfig-unpauseAll}.
     */
    function unpauseAll() external virtual onlyOwner {
        _setPausedAll(false);
    }

    /**
     * @notice See {ISpaceBridgeConfig-isPausableContract}.
     */
    function isPausableContract(address contractAddress) external view virtual returns (bool) {
        return _getSpaceBridgeConfigStorage().isPausableContract[contractAddress];
    }

    /**
     * @notice See {ISpaceBridgeConfig-getPausableContracts}.
     */
    function getPausableContracts() external view virtual returns (address[] memory) {
        return _getSpaceBridgeConfigStorage().pausableContracts;
    }

    /**
     * @notice Pauses or unpauses every registered dependent contract.
     * @dev Contracts already in the target state are skipped; any other failure reverts the
     * whole transaction, so the operation is atomic across all affected contracts. Since this
     * contract is the caller, each dependent contract's {Pausable} module authorizes the call
     * through its `callerAddress == spacebridgeConfigAddress` branch.
     * @param paused Whether to pause (true) or unpause (false) the dependent contracts.
     */
    function _setPausedAll(bool paused) internal virtual {
        address[] memory targets = _getSpaceBridgeConfigStorage().pausableContracts;
        address[] memory affected = new address[](targets.length);
        uint256 affectedCount = 0;

        for (uint256 i = 0; i < targets.length; i++) {
            IPausableTarget target = IPausableTarget(targets[i]);
            if (target.paused() == paused) {
                continue;
            }
            if (paused) {
                target.pause();
            } else {
                target.unpause();
            }
            affected[affectedCount] = targets[i];
            affectedCount++;
        }

        // Shrink the affected list to its actual size before emitting
        assembly {
            mstore(affected, affectedCount)
        }

        if (paused) {
            emit ContractsPaused(affected);
        } else {
            emit ContractsUnpaused(affected);
        }
    }

    // ----------------------------------------------------------------------------------------------
    // Internal setters
    // ----------------------------------------------------------------------------------------------

    /**
     * @notice Sets the alphatrions and their threshold.
     * @param newAlphatrions The new alphatrions.
     * @param newAlphatrionThreshold The new alphatrion threshold.
     */
    function _setAlphatrions(
        Alphatrion[] calldata newAlphatrions,
        uint256 newAlphatrionThreshold
    ) internal virtual {
        if (newAlphatrions.length == 0) {
            revert EmptyAlphatrions();
        }

        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();

        // Register the new alphatrions
        for (uint256 i = 0; i < newAlphatrions.length; i++) {
            address newAlphatrionTxSenderAddress = newAlphatrions[i].txSenderAddress;
            address newAlphatrionSignerAddress = newAlphatrions[i].signerAddress;

            // Check for zero addresses
            if (newAlphatrionTxSenderAddress == address(0)) {
                revert InvalidAlphatrionTxSenderAddress();
            }
            if (newAlphatrionSignerAddress == address(0)) {
                revert InvalidAlphatrionSignerAddress();
            }

            // Check for alphatrion transaction sender and signer duplicates
            if ($.isAlphatrionTxSender[newAlphatrionTxSenderAddress]) {
                revert AlphatrionTxSenderAlreadyRegistered(newAlphatrionTxSenderAddress);
            }
            if ($.isAlphatrionSigner[newAlphatrionSignerAddress]) {
                revert AlphatrionSignerAlreadyRegistered(newAlphatrionSignerAddress);
            }

            // Register alphatrion transaction sender
            $.isAlphatrionTxSender[newAlphatrionTxSenderAddress] = true;
            $.alphatrionTxSenderAddresses.push(newAlphatrionTxSenderAddress);

            // Register alphatrion signer
            $.isAlphatrionSigner[newAlphatrionSignerAddress] = true;
            $.alphatrionSignerAddresses.push(newAlphatrionSignerAddress);

            // Register alphatrion
            $.alphatrions[newAlphatrionTxSenderAddress] = newAlphatrions[i];
        }

        // Setting the alphatrion threshold should be done after the alphatrions have been
        // registered as the functions reading the `alphatrionSignerAddresses` array.
        _setAlphatrionThreshold(newAlphatrionThreshold);
    }

    /**
     * @notice Returns the minimum consensus threshold enforcing a majority quorum.
     * @dev A threshold of `floor(n / 2) + 1` guarantees that any two quorums intersect. Since an
     * alphatrion or KMS node can only submit once per handle/job (double-voting is rejected on
     * chain), two conflicting values can never both reach such a quorum. Allowing lower values
     * (e.g. `t = 1`) would let a single compromised node finalize arbitrary consensus records.
     * @param n The number of registered nodes.
     * @return The minimum threshold required.
     */
    function _minimumQuorum(uint256 n) internal pure virtual returns (uint256) {
        return n / 2 + 1;
    }

    /**
     * @notice Sets the alphatrion threshold.
     * @param newAlphatrionThreshold The new alphatrion threshold.
     */
    function _setAlphatrionThreshold(uint256 newAlphatrionThreshold) internal virtual {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        uint256 nAlphatrions = $.alphatrionSignerAddresses.length;

        // Check that the alphatrion threshold `t` is valid. It must verify:
        // - `t >= floor(n / 2) + 1` : the alphatrion consensus should require a majority quorum
        // - `t <= n` : it should be less than or equal to the number of registered alphatrions
        if (newAlphatrionThreshold == 0) {
            revert InvalidAlphatrionThreshold();
        }
        if (newAlphatrionThreshold > nAlphatrions) {
            revert InvalidHighAlphatrionThreshold(newAlphatrionThreshold, nAlphatrions);
        }
        uint256 minThreshold = _minimumQuorum(nAlphatrions);
        if (newAlphatrionThreshold < minThreshold) {
            revert InvalidLowAlphatrionThreshold(newAlphatrionThreshold, minThreshold);
        }

        // set new Alphatrion threshold
        $.alphatrionThreshold = newAlphatrionThreshold;
    }

    /**
     * @notice Registers KMS nodes and sets the decryption consensus thresholds.
     * @dev No mpc/keygen threshold here — see contract-level dev note.
     */
    function _setKmsNodes(
        KmsNode[] calldata newKmsNodes,
        uint256 newPublicDecryptionThreshold,
        uint256 newUserDecryptionThreshold
    ) internal virtual {
        if (newKmsNodes.length == 0) revert EmptyKmsNodes();

        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();

        for (uint256 i = 0; i < newKmsNodes.length; i++) {
            address txSender = newKmsNodes[i].txSenderAddress;
            address signer = newKmsNodes[i].signerAddress;

            if (txSender == address(0)) revert InvalidKmsTxSenderAddress();
            if (signer == address(0)) revert InvalidKmsSignerAddress();
            if ($.isKmsTxSender[txSender]) revert KmsTxSenderAlreadyRegistered(txSender);
            if ($.isKmsSigner[signer]) revert KmsSignerAlreadyRegistered(signer);

            $.isKmsTxSender[txSender] = true;
            $.kmsTxSenderAddresses.push(txSender);
            $.isKmsSigner[signer] = true;
            $.kmsSignerAddresses.push(signer);
            $.kmsNodes[txSender] = newKmsNodes[i];
        }

        // Thresholds are validated against node count, so set them after registration.
        _setPublicDecryptionThreshold(newPublicDecryptionThreshold);
        _setUserDecryptionThreshold(newUserDecryptionThreshold);
    }

    /**
     * @notice Sets the public decryption threshold.
     * @dev The new threshold must verify `floor(n / 2) + 1 <= t <= n`, with `n` the number of KMS
     * nodes currently registered.
     * @param newPublicDecryptionThreshold The new public decryption threshold.
     */
    function _setPublicDecryptionThreshold(uint256 newPublicDecryptionThreshold) internal virtual {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        uint256 n = $.kmsSignerAddresses.length;

        if (newPublicDecryptionThreshold == 0) revert InvalidNullPublicDecryptionThreshold();
        if (newPublicDecryptionThreshold > n) {
            revert InvalidHighPublicDecryptionThreshold(newPublicDecryptionThreshold, n);
        }
        uint256 minThreshold = _minimumQuorum(n);
        if (newPublicDecryptionThreshold < minThreshold) {
            revert InvalidLowPublicDecryptionThreshold(newPublicDecryptionThreshold, minThreshold);
        }

        $.publicDecryptionThreshold = newPublicDecryptionThreshold;
    }

    /**
     * @notice Sets the user decryption threshold.
     * @dev The new threshold must verify `floor(n / 2) + 1 <= t <= n`, with `n` the number of KMS
     * nodes currently registered.
     * @param newUserDecryptionThreshold The new user decryption threshold.
     */
    function _setUserDecryptionThreshold(uint256 newUserDecryptionThreshold) internal virtual {
        SpaceBridgeConfigStorage storage $ = _getSpaceBridgeConfigStorage();
        uint256 n = $.kmsSignerAddresses.length;

        if (newUserDecryptionThreshold == 0) revert InvalidNullUserDecryptionThreshold();
        if (newUserDecryptionThreshold > n) {
            revert InvalidHighUserDecryptionThreshold(newUserDecryptionThreshold, n);
        }
        uint256 minThreshold = _minimumQuorum(n);
        if (newUserDecryptionThreshold < minThreshold) {
            revert InvalidLowUserDecryptionThreshold(newUserDecryptionThreshold, minThreshold);
        }

        $.userDecryptionThreshold = newUserDecryptionThreshold;
    }

    /**
     * @notice See {ISpaceBridgeConfig-getVersion}.
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
     * @notice Returns the SpaceBridgeConfig storage location.
     * @dev Note that this function is internal but not virtual: derived contracts should be able to access it.
     */
    function _getSpaceBridgeConfigStorage() internal pure returns (SpaceBridgeConfigStorage storage $) {
        assembly {
            $.slot := SPACEBRIDGE_CONFIG_STORAGE_LOCATION
        }
    }
}
