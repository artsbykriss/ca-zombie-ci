// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InternalLeanIMT, LeanIMTData} from "@zk-kit/lean-imt.sol/InternalLeanIMT.sol";
import {Constants} from './Constants.sol';

/// @notice Self-contained Merkle tree state with root history
struct MerkleTreeData {
    LeanIMTData tree;
    mapping(uint256 index => uint256 root) roots;
    uint32 currentRootIndex;
}

/// @notice Errors for Merkle tree operations
error MaxTreeDepthReached();

/// @title MerkleTree
/// @notice Wrapper around LeanIMT that adds root history tracking
/// @dev Use this library for any append-only Merkle tree with historical root verification
library MerkleTree {
    using InternalLeanIMT for LeanIMTData;

    /// @notice Insert a leaf into the tree and update root history
    /// @param self The Merkle tree state
    /// @param leaf The leaf to insert
    /// @return newRoot The new root after insertion
    function insert(MerkleTreeData storage self, uint256 leaf) internal returns (uint256 newRoot) {
        newRoot = self.tree._insert(leaf);

        if (self.tree.depth > Constants.MAX_TREE_DEPTH) revert MaxTreeDepthReached();

        uint32 nextIndex = (self.currentRootIndex + 1) % Constants.ROOT_HISTORY_SIZE;
        self.roots[nextIndex] = newRoot;
        self.currentRootIndex = nextIndex;
    }

    /// @notice Insert multiple leaves into the tree and update root history
    /// @param self The Merkle tree state
    /// @param leaves The leaves to insert
    /// @return newRoot The new root after insertion
    function insertMany(MerkleTreeData storage self, uint256[] memory leaves) internal returns (uint256 newRoot) {
        newRoot = self.tree._insertMany(leaves);

        if (self.tree.depth > Constants.MAX_TREE_DEPTH) revert MaxTreeDepthReached();

        uint32 nextIndex = (self.currentRootIndex + 1) % Constants.ROOT_HISTORY_SIZE;
        self.roots[nextIndex] = newRoot;
        self.currentRootIndex = nextIndex;
    }

    /// @notice Check if a root exists in the history
    /// @dev Searches from most recent to oldest for better average performance
    /// @param self The Merkle tree state
    /// @param _root The root to check
    /// @return True if root is in history
    function isKnownRoot(MerkleTreeData storage self, uint256 _root) internal view returns (bool) {
        if (_root == 0) return false;

        uint32 index = self.currentRootIndex;
        for (uint32 i = 0; i < Constants.ROOT_HISTORY_SIZE; i++) {
            if (_root == self.roots[index]) return true;
            index = (index + Constants.ROOT_HISTORY_SIZE - 1) % Constants.ROOT_HISTORY_SIZE;
        }
        return false;
    }

    /// @notice Check if a leaf exists in the tree
    function has(MerkleTreeData storage self, uint256 leaf) internal view returns (bool) {
        return self.tree._has(leaf);
    }

    /// @notice Get the current root
    function root(MerkleTreeData storage self) internal view returns (uint256) {
        return self.tree._root();
    }

    /// @notice Get the current tree depth
    function depth(MerkleTreeData storage self) internal view returns (uint256) {
        return self.tree.depth;
    }

    /// @notice Get the current tree size (number of leaves)
    function size(MerkleTreeData storage self) internal view returns (uint256) {
        return self.tree.size;
    }

    /// @notice Update a leaf in the tree and update root history
    /// @param self The Merkle tree state
    /// @param oldLeaf The leaf value to replace
    /// @param newLeaf The new leaf value
    /// @param siblingNodes The sibling nodes for the merkle proof
    /// @return newRoot The new root after update
    function update(
        MerkleTreeData storage self,
        uint256 oldLeaf,
        uint256 newLeaf,
        uint256[] calldata siblingNodes
    ) internal returns (uint256 newRoot) {
        newRoot = self.tree._update(oldLeaf, newLeaf, siblingNodes);

        uint32 nextIndex = (self.currentRootIndex + 1) % Constants.ROOT_HISTORY_SIZE;
        self.roots[nextIndex] = newRoot;
        self.currentRootIndex = nextIndex;
    }
}
