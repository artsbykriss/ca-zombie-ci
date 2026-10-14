// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ILayerZeroEndpointV2 } from "../interfaces/layerzero/ILayerZeroEndpointV2.sol";
import { IOFT, OFTFeeDetail, OFTLimit, OFTReceipt, SendParam } from "../interfaces/layerzero/IOFT.sol";
import { IPrintrTeleport } from "../interfaces/printr/IPrintrTeleport.sol";

/**
 * @title OftStandard
 * @notice Abstract contract implementing LayerZero OFT standard for Telecoins
 * @dev Delegates to existing teleport infrastructure under the hood
 * @dev Expects inheriting contracts to provide _lzTeleport and quoteTeleportFee implementations from Telecoin
 */
abstract contract OftStandard is IOFT {

    /**
     * @notice Retrieves interfaceID and version of the OFT
     * @return interfaceId The interface ID (0x02e49c2c)
     * @return version The version (1)
     */
    function oftVersion() external pure returns (bytes4 interfaceId, uint64 version) {
        return (0x02e49c2c, 1);
    }

    /**
     * @notice Retrieves the address of the token associated with the OFT
     * @return token The address of the ERC20 token implementation (this contract)
     */
    function token() external view returns (address) {
        return address(this);
    }

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send
     * @return requiresApproval False, as the token itself implements the OFT interface
     */
    function approvalRequired() external pure returns (bool) {
        return false;
    }

    /**
     * @notice Retrieves the shared decimals of the OFT
     * @return sharedDecimals The shared decimals (9)
     */
    function sharedDecimals() external pure returns (uint8) {
        return 9;
    }

    /**
     * @notice Provides a quote for OFT-related operations
     * @param _sendParam The parameters for the send operation
     * @return limit The OFT limit information
     * @return oftFeeDetails The details of OFT fees
     * @return receipt The OFT receipt information
     */
    function quoteOFT(
        SendParam calldata _sendParam
    ) external returns (OFTLimit memory limit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory receipt) {
        // Convert SendParam to TeleportParams
        IPrintrTeleport.TeleportParams memory params = _sendParamToTeleportParams(_sendParam);

        // Get fee from PrintrTeleport
        (uint256 totalNativeFee,,, uint256 bridgeFee) = _quoteTeleportFee(params);

        // Calculate protocol fee
        uint256 protocolFee = totalNativeFee - bridgeFee;

        // Return limits (no hard limits on telecoin transfers)
        limit = OFTLimit({ minAmountLD: 0, maxAmountLD: type(uint256).max });

        // Return fee details array with protocol fee and bridge fee
        oftFeeDetails = new OFTFeeDetail[](2);
        oftFeeDetails[0] = OFTFeeDetail({ feeAmountLD: int256(protocolFee), description: "Protocol Fee" });
        oftFeeDetails[1] = OFTFeeDetail({ feeAmountLD: int256(bridgeFee), description: "Bridge Fee" });

        // Return receipt (1:1 transfer, no conversion)
        receipt = OFTReceipt({ amountSentLD: _sendParam.amountLD, amountReceivedLD: _sendParam.amountLD });
    }

    /**
     * @notice Provides a quote for the send() operation
     * @param _sendParam The parameters for the send() operation
     * @return fee The calculated LayerZero messaging fee
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool /* _payInLzToken */
    ) external returns (ILayerZeroEndpointV2.MessagingFee memory fee) {
        // Convert SendParam to TeleportParams
        IPrintrTeleport.TeleportParams memory params = _sendParamToTeleportParams(_sendParam);

        // Get fee from PrintrTeleport
        (uint256 totalNativeFee,,,) = _quoteTeleportFee(params);

        // Return MessagingFee (we don't support LZ token payments)
        fee = ILayerZeroEndpointV2.MessagingFee({ nativeFee: totalNativeFee, lzTokenFee: 0 });
    }

    /**
     * @notice Executes the send() operation
     * @param _sendParam The parameters for the send operation
     * @param _fee The fee information supplied by the caller
     * @return receipt The LayerZero messaging receipt
     * @return oftReceipt The OFT receipt information
     */
    function send(
        SendParam calldata _sendParam,
        ILayerZeroEndpointV2.MessagingFee calldata _fee,
        address /* _refundAddress */
    ) external payable returns (ILayerZeroEndpointV2.MessagingReceipt memory receipt, OFTReceipt memory oftReceipt) {
        // Check slippage
        if (_sendParam.amountLD < _sendParam.minAmountLD) {
            revert SlippageExceeded(_sendParam.amountLD, _sendParam.minAmountLD);
        }

        // Convert SendParam to TeleportParams
        IPrintrTeleport.TeleportParams memory params = _sendParamToTeleportParams(_sendParam);

        // Call the LayerZero teleport function
        bytes memory data = _lzTeleport(msg.sender, params);

        // Check if we received actual LayerZero receipt data
        if (data.length > 0) {
            // Decode the actual LayerZero MessagingReceipt
            receipt = abi.decode(data, (ILayerZeroEndpointV2.MessagingReceipt));
        } else {
            // Create synthetic receipt until LZ channels return receipt

            // Create a pseudo-GUID from sender and params
            bytes32 guid = keccak256(abi.encodePacked(msg.sender, _sendParam.dstEid, _sendParam.amountLD));
            // Return synthetic receipt
            receipt = ILayerZeroEndpointV2.MessagingReceipt({
                guid: guid, nonce: uint64(block.timestamp), fee: ILayerZeroEndpointV2.MessagingFee(_fee.nativeFee, 0)
            });
        }

        // Emit OFTSent event
        emit OFTSent(receipt.guid, _sendParam.dstEid, msg.sender, _sendParam.amountLD, _sendParam.amountLD);

        // Return OFT receipt
        oftReceipt = OFTReceipt({ amountSentLD: _sendParam.amountLD, amountReceivedLD: _sendParam.amountLD });
    }

    function _quoteTeleportFee(
        IPrintrTeleport.TeleportParams memory params
    ) internal virtual returns (uint256 totalNativeFee, uint256 basePairFee, address basePair, uint256 bridgeFee);

    /**
     * @notice Internal abstract function for teleporting tokens
     * @dev Must be implemented by Telecoin to call its teleport() function
     * @param params The teleport parameters
     */
    function _lzTeleport(
        address from,
        IPrintrTeleport.TeleportParams memory params
    ) internal virtual returns (bytes memory receipt);

    /**
     * @notice Converts SendParam to TeleportParams
     * @param _sendParam The OFT SendParam struct
     * @return params The equivalent TeleportParams struct
     */
    function _sendParamToTeleportParams(
        SendParam calldata _sendParam
    ) internal pure returns (IPrintrTeleport.TeleportParams memory params) {
        // Map endpoint ID to chain name
        string memory destChain = _eidToString(_sendParam.dstEid);

        // Determine protocol based on extraOptions (default to LZ_FAST)
        IPrintrTeleport.TeleportProtocol protocol = _parseProtocolFromOptions(_sendParam.extraOptions);

        // Convert recipient from bytes32 to bytes
        bytes memory destAddress = abi.encodePacked(_sendParam.to);

        // Combine composeMsg and oftCmd into metadata if present
        bytes memory metadata;
        if (_sendParam.composeMsg.length > 0 || _sendParam.oftCmd.length > 0) {
            metadata = abi.encode(_sendParam.composeMsg, _sendParam.oftCmd);
        }

        params = IPrintrTeleport.TeleportParams({
            destChain: destChain,
            destAddress: destAddress,
            amount: _sendParam.amountLD,
            metadata: metadata,
            protocol: protocol
        });
    }

    /**
     * @notice Converts LayerZero endpoint ID to string representation
     * @param eid Endpoint ID
     * @return eidString The endpoint ID as a string (e.g., "30101")
     */
    function _eidToString(
        uint32 eid
    ) internal pure returns (string memory eidString) {
        // Convert uint32 to string
        if (eid == 0) {
            return "0";
        }

        uint32 temp = eid;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (eid != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint32(eid % 10)));
            eid /= 10;
        }

        return string(buffer);
    }

    /**
     * @notice Parses LayerZero extraOptions to determine protocol
     * @param extraOptions The extra options bytes (can encode security level)
     * @return protocol The teleport protocol to use
     */
    function _parseProtocolFromOptions(
        bytes calldata extraOptions
    ) internal pure returns (IPrintrTeleport.TeleportProtocol protocol) {
        // Default to LZ_FAST if no options provided
        if (extraOptions.length == 0) {
            return IPrintrTeleport.TeleportProtocol.LZ_FAST;
        }

        // Parse first byte as security level indicator if present
        // 1 = LZ_FAST, 2 = LZ_SECURE, 3 = LZ_SLOW
        uint8 securityLevel = uint8(extraOptions[0]);
        if (securityLevel == 1) {
            return IPrintrTeleport.TeleportProtocol.LZ_FAST;
        } else if (securityLevel == 2) {
            return IPrintrTeleport.TeleportProtocol.LZ_SECURE;
        } else if (securityLevel == 3) {
            return IPrintrTeleport.TeleportProtocol.LZ_SLOW;
        }

        // Default to LZ_FAST for any other value
        return IPrintrTeleport.TeleportProtocol.LZ_FAST;
    }

}
