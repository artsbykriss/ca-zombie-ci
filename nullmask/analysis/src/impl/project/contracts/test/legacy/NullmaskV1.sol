// SPDX-License-Identifier: MIT
// Test-only copy of contracts/contracts/Nullmask.sol as of commit 6232c91 (main before the
// fees/check change set), renamed so it can sit next to the current contract. Used by
// test/Upgrade.ts as the "old implementation" of an in-place upgrade. Do not edit: its
// only job is to be the code a live proxy runs today.
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {StateV1} from "./StateV1.sol";
import {MerkleTree, MerkleTreeData, RootSet} from "../../Merkle/MerkleTree.sol";
import {Constants} from "../../Merkle/Constants.sol";
import {IUpgradeController} from "../../upgrade/IUpgradeController.sol";
import {Poseidon2T4Unrolled} from "poseidon2-lib/Poseidon2T4Unrolled.sol";

interface IVerifierV1 {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2RouterV1 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/**
 * @title Nullmask
 * @notice Privacy pool with shielded transfers and withdrawals using ZK proofs
 * @dev Uses UUPS proxy pattern for upgradeability. Upgrade permissions are
 *      delegated to an IUpgradeController, allowing the permission mechanism
 *      itself to be upgraded (e.g., from admin-only to timelock or multisig).
 */
contract NullmaskV1 is StateV1, Initializable, UUPSUpgradeable, ReentrancyGuardTransient {
    using MerkleTree for MerkleTreeData;
    using MerkleTree for RootSet;
    using SafeERC20 for IERC20;

    // ---- Errors ----
    error NotAccountOwner(address caller, address expected);
    error NullifierAlreadySpent();
    error ZeroAddress();
    error ReceivingKeyNotFound(address account);
    error TxNullifierAlreadyUsed(bytes32 nullifier);
    error InvalidNoteTreeRoot(bytes32 root);
    error InvalidKeyRegistryRoot(bytes32 root);
    error InvalidProof();
    error ETHTransferFailed(address recipient, uint256 amount);
    error NotGuard(address caller);
    error NotWhitelistManager(address caller);
    error UpgradeNotAuthorized(address caller);
    error NotUpgradeController(address caller);
    error InvalidDepositData();
    error DepositNotPending(uint256 index);
    error NotDepositor(address caller);
    error InsufficientValue();
    error TokenNotWhitelisted(address token);
    error InvalidReceivingKey();
    error InvalidSwapSelector();
    error LengthMismatch();
    error KeyDataAddressMismatch(address keyDataAddress, address derivedAddress);
    error PublicInputNotInField();
    error NotRelayer(address caller);
    error DeadlineTooFar(uint256 deadline, uint256 maxDeadline);
    /// @notice A shielded swap arrived with no slippage floor at all (F7).
    error ZeroAmountOutMin();
    error DepositTooLarge(address token, uint256 amount, uint256 limit);
    error DepositCapExceeded(address token, uint256 poolBalance, uint256 cap);
    error ContractPaused();
    error WithdrawalsArePaused();
    error KeyRotationTooSoon(uint256 availableAt);
    error EncryptionKeyNotOnCurve(bytes32 ekX, bytes32 ekY);

    // ---- Field Modulus ----
    uint256 private constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @notice Grumpkin curve parameter `b` in `y^2 = x^3 + b`, i.e. `-17 mod FIELD_MODULUS`.
    /// @dev Must stay identical to `GRUMPKIN_B` in the Noir library, circuits/lib/src. Grumpkin is
    ///      the curve the note encryption keys live on: its base field is exactly the BN254
    ///      scalar field, so the arithmetic below is plain `mulmod`/`addmod` over FIELD_MODULUS.
    uint256 private constant GRUMPKIN_B =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffff0;

    /// @notice Upper bound on how far into the future a shielded swap may set the
    ///         router deadline. Without it a proof stays executable indefinitely and a
    ///         searcher can sit on it until the price moves in their favour.
    /// @dev The wallet picks the deadline before the proof is generated, and generation
    ///      plus the relayer's queue can take minutes under load. A ceiling tight enough
    ///      to expire during a normal send is not a safety measure, it is an outage - the
    ///      first cut at 10 minutes sat below the interface's own 20 minute default and
    ///      rejected every swap. Slippage (`amountOutMin`) is the primary defence against
    ///      a stale price; this is the secondary bound on how long the proof stays live.
    uint256 public constant MAX_SWAP_DEADLINE = 30 minutes;

    /// @notice Minimum interval between two receiving key writes by the same address.
    /// @dev Caps how fast one address can append leaves to the key registry (F6). It does
    ///      not apply to a first registration, so onboarding is unaffected; it only bounds
    ///      rotation, which a user does deliberately and rarely.
    uint256 public constant KEY_ROTATION_COOLDOWN = 1 days;

    // ---- Chain-specific immutables (set via constructor, vary per deployment) ----
    uint256 public immutable VIRTUAL_CHAIN_ID;
    address public immutable UNISWAP_V2_ROUTER;

    // ---- Structs ----
    struct GasFee {
        bytes32 maxPriorityFeePerGas;
        bytes32 maxFeePerGas;
        bytes32 gasLimit;
    }

    struct SwapRouterArgs {
        bytes32 amountIn;
        bytes32 amountOutMin;
        bytes32[4] path;
        bytes32 pathLength;
        bytes32 deadline;
    }

    struct ShieldedSwapParams {
        bytes32[6] noteNullifiers;
        bytes32 txNullifier;
        bytes32 root;
        bytes32 noteChangeCommitment;
        bytes32 noteFeeChangeCommitment;
        bytes32 selector;
        SwapRouterArgs routerArgs;
        bytes32 receivingKeyCommitment;
        bytes32[9] ciphertextChange;
        bytes32[9] ciphertextFeeChange;
        bytes32[6] ciphertextSwap;
        GasFee gasFee;
        bytes32 nullifiersHash;
        bytes32 fee;
        bytes32 feeTokenAddress;
    }

    struct SwapResult {
        bytes32 noteOutCommitment;
        bytes32[9] noteOutCiphertext;
        uint256 amountIn;
        address inputToken;
        uint256 amountOut;
        address outputToken;
    }

    struct ShieldedTransferParams {
        bytes32[6] noteNullifiers;
        bytes32 txNullifier;
        bytes32 root;
        bytes32 rkRoot;
        bytes32 noteOutCommitment;
        bytes32 noteChangeCommitment;
        bytes32 noteFeeChangeCommitment;
        bytes32[9] ciphertextOut;
        bytes32[9] ciphertextChange;
        bytes32[9] ciphertextFeeChange;
        GasFee gasFee;
        bytes32 nullifiersHash;
        bytes32 fee;
        bytes32 feeTokenAddress;
    }

    struct ShieldedWithdrawalParams {
        bytes32[6] noteNullifiers;
        bytes32 txNullifier;
        bytes32 root;
        bytes32 noteChangeCommitment;
        bytes32 noteFeeChangeCommitment;
        bytes32 value;
        bytes32 recipientAddress;
        bytes32 coinId;
        bytes32[9] ciphertextChange;
        bytes32[9] ciphertextFeeChange;
        GasFee gasFee;
        bytes32 nullifiersHash;
        bytes32 fee;
        bytes32 feeTokenAddress;
    }

    // ---- Events ----
    event NoteAdded(
        uint256 indexed index,
        bytes32 noteCommitment,
        bytes32[9] noteCiphertext
    );
    event NoteSpent(bytes32 indexed noteNullifier);
    event ShieldedTransfer(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteOutCommitment,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        uint256 fee,
        address feeTokenAddress
    );
    event ShieldedWithdrawal(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        address recipientAddress,
        uint256 amount,
        address tokenAddress,
        uint256 fee,
        address feeTokenAddress
    );
    event ShieldedSwap(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteOutCommitment,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut,
        uint256 fee,
        address feeTokenAddress
    );
    event Deposit(
        uint256 indexed index,
        address indexed account,
        address token,
        uint256 amount,
        uint256 revocationPublicKeyX,
        uint256 revocationPublicKeyY
    );
    event DepositPending(
        uint256 indexed index,
        address indexed recipient,
        address token,
        uint256 amount,
        address depositor,
        uint256 gasEscrow
    );
    event DepositStatusChanged(uint256 indexed index, DepositStatus status);
    event ReceivingKeyRegistered(
        address indexed account,
        uint256 indexed index,
        uint256 hash,
        bytes32 pkX,
        bytes32 pkY,
        bytes32 keyData,
        bytes32 pnk,
        bytes32 ekX,
        bytes32 ekY
    );
    /// @notice A registered address replaced its receiving key.
    /// @dev Emitted alongside ReceivingKeyRegistered so a scanner can tell a rotation from
    ///      a first registration without tracking per-account state. The previous leaf is
    ///      still in the registry tree - it cannot be removed - so clients must treat the
    ///      newest key for an account as the only one to send to.
    event ReceivingKeyRotated(address indexed account, uint256 previousHash, uint256 newHash);
    event TokenWhitelistUpdated(address indexed token, TokenType tokenType);
    event WhitelistManagerUpdated(address indexed previousManager, address indexed newManager);
    event GuardUpdated(address indexed previousGuard, address indexed newGuard);
    event UpgradeControllerUpdated(address indexed previousController, address indexed newController);
    event VerifiersUpdated(
        address indexed shieldedTransferVerifier,
        address indexed shieldedWithdrawalVerifier,
        address indexed shieldedSwapVerifier
    );
    event RelayerUpdated(address indexed relayer, bool allowed);
    event DepositLimitsUpdated(address indexed token, uint256 maxDeposit, uint256 depositCap);
    event PauseUpdated(address indexed account, bool paused);
    event WithdrawalPauseUpdated(address indexed account, bool paused);

    // ---- Modifiers ----
    /// @dev Blocks the ways value enters or moves inside the pool.
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    /// @dev Guards the exit path. Driven by a separate flag so the ordinary pause
    ///      never locks user funds in; see `setWithdrawalsPaused`.
    modifier whenWithdrawalsNotPaused() {
        if (withdrawalsPaused) revert WithdrawalsArePaused();
        _;
    }

    // ---- Constructor ----
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 _virtualChainId, address _uniswapV2Router) {
        _disableInitializers();
        VIRTUAL_CHAIN_ID = _virtualChainId;
        UNISWAP_V2_ROUTER = _uniswapV2Router;
    }

