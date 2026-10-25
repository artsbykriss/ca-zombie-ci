// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {State} from "../State.sol";
import {MerkleTree, MerkleTreeData, RootSet} from "../Merkle/MerkleTree.sol";

/**
 * @title StateTest
 * @notice Test contract that exposes State's internal methods for testing
 */
contract StateTest is State {
  using MerkleTree for MerkleTreeData;
  using MerkleTree for RootSet;

  event NoteInserted(uint256 _index, uint256 _leaf, uint256 _root);

  function insertNote(uint256 _leaf) external returns (uint256 _updatedRoot) {
    _updatedRoot = _noteTree.insert(_noteTreeRoots, _leaf);
    emit NoteInserted(_noteTree.size(), _leaf, _updatedRoot);
  }

  function noteTreeRoot() external view returns (uint256) {
    return _noteTree.root();
  }

  function noteTreeDepth() external view returns (uint256) {
    return _noteTree.depth();
  }

  function noteTreeSize() external view returns (uint256) {
    return _noteTree.size();
  }

  function isKnownNoteTreeRoot(uint256 _root) external view returns (bool) {
    return _noteTreeRoots.isKnownRoot(_root);
  }

  /// @notice Non-view wrapper around `isKnownRoot` so a test can price the lookup.
  /// @dev A `view` call has no gas receipt, so the benchmark needs a real transaction.
  ///      The event is a constant overhead that cancels out in a before/after comparison.
  function probeKnownNoteTreeRoot(uint256 _root) external returns (bool _known) {
    _known = _noteTreeRoots.isKnownRoot(_root);
    emit RootProbed(_root, _known);
  }

  event RootProbed(uint256 _root, bool _known);

  function isNoteInTree(uint256 _leaf) external view returns (bool) {
    return _noteTree.has(_leaf);
  }
}
