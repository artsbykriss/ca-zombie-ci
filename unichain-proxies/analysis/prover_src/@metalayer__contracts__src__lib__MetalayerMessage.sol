// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import {ReadOperation} from "../interfaces/IMetalayerRecipient.sol";

enum FinalityState {
    INSTANT,
    FINALIZED
}

/**
 * @title Metalayer Message Library
 * @notice Library for formatted messages for the metalayer. These will be the message body of Hyperlane messages.
 *
 */
library MetalayerMessage {
    using TypeCasts for bytes32;

    uint256 private constant VERSION_OFFSET = 0;
    uint256 private constant FINALITY_STATE_FLAG_OFFSET = 1;
    uint256 private constant NONCE_OFFSET = 2;
    uint256 private constant ORIGIN_OFFSET = 6;
    uint256 private constant SENDER_OFFSET = 10;
    uint256 private constant DESTINATION_OFFSET = 42;
    uint256 private constant RECIPIENT_OFFSET = 46;
    uint256 private constant BODY_OFFSET = 78;

    // Constants for read operation parsing within message body
    uint256 private constant READ_COUNT_OFFSET = 0;
    uint256 private constant READS_OFFSET = 4; // uint32 size for read count

    /**
     * @notice Returns formatted message supporting multiple read operations
     * @param _version The version of the origin and destination Mailboxes
     * @param _finalityState What sort of finality we should wait for before the message is valid. Currently only have 0 for instant, 1 for final.
     * @param _nonce A nonce to uniquely identify the message on its origin chain
     * @param _originDomain Domain of origin chain
     * @param _sender Address of sender
     * @param _destinationDomain Domain of destination chain
     * @param _recipient Address of recipient on destination chain
     * @param _reads Array of read operations to perform
     * @param _writeCallData The call data for the final write operation
     * @return Formatted message with reads
     */
    function formatMessageWithReads(
        uint8 _version,
        FinalityState _finalityState,
        uint32 _nonce,
        uint32 _originDomain,
        bytes32 _sender,
        uint32 _destinationDomain,
        bytes32 _recipient,
        ReadOperation[] memory _reads,
        bytes memory _writeCallData
    ) internal pure returns (bytes memory) {
        bytes memory messageBody = abi.encodePacked(uint32(_reads.length));

        // this is n^2 -> optimize later by just preallocating the appropriate size
        // can keep slow for test
        for (uint256 i = 0; i < _reads.length; i++) {
            messageBody = abi.encodePacked(
                messageBody, _reads[i].domain, _reads[i].target, uint32(_reads[i].callData.length), _reads[i].callData
            );
        }

        messageBody = abi.encodePacked(messageBody, _writeCallData);

        return abi.encodePacked(
            _version, uint8(_finalityState), _nonce, _originDomain, _sender, _destinationDomain, _recipient, messageBody
        );
    }

    /**
     * @notice Returns the message ID.
     * @param _message ABI encoded Metalayer message.
     * @return ID of `_message`
     */
    function id(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    /**
     * @notice Returns the message version
     * @param _message ABI encoded Metalayer message
     * @return Version of `_message`
     */
    function version(bytes calldata _message) internal pure returns (uint8) {
        return uint8(bytes1(_message[VERSION_OFFSET:NONCE_OFFSET]));
    }

    /**
     * @notice Returns the message nonce
     * @param _message ABI encoded Metalayer message
     * @return Nonce of `_message`
     */
    function nonce(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[NONCE_OFFSET:ORIGIN_OFFSET]));
    }

    /**
     * @notice Returns whether the message should use finalized ISM
     * @param _message ABI encoded Metalayer message
     * @return Whether to use finalized ISM
     */
    function finalityState(bytes calldata _message) internal pure returns (FinalityState) {
        return FinalityState(uint8(bytes1(_message[FINALITY_STATE_FLAG_OFFSET:NONCE_OFFSET])));
    }

    /**
     * @notice Returns the message origin domain
     * @param _message ABI encoded Metalayer message
     * @return Origin domain of `_message`
     */
    function origin(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[ORIGIN_OFFSET:SENDER_OFFSET]));
    }

    /**
     * @notice Returns the message sender as address
     * @param _message ABI encoded Metalayer message
     * @return Sender of `_message` as address
     */
    function senderAddress(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[SENDER_OFFSET:DESTINATION_OFFSET]);
    }

    /**
     * @notice Returns the message destination domain
     * @param _message ABI encoded Metalayer message
     * @return Destination domain of `_message`
     */
    function destination(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
    }

    /**
     * @notice Returns the message recipient as address. We only support evm chains for now, so address only.
     * @param _message ABI encoded Metalayer message
     * @return Recipient of `_message` as address
     */
    function recipientAddress(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[RECIPIENT_OFFSET:BODY_OFFSET]);
    }

    /**
     * @notice Returns the message body
     * @param _message ABI encoded Metalayer message
     * @return Body of `_message`
     */
    function body(bytes calldata _message) internal pure returns (bytes calldata) {
        return bytes(_message[BODY_OFFSET:]);
    }

    /**
     * @notice Returns the number of read operations in the message
     * @param _message ABI encoded Metalayer message
     * @return Number of read operations
     */
    function readCount(bytes calldata _message) internal pure returns (uint256) {
        return uint32(bytes4(body(_message)[READ_COUNT_OFFSET:READS_OFFSET]));
    }

    /**
     * @notice Returns the read operation at the specified index
     * @param _message ABI encoded Metalayer message
     * @param _index Index of the read operation to retrieve
     * @return The read operation at the specified index
     */
    function getRead(bytes calldata _message, uint256 _index) internal pure returns (ReadOperation memory) {
        require(_index < readCount(_message), "Index out of bounds");

        bytes calldata messageBody = body(_message);
        uint256 currentOffset = READS_OFFSET;

        for (uint256 i = 0; i < _index; i++) {
            uint256 lesserCallDataLength = uint32(bytes4(messageBody[currentOffset + 24:currentOffset + 28]));
            currentOffset += 28 + lesserCallDataLength; // 4 (domain) + 20 (contract) + 4 (length) + lesserCallDataLength
        }

        uint32 sourceChainId = uint32(bytes4(messageBody[currentOffset:currentOffset + 4]));
        address sourceContract = address(bytes20(messageBody[currentOffset + 4:currentOffset + 24]));
        uint256 callDataLength = uint32(bytes4(messageBody[currentOffset + 24:currentOffset + 28]));
        bytes calldata callData = messageBody[currentOffset + 28:currentOffset + 28 + callDataLength];

        return ReadOperation({domain: sourceChainId, target: sourceContract, callData: callData});
    }

    /**
     * @notice Returns all read operations from the message. Use this instead of getRead repeatedly if you want all operations as that is O(n) to find one read, O(n^2) total.
     * @param _message ABI encoded Metalayer message
     * @return Array of all read operations
     */
    function reads(bytes calldata _message) internal pure returns (ReadOperation[] memory) {
        uint256 numReads = readCount(_message);
        ReadOperation[] memory tempReads = new ReadOperation[](numReads);

        bytes calldata messageBody = body(_message);
        uint256 currentOffset = READS_OFFSET;

        for (uint256 i = 0; i < numReads; i++) {
            uint32 sourceChainId = uint32(bytes4(messageBody[currentOffset:currentOffset + 4]));
            address sourceContract = address(bytes20(messageBody[currentOffset + 4:currentOffset + 24]));
            uint256 callDataLength = uint32(bytes4(messageBody[currentOffset + 24:currentOffset + 28]));
            bytes calldata callData = messageBody[currentOffset + 28:currentOffset + 28 + callDataLength];

            tempReads[i] = ReadOperation({domain: sourceChainId, target: sourceContract, callData: callData});

            currentOffset += 28 + callDataLength; // 4 (domain) + 20 (contract) + 4 (length) + callDataLength
        }

        return tempReads;
    }

    /**
     * @notice Returns the write call data from the message
     * @param _message ABI encoded Metalayer message
     * @return The write call data
     */
    function writeCallData(bytes calldata _message) internal pure returns (bytes calldata) {
        bytes calldata messageBody = body(_message);
        uint256 currentOffset = READS_OFFSET;

        uint256 numReads = readCount(_message);
        for (uint256 i = 0; i < numReads; i++) {
            uint256 callDataLength = uint32(bytes4(messageBody[currentOffset + 24:currentOffset + 28]));
            currentOffset += 28 + callDataLength;
        }

        return messageBody[currentOffset:];
    }
}
