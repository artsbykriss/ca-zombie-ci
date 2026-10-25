// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {State} from "./State.sol";
import {MerkleTree, MerkleTreeData, RootSet} from "./Merkle/MerkleTree.sol";
import {Constants} from "./Merkle/Constants.sol";
import {IUpgradeController} from "./upgrade/IUpgradeController.sol";
import {Poseidon2T4Unrolled} from "poseidon2-lib/Poseidon2T4Unrolled.sol";
import {NullmaskSwap} from "./NullmaskSwap.sol";

interface IVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title Nullmask
 * @notice Privacy pool with shielded transfers and withdrawals using ZK proofs
 * @dev Uses UUPS proxy pattern for upgradeability. Upgrade permissions are
 *      delegated to an IUpgradeController, allowing the permission mechanism
 *      itself to be upgraded (e.g., from admin-only to timelock or multisig).
 */
contract Nullmask is State, Initializable, UUPSUpgradeable, ReentrancyGuardTransient {
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
    error FeeTooHigh(uint256 value, uint256 max);
    error GasFeeTooHigh(uint256 gasFee, uint256 max);
    error DepositTooSmall(address token, uint256 amount, uint256 minimum);
    error FeesExceedDeposit(uint256 amount, uint256 fees);
    error InvalidPullIntent();
    error PullIntentExpired(uint256 deadline);
    error PullRequestUsed(bytes32 requestId);
    error InvalidRecipient(address recipient);
    error DirectTransferNotAccepted();

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

    /// @notice Retired: nothing reads it. It rate limited receiving key rotation (F6), and a
    ///         registered key can no longer be replaced at all (M-1). Kept so the ABI the
    ///         clients are built against does not change.
    uint256 public constant KEY_ROTATION_COOLDOWN = 1 days;

    /// @notice Hard ceiling on either protocol fee: 1%. No admin key can set more.
    uint256 public constant MAX_PROTOCOL_FEE_BPS = 100;
    /// @notice Hard ceiling on the check cost kept from a refused deposit: 1% of it,
    ///         whatever `checkFee` says. A decimals mistake in `checkFee` (USDT has 6 on
    ///         Ethereum and 18 on BSC) can therefore never eat a deposit, pending ones included.
    uint256 public constant MAX_CHECK_FEE_BPS = 100;
    /// @notice Hard ceiling on the gas a pull withholds: 5% of what arrived, whatever
    ///         `maxPullGasFee` says. The depositor's PullIntent does not name the gas fee,
    ///         so without it a decimals mistake in `maxPullGasFee` (18-decimal units on a
    ///         6-decimal USDT) would let a faulty or compromised guard book almost the
    ///         whole deposit as gas.
    uint256 public constant MAX_PULL_GAS_BPS = 500;
    uint256 private constant BPS = 10_000;

    /// @dev Gas the guard spends on a settlement that `startGas - gasleft()` cannot see:
    ///      the 21000 intrinsic cost, calldata, dispatch before the first line runs, and
    ///      the transfers and event after the measurement. Calibrated by test/Guard.ts so
    ///      the guard ends an ordinary approve or reject close to zero, never in the red.
    ///      Used while `settleGasOverhead` is 0; an L2 sets its own to add the L1 data fee.
    uint256 private constant DEFAULT_SETTLE_OVERHEAD = 45_000;
    uint256 private constant MAX_SETTLE_OVERHEAD = 500_000;
    /// @dev The part of that overhead a transaction pays once, however many settlements it
    ///      carries: the 21000 intrinsic gas, and the proxy's first touch of the implementation
    ///      (cold account, cold ERC1967 slot) before `startGas` is read. A guard that settles
    ///      several deposits in one transaction (an EIP-7702 delegate, or a guard contract)
    ///      has it deducted from every settlement after the first, so batching cannot turn
    ///      depositors' escrow into guard profit (audit finding 8). Calibrated by test/Guard.ts.
    uint256 private constant TX_ONCE_OVERHEAD = 25_000;
    /// @dev Transient slot set by the first settlement of a transaction. Any fixed slot will
    ///      do that nothing else in this contract uses transiently; the only other user is
    ///      ReentrancyGuardTransient, whose slot is a full keccak256 namespace.
    uint256 private constant SETTLED_IN_TX_TSLOT = 0x6e756c6c6d61736b2e736574746c6564; // "nullmask.settled"
    /// @dev Most the guard is reimbursed per gas above the base fee. Without it the guard
    ///      could hand the whole escrow to the block builder as a tip.
    uint256 private constant MAX_PRIORITY_FEE = 3 gwei;
    /// @dev Gas forwarded with the depositor's share of the escrow on the soft refund. A
    ///      wallet that needs more than this to accept ETH forfeits its share to the guard
    ///      rather than blocking the credit.
    uint256 private constant REFUND_GAS_STIPEND = 30_000;

    /// @dev EIP-712 domain {name: "Nullmask", version: "1", chainId, verifyingContract},
    ///      built on the fly from block.chainid and address(this), the proxy.
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("Nullmask");
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256("1");
    bytes32 public constant PULL_INTENT_TYPEHASH =
        keccak256("PullIntent(address depositor,address token,uint256 amount,bytes32 requestId,uint256 deadline)");

    // ---- Chain-specific immutables (set via constructor, vary per deployment) ----
    uint256 public immutable VIRTUAL_CHAIN_ID;
    address public immutable UNISWAP_V2_ROUTER;

    // ---- Fees ----
    /// @notice What a `ProtocolFeeCharged` event was charged for.
    enum FeeKind { DEPOSIT, WITHDRAWAL, CHECK, PULL_GAS }

    // ---- Structs ----
    /// @notice A deposit the guard pulls from `depositor` against the depositor's signed
    ///         EIP-712 PullIntent{depositor, token, amount, requestId, deadline}.
    /// @param gasFee Gas the guard withholds for the pull, in token units, capped by
    ///               `maxPullGasFee[token]` and by MAX_PULL_GAS_BPS of what arrived. Not
    ///               part of the signed intent.
    /// @param requestId Unique id of the intent; burned by the pull.
    /// @param deadline Last timestamp at which the intent may be used.
    struct PullParams {
        address depositor;
        address token;
        uint256 amount;
        uint256 gasFee;
        bytes32 requestId;
        uint256 deadline;
    }

    /// @notice Revocation key the guard binds into a deposit note.
    struct RevocationKey {
        uint256 x;
        uint256 y;
        uint256 hash;
    }

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
    /// @dev Never emitted: a registered key cannot be replaced (M-1). Kept so the ABI the
    ///      clients are built against does not change.
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
    event TreasuryUpdated(address indexed previous, address indexed next);
    event FeeConfigUpdated(uint16 depositFeeBps, uint16 withdrawalFeeBps, bool cancelCheckFee, uint32 settleGasOverhead);
    event TokenParamsUpdated(address indexed token, uint256 minDeposit, uint256 checkFee, uint256 maxPullGasFee);
    /// @param ref `bytes32(index)` for deposit-side fees, the `txNullifier` for withdrawals.
    event ProtocolFeeCharged(FeeKind indexed kind, bytes32 indexed ref, address indexed token, uint256 amount);
    event ProtocolFeesSwept(address indexed token, address indexed treasury, uint256 amount);
    /// @notice How a deposit's gas escrow was split: the gas the guard actually spent,
    ///         and the rest back to the depositor. The two always sum to the escrow.
    event GasEscrowSettled(uint256 indexed index, uint256 toGuard, uint256 toDepositor);

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
    /// @dev ETH reaches the pool only from the Uniswap router, during a shielded swap.
    ///      A plain transfer is not a deposit: it reverts, so the ETH never leaves the
    ///      sender. Deposits go through deposit/depositTo, which carry the gas escrow
    ///      the guard needs to credit them.
    receive() external payable {
        if (msg.sender != UNISWAP_V2_ROUTER) revert DirectTransferNotAccepted();
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

    /// @dev Spends the (non-zero) note nullifiers and burns the transaction nullifier.
    function _spendNotes(bytes32[6] calldata noteNullifiers, bytes32 txNullifier) internal {
        for (uint256 i = 0; i < 6; i++) {
            if (noteNullifiers[i] != bytes32(0)) _spendNote(noteNullifiers[i]);
        }
        txNullifiers[txNullifier] = true;
    }

    /// @dev The checks every shielded operation runs before its proof: relayer allowlist
    ///      for a fee-paying operation, unused transaction nullifier, known note tree root.
    function _checkSpend(bytes32 fee, bytes32 txNullifier, bytes32 root) internal view {
        _requireRelayer(fee);
        if (txNullifiers[txNullifier]) revert TxNullifierAlreadyUsed(txNullifier);
        if (!isKnownNoteTreeRoot(uint256(root))) revert InvalidNoteTreeRoot(root);
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
        // The trapdoor is the guard's revocationPublicKeyHash, taken as given. Poseidon2
        // does not reduce its inputs, so a value >= FIELD_MODULUS yields a commitment that
        // no field-element opening matches and a ciphertext clients cannot decrypt: the
        // deposit would be credited to a note nobody can ever spend (H-1).
        if (valueCommitmentTrapdoor >= FIELD_MODULUS) revert PublicInputNotInField();
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

        // A registered key is final: a different one is refused, whenever it comes (M-1).
        // The circuits key the transaction nullifier by the sender's receiving key hash, so
        // after a rotation one signed transaction could be proven, and executed, once per
        // key the address has ever had. It also caps every address at one registry leaf,
        // which is what the old rotation cooldown was for (F6): pnk, ekX and ekY are free
        // parameters, and unlimited leaves would grow the registry to MAX_TREE_DEPTH.
        // `availableAt` = type(uint256).max reads as "never".
        if (currentHash != 0) revert KeyRotationTooSoon(type(uint256).max);

        _addressToReceivingKeyHash[msg.sender] = rkHash;
        receivingKeyUpdatedAt[msg.sender] = block.timestamp;

        _keyRegistryTree.insert(_keyRegistryTreeRoots, rkHash);

        uint256 index = _keyRegistryIndex;
        _keyRegistryIndex += 1;

        emit ReceivingKeyRegistered(msg.sender, index, rkHash, rk.pkX, rk.pkY, rk.keyData, rk.pnk, rk.ekX, rk.ekY);
    }

    /// @notice Earliest timestamp at which `account` may register a different key.
    /// @dev Zero for an address that has never registered. type(uint256).max, i.e. never,
    ///      once it has: a registered key cannot be replaced (M-1).
    function receivingKeyRotatableAt(address account) external view returns (uint256) {
        if (_addressToReceivingKeyHash[account] == 0) return 0;
        return type(uint256).max;
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
            (amount, poolBalance) = _pullTokens(token, msg.sender, amount);
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

    /**
     * @notice Credit a deposit the guard pulls from the depositor's wallet, after checking
     *         it off-chain, against the depositor's signed PullIntent and an ERC20 approve.
     * @dev Guard only. Consent is the depositor's EIP-712 signature over
     *      PullIntent{depositor, token, amount, requestId, deadline}, not the allowance: an
     *      allowance left over from an abandoned direct deposit cannot be pulled without it.
     *      Each requestId pulls once. There is no recipient parameter on purpose: the note
     *      can only land on the depositor's own current receiving key, so the guard cannot
     *      send pulled funds anywhere else. The guard withholds the protocol fee and for its
     *      gas at most `maxPullGasFee[token]` and MAX_PULL_GAS_BPS of what arrived; both
     *      accrue to the treasury.
     *      Events match a deposit followed by an approval (DepositPending, NoteAdded,
     *      DepositStatusChanged(APPROVED), Deposit), with a zero pending hash and escrow.
     * @param intentSig 65-byte ECDSA signature by `p.depositor`, or anything the depositor's
     *        code accepts through ERC-1271.
     */
    function pullDeposit(PullParams calldata p, RevocationKey calldata rk, bytes calldata intentSig)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 index)
    {
        if (msg.sender != guard) revert NotGuard(msg.sender);
        address token = p.token;
        address depositor = p.depositor;
        {
            TokenType tokenType = tokenWhitelist[token];
            if (tokenType != TokenType.ERC20 && tokenType != TokenType.ERC20_FEE_ON_TRANSFER) {
                revert TokenNotWhitelisted(token);
            }
        }
        if (_addressToReceivingKeyHash[depositor] == 0) revert ReceivingKeyNotFound(depositor);
        _consumePullIntent(p, intentSig);

        (uint256 received, uint256 poolBalance) = _pullTokens(token, depositor, p.amount);
        _checkDepositLimits(token, received, poolBalance);
        {
            // The smaller of the admin's cap and MAX_PULL_GAS_BPS of what arrived.
            uint256 maxGasFee = received * MAX_PULL_GAS_BPS / BPS;
            if (maxPullGasFee[token] < maxGasFee) maxGasFee = maxPullGasFee[token];
            if (p.gasFee > maxGasFee) revert GasFeeTooHigh(p.gasFee, maxGasFee);
        }

        uint256 fee = received * depositFeeBps / BPS;
        if (fee + p.gasFee >= received) revert FeesExceedDeposit(received, fee + p.gasFee);

        index = _depositIndex;
        _depositIndex += 1;

        emit DepositPending(index, depositor, token, received, depositor, 0);
        _creditDeposit(index, depositor, token, received - fee - p.gasFee, rk.x, rk.y, rk.hash);
        _accrue(FeeKind.DEPOSIT, bytes32(index), token, fee);
        _accrue(FeeKind.PULL_GAS, bytes32(index), token, p.gasFee);
    }

    /**
     * @dev Checks the deadline, burns the requestId and verifies the depositor's signature
     *      over the intent. A plain ECDSA signature by the depositor's key is tried first,
     *      and ERC-1271 only if that fails. That order matters for EIP-7702 accounts: they
     *      carry delegation code, so OpenZeppelin's `isValidSignatureNow` would send them
     *      to ERC-1271 only, and a delegate without it would lock out the account's own key.
     *      The key controls a 7702 account whatever its delegate, so accepting it is sound.
     */
    function _consumePullIntent(PullParams calldata p, bytes calldata sig) internal {
        if (block.timestamp > p.deadline) revert PullIntentExpired(p.deadline);
        if (usedPullRequests[p.requestId]) revert PullRequestUsed(p.requestId);
        usedPullRequests[p.requestId] = true;

        bytes32 digest = keccak256(
            abi.encodePacked(
                hex"1901",
                keccak256(abi.encode(DOMAIN_TYPEHASH, DOMAIN_NAME_HASH, DOMAIN_VERSION_HASH, block.chainid, address(this))),
                keccak256(abi.encode(PULL_INTENT_TYPEHASH, p.depositor, p.token, p.amount, p.requestId, p.deadline))
            )
        );
        (address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(digest, sig);
        if (
            (err != ECDSA.RecoverError.NoError || signer != p.depositor)
                && !SignatureChecker.isValidERC1271SignatureNow(p.depositor, digest, sig)
        ) revert InvalidPullIntent();
    }

    /// @dev Pulls `amount` of `token` from `from` and measures what actually arrived, so a
    ///      fee-on-transfer token is credited for what the pool holds.
    function _pullTokens(address token, address from, uint256 amount)
        internal
        returns (uint256 received, uint256 poolBalance)
    {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(from, address(this), amount);
        poolBalance = IERC20(token).balanceOf(address(this));
        received = poolBalance - balanceBefore;
    }

    /// @dev Inserts the deposit note and emits NoteAdded -> DepositStatusChanged(APPROVED) ->
    ///      Deposit, the order the notes scanner pairs them in.
    function _creditDeposit(
        uint256 index,
        address account,
        address token,
        uint256 amount,
        uint256 revocationPublicKeyX,
        uint256 revocationPublicKeyY,
        uint256 revocationPublicKeyHash
    ) internal {
        _addDepositNote(_addressToReceivingKeyHash[account], amount, token, revocationPublicKeyHash, index);
        emit DepositStatusChanged(index, DepositStatus.APPROVED);
        emit Deposit(index, account, token, amount, revocationPublicKeyX, revocationPublicKeyY);
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
     *
     *      Allowlisting a relayer also trusts it with protocol revenue (audit finding 17).
     *      The relay `fee` is the relayer's gas reimbursement: it is paid to msg.sender
     *      whole, without the protocol fee, and nothing on-chain bounds it by the gas
     *      actually spent. A relayer and a user who agree to it can therefore move value
     *      out as `fee` with a small `value` and skip `withdrawalFeeBps` on that part.
     *      With only the project's own relayer listed, that value reaches the project
     *      anyway. Before listing a third party, charge the fee on `fee` too, or bound it.
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
     *
     *      The cap is the pool's balance of the token, so pending deposits count towards
     *      it, and for ETH so does every pending gas escrow: it bounds all the money at
     *      risk in the contract, not only credited notes. The flip side (audit finding 7,
     *      accepted): one depositor can fill the free room with pending deposits and take
     *      them back later, blocking other deposits meanwhile. By default a take-back is
     *      free; `cancelCheckFee` with a non-zero `checkFee` makes each one cost the
     *      check fee, and `minDeposit` sets a floor. The admin can also raise the cap.
     *      A cap on credited money alone would need a pending-deposit counter in every
     *      deposit path; it does not fit in EIP-170 (+519 B measured) and is not done.
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

    /// @dev Enforces the minimum and both deposit limits. `poolBalance` is the balance
    ///      already including the incoming funds, so the cap is checked against the
    ///      post-state. Accrued protocol fees are not deposits, so they do not count
    ///      towards the cap; pending deposits and escrow do (see `setDepositLimits`).
    function _checkDepositLimits(address token, uint256 amount, uint256 poolBalance) internal view {
        uint256 minimum = minDeposit[token];
        if (amount < minimum) revert DepositTooSmall(token, amount, minimum);
        uint256 limit = maxDeposit[token];
        if (limit != 0 && amount > limit) revert DepositTooLarge(token, amount, limit);
        uint256 cap = depositCap[token];
        if (cap != 0) {
            poolBalance -= protocolFeesAccrued[token];
            if (poolBalance > cap) revert DepositCapExceeded(token, poolBalance, cap);
        }
    }

    // ---- Protocol fees ----
    /**
     * @notice Set the address accrued protocol fees are swept to.
     * @dev Admin only. The guard cannot reach any fee setting: it is a hot key.
     */
    function setTreasury(address next) external {
        _requireAdmin();
        if (next == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, next);
        treasury = next;
    }

    /**
     * @notice Set the protocol fees, whether a self-withdrawal pays the check cost, and
     *         the per-chain gas overhead added to every escrow settlement.
     * @dev Admin only. Each rate is capped at MAX_PROTOCOL_FEE_BPS and the overhead at
     *      MAX_SETTLE_OVERHEAD gas. The rate in force when a deposit is credited or a
     *      withdrawal executes is the one charged.
     * @param settleGasOverhead_ Gas added on top of what a settlement measures; 0 keeps the
     *        built-in default. An L2 raises it to cover its L1 data fee. A second settlement
     *        in the same transaction gets TX_ONCE_OVERHEAD less (see `_settleEscrow`).
     */
    function setFeeConfig(uint16 depositBps, uint16 withdrawalBps, bool cancelCheckFee_, uint32 settleGasOverhead_)
        external
    {
        _requireAdmin();
        if (depositBps > MAX_PROTOCOL_FEE_BPS) revert FeeTooHigh(depositBps, MAX_PROTOCOL_FEE_BPS);
        if (withdrawalBps > MAX_PROTOCOL_FEE_BPS) revert FeeTooHigh(withdrawalBps, MAX_PROTOCOL_FEE_BPS);
        if (settleGasOverhead_ > MAX_SETTLE_OVERHEAD) revert FeeTooHigh(settleGasOverhead_, MAX_SETTLE_OVERHEAD);
        depositFeeBps = depositBps;
        withdrawalFeeBps = withdrawalBps;
        cancelCheckFee = cancelCheckFee_;
        settleGasOverhead = settleGasOverhead_;
        emit FeeConfigUpdated(depositBps, withdrawalBps, cancelCheckFee_, settleGasOverhead_);
    }

    /**
     * @notice Set the per-token deposit minimum, check cost and pull gas cap.
     * @dev Admin only. All three are in token units and 0 switches each off.
     */
    function setTokenParams(address token, uint256 minDeposit_, uint256 checkFee_, uint256 maxPullGasFee_)
        external
    {
        _requireAdmin();
        minDeposit[token] = minDeposit_;
        checkFee[token] = checkFee_;
        maxPullGasFee[token] = maxPullGasFee_;
        emit TokenParamsUpdated(token, minDeposit_, checkFee_, maxPullGasFee_);
    }

    /**
     * @notice Send the protocol fees accrued in `token` to the treasury.
     * @dev Anyone may call it; the money can only go to `treasury`. Only the fee counter
     *      moves, so a treasury the token refuses (a frozen USDT address) blocks this sweep and
     *      nothing else - deposits and withdrawals never depend on it.
     */
    function sweepProtocolFees(address token) external nonReentrant {
        address to = treasury;
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = protocolFeesAccrued[token];
        if (amount == 0) return;
        protocolFeesAccrued[token] = 0;
        _transferAsset(token, to, amount);
        emit ProtocolFeesSwept(token, to, amount);
    }

    /// @dev Books a protocol fee against the treasury. A zero fee leaves no trace.
    function _accrue(FeeKind kind, bytes32 ref, address token, uint256 amount) internal {
        if (amount == 0) return;
        protocolFeesAccrued[token] += amount;
        emit ProtocolFeeCharged(kind, ref, token, amount);
    }

    /// @dev Keeps the check cost of a refused deposit and returns the refund. The fee
    ///      is the smallest of `cost` (what checking this deposit actually cost), the
    ///      admin-set `checkFee[token]` and MAX_CHECK_FEE_BPS of the deposit.
    function _chargeCheckFee(uint256 index, address token, uint256 amount, uint256 cost)
        internal
        returns (uint256 refund)
    {
        uint256 fee = checkFee[token];
        if (cost < fee) fee = cost;
        uint256 cap = amount * MAX_CHECK_FEE_BPS / BPS;
        if (cap < fee) fee = cap;
        _accrue(FeeKind.CHECK, bytes32(index), token, fee);
        return amount - fee;
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
     * @notice Emergency switch that also halts shielded withdrawals and shielded swaps.
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
        uint256 startGas = gasleft();
        if (msg.sender != guard) revert NotGuard(msg.sender);
        if (!_clearPending(index, _computeDepositHash(recipient, token, amount, depositor, gasEscrow))) {
            revert InvalidDepositData();
        }

        // The rate in force now is the one charged; rounding down favours the depositor.
        uint256 fee = amount * depositFeeBps / BPS;
        _creditDeposit(
            index, recipient, token, amount - fee, revocationPublicKeyX, revocationPublicKeyY, revocationPublicKeyHash
        );
        _accrue(FeeKind.DEPOSIT, bytes32(index), token, fee);

        // The guard takes the gas it spent; the unused escrow goes back to the depositor.
        _settleEscrow(index, depositor, address(0), 0, gasEscrow, startGas);
    }

    /**
     * @notice Refuse a pending deposit and refund it, minus only what was actually spent.
     * @dev Guard only. Keeps the check cost (see `_chargeCheckFee`) and, out of the
     *      escrow, the gas the guard spent; the protocol fee is not charged. An escrow too
     *      small for the gas does not block the refusal: the guard gets all of it and pays
     *      the rest itself. If the depositor cannot receive the refund (an address the token
     *      has frozen, a contract that refuses ETH) this reverts and the deposit stays pending.
     * @param checkCost What checking this deposit cost: `checkFee[token]` after a paid
     *        check, 0 after a cached answer or a free lookup. Capped at
     *        `checkFee[token]` and at MAX_CHECK_FEE_BPS of the deposit.
     */
    function rejectDeposit(
        uint256 index,
        address recipient,
        address token,
        uint256 amount,
        address depositor,
        uint256 gasEscrow,
        uint256 checkCost
    ) external nonReentrant {
        uint256 startGas = gasleft();
        if (msg.sender != guard) revert NotGuard(msg.sender);
        if (!_clearPending(index, _computeDepositHash(recipient, token, amount, depositor, gasEscrow))) {
            revert InvalidDepositData();
        }

        uint256 refund = _chargeCheckFee(index, token, amount, checkCost);
        emit DepositStatusChanged(index, DepositStatus.REJECTED);
        _settleEscrow(index, depositor, token, refund, gasEscrow, startGas);
    }

    /**
     * @notice Take a pending deposit back. Works while paused: it is an exit.
     * @dev Refunds the whole deposit and the whole gas escrow. Only if the admin switched
     *      `cancelCheckFee` on is the check cost kept, capped like on a refusal: the
     *      contract cannot tell whether a paid check was made for this deposit.
     */
    function withdrawPendingDeposit(uint256 index, address recipient, address token, uint256 amount, uint256 gasEscrow)
        external
        nonReentrant
    {
        // The hash binds the depositor, so only the original depositor matches it
        if (!_clearPending(index, _computeDepositHash(recipient, token, amount, msg.sender, gasEscrow))) {
            revert NotDepositor(msg.sender);
        }

        uint256 refund = _chargeCheckFee(index, token, amount, cancelCheckFee ? type(uint256).max : 0);
        if (token == address(0)) {
            // One transfer for an ETH deposit and its escrow
            refund += gasEscrow;
            gasEscrow = 0;
        }
        _transferAsset(token, msg.sender, refund);
        _transferAsset(address(0), msg.sender, gasEscrow);

        emit DepositStatusChanged(index, DepositStatus.REVERTED);
    }

    /// @dev Deletes pending deposit `index` if `hash` matches it. Returns false on a
    ///      mismatch so each caller can raise its own error.
    function _clearPending(uint256 index, bytes32 hash) internal returns (bool) {
        bytes32 storedHash = pendingDepositHashes[index];
        if (storedHash == bytes32(0)) revert DepositNotPending(index);
        if (storedHash != hash) return false;
        delete pendingDepositHashes[index];
        return true;
    }

    /**
     * @dev Settles a guard action on a pending deposit. Pays the depositor `refund` of
     *      `token`, splits `gasEscrow` by the gas the guard (msg.sender) actually spent since
     *      `startGas`, and pays the guard its part.
     *
     *      The guard's part is (measured gas + overhead) x price, where the price is
     *      tx.gasprice capped at block.basefee + MAX_PRIORITY_FEE and the overhead is
     *      `settleGasOverhead`, or DEFAULT_SETTLE_OVERHEAD while that is 0. Only the first
     *      settlement of a transaction gets the whole overhead; each later one in the same
     *      transaction gets it minus TX_ONCE_OVERHEAD, the part a transaction pays once. It
     *      never exceeds the escrow: if the escrow is short, the guard gets all of it and
     *      bears the rest.
     *
     *      A token refund is sent first and must succeed. An ETH refund carries the
     *      depositor's escrow share in the same transfer and must succeed too; a depositor
     *      that refuses it, or needs more than REFUND_GAS_STIPEND to take it, leaves the
     *      deposit pending, and can take it back with `withdrawPendingDeposit`. With no ETH
     *      refund owed, the escrow share is sent softly: if the depositor refuses it the
     *      share goes to the guard, so a wallet that cannot take ETH can never block its
     *      own credit. Both ETH sends go through `_sendNoCopy`.
     */
    function _settleEscrow(
        uint256 index,
        address depositor,
        address token,
        uint256 refund,
        uint256 gasEscrow,
        uint256 startGas
    ) internal {
        if (token != address(0)) {
            _transferAsset(token, depositor, refund);
            refund = 0;
        }

        uint256 toGuard;
        {
            uint256 price = block.basefee + MAX_PRIORITY_FEE;
            if (tx.gasprice < price) price = tx.gasprice;
            uint256 overhead = settleGasOverhead;
            if (overhead == 0) overhead = DEFAULT_SETTLE_OVERHEAD;
            assembly {
                // A later settlement in the same transaction: the once-per-transaction part
                // was already paid for. Saturating, so a small settleGasOverhead ends at 0.
                if tload(SETTLED_IN_TX_TSLOT) {
                    overhead := mul(gt(overhead, TX_ONCE_OVERHEAD), sub(overhead, TX_ONCE_OVERHEAD))
                }
                tstore(SETTLED_IN_TX_TSLOT, 1)
            }
            toGuard = (startGas - gasleft() + overhead) * price;
        }
        if (toGuard > gasEscrow) toGuard = gasEscrow;
        uint256 toDepositor = gasEscrow - toGuard;

        if (refund != 0) {
            if (!_sendNoCopy(depositor, refund + toDepositor)) revert ETHTransferFailed(depositor, refund + toDepositor);
        } else if (toDepositor != 0 && !_sendNoCopy(depositor, toDepositor)) {
            toGuard = gasEscrow;
            toDepositor = 0;
        }

        _transferAsset(address(0), msg.sender, toGuard);
        emit GasEscrowSettled(index, toGuard, toDepositor);
    }

    /// @dev Sends ETH to a depositor after the guard's gas has been measured, so whatever
    ///      the depositor's code does here is paid by the guard and never reimbursed. Bounded
    ///      by REFUND_GAS_STIPEND, and no returndata is copied, so neither an expensive
    ///      `receive` nor a returndata bomb can make a settlement cost the guard more.
    function _sendNoCopy(address to, uint256 amount) private returns (bool ok) {
        assembly {
            ok := call(REFUND_GAS_STIPEND, to, amount, 0, 0, 0, 0)
        }
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
        _checkSpend(params.fee, params.txNullifier, params.root);
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
        _verifyProof(shieldedTransferVerifier, proof, publicInputs);

        _spendNotes(params.noteNullifiers, params.txNullifier);

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
        _checkSpend(params.fee, params.txNullifier, params.root);

        // Hand-counted from ShieldedWithdrawalParams; see test/PublicInputLayout.ts (NEW-9).
        bytes32[] memory publicInputs = new bytes32[](38);
        publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
        assembly {
            calldatacopy(add(publicInputs, 0x40), 4, 1184) // 37 * 32, offset 4 (after selector)
        }
        _verifyProof(shieldedWithdrawalVerifier, proof, publicInputs);

        _spendNotes(params.noteNullifiers, params.txNullifier);

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
        _payWithdrawal(params);

        _emitWithdrawal(params);
    }

    /// @dev Pays the recipient the withdrawn value minus the protocol fee, which stays in
    ///      the pool for the treasury. Charged whoever submits it, relayer or not, since a
    ///      fee-less self-submitted withdrawal is always allowed. Rounds down; with a rate
    ///      capped at 1% it can never exceed the value, so it can never block the exit.
    ///      The ShieldedWithdrawal event still reports the full value that left the note.
    ///      The relay `fee` is not charged: it is gas reimbursement for an allowlisted
    ///      relayer and is paid separately, whole (see `setRelayer`, audit finding 17).
    ///      A withdrawal to the pool itself is refused: ERC20 sent there would be lost
    ///      silently, since nothing credits it to anyone.
    function _payWithdrawal(ShieldedWithdrawalParams calldata params) internal {
        address coin = _toAddress(params.coinId);
        uint256 value = uint256(params.value);
        address to = _toAddress(params.recipientAddress);
        if (to == address(this)) revert InvalidRecipient(to);
        uint256 fee = value * withdrawalFeeBps / BPS;
        _accrue(FeeKind.WITHDRAWAL, params.txNullifier, coin, fee);
        _transferAsset(coin, to, value - fee);
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
    // The router leg (fee-on-transfer detection, approve, the six router entry points and
    // the balance-delta measurement) lives in the linked NullmaskSwap library, to keep the
    // pool under EIP-170. It runs by DELEGATECALL, i.e. as the pool.

    /// @dev Also stopped by `withdrawalsPaused`: a swap's input leaves the pool for Uniswap
    ///      pairs, so it is an exit too (audit SZK-2; NullmaskSwap limits the path).
    function shieldedSwap(ShieldedSwapParams calldata params, bytes calldata proof)
        external
        nonReentrant
        whenNotPaused
        whenWithdrawalsNotPaused
    {
        _checkSpend(params.fee, params.txNullifier, params.root);

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
            _verifyProof(shieldedSwapVerifier, proof, publicInputs);
        }

        // Spend input notes (skip zero nullifiers from dummy notes)
        _spendNotes(params.noteNullifiers, params.txNullifier);

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
        result.amountOut = NullmaskSwap.swap(
            tokenWhitelist,
            UNISWAP_V2_ROUTER,
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

    /// @dev Range-checks every public input, then verifies the proof against them.
    function _verifyProof(address verifier, bytes calldata proof, bytes32[] memory inputs) internal view {
        for (uint256 i = 0; i < inputs.length; i++) {
            if (uint256(inputs[i]) >= FIELD_MODULUS) revert PublicInputNotInField();
        }
        if (!IVerifier(verifier).verify(proof, inputs)) revert InvalidProof();
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
