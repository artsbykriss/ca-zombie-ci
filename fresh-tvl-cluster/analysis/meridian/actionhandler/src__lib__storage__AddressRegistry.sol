// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library AddressRegistry {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.AddressRegistry.Data"));

    struct Data {
        /// Mapping of contract name to addresses
        mapping(bytes32 contractName => address contractAddress) records;
    }

    function load() internal pure returns (Data storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }
}
