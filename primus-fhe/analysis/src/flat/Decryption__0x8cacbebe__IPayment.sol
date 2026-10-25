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
 * @title Interface for the Payment contract.
 * @notice The Payment contract manages payment and fees.
 */
interface IPayment {
    /**
     * @notice Emitted when the payment is initialized.
     * @param publicDecryptionPrice Public decryption price, quoted in host chain token base units.
     * @param userDecryptionPrice The user decryption price, quoted in host chain token base units.
     * @param callbackExecutePrice The callback execute price, quoted in host chain token base units.
     * @param ciphertextVerificationPrice The ciphertext verification price, quoted in host chain token base units.
     */
    event InitializePayment(
        uint256 publicDecryptionPrice,
        uint256 userDecryptionPrice,
        uint256 callbackExecutePrice,
        uint256 ciphertextVerificationPrice
    );

    /**
     * @notice Emitted when the public decryption price is set.
     * @param price The new public decryption price in host chain token base units.
     */
    event NewPublicDecryptionPrice(uint256 price);

    /**
     * @notice Emitted when the user decryption price is set.
     * @param price The new user decryption price in host chain token base units.
     */
    event NewUserDecryptionPrice(uint256 price);

    /**
     * @notice Emitted when the callback execute price is set.
     * @param price The new callback execute price in host chain token base units.
     */
    event NewCallbackExecutePrice(uint256 price);

    /**
     * @notice Emitted when the ciphertext verification price is set.
     * @param price The new ciphertext verification price in host chain token base units.
     */
    event NewCiphertextVerificationPrice(uint256 price);

    /**
     * @notice Emitted when the sender is not the Decryption contract.
     * @param sender The address of the sender.
     */
    error SenderNotDecryptionContract(address sender);

    /**
     * @notice Emitted when the sender is not the Ciphertext Verification contract.
     * @param sender The address of the sender.
     */
    error SenderNotCiphertextVerificationContract(address sender);

    /**
    * @notice Thrown when attempting to set a fee price to zero or an invalid value.
    * @dev Activated in `initialize()` and price setter functions to prevent 
    *      zero-cost attacks or economic misconfiguration. 
    */
    error InvalidPrice();

    /**
    * @notice Thrown when attempting to configure a critical address parameter with the zero address.
    * @dev This error is triggered in initialization and setter functions to prevent 
    *      irreversible misconfiguration. Zero address checks protect against.
    */
    error ZeroAddressNotAllowed();

    /**
     * @notice Get the price in host chain token for a public decryption.
     * @return The price of the public decryption in host chain token base units.
     */
    function getPublicDecryptionPrice() external view returns (uint256);

    /**
     * @notice Get the price in host chain token for a user decryption.
     * @return The price of the user decryption in host chain token base units.
     */
    function getUserDecryptionPrice() external view returns (uint256);

    /**
     * @notice Get the price in host chain token for a callback execute.
     * @return The price of the callback execute in host chain token base units.
     */
    function getCallbackExecutePrice() external view returns (uint256);

    /**
     * @notice Get the price in host chain token for a ciphertext verification.
     * @return The price of the ciphertext verification in host chain token base units.
     */
    function getCiphertextVerificationPrice() external view returns (uint256);

    /**
     * @notice Set the price in host chain token for a public decryption.
     * @param price The price of the public decryption in host chain token base units.
     */
    function setPublicDecryptionPrice(uint256 price) external;

    /**
     * @notice Set the price in host chain token for a user decryption.
     * @param price The price of the user decryption in host chain token base units.
     */
    function setUserDecryptionPrice(uint256 price) external;

    /**
     * @notice Set the price in host chain token for a callback execute.
     * @param price The price of the callback execute in host chain token base units.
     */
    function setCallbackExecutePrice(uint256 price) external;

    /**
     * @notice Set the price in host chain token for a ciphertext verification.
     * @param price The price of the ciphertext verification in host chain token base units.
     */
    function setCiphertextVerificationPrice(uint256 price) external;

    /**
     * @notice charge the host chain token fees from the transaction sender for a public decryption.
     * @param txSender The address of the transaction sender.
     */
    function chargePublicDecryptionFee(address txSender) external;

    /**
     * @notice charge the host chain token fees from the transaction sender for a user decryption.
     * @param txSender The address of the transaction sender.
     */
    function chargeUserDecryptionFee(address txSender) external;

    /**
     * @notice charge the host chain token fees from the transaction sender for a callback execute.
     * @param txSender The address of the transaction sender.
     */
    function chargeDecryptionAndCallbackFee(address txSender) external;

    /**
     * @notice charge the host chain token fees from the transaction sender for an ciphertext verification request.
     * @param txSender The address of the transaction sender.
     */
    function chargeCiphertextVerificationFee(address txSender) external;

    /**
     * @notice Returns the versions of the Payment contract in SemVer format.
     */
    function getVersion() external pure returns (string memory);
}