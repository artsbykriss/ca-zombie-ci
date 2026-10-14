// SPDX-License-Identifier: MIT
// https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/main/contracts/libs/Bytes32String.sol
pragma solidity ^0.8.27;

/**
 * @title StringToBytes32
 * @notice Utility library for converting strings to bytes32 with length preservation
 * @dev Encodes strings up to 31 bytes, storing length in the last byte
 */
library StringToBytes32 {

    /**
     * @notice Thrown when string length is 0 or exceeds 31 bytes
     * @dev Limited to 31 bytes as last byte is used to store length
     */
    error InvalidStringLength();

    /**
     * @notice Converts a string to bytes32 while preserving its length
     * @dev Stores string length in the last byte of bytes32
     * @param str The string to convert (must be 1-31 bytes)
     * @return The bytes32 representation with length encoded
     * @custom:throws InvalidStringLength if string is empty or longer than 31 bytes
     */
    function toBytes32(
        string memory str
    ) internal pure returns (bytes32) {
        // Convert string to bytes for length check and manipulation
        bytes memory stringBytes = bytes(str);

        // Verify length constraints (0 < length <= 31)
        if (stringBytes.length == 0 || stringBytes.length > 31) {
            revert InvalidStringLength();
        }

        // Convert string bytes to uint256 for bitwise operations
        uint256 stringNumber = uint256(bytes32(stringBytes));

        // Store length in last byte using bitwise OR
        stringNumber |= 0xff & stringBytes.length;
        return bytes32(stringNumber);
    }

}

/**
 * @title Bytes32ToString
 * @notice Utility library for converting bytes32 back to strings
 * @dev Recovers original string using length stored in last byte
 */
library Bytes32ToString {

    /**
     * @notice Converts bytes32 back to string, trimming to original length
     * @dev Uses assembly for efficient memory operations
     * @param stringData bytes32 value containing string data and length
     * @return converted The recovered string with correct length
     */
    function toTrimmedString(
        bytes32 stringData
    ) internal pure returns (string memory converted) {
        // Extract length from last byte
        uint256 length = 0xff & uint256(stringData);

        // Use assembly for efficient memory operations
        assembly {
            // Allocate memory for string
            converted := mload(0x40)
            // Update free memory pointer (add 64 bytes: 32 for length, 32 for data)
            mstore(0x40, add(converted, 0x40))
            // Store string length
            mstore(converted, length)
            // Store string data
            mstore(add(converted, 0x20), stringData)
        }
    }

}
