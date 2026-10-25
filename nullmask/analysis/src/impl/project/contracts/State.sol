// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {MerkleTreeData, RootSet} from './Merkle/MerkleTree.sol';

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

  /// @notice Hash of pending deposit data, gas escrow included:
  ///         keccak256(abi.encode(recipient, token, amount, depositor, gasEscrow))
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

  /// @notice When each address registered its receiving key, as a block timestamp.
  /// @dev Used to rate-limit key rotation (finding F6); a registered key can no longer be
  ///      replaced at all (M-1), so it is only a record now. Slot 7/7 of the carve-out.
  mapping(address => uint256) public receivingKeyUpdatedAt;

  /*///////////////////////////////////////////////////////////////
              FEES AND CHECKS (carved out of __gap)
  //////////////////////////////////////////////////////////////*/
  /// @dev Slots 35-40, taken from __gap, which shrank from 38 to 32 so the tail still
  ///      ends at slot 72. Every value here defaults to zero, and zero means "off":
  ///      an upgrade that reads these slots fresh behaves like the old code until the
  ///      admin configures them (the one exception, the unused gas escrow going back to
  ///      the depositor, is in Nullmask.sol). Never insert anything above this block.

  /// @notice Where accrued protocol fees are swept to. Slot 35, bytes 0-19.
  address public treasury;

  /// @notice Protocol fee on credited deposits, in basis points. Slot 35, bytes 20-21.
  uint16 public depositFeeBps;

  /// @notice Protocol fee on shielded withdrawals, in basis points. Slot 35, bytes 22-23.
  uint16 public withdrawalFeeBps;

  /// @notice Whether a depositor taking back their own pending deposit pays the capped
  ///         check cost. false (the default) refunds everything. Slot 35, byte 24.
  bool public cancelCheckFee;

  /// @notice Gas added to every escrow settlement for what the contract cannot measure:
  ///         intrinsic gas, calldata, and on an L2 the L1 data fee expressed in L2 gas.
  ///         0 means the built-in default. Set per chain. Slot 35, bytes 25-28.
  uint32 public settleGasOverhead;

  /// @notice Protocol fees held by the pool per token, waiting to be swept. Slot 36.
  mapping(address => uint256) public protocolFeesAccrued;

  /// @notice Smallest deposit accepted per token, in token units. 0 == no minimum. Slot 37.
  mapping(address => uint256) public minDeposit;

  /// @notice Price of one paid check, in token units: the most a refused deposit
  ///         can be charged for its check, and never more than MAX_CHECK_FEE_BPS of the
  ///         deposit. Slot 38.
  mapping(address => uint256) public checkFee;

  /// @notice Cap on the gas the guard may withhold, in token units, when it pulls a
  ///         deposit. Slot 39.
  mapping(address => uint256) public maxPullGasFee;

  /// @notice PullIntent request ids already used, so each signed intent pulls at most
  ///         once. Slot 40.
  mapping(bytes32 => bool) public usedPullRequests;

  /*///////////////////////////////////////////////////////////////
                          STORAGE GAP
  //////////////////////////////////////////////////////////////*/

  /// @dev Reserved storage for future upgrades.
  ///      Was uint256[45]; 13 slots were consumed by the blocks above.
  uint256[32] private __gap;
}
