// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Nullmask} from './Nullmask.sol';
import {MerkleTree, MerkleTreeData} from './Merkle/MerkleTree.sol';

/**
 * @title NullmaskTesting
 * @notice Test-only contract that exposes direct tree insertion for faster testing
 * @dev DO NOT DEPLOY TO PRODUCTION - bypasses all validation
 */
contract NullmaskTesting is Nullmask {
    using MerkleTree for MerkleTreeData;

    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    constructor(uint256 _virtualChainId, address _uniswapV2Router)
        Nullmask(_virtualChainId, _uniswapV2Router) {}

    /**
     * @notice Insert N dummy notes to quickly grow the tree to a target size
     * @dev Uses _addNote to emit standard AddNote events for test tree rebuilding
     * @param count Number of dummy notes to insert
     * @param seed Starting seed for generating unique commitments
     */
    function insertDummyNotes(uint256 count, uint256 seed) external {
        bytes32[9] memory dummyCiphertext;
        for (uint256 i = 0; i < count; i++) {
            // Generate unique but deterministic commitments
            uint256 commitment = uint256(keccak256(abi.encode(seed, i)));
            // Ensure commitment is in the field and non-zero
            commitment = (commitment % (FIELD_MODULUS - 1)) + 1;
            _addNote(bytes32(commitment), dummyCiphertext);
        }
    }

    /**
     * @notice Fast tree growth without event emission - for testing tree depth only
     * @dev MUCH faster than insertDummyNotes since it skips event emission
     * @param count Number of dummy commitments to insert
     * @param seed Starting seed for generating unique commitments
     */
    function insertDummyNotesFast(uint256 count, uint256 seed) external {
        for (uint256 i = 0; i < count; i++) {
            uint256 commitment = uint256(keccak256(abi.encode(seed, i)));
            commitment = (commitment % (FIELD_MODULUS - 1)) + 1;
            _noteTree.insert(_noteTreeRoots, commitment);
        }
    }

    /**
     * @notice Insert N dummy key hashes into the key registry tree
     * @dev Lets a test grow the registry past any number of entries without needing one
     *      funded EOA per key. Inherited by NullmaskMigrationToPoseidon2T4Testing.
     * @param count Number of dummy keys to insert
     * @param seed Starting seed for generating unique hashes
     */
    function insertDummyKeys(uint256 count, uint256 seed) external {
        for (uint256 i = 0; i < count; i++) {
            uint256 keyHash = uint256(keccak256(abi.encode("key", seed, i)));
            keyHash = (keyHash % (FIELD_MODULUS - 1)) + 1;
            _keyRegistryTree.insert(_keyRegistryTreeRoots, keyHash);
            uint256 index = _keyRegistryIndex;
            _keyRegistryIndex += 1;
            emit ReceivingKeyRegistered(
                address(0), index, keyHash,
                bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)
            );
        }
    }
}
