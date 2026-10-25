// SPDX-License-Identifier: Apache-2.0
// Test-only copy of contracts/contracts/State.sol as of commit 6232c91 (main before the
// fees/check change set), renamed so it can sit next to the current contract. Used by
// test/Upgrade.ts as the "old implementation" of an in-place upgrade. Do not edit: its
// only job is to be the code a live proxy runs today.
pragma solidity ^0.8.28;

import {MerkleTreeData, RootSet} from '../../Merkle/MerkleTree.sol';

/**
 * @title State
 * @notice Abstract storage contract for privacy pool - contains only state variables
 * @dev All logic and view functions are in Nullmask.sol for UUPS upgradeability
 */
abstract contract StateV1 {
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
              RISK CONTROLS (carved out of __gap)
  //////////////////////////////////////////////////////////////*/
  /// @dev IMPORTANT: every variable below was taken from __gap, which shrank by
  ///      the same number of slots (45 -> 41). Never insert state above this
  ///      block: MerkleTreeData is embedded by value and any field added inside
  ///      it (or before it) shifts _keyRegistryTree and the whole storage tail.
  ///      That is also why the root sets below sit here rather than inside
  ///      MerkleTreeData, where they conceptually belong.

  /// @notice Relayers allowed to submit fee-paying shielded operations.
  /// @dev Fee-less (fee == 0) operations stay permissionless on purpose, so a
  ///      censoring relayer can never lock a user out of their own funds.
  ///      Slot 1/4.
  mapping(address => bool) public allowedRelayers;

  /// @notice Per-token cap on the size of a single deposit. 0 == no limit.
  /// @dev Slot 2/4.
  mapping(address => uint256) public maxDeposit;

  /// @notice Per-token cap on the total amount the pool may hold. 0 == no limit.
  /// @dev Slot 3/4.
  mapping(address => uint256) public depositCap;

  /// @notice Halts deposits, shielded transfers and shielded swaps.
  /// @dev Withdrawals stay open on purpose so a pause never traps user funds.
  ///      Packed with `withdrawalsPaused` into slot 4/4.
  bool public paused;

  /// @notice Emergency-only switch that also halts shielded withdrawals.
  /// @dev Separate from `paused` because stopping the exit is only correct while
  ///      an active drain is in progress. Packed into slot 4/4.
  bool public withdrawalsPaused;

  /*///////////////////////////////////////////////////////////////
              ROOT HISTORY (carved out of __gap)
  //////////////////////////////////////////////////////////////*/
  /// @dev Replaces the 64-entry circular buffer that used to live inside
  ///      MerkleTreeData (findings F11 and NEW-3). Each set records every root its
  ///      tree has ever had, so a proof never expires and the lookup is one SLOAD.
  ///      They are declared here, not in MerkleTreeData, because that struct is
  ///      embedded by value and cannot grow - see the note above.

  /// @notice Every root `_noteTree` has ever had. Slot 5/6 of the carve-out.
  RootSet internal _noteTreeRoots;

  /// @notice Every root `_keyRegistryTree` has ever had. Slot 6/6 of the carve-out.
  RootSet internal _keyRegistryTreeRoots;

  /*///////////////////////////////////////////////////////////////
              KEY ROTATION (carved out of __gap)
  //////////////////////////////////////////////////////////////*/

  /// @notice When each address last wrote a receiving key, as a block timestamp.
  /// @dev Rate-limits how fast one address can append leaves to the key registry
  ///      (finding F6). Slot 7/7 of the carve-out.
  mapping(address => uint256) public receivingKeyUpdatedAt;

  /*///////////////////////////////////////////////////////////////
                          STORAGE GAP
  //////////////////////////////////////////////////////////////*/

  /// @dev Reserved storage for future upgrades.
  ///      Was uint256[45]; 7 slots were consumed by the blocks above.
  uint256[38] private __gap;
}