    // ---- Initializer ----
    /**
     * @notice Initialize the contract (called once through proxy)
     * @param _shieldedTransferVerifier Address of the shielded transfer verifier
     * @param _shieldedWithdrawalVerifier Address of the shielded withdrawal verifier
     * @param _shieldedSwapVerifier Address of the shielded swap verifier
     * @param _guard Address of the deposit guard
     * @param _upgradeController Address of the upgrade controller
     */
    function initialize(
        address _shieldedTransferVerifier,
        address _shieldedWithdrawalVerifier,
        address _shieldedSwapVerifier,
        address _guard,
        address _upgradeController
    ) external initializer {
        if (_shieldedTransferVerifier == address(0)) revert ZeroAddress();
        if (_shieldedWithdrawalVerifier == address(0)) revert ZeroAddress();
        if (_shieldedSwapVerifier == address(0)) revert ZeroAddress();
        if (_guard == address(0)) revert ZeroAddress();
        if (_upgradeController == address(0)) revert ZeroAddress();
        shieldedTransferVerifier = _shieldedTransferVerifier;
        shieldedWithdrawalVerifier = _shieldedWithdrawalVerifier;
        shieldedSwapVerifier = _shieldedSwapVerifier;
        guard = _guard;
        upgradeController = _upgradeController;
    }

    // ---- Ether handling ----
    receive() external payable {
        // Don't auto-deposit when receiving ETH from Uniswap router (during swaps)
        if (msg.sender != UNISWAP_V2_ROUTER) {
            deposit(msg.value, address(0));
        }
    }

    function deposit() external payable {
        deposit(msg.value, address(0));
    }

    // ---- Note operations ----
    function _addNote(bytes32 noteCommitment, bytes32[9] memory noteCiphertext) internal {
        uint256 commitment = uint256(noteCommitment);
        _noteTree.insert(_noteTreeRoots, commitment);
        uint256 index = _noteTree.size() - 1;
        emit NoteAdded(index, noteCommitment, noteCiphertext);
    }

