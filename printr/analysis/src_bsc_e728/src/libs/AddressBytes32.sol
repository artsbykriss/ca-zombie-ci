// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title AddressBytes32
 * @notice Utility library for converting between address and bytes32 types
 * @dev Provides type casting operations for address-bytes32 conversion without modifying data
 */
library AddressBytes32 {

    /**
     * @notice Converts a bytes32 value to an address
     * @dev Performs type casting by taking the last 20 bytes (address length) from bytes32
     * @param bytesAddress The bytes32 value to convert (only last 20 bytes are used)
     * @return addr The resulting address
     */
    function toAddress(
        bytes32 bytesAddress
    ) internal pure returns (address addr) {
        // Convert bytes32 to uint256, then take last 20 bytes by masking to uint160
        addr = address(uint160(uint256(bytesAddress)));
    }

    /**
     * @notice Converts an address to bytes32
     * @dev Performs type casting by zero-padding address to 32 bytes
     * @param addr The address to convert
     * @return bytesAddress The bytes32 representation (address zero-padded to 32 bytes)
     */
    function toBytes32(
        address addr
    ) internal pure returns (bytes32 bytesAddress) {
        // Convert address to uint160, then to uint256, then to bytes32
        bytesAddress = bytes32(uint256(uint160(addr)));
    }

}
