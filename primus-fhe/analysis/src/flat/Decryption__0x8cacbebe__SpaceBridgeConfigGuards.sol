// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SpaceBridgeConfig Guards
 */
abstract contract SpaceBridgeConfigGuards is Initializable {
    /**
     * @notice The address of the SpaceBridgeConfig contract.
     */
    ISpaceBridgeConfig internal spaceBridgeConfig;

    /**
     * @dev Reserved storage gap to allow adding new state variables in future upgrades.
     */
    uint256[10] private __gap;

    /**
     * @notice Initializes the contract
     * @param _spacebirdgeConfigContractAddress The address of the SpaceBridge contract.
     */
    function __SpaceBridgeConfigGuards_init(address _spacebirdgeConfigContractAddress) internal onlyInitializing {
        require(_spacebirdgeConfigContractAddress != address(0), "Invalid SpaceBridgeConfig address");
        spaceBridgeConfig = ISpaceBridgeConfig(_spacebirdgeConfigContractAddress);
    }

    /**
     * @notice Error emitted when an address is not a KMS transaction sender.
     * @param txSenderAddress The address that is not a KMS transaction sender.
     */
    error NotKmsTxSender(address txSenderAddress);

    /**
     * @notice Error emitted when an address is not a KMS signer.
     * @param signerAddress The address that is not a KMS signer.
     */
    error NotKmsSigner(address signerAddress);

    /**
     * @notice Error emitted when an address is not a alphatrion transaction sender.
     * @param txSenderAddress The address that is not a alphatrion transaction sender.
     */
    error NotAlphatrionTxSender(address txSenderAddress);

    /**
     * @notice Error emitted when an address is not a alphatrion signer.
     * @param signerAddress The address that is not a alphatrion signer.
     */
    error NotAlphatrionSigner(address signerAddress);

    /**
     * @notice Error emitted when the alphatrion signer does not correspond to the alphatrion transaction sender.
     * @param signerAddress The address of the alphatrion signer.
     * @param txSenderAddress The address of the alphatrion transaction sender.
     */
    error AlphatrionSignerMismatchTxSender(address signerAddress, address txSenderAddress);

    /**
     * @notice Checks if the sender is a KMS transaction sender.
     */
    modifier onlyKmsTxSender() {
        if (!spaceBridgeConfig.isKmsTxSender(msg.sender)) {
            revert NotKmsTxSender(msg.sender);
        }
        _;
    }

    /**
     * @notice Checks if the sender is a alphatrion transaction sender.
     */
    modifier onlyAlphatrionTxSender() {
        if (!spaceBridgeConfig.isAlphatrionTxSender(msg.sender)) {
            revert NotAlphatrionTxSender(msg.sender);
        }
        _;
    }

    /**
     * @notice Checks if the address is a alphatrion signer.
     * @param signerAddress The address to check.
     */
    function _checkIsAlphatrionSigner(address signerAddress) internal view {
        if (!spaceBridgeConfig.isAlphatrionSigner(signerAddress)) {
            revert NotAlphatrionSigner(signerAddress);
        }
    }

    /**
     * @notice Checks if the signer is a alphatrion signer, and that it corresponds to the transaction sender of the same alphatrion.
     * @param signerAddress The signer address to check.
     * @param txSenderAddress The address of the alphatrion transaction sender.
     */
    function _checkAlphatrionSignerMatchesTxSender(address signerAddress, address txSenderAddress) internal view {
        _checkIsAlphatrionSigner(signerAddress);

        if (spaceBridgeConfig.getAlphatrion(txSenderAddress).signerAddress != signerAddress) {
            revert AlphatrionSignerMismatchTxSender(signerAddress, txSenderAddress);
        }
    }
}