    function _addNotes(
        bytes32[] memory noteCommitments,
        bytes32[9][] memory noteCiphertexts
    ) internal {
        uint256 startIndex = _noteTree.size();
        uint256[] memory commitments = new uint256[](noteCommitments.length);
        for (uint256 i = 0; i < noteCommitments.length;) {
            commitments[i] = uint256(noteCommitments[i]);
            unchecked { ++i; }
        }
        _noteTree.insertMany(_noteTreeRoots, commitments);
        for (uint256 i = 0; i < noteCommitments.length;) {
            emit NoteAdded(startIndex + i, noteCommitments[i], noteCiphertexts[i]);
            unchecked { ++i; }
        }
    }

    function _spendNotes(bytes32[6] calldata noteNullifiers) internal {
        for (uint256 i = 0; i < 6; i++) {
            if (noteNullifiers[i] != bytes32(0)) _spendNote(noteNullifiers[i]);
        }
    }

    function _spendNote(bytes32 noteNullifier) internal {
        uint256 nullifierHash = uint256(noteNullifier);
        if (noteNullifiers[nullifierHash]) revert NullifierAlreadySpent();
        noteNullifiers[nullifierHash] = true;
        emit NoteSpent(noteNullifier);
    }

    function _addDepositNote(
        uint256 rkHash,
        uint256 amount,
        address token,
        uint256 valueCommitmentTrapdoor,
        uint256 depositIndex
    ) internal {
        bytes32 commitment = _commitNote(
            _commitNoteRkHash(rkHash, 0), 
            _commitNoteValue(amount, token, valueCommitmentTrapdoor),
            depositIndex // unique value replacing nullifierdHash
        );
        // Fields 0-3 are header (epk.x, epk.y, encrypted_secret, tag) - zero for deposits
        // Fields 4-8: owner_hash, rkTrapdoor, value, coinId, valueTrapdoor
        bytes32[9] memory ciphertext;
        ciphertext[4] = bytes32(rkHash);
        // ciphertext[5] = 0;
        ciphertext[6] = bytes32(amount);
        ciphertext[7] = bytes32(uint256(uint160(token)));
        ciphertext[8] = bytes32(valueCommitmentTrapdoor);
        _addNote(commitment, ciphertext);
    }

    // ---- Receiving key operations ----
    function registerReceivingKey(ReceivingKey calldata rk) public {
        // Scoped so the validation locals do not stay live across the 9-argument event
        // emission below, which would otherwise blow the stack.
        {
            bytes memory pubKey = abi.encodePacked(rk.pkX, rk.pkY);
            bytes32 hash = keccak256(pubKey);
            address derivedAddress = address(uint160(uint256(hash)));
            if (derivedAddress != msg.sender) {
                revert NotAccountOwner(msg.sender, derivedAddress);
            }

            // Verify keyData contains the correct address (first 20 bytes)
            address keyDataAddress = address(bytes20(rk.keyData));
            if (keyDataAddress != derivedAddress) {
                revert KeyDataAddressMismatch(keyDataAddress, derivedAddress);
            }
        }

        uint256 rkHash = _computeRkHash(rk);
        uint256 currentHash = _addressToReceivingKeyHash[msg.sender];

        // Idempotent on re-registration. Receiving keys are derived deterministically
        // from the owner's signature, so calling this twice yields the same leaf, and the
        // second call used to revert with LeafAlreadyExists raised deep inside the tree
        // library - an opaque failure for an already-registered user, and one that made
        // registerReceivingKeyAndDeposit usable exactly once (NEW-7). Nothing has changed
        // here, so there is nothing to insert, index or announce.
        if (currentHash == rkHash) return;

        // Anything past the first key is a rotation, and rotations are rate limited (F6).
        // pnk, ekX and ekY are free parameters, so without a limit one address could mint
        // an unbounded number of distinct leaves and grow the registry until it hits
        // MAX_TREE_DEPTH, at which point nobody can register at all. Flatly forbidding a
        // second registration would be the obvious fix and the wrong one: the client is
        // about to gain deliberate key rotation (F16), so the operation has to stay
        // available - just not for free and not in a loop.
        if (currentHash != 0) {
            uint256 availableAt = receivingKeyUpdatedAt[msg.sender] + KEY_ROTATION_COOLDOWN;
            if (block.timestamp < availableAt) revert KeyRotationTooSoon(availableAt);
        }

        // Replaces the caller's entry rather than adding a second one, so deposits and
        // transfers resolve to the new key immediately.
        _addressToReceivingKeyHash[msg.sender] = rkHash;
        receivingKeyUpdatedAt[msg.sender] = block.timestamp;

        // The superseded leaf stays in the registry: the tree is append-only and removing
        // a leaf is not possible, so an old key remains provably registered forever. That
        // is a property of the registry, not a regression - it holds for every root the
        // tree has ever had. Choosing the *current* key of a recipient is, and always was,
        // the sender's job off-chain; F16 is the client-side half of this.
        _keyRegistryTree.insert(_keyRegistryTreeRoots, rkHash);

        uint256 index = _keyRegistryIndex;
        _keyRegistryIndex += 1;

        emit ReceivingKeyRegistered(msg.sender, index, rkHash, rk.pkX, rk.pkY, rk.keyData, rk.pnk, rk.ekX, rk.ekY);
        if (currentHash != 0) emit ReceivingKeyRotated(msg.sender, currentHash, rkHash);
    }

    /// @notice Earliest timestamp at which `account` may register a different key.
    /// @dev Zero for an address that has never registered: the first key is not rate limited.
    function receivingKeyRotatableAt(address account) external view returns (uint256) {
        if (_addressToReceivingKeyHash[account] == 0) return 0;
        return receivingKeyUpdatedAt[account] + KEY_ROTATION_COOLDOWN;
    }

    // ---- Deposit operations ----
    function deposit(uint256 amount, address token) public payable returns (uint256) {
        return depositTo(msg.sender, amount, token);
    }

