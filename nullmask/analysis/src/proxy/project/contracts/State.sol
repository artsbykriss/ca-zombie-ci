// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {MerkleTreeData} from './Merkle/MerkleTree.sol';

/**
 * @title State
 * @notice Abstract storage contract for privacy pool - contains only state variables
 * @dev All logic and view functions are in Nullmask.sol for UUPS upgradeability
 */
abstract contract State {
  /*///////////////////////////////////////////////////////////////
                              ENUMS
  //////////////////////////////////////////////////////////////*/

  enum DepositStatus {
    REJECTED,
    PENDING,
    ACTION_REQUIRED,
    APPROVED,
    REVERTED  // Depositor withdrew their pending deposit
  }

  enum TokenType { NOT_ALLOWED, NATIVE_TOKEN, ERC20, ERC20_FEE_ON_TRANSFER }

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/

  struct ReceivingKey {
    bytes32 pkX;
    bytes32 pkY;
    bytes32 keyData;
    bytes32 pnk;
    bytes32 ekX;
    bytes32 ekY;
  }

  /*///////////////////////////////////////////////////////////////
                              STATE
  //////////////////////////////////////////////////////////////*/

  /// @dev Deprecated: was `bool public dead` - preserved for storage layout
  uint256 private __deprecated_dead;

  MerkleTreeData internal _noteTree;
  MerkleTreeData internal _keyRegistryTree;

  /// @notice Hash of pending deposit data: keccak256(abi.encode(recipient, token, amount, depositor))
  mapping(uint256 => bytes32) public pendingDepositHashes;

  /// @dev Deprecated: was `revocationPublicKeys` - preserved for storage layout
  uint256 private __deprecated_revocationPublicKeys;

  mapping(uint256 => bool) public noteNullifiers;
  mapping(bytes32 => bool) public txNullifiers;
  // NOTE: _receivingKeys is unused - key data is now fetched from ReceivingKeyRegistered events
  mapping(address => ReceivingKey) internal _receivingKeys;
  mapping(address => uint256) public _addressToReceivingKeyHash;
  mapping(address => TokenType) public tokenWhitelist;

  address public guard;
  address public shieldedTransferVerifier;
  address public shieldedWithdrawalVerifier;
  address public shieldedSwapVerifier;

  /// @notice Controller that authorizes UUPS upgrades
  address public upgradeController;

  uint256 internal _depositIndex;
  uint256 internal _keyRegistryIndex;

  address public whitelistManager;

  /*///////////////////////////////////////////////////////////////
                          STORAGE GAP
  //////////////////////////////////////////////////////////////*/

  /// @dev Reserved storage for future upgrades
  uint256[45] private __gap;
}
