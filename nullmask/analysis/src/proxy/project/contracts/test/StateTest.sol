// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {State} from "../State.sol";
import {MerkleTree, MerkleTreeData} from "../Merkle/MerkleTree.sol";
import {Constants} from "../Merkle/Constants.sol";

/**
 * @title StateTest
 * @notice Test contract that exposes State's internal methods for testing
 */
contract StateTest is State {
  using MerkleTree for MerkleTreeData;

  event NoteInserted(uint256 _index, uint256 _leaf, uint256 _root);

  function insertNote(uint256 _leaf) external returns (uint256 _updatedRoot) {
    _updatedRoot = _noteTree.insert(_leaf);
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

  function ROOT_HISTORY_SIZE() external pure returns (uint32) {
    return Constants.ROOT_HISTORY_SIZE;
  }

  function noteTreeRootIndex() external view returns (uint32) {
    return _noteTree.currentRootIndex;
  }

  function isKnownNoteTreeRoot(uint256 _root) external view returns (bool) {
    return _noteTree.isKnownRoot(_root);
  }

  function isNoteInTree(uint256 _leaf) external view returns (bool) {
    return _noteTree.has(_leaf);
  }
}
