// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { IPayment } from "./interfaces/IPayment.sol";

abstract contract PaymentFee {
    /**
     * @dev Storage location has been computed using the following command:
     * keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.PaymentFee")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 private constant PAYMENT_FEE_STORAGE_LOCATION = 0xc503cb40cbbcf649e22803490cc1a5a8dbf8c75e298e458c7abeb4cb4d3b2900; 

    struct PaymentFeeStorage {
        address payment; 
    }

    /**
     * @notice Returns the storage pointer for PaymentFee.
     */
    function _getPaymentFeeStorage() internal pure returns (PaymentFeeStorage storage $) { 
        assembly { 
            $.slot := PAYMENT_FEE_STORAGE_LOCATION 
        } 
    } 
    
    /**
     * @notice Sets the Payment contract address used for fee charging.
     */
    function _setPaymentAddress(address payment) internal {
        if (payment == address(0)) revert IPayment.ZeroAddressNotAllowed();
        _getPaymentFeeStorage().payment = payment;
    }

    /**
     * @notice Returns the Payment contract interface for fee-related operations.
     */
    function _payment() internal view returns (IPayment) { 
        return IPayment(_getPaymentFeeStorage().payment); 
    }

    /**
     * @notice Checks if the Payment contract is configured.
     * @return True if the payment address is set, false otherwise.
     */
    function _isPaymentConfigured() internal view returns (bool) {
        return _getPaymentFeeStorage().payment != address(0);
    }
    
    /**
     * @notice charge the host chain token fees from the transaction sender for a public decryption.
     * @param txSender The address of the transaction sender.
     */
    function _chargePublicDecryptionFee(address txSender) internal { 
        _payment().chargePublicDecryptionFee(txSender); 
    } 
    
    /**
     * @notice charge the host chain token fees from the transaction sender for a user decryption.
     * @param txSender The address of the transaction sender.
     */
    function _chargeUserDecryptionFee(address txSender) internal { 
        _payment().chargeUserDecryptionFee(txSender); 
    } 
    
    /**
     * @notice charge the host chain token fees from the transaction sender for a callback execute.
     * @param txSender The address of the transaction sender.
     */
    function _chargeDecryptionAndCallbackFee(address txSender) internal {
        _payment().chargeDecryptionAndCallbackFee(txSender); 
    }

    /**
     * @notice charge the host chain token fees from the transaction sender for an ciphertext verification request.
     * @param txSender The address of the transaction sender.
     */
    function _chargeCiphertextVerificationFee(address txSender) internal {
        _payment().chargeCiphertextVerificationFee(txSender);
    }
}