    function depositTo(address recipient, uint256 amount, address token)
        public
        payable
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        // Verify receiving key exists
        if (_addressToReceivingKeyHash[recipient] == 0) revert ReceivingKeyNotFound(recipient);
        // Check token is whitelisted
        if (tokenWhitelist[token] == TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(token);

        uint256 gasEscrow;
        uint256 poolBalance;
        if (token == address(0)) {
            // ETH deposit: msg.value = amount + gasEscrow
            if (msg.value < amount) revert InsufficientValue();
            gasEscrow = msg.value - amount;
            // msg.value is already part of the balance at this point
            poolBalance = address(this).balance;
        } else {
            // ERC20 deposit: msg.value = gasEscrow only
            gasEscrow = msg.value;
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            poolBalance = IERC20(token).balanceOf(address(this));
            amount = poolBalance - balanceBefore;
        }

        _checkDepositLimits(token, amount, poolBalance);

        uint256 index = _depositIndex;
        _depositIndex += 1;

        // Store hash of pending deposit data including gasEscrow - commitment computed at approval time
        pendingDepositHashes[index] = _computeDepositHash(recipient, token, amount, msg.sender, gasEscrow);

        emit DepositPending(index, recipient, token, amount, msg.sender, gasEscrow);
        return index;
    }

    function registerReceivingKeyAndDeposit(uint256 amount, address token, ReceivingKey calldata rk)
        external
        payable
        returns (uint256)
    {
        registerReceivingKey(rk);
        return deposit(amount, token);
    }

