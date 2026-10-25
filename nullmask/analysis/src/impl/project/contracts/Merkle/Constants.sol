// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

// Based on Wonderland's privacy-pools-core implementation
// Source: https://github.com/0xbow-io/privacy-pools-core
// Original license: Apache-2.0

library Constants {
  uint256 constant SNARK_SCALAR_FIELD =
    21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;

  address constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // NOTE: `ROOT_HISTORY_SIZE = 64` used to bound a circular buffer of historical roots.
  // The buffer was replaced by a persistent root set (see Merkle/MerkleTree.sol), so
  // there is no longer a window past which a root expires and no constant to size it.

  /// @notice Maximum Merkle tree depth (constrained by ZK circuit compile-time bounds)
  uint32 constant MAX_TREE_DEPTH = 32;

  /// @notice Sentinel value used to mark removed tree leafs
  uint256 constant SENTINEL = 0;

  /// @notice Returns the maximum tree depth
  function maxTreeDepth() internal pure returns (uint32) {
    return MAX_TREE_DEPTH;
  }
}