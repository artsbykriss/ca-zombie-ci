// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title ILayerZeroEndpointV2
 * @notice Interface for LayerZero V2 endpoint contract
 * @dev Defines the core messaging functions for cross-chain communication
 */
interface ILayerZeroEndpointV2 {

    /**
     * @notice Struct containing messaging fee information
     * @param nativeFee Native fee amount to send
     * @param lzTokenFee LayerZero token fee amount
     */
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }

    /**
     * @notice Struct containing messaging parameters
     * @param dstEid Destination endpoint ID
     * @param receiver Receiver address on destination chain (as bytes32)
     * @param message Message payload to send
     * @param options Execution options for the message
     * @param payInLzToken Whether to pay fees in LZ token
     */
    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
        bytes options;
        bool payInLzToken;
    }

    /**
     * @notice Struct containing messaging receipt information
     * @param guid Globally unique identifier for the message
     * @param nonce Message nonce
     * @param fee Messaging fee paid
     */
    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }

    /**
     * @notice Send a message to another chain
     * @param params Messaging parameters
     * @param refundAddress Address to refund excess fees
     * @return receipt Message receipt containing guid and fee info
     */
    function send(
        MessagingParams calldata params,
        address refundAddress
    ) external payable returns (MessagingReceipt memory receipt);

    /**
     * @notice Quote the fee for sending a message
     * @param params Messaging parameters
     * @param sender The sender address
     * @return fee The messaging fee quote
     */
    function quote(
        MessagingParams calldata params,
        address sender
    ) external view returns (MessagingFee memory fee);

    /**
     * @notice Struct for setting configuration parameters
     * @param eid Endpoint ID
     * @param configType Configuration type (1=Executor, 2=ULN)
     * @param config Encoded configuration data
     */
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    /**
     * @notice Set configuration for an OApp
     * @param oapp The OApp address to configure
     * @param lib The library address (SendLib or ReceiveLib)
     * @param params Array of configuration parameters
     */
    function setConfig(
        address oapp,
        address lib,
        SetConfigParam[] calldata params
    ) external;

    /**
     * @notice Set send library for an OApp
     * @param _oapp The OApp address
     * @param _eid Destination endpoint ID
     * @param _newLib Send library address
     */
    function setSendLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib
    ) external;

    /**
     * @notice Set receive library for an OApp
     * @param _oapp The OApp address
     * @param _eid Source endpoint ID
     * @param _newLib Receive library address
     * @param _gracePeriod Grace period for library switch
     */
    function setReceiveLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib,
        uint256 _gracePeriod
    ) external;

    /**
     * @notice Set delegate for message handling
     * @param delegate Address of the delegate
     */
    function setDelegate(
        address delegate
    ) external;

    /**
     * @notice Get the send library for an OApp and destination
     * @param _sender The sender address
     * @param _eid Destination endpoint ID
     * @return lib The send library address
     */
    function getSendLibrary(
        address _sender,
        uint32 _eid
    ) external view returns (address lib);

    /**
     * @notice Get the receive library for an OApp and source
     * @param _receiver The receiver address
     * @param _eid Source endpoint ID
     * @return lib The receive library address
     */
    function getReceiveLibrary(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, bool);

    /**
     * @notice Get the default send library for an endpoint
     * @param _eid Destination endpoint ID
     * @return The default send library address
     */
    function defaultSendLibrary(
        uint32 _eid
    ) external view returns (address);

    /**
     * @notice Get the default receive library for an endpoint
     * @param _eid Source endpoint ID
     * @return The default receive library address
     */
    function defaultReceiveLibrary(
        uint32 _eid
    ) external view returns (address);

}