    // ---- Access control helpers ----
    /// @dev True when the caller is authorized by the upgrade controller (the admin role).
    function _isAdmin() internal view returns (bool) {
        return IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0));
    }

    /// @dev Current guard or admin. Reserved for the emergency pause only.
    ///      Anything that changes WHO holds power (setGuard, setRelayer, setVerifiers,
    ///      setWhitelistManager, setUpgradeController) must use `_requireAdmin` instead:
    ///      the guard key is a hot key living in a server environment variable, and a guard
    ///      able to appoint a new guard would let a single compromised key walk around the
    ///      admin multisig entirely.
    function _requireGuardOrAdmin() internal view {
        if (msg.sender != guard && !_isAdmin()) revert NotGuard(msg.sender);
    }

    /// @dev Admin only (upgrade controller).
    function _requireAdmin() internal view {
        if (!_isAdmin()) revert UpgradeNotAuthorized(msg.sender);
    }

    /// @dev The whitelist manager, or the admin standing in for it.
    function _requireWhitelistManager() internal view {
        if (msg.sender != whitelistManager && !_isAdmin()) revert NotWhitelistManager(msg.sender);
    }

    // ---- Guard operations ----
    /// @dev Admin only. The guard deliberately cannot replace itself: it is a hot key, and
    ///      letting it appoint a successor would hand a single compromised key the guard role
    ///      (approveDeposit plus the whole gas escrow) without ever touching the admin multisig.
    function setGuard(address newGuard) external {
        _requireAdmin();
        emit GuardUpdated(guard, newGuard);
        guard = newGuard;
    }

    // ---- Relayer allowlist (F8) ----
    /**
     * @notice Allow or disallow a relayer to submit fee-paying shielded operations.
     * @dev Admin only. Adding a relayer is planned work, never an emergency, so it does not
     *      need the hot guard key — and a compromised guard able to allowlist itself would
     *      collect every relay fee in the protocol.
     *      The fee recipient is not bound into the proof, so without this list anyone
     *      could pick a (params, proof) pair out of the mempool, land it first and
     *      collect the fee, reverting the relayer's own transaction.
     * @param relayer The relayer address
     * @param allowed Whether the relayer may collect fees
     */
    function setRelayer(address relayer, bool allowed) external {
        _requireAdmin();
        if (relayer == address(0)) revert ZeroAddress();
        allowedRelayers[relayer] = allowed;
        emit RelayerUpdated(relayer, allowed);
    }

    /// @dev Reverts unless a fee-paying operation is submitted by an allowlisted relayer.
    ///      Fee-less operations stay permissionless: that is the escape hatch a user
    ///      needs when every relayer refuses to carry their transaction.
    function _requireRelayer(bytes32 fee) internal view {
        if (uint256(fee) != 0 && !allowedRelayers[msg.sender]) revert NotRelayer(msg.sender);
    }

    // ---- Deposit limits ----
    /**
     * @notice Set the per-token deposit size limit and the pool-wide cap for a token.
     * @dev Admin only. A value of 0 means "no limit", which is also the default, so a
     *      fresh deployment (or an upgrade that reads these slots as zero) behaves
     *      exactly as before until the limits are switched on at launch.
     *      To stop deposits of a token entirely, de-whitelist it instead.
     * @param token Token address (address(0) for native ETH)
     * @param maxDepositAmount Largest single deposit accepted, 0 for no limit
     * @param poolCap Largest total balance the pool may hold for this token, 0 for no limit
     */
    function setDepositLimits(address token, uint256 maxDepositAmount, uint256 poolCap) external {
        _requireAdmin();
        maxDeposit[token] = maxDepositAmount;
        depositCap[token] = poolCap;
        emit DepositLimitsUpdated(token, maxDepositAmount, poolCap);
    }

    /// @dev Enforces both deposit limits. `poolBalance` is the balance already
    ///      including the incoming funds, so the cap is checked against the post-state.
    function _checkDepositLimits(address token, uint256 amount, uint256 poolBalance) internal view {
        uint256 limit = maxDeposit[token];
        if (limit != 0 && amount > limit) revert DepositTooLarge(token, amount, limit);
        uint256 cap = depositCap[token];
        if (cap != 0 && poolBalance > cap) revert DepositCapExceeded(token, poolBalance, cap);
    }

    // ---- Pause ----
    /**
     * @notice Halt deposits, shielded transfers and shielded swaps.
     * @dev Same access control as `setGuard` (guard or admin) so the hot monitoring key
     *      can react without touching the upgrade key. Withdrawals are NOT affected.
     */
    function setPaused(bool _paused) external {
        _requireGuardOrAdmin();
        paused = _paused;
        emit PauseUpdated(msg.sender, _paused);
    }

    /**
     * @notice Emergency switch that also halts shielded withdrawals.
     * @dev Admin only: this is the only control that can keep user funds inside the
     *      pool, so it is deliberately harder to reach than `setPaused`. It exists for
     *      the one case where leaving the exit open is wrong - an in-progress drain.
     */
    function setWithdrawalsPaused(bool _paused) external {
        _requireAdmin();
        withdrawalsPaused = _paused;
        emit WithdrawalPauseUpdated(msg.sender, _paused);
    }

    /// @dev Admin only, like `setGuard`. The whitelist manager is the lower-trust role - a key
    ///      an operator or a bot holds to curate tokens - and letting it appoint its own
    ///      successor turns one compromised operator key into permanent control of what may
    ///      enter the pool. Curating the list stays with the manager below; handing out the
    ///      role does not.
    function setWhitelistManager(address newWhitelistManager) external {
        _requireAdmin();
        emit WhitelistManagerUpdated(whitelistManager, newWhitelistManager);
        whitelistManager = newWhitelistManager;
    }

    /// @dev Manager or admin: curating the token list is the manager's actual job.
    function setTokenWhitelist(address token, TokenType tokenType) external {
        _requireWhitelistManager();
        tokenWhitelist[token] = tokenType;
        emit TokenWhitelistUpdated(token, tokenType);
    }

    /// @dev Manager or admin, as `setTokenWhitelist`.
    function setTokenWhitelistBatch(address[] calldata tokens, TokenType[] calldata tokenTypes) external {
        _requireWhitelistManager();
        if (tokens.length != tokenTypes.length) revert LengthMismatch();
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenWhitelist[tokens[i]] = tokenTypes[i];
            emit TokenWhitelistUpdated(tokens[i], tokenTypes[i]);
        }
    }

    function setVerifiers(
        address _shieldedTransferVerifier,
        address _shieldedWithdrawalVerifier,
        address _shieldedSwapVerifier
    ) external {
        _requireAdmin();
        if (_shieldedTransferVerifier == address(0)) revert ZeroAddress();
        if (_shieldedWithdrawalVerifier == address(0)) revert ZeroAddress();
        if (_shieldedSwapVerifier == address(0)) revert ZeroAddress();
        shieldedTransferVerifier = _shieldedTransferVerifier;
        shieldedWithdrawalVerifier = _shieldedWithdrawalVerifier;
        shieldedSwapVerifier = _shieldedSwapVerifier;
        emit VerifiersUpdated(_shieldedTransferVerifier, _shieldedWithdrawalVerifier, _shieldedSwapVerifier);
    }

    function approveDeposit(
        uint256 index,
        address recipient,
        address token,
        uint256 amount,
        address depositor,
        uint256 gasEscrow,
        uint256 revocationPublicKeyX,
        uint256 revocationPublicKeyY,
        uint256 revocationPublicKeyHash
    ) external nonReentrant {
        if (msg.sender != guard) revert NotGuard(msg.sender);

        // Validate deposit data
        bytes32 storedHash = pendingDepositHashes[index];
        if (storedHash == bytes32(0)) revert DepositNotPending(index);
        if (storedHash != _computeDepositHash(recipient, token, amount, depositor, gasEscrow)) {
            revert InvalidDepositData();
        }

        delete pendingDepositHashes[index];

        // Compute and store note
        uint256 rkHash = _addressToReceivingKeyHash[recipient];
        _addDepositNote(
            rkHash, amount, token, revocationPublicKeyHash, index
        );

        emit DepositStatusChanged(index, DepositStatus.APPROVED);
        emit Deposit(index, recipient, token, amount, revocationPublicKeyX, revocationPublicKeyY);

        // Pay entire gas escrow to guard
        _transferAsset(address(0), msg.sender, gasEscrow);
    }

    function rejectDeposit(
        uint256 index,
        address recipient,
        address token,
        uint256 amount,
        address depositor,
        uint256 gasEscrow
    ) external nonReentrant {
        if (msg.sender != guard) revert NotGuard(msg.sender);

        bytes32 storedHash = pendingDepositHashes[index];
        if (storedHash == bytes32(0)) revert DepositNotPending(index);
        if (storedHash != _computeDepositHash(recipient, token, amount, depositor, gasEscrow)) {
            revert InvalidDepositData();
        }

        delete pendingDepositHashes[index];

        _transferAsset(token, depositor, amount);

        emit DepositStatusChanged(index, DepositStatus.REJECTED);

        // Pay entire gas escrow to guard
        _transferAsset(address(0), msg.sender, gasEscrow);
    }

    function withdrawPendingDeposit(uint256 index, address recipient, address token, uint256 amount, uint256 gasEscrow)
        external
        nonReentrant
    {
        // Verify caller is original depositor via hash
        bytes32 storedHash = pendingDepositHashes[index];
        if (storedHash == bytes32(0)) revert DepositNotPending(index);
        if (storedHash != _computeDepositHash(recipient, token, amount, msg.sender, gasEscrow)) {
            revert NotDepositor(msg.sender);
        }

        // Clear storage before external call (reentrancy protection)
        delete pendingDepositHashes[index];

        // Refund depositor (deposit + gas escrow)
        _transferAsset(token, msg.sender, amount);
        _transferAsset(address(0), msg.sender, gasEscrow);

        emit DepositStatusChanged(index, DepositStatus.REVERTED);
    }

    // ---- Upgrade operations ----
    /**
     * @notice Set a new upgrade controller
     * @dev Can only be called by the current upgrade controller.
     *      This allows upgrading from admin-only to timelock/multisig.
     * @param newController Address of the new upgrade controller
     */
    function setUpgradeController(address newController) external {
        if (msg.sender != upgradeController) revert NotUpgradeController(msg.sender);
        if (newController == address(0)) revert ZeroAddress();
        emit UpgradeControllerUpdated(upgradeController, newController);
        upgradeController = newController;
    }

    /**
     * @notice Authorization check for UUPS upgrades
     * @dev Delegates to the upgrade controller to check permissions
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal view override {
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, newImplementation)) {
            revert UpgradeNotAuthorized(msg.sender);
        }
    }

    // ---- Shielded Transfer ----
    function shieldedTransfer(ShieldedTransferParams calldata params, bytes calldata proof)
        external
        nonReentrant
        whenNotPaused
    {
        _requireRelayer(params.fee);
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);
        if (!isKnownKeyRegistryRoot(uint256(params.rkRoot))) revert InvalidKeyRegistryRoot(params.rkRoot);

        // 46 and 1440 are hand-counted from ShieldedTransferParams and the compiler does not
        // know about either. Change the struct without changing them and every proof starts
        // failing with a bare InvalidProof that points nowhere (NEW-9). test/PublicInputLayout.ts
        // recomputes both from the ABI and says exactly which number to fix.
        bytes32[] memory publicInputs = new bytes32[](46);
        publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
        assembly {
            calldatacopy(add(publicInputs, 0x40), 4, 1440) // 45 * 32, offset 4 (after selector)
        }
        _validatePublicInputs(publicInputs);

        if (!IVerifierV1(shieldedTransferVerifier).verify(proof, publicInputs)) revert InvalidProof();

        _spendNotes(params.noteNullifiers);
        txNullifiers[params.txNullifier] = true;

        bytes32[] memory commitments = new bytes32[](3);
        commitments[0] = params.noteOutCommitment;
        commitments[1] = params.noteChangeCommitment;
        commitments[2] = params.noteFeeChangeCommitment;
        bytes32[9][] memory ciphertexts = new bytes32[9][](3);
        ciphertexts[0] = params.ciphertextOut;
        ciphertexts[1] = params.ciphertextChange;
        ciphertexts[2] = params.ciphertextFeeChange;
        _addNotes(commitments, ciphertexts);

        _transferAsset(_toAddress(params.feeTokenAddress), msg.sender, uint256(params.fee));

        emit ShieldedTransfer(
            params.txNullifier,
            params.nullifiersHash,
            params.noteOutCommitment,
            params.noteChangeCommitment,
            params.noteFeeChangeCommitment,
            uint256(params.fee),
            _toAddress(params.feeTokenAddress)
        );
    }

    // ---- Shielded Withdrawal ----
    function shieldedWithdrawal(ShieldedWithdrawalParams calldata params, bytes calldata proof)
        external
        nonReentrant
        whenWithdrawalsNotPaused
    {
        _requireRelayer(params.fee);
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);

        // Hand-counted from ShieldedWithdrawalParams; see test/PublicInputLayout.ts (NEW-9).
        bytes32[] memory publicInputs = new bytes32[](38);
        publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
        assembly {
            calldatacopy(add(publicInputs, 0x40), 4, 1184) // 37 * 32, offset 4 (after selector)
        }
        _validatePublicInputs(publicInputs);

        if (!IVerifierV1(shieldedWithdrawalVerifier).verify(proof, publicInputs)) revert InvalidProof();

        _spendNotes(params.noteNullifiers);
        txNullifiers[params.txNullifier] = true;

        // One batched insert, like shieldedTransfer and shieldedSwap already do. Two
        // separate inserts produced the same tree but walked it twice and recorded an
        // intermediate root nobody could ever build a proof against (NEW-4).
        bytes32[] memory commitments = new bytes32[](2);
        commitments[0] = params.noteChangeCommitment;
        commitments[1] = params.noteFeeChangeCommitment;
        bytes32[9][] memory ciphertexts = new bytes32[9][](2);
        ciphertexts[0] = params.ciphertextChange;
        ciphertexts[1] = params.ciphertextFeeChange;
        _addNotes(commitments, ciphertexts);

        _transferAsset(_toAddress(params.feeTokenAddress), msg.sender, uint256(params.fee));
        _transferAsset(_toAddress(params.coinId), _toAddress(params.recipientAddress), uint256(params.value));

        _emitWithdrawal(params);
    }

    function _emitWithdrawal(ShieldedWithdrawalParams calldata params) internal {
        emit ShieldedWithdrawal(
            params.txNullifier,
            params.nullifiersHash,
            params.noteChangeCommitment,
            params.noteFeeChangeCommitment,
            _toAddress(params.recipientAddress),
            uint256(params.value),
            _toAddress(params.coinId),
            uint256(params.fee),
            _toAddress(params.feeTokenAddress)
        );
    }

    // ---- Shielded Swap ----

    // Check if any token in the path may be a fee-on-transfer token.
    // Unknown/forbidden tokens are assumed to be taxed (safe default).
    function _pathHasFeeOnTransferToken(address[] memory path) internal view returns (bool) {
        for (uint256 i = 0; i < path.length; i++) {
            TokenType tt = tokenWhitelist[path[i]];
            if (tt != TokenType.ERC20 && tt != TokenType.NATIVE_TOKEN) return true;
        }
        return false;
    }

    // Internal helper to execute Uniswap swap and return amountOut (using delta-accounting)
    function _executeSwap(
        bytes4 selector,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline
    ) internal returns (uint256) {
        bool feeOnTransfer = _pathHasFeeOnTransferToken(path);

        // Determine output asset for balance snapshot
        bool outputIsETH = (selector == bytes4(0x18cbafe5));
        address outputToken = outputIsETH ? address(0) : path[path.length - 1];

        // Check that the output token is whitelisted
        if (tokenWhitelist[outputToken] == TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(outputToken);

        // Snapshot balance before swap
        uint256 balanceBefore = outputIsETH
            ? address(this).balance
            : IERC20(outputToken).balanceOf(address(this));

        if (selector == bytes4(0x38ed1739)) {
            // swapExactTokensForTokens
            IERC20(path[0]).forceApprove(UNISWAP_V2_ROUTER, amountIn);
            if (feeOnTransfer) {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
            } else {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
            }
        } else if (selector == bytes4(0x7ff36ab5)) {
            // swapExactETHForTokens
            if (feeOnTransfer) {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                );
            } else {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                );
            }
        } else if (selector == bytes4(0x18cbafe5)) {
            // swapExactTokensForETH
            IERC20(path[0]).forceApprove(UNISWAP_V2_ROUTER, amountIn);
            if (feeOnTransfer) {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
            } else {
                IUniswapV2RouterV1(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
            }
        } else {
            revert InvalidSwapSelector();
        }

        // Measure actual output via balance delta
        uint256 balanceAfter = outputIsETH
            ? address(this).balance
            : IERC20(outputToken).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function shieldedSwap(ShieldedSwapParams calldata params, bytes calldata proof)
        external
        nonReentrant
        whenNotPaused
    {
        _requireRelayer(params.fee);
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);

        // Bound how far ahead the router deadline may sit, so the proof cannot be
        // held back and executed at an arbitrarily later, more profitable moment.
        uint256 deadline = uint256(params.routerArgs.deadline);
        uint256 maxDeadline = block.timestamp + MAX_SWAP_DEADLINE;
        if (deadline > maxDeadline) revert DeadlineTooFar(deadline, maxDeadline);

        // A zero floor tells the router "any output will do", which hands a
        // sandwich the entire value of the swap: move the price, let this
        // execute against it, move it back. Nobody consents to that on purpose,
        // so it is refused here rather than trusted to the caller (F7).
        //
        // This does not stop sandwiching by itself. A floor checked against the
        // pool at execution time would be worthless - by then the attacker has
        // already moved the price and the contract would read their quote. What
        // actually defends the user is the floor their client computes from an
        // honest quote, and keeping the transaction out of the public mempool
        // (CW-16). This only removes the case where there is no floor at all.
        if (uint256(params.routerArgs.amountOutMin) == 0) revert ZeroAmountOutMin();

        // Verify ZK proof (50 public inputs for shielded swap)
        {
            // Hand-counted from ShieldedSwapParams; see test/PublicInputLayout.ts (NEW-9).
            // Two contract-supplied inputs here, hence the 0x60 destination rather than 0x40.
            bytes32[] memory publicInputs = new bytes32[](52);
            publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
            publicInputs[1] = bytes32(uint256(uint160(UNISWAP_V2_ROUTER)));
            assembly {
                calldatacopy(add(publicInputs, 0x60), 4, 1600) // 50 * 32, offset 4 (after selector)
            }
            _validatePublicInputs(publicInputs);
            if (!IVerifierV1(shieldedSwapVerifier).verify(proof, publicInputs)) revert InvalidProof();
        }

        // Spend input notes (skip zero nullifiers from dummy notes)
        _spendNotes(params.noteNullifiers);
        txNullifiers[params.txNullifier] = true;

        // Execute swap, add notes, pay fee and emit event
        SwapResult memory result = _executeSwapAndAddNotes(params);

        bytes32[] memory commitments = new bytes32[](3);
        commitments[0] = result.noteOutCommitment;
        commitments[1] = params.noteChangeCommitment;
        commitments[2] = params.noteFeeChangeCommitment;
        bytes32[9][] memory ciphertexts = new bytes32[9][](3);
        ciphertexts[0] = result.noteOutCiphertext;
        ciphertexts[1] = params.ciphertextChange;
        ciphertexts[2] = params.ciphertextFeeChange;
        _addNotes(commitments, ciphertexts);

        // Pay relayer fee
        _transferAsset(_toAddress(params.feeTokenAddress), msg.sender, uint256(params.fee));

        // Emit event using helper to reduce stack pressure
        _emitSwap(params, result);
    }

    function _executeSwapAndAddNotes(ShieldedSwapParams calldata params) internal returns (SwapResult memory result) {
        // Build path array from fixed-size path
        uint256 pathLength = uint256(params.routerArgs.pathLength);
        address[] memory path = new address[](pathLength);
        for (uint256 i = 0; i < pathLength; i++) {
            path[i] = _toAddress(params.routerArgs.path[i]);
        }

        // Execute swap (selector is stored as a field element, extract lower 4 bytes)
        bytes4 selector = bytes4(uint32(uint256(params.selector)));
        result.amountOut = _executeSwap(
            selector,
            uint256(params.routerArgs.amountIn),
            uint256(params.routerArgs.amountOutMin),
            path,
            uint256(params.routerArgs.deadline)
        );
        result.amountIn = uint256(params.routerArgs.amountIn);

        // Determine input token: for swapExactETHForTokens (0x7ff36ab5), input is ETH (address 0)
        result.inputToken = (selector == bytes4(0x7ff36ab5)) ? address(0) : path[0];
        // Determine output token: for swapExactTokensForETH (0x18cbafe5), output is ETH (address 0)
        result.outputToken = (selector == bytes4(0x18cbafe5)) ? address(0) : path[pathLength - 1];

        // Compute and add swap output note (receivingKeyCommitment is already poseidon2([rk_hash, trapdoor]) from circuit)
        result.noteOutCommitment = _commitNote(
            uint256(params.receivingKeyCommitment),
            _commitNoteValue(result.amountOut, result.outputToken, 0),
            uint256(params.nullifiersHash)
        );

        // Combine circuit's half-ciphertext with swap output values
        // Circuit provides ciphertextSwap[0:6] = [epk.x, epk.y, encrypted_secret, tag, owner_hash, rkTrapdoor]
        // Contract adds [6] = value, [7] = coinId, [8] = valueTrapdoor (=0 for swaps)
        for (uint256 i = 0; i < 6; i++) {
            result.noteOutCiphertext[i] = params.ciphertextSwap[i];
        }
        result.noteOutCiphertext[6] = bytes32(result.amountOut);
        result.noteOutCiphertext[7] = bytes32(uint256(uint160(result.outputToken)));
        // result.noteOutCiphertext[8] = 0 by default (valueTrapdoor = 0 for swaps)
    }

    function _emitSwap(ShieldedSwapParams calldata params, SwapResult memory result) internal {
        emit ShieldedSwap(
            params.txNullifier,
            params.nullifiersHash,
            result.noteOutCommitment,
            params.noteChangeCommitment,
            params.noteFeeChangeCommitment,
            result.amountIn,
            result.inputToken,
            result.amountOut,
            result.outputToken,
            uint256(params.fee),
            _toAddress(params.feeTokenAddress)
        );
    }

    // ---- Internal Helpers ----

    function _computeDepositHash(address recipient, address token, uint256 amount, address depositor, uint256 gasEscrow)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(recipient, token, amount, depositor, gasEscrow));
    }

    function _transferAsset(address token, address recipient, uint256 amount) internal {
        if (amount == 0) return;
        if (token == address(0)) {
            (bool ok,) = recipient.call{value: amount}("");
            if (!ok) revert ETHTransferFailed(recipient, amount);
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function _toAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function _validatePublicInputs(bytes32[] memory inputs) internal pure {
        for (uint256 i = 0; i < inputs.length; i++) {
            if (uint256(inputs[i]) >= FIELD_MODULUS) revert PublicInputNotInField();
        }
    }

    // ---- Internal Note Commitment Helpers ----

    /// @notice Rejects a note encryption key that is not a point of the Grumpkin curve.
    /// @dev registerReceivingKey proves that `pkX/pkY` hash to `msg.sender` and that `keyData`
    ///      carries the same address, but `pnk`, `ekX` and `ekY` used to be accepted on nothing
    ///      but a range check. Two consequences, both silent:
    ///
    ///      1. Theft. A dishonest proxy could hand the client the victim's real `pkX/pkY`
    ///         together with its *own* `ekX/ekY`; registration succeeded and every later deposit
    ///         to that address was encrypted to the attacker. (The audit filed this as CW-12 and
    ///         called it mitigated because "the contract guarantees correctness" - it did not.
    ///         web/packages/core-ui/src/hooks/use-verify-receiving-key.ts covers the app; this
    ///         covers everyone who registers by any other route.)
    ///      2. Burning. Garbage that is merely in-field is not a curve point, so no secret `ek`
    ///         exists for it. A sender encrypts honestly, the note lands in the tree, the money
    ///         is gone and nobody can ever decrypt it. Neither the contract nor the circuit
    ///         noticed: circuits/lib/src/note.nr builds an EmbeddedCurvePoint straight from the
    ///         raw coordinates.
    ///
    ///      The curve equation does not (and cannot) prove that the registrant knows the matching
    ///      secret, so case 1 is narrowed - an attacker must substitute a key it controls rather
    ///      than any 32 bytes - not closed. Case 2 is closed outright.
    ///
    ///      Point at infinity: Grumpkin has `b = -17 != 0`, so `(0,0)` fails `y^2 = x^3 + b` and
    ///      is rejected by the equation itself - no special case needed, and rejecting it is what
    ///      we want, since the identity as an encryption key makes every DH shared secret the
    ///      identity too. Noir's affine `EmbeddedCurvePoint` has no other encoding for infinity.
    ///      Small subgroups are a non-issue: Grumpkin has prime order (cofactor 1), so on-curve
    ///      plus non-identity is the complete check.
    /// @param ekX X coordinate, already known to be < FIELD_MODULUS by the caller.
    /// @param ekY Y coordinate, already known to be < FIELD_MODULUS by the caller.
    function _requireEncryptionKeyOnCurve(bytes32 ekX, bytes32 ekY) internal pure {
        uint256 x = uint256(ekX);
        uint256 y = uint256(ekY);
        uint256 lhs = mulmod(y, y, FIELD_MODULUS);
        uint256 rhs = addmod(mulmod(mulmod(x, x, FIELD_MODULUS), x, FIELD_MODULUS), GRUMPKIN_B, FIELD_MODULUS);
        if (lhs != rhs) revert EncryptionKeyNotOnCurve(ekX, ekY);
    }

    function _computeRkHash(ReceivingKey memory rk) internal pure returns (uint256) {
        // Pack [pkX (32), pkY (32), keyData[0:29]] = 93 bytes into 3 field elements (31 bytes each)
        bytes memory combined = abi.encodePacked(rk.pkX, rk.pkY, bytes29(rk.keyData));
        uint256[] memory fields = new uint256[](6);
        for (uint256 i = 0; i < 3; i++) {
            uint256 offset = i * 31;
            uint256 value = 0;
            for (uint256 j = 0; j < 31; j++) {
                value += uint256(uint8(combined[offset + j])) << (8 * j);
            }
            fields[i] = value;
        }
        if (uint256(rk.pnk) >= FIELD_MODULUS || uint256(rk.ekX) >= FIELD_MODULUS || uint256(rk.ekY) >= FIELD_MODULUS) {
            revert InvalidReceivingKey();
        }
        // Only reached from registerReceivingKey, so this is where every piece of key
        // material a sender will later encrypt to gets validated.
        //
        // pnk deliberately gets nothing beyond the range check above, and never will:
        // pnk = poseidon2([nk]) where nk is the owner's secret nullifier key. Any field
        // element is a possible Poseidon2 image, so there is no structure to test, and the
        // only thing worth proving - that the registrant knows the nk behind it - is a
        // preimage claim the chain cannot check without the secret. A wrong pnk breaks the
        // owner's own ability to spend, not anyone else's funds; it is not a theft vector,
        // and the client is the only place it can be caught. Do not go looking for an
        // on-chain check here.
        _requireEncryptionKeyOnCurve(rk.ekX, rk.ekY);
        fields[3] = uint256(rk.pnk);
        fields[4] = uint256(rk.ekX);
        fields[5] = uint256(rk.ekY);
        return Poseidon2T4Unrolled.hashMany(fields);
    }

    function _commitNoteRkHash(uint256 rkHash, uint256 rkTrapdoor) internal pure returns (uint256) {
        return Poseidon2T4Unrolled.hash2(rkHash, rkTrapdoor);
    }

    function _commitNoteValue(uint256 value, address coinId, uint256 valueTrapdoor) internal pure returns (uint256) {
        return Poseidon2T4Unrolled.hash3(value, uint256(uint160(coinId)), valueTrapdoor);
    }

    function _commitNote(uint256 rkCommitment, uint256 valueCommitment, uint256 nullifiersHash)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(Poseidon2T4Unrolled.hash3(rkCommitment, valueCommitment, nullifiersHash));
    }

    // ---- State views ----

    // NOTE: `ROOT_HISTORY_SIZE()`, `noteTreeRoots(uint256)` and `noteTreeRootIndex()`
    // were removed together with the circular buffer they described. Keeping them would
    // have meant three getters reporting a window that no longer exists and an index
    // frozen at zero; `isKnownNoteTreeRoot` answers the only question they were used for.

    function MAX_TREE_DEPTH() external pure returns (uint32) {
        return Constants.maxTreeDepth();
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

    function keyRegistryRoot() external view returns (uint256) {
        return _keyRegistryTree.root();
    }

    function keyRegistrySize() external view returns (uint256) {
        return _keyRegistryTree.size();
    }

    /// @notice True if the note tree ever had this root. Any historical root is accepted:
    ///         the tree is append-only, so membership under an old root still holds, and
    ///         double spends are stopped by the nullifier rather than by root freshness.
    function isKnownNoteTreeRoot(uint256 _root) public view returns (bool) {
        return _noteTreeRoots.isKnownRoot(_root);
    }

    /// @notice True if the key registry tree ever had this root. See above.
    function isKnownKeyRegistryRoot(uint256 _root) public view returns (bool) {
        return _keyRegistryTreeRoots.isKnownRoot(_root);
    }

    function isNoteInTree(uint256 _leaf) public view returns (bool) {
        return _noteTree.has(_leaf);
    }

    function isReceivingKeyRegistered(uint256 _leaf) public view returns (bool) {
        return _keyRegistryTree.has(_leaf);
    }

    function hasReceivingKey(address account) external view returns (bool) {
        return _addressToReceivingKeyHash[account] != 0;
    }
}
