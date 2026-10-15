// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaAdhocStorage } from "../Structs.sol";

contract AdhocStorage {
    bytes32 private constant CEGA_ADHOC_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.adhoc.storage")) - 1);

    function getStorage() internal pure returns (CegaAdhocStorage storage ds) {
        bytes32 position = CEGA_ADHOC_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
