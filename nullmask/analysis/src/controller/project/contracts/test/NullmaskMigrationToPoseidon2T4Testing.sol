// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NullmaskTesting} from "../NullmaskTesting.sol";
import {MerkleTree, MerkleTreeData} from "../Merkle/MerkleTree.sol";

/**
 * @title NullmaskMigrationToPoseidon2T4Testing
 * @notice Extends NullmaskTesting with key registry tree insertion for migration tests
 * @dev DO NOT DEPLOY TO PRODUCTION
 */
contract NullmaskMigrationToPoseidon2T4Testing is NullmaskTesting {
    using MerkleTree for MerkleTreeData;

    constructor(uint256 _virtualChainId, address _uniswapV2Router)
        NullmaskTesting(_virtualChainId, _uniswapV2Router) {}

    /**
     * @notice Insert N dummy key hashes into the key registry tree
     * @param count Number of dummy keys to insert
     * @param seed Starting seed for generating unique hashes
     */
    function insertDummyKeys(uint256 count, uint256 seed) external {
        for (uint256 i = 0; i < count; i++) {
            uint256 keyHash = uint256(keccak256(abi.encode("key", seed, i)));
            keyHash = (keyHash % (FIELD_MODULUS - 1)) + 1;
            _keyRegistryTree.insert(keyHash);
            uint256 index = _keyRegistryIndex;
            _keyRegistryIndex += 1;
            emit ReceivingKeyRegistered(
                address(0), index, keyHash,
                bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)
            );
        }
    }
}
