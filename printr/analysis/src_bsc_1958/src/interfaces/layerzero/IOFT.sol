// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ILayerZeroEndpointV2 } from "./ILayerZeroEndpointV2.sol";

/**
 * @dev Struct representing token parameters for the OFT send() operation.
 */
struct SendParam {
    uint32 dstEid; // Destination endpoint ID
    bytes32 to; // Recipient address
    uint256 amountLD; // Amount to send in local decimals
    uint256 minAmountLD; // Minimum amount to send in local decimals
    bytes extraOptions; // Additional options for LayerZero message
    bytes composeMsg; // Composed message for send() operation
    bytes oftCmd; // OFT command (unused in default implementations)
}

/**
 * @dev Struct representing OFT limit information.
 */
struct OFTLimit {
    uint256 minAmountLD; // Minimum amount in local decimals
    uint256 maxAmountLD; // Maximum amount in local decimals
}

/**
 * @dev Struct representing OFT receipt information.
 */
struct OFTReceipt {
    uint256 amountSentLD; // Amount debited from sender
    uint256 amountReceivedLD; // Amount to be received on remote side
}

/**
 * @dev Struct representing OFT fee details.
 */
struct OFTFeeDetail {
    int256 feeAmountLD; // Amount of fee in local decimals
    string description; // Description of the fee
}

/**
 * @title IOFT
 * @dev Interface for the Omnichain Fungible Token (OFT) standard.
 * @dev Interface ID: 0x02e49c2c
 */
interface IOFT {

    // Custom errors
    error InvalidLocalDecimals();
    error SlippageExceeded(uint256 amountLD, uint256 minAmountLD);

    // Events
    event OFTSent(
        bytes32 indexed guid, uint32 dstEid, address indexed fromAddress, uint256 amountSentLD, uint256 amountReceivedLD
    );

    event OFTReceived(bytes32 indexed guid, uint32 srcEid, address indexed toAddress, uint256 amountReceivedLD);

    /**
     * @notice Retrieves interfaceID and version of the OFT.
     * @return interfaceId The interface ID (0x02e49c2c).
     * @return version The version.
     */
    function oftVersion() external view returns (bytes4 interfaceId, uint64 version);

    /**
     * @notice Retrieves the address of the token associated with the OFT.
     * @return token The address of the ERC20 token implementation.
     */
    function token() external view returns (address);

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Whether approval is required.
     */
    function approvalRequired() external view returns (bool);

    /**
     * @notice Retrieves the shared decimals of the OFT.
     * @return sharedDecimals The shared decimals (typically 6).
     */
    function sharedDecimals() external view returns (uint8);

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return limit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return receipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    ) external returns (OFTLimit memory limit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory receipt);

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return fee The calculated LayerZero messaging fee.
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external returns (ILayerZeroEndpointV2.MessagingFee memory fee);

    /**
     * @notice Executes the send() operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The fee information supplied by the caller.
     * @param _refundAddress The address to receive any excess funds.
     * @return receipt The LayerZero messaging receipt.
     * @return oftReceipt The OFT receipt information.
     */
    function send(
        SendParam calldata _sendParam,
        ILayerZeroEndpointV2.MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (ILayerZeroEndpointV2.MessagingReceipt memory receipt, OFTReceipt memory oftReceipt);

}
