// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {EngineType} from "../../share/Enums.sol";

library ProductRegistry {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.ProductRegistry.Data"));

    struct Data {
        /// Last used productId from prior register invocation
        uint32 productIdCounter;
        /// Mapping of tickers by engineType
        mapping(EngineType engineType => mapping(bytes ticker => bool used)) usedTickers;
    }

    function load() internal pure returns (Data storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }

    /// @dev Returns the next productId for the given engineType then updating id counter.
    function getAndIncrementNextProductId(ProductRegistry.Data storage self) internal returns (uint32) {
        uint32 nextId = self.productIdCounter + 1;
        self.productIdCounter = nextId;
        return nextId;
    }
}
