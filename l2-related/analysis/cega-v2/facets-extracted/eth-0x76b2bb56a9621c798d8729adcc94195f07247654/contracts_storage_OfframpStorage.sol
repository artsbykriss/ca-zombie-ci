// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaOfframpStorage } from "../Structs.sol";

contract OfframpStorage {
    bytes32 private constant CEGA_ADHOC_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.offramp.storage")) - 1);

    function getOfframpStorage()
        internal
        pure
        returns (CegaOfframpStorage storage ds)
    {
        bytes32 position = CEGA_ADHOC_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
