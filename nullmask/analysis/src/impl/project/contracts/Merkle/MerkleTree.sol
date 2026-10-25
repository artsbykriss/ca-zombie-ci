// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InternalLeanIMT, LeanIMTData} from "@zk-kit/lean-imt.sol/InternalLeanIMT.sol";
import {Constants} from './Constants.sol';

/// @notice Append-only Merkle tree state.
/// @dev The last two fields are the remains of the 64-entry circular root buffer this
///      library used to keep (see `RootSet`). They are dead - nothing reads or writes
///      them - but they MUST stay: `MerkleTreeData` is embedded in `State` by value, so
///      removing a field would shift `_keyRegistryTree` and the entire storage tail of a
///      live proxy. For the same reason the replacement lives outside this struct.
struct MerkleTreeData {
    LeanIMTData tree;
    /// @dev Deprecated: was `mapping(uint256 index => uint256 root) roots`.
    mapping(uint256 => uint256) __deprecated_roots;
    /// @dev Deprecated: was `uint32 currentRootIndex`.
    uint32 __deprecated_currentRootIndex;
}

/// @notice Every root the tree has ever had, kept forever.
/// @dev One storage slot, declared next to the tree it belongs to (in `State`, carved out
///      of `__gap`) rather than inside `MerkleTreeData`, which cannot grow.
struct RootSet {
    mapping(uint256 root => bool known) known;
}

/// @notice Errors for Merkle tree operations
error MaxTreeDepthReached();

/// @title MerkleTree
/// @notice Wrapper around LeanIMT that records every root the tree has ever had.
/// @dev Historical roots are kept indefinitely instead of in a fixed-size window.
///
///      Why that is safe: the tree is append-only, so a leaf that was a member under an
///      old root is still a member today, and a membership proof against an old root
///      proves exactly what it proved when the root was current. Nothing about spending
///      depends on the root being recent - a note can only be spent once because its
///      nullifier is recorded, and the nullifier is derived from the note, not the root.
///      RAILGUN accepts any root over the tree's whole history in production for the same
///      reason.
///
///      Why the old window was wrong: it made proof validity expire. A proof takes
///      seconds to build, and any 64 unrelated insertions in that interval - registrations
///      by strangers, other users' transfers - silently invalidated it (NEW-3). An
///      attacker could force that eviction for the price of 64 key registrations (F11).
library MerkleTree {
    using InternalLeanIMT for LeanIMTData;

    /// @notice Insert a leaf into the tree and record the resulting root
    /// @param self The Merkle tree state
    /// @param roots The tree's root set
    /// @param leaf The leaf to insert
    /// @return newRoot The new root after insertion
    function insert(
        MerkleTreeData storage self,
        RootSet storage roots,
        uint256 leaf
    ) internal returns (uint256 newRoot) {
        newRoot = self.tree._insert(leaf);

        if (self.tree.depth > Constants.MAX_TREE_DEPTH) revert MaxTreeDepthReached();

        roots.known[newRoot] = true;
    }

    /// @notice Insert multiple leaves into the tree and record the resulting root
    /// @dev Only the final root is recorded: the intermediate roots never existed as far
    ///      as any observer is concerned, so no proof can have been built against them.
    /// @param self The Merkle tree state
    /// @param roots The tree's root set
    /// @param leaves The leaves to insert
    /// @return newRoot The new root after insertion
    function insertMany(
        MerkleTreeData storage self,
        RootSet storage roots,
        uint256[] memory leaves
    ) internal returns (uint256 newRoot) {
        newRoot = self.tree._insertMany(leaves);

        if (self.tree.depth > Constants.MAX_TREE_DEPTH) revert MaxTreeDepthReached();

        roots.known[newRoot] = true;
    }

    /// @notice Check whether the tree ever had this root
    /// @dev One SLOAD, independent of how many roots have been recorded.
    /// @param roots The tree's root set
    /// @param _root The root to check
    /// @return True if the tree produced this root at some point
    function isKnownRoot(RootSet storage roots, uint256 _root) internal view returns (bool) {
        if (_root == 0) return false;
        return roots.known[_root];
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

    /// @notice Update a leaf in the tree and record the resulting root
    /// @param self The Merkle tree state
    /// @param roots The tree's root set
    /// @param oldLeaf The leaf value to replace
    /// @param newLeaf The new leaf value
    /// @param siblingNodes The sibling nodes for the merkle proof
    /// @return newRoot The new root after update
    function update(
        MerkleTreeData storage self,
        RootSet storage roots,
        uint256 oldLeaf,
        uint256 newLeaf,
        uint256[] calldata siblingNodes
    ) internal returns (uint256 newRoot) {
        newRoot = self.tree._update(oldLeaf, newLeaf, siblingNodes);

        roots.known[newRoot] = true;
    }
}
