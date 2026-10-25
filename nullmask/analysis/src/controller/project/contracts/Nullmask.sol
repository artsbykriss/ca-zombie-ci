// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {State} from "./State.sol";
import {MerkleTree, MerkleTreeData} from "./Merkle/MerkleTree.sol";
import {Constants} from "./Merkle/Constants.sol";
import {IUpgradeController} from "./upgrade/IUpgradeController.sol";
import {Poseidon2T4Unrolled} from "poseidon2-lib/Poseidon2T4Unrolled.sol";

interface IVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router {
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
contract Nullmask is State, Initializable, UUPSUpgradeable, ReentrancyGuardTransient {
    using MerkleTree for MerkleTreeData;
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

    // ---- Field Modulus ----
    uint256 private constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

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
    event TokenWhitelistUpdated(address indexed token, TokenType tokenType);
    event WhitelistManagerUpdated(address indexed previousManager, address indexed newManager);

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
        _noteTree.insert(commitment);
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
        _noteTree.insertMany(commitments);
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

        uint256 rkHash = _computeRkHash(rk);
        _addressToReceivingKeyHash[msg.sender] = rkHash;
        _keyRegistryTree.insert(rkHash);

        uint256 index = _keyRegistryIndex;
        _keyRegistryIndex += 1;

        emit ReceivingKeyRegistered(msg.sender, index, rkHash, rk.pkX, rk.pkY, rk.keyData, rk.pnk, rk.ekX, rk.ekY);
    }

    // ---- Deposit operations ----
    function deposit(uint256 amount, address token) public payable returns (uint256) {
        return depositTo(msg.sender, amount, token);
    }

    function depositTo(address recipient, uint256 amount, address token) public payable nonReentrant returns (uint256) {
        // Verify receiving key exists
        if (_addressToReceivingKeyHash[recipient] == 0) revert ReceivingKeyNotFound(recipient);
        // Check token is whitelisted
        if (tokenWhitelist[token] == TokenType.NOT_ALLOWED) revert TokenNotWhitelisted(token);

        uint256 gasEscrow;
        if (token == address(0)) {
            // ETH deposit: msg.value = amount + gasEscrow
            if (msg.value < amount) revert InsufficientValue();
            gasEscrow = msg.value - amount;
        } else {
            // ERC20 deposit: msg.value = gasEscrow only
            gasEscrow = msg.value;
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            amount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        }

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

    // ---- Guard operations ----
    function setGuard(address newGuard) external {
        bool isGuard = msg.sender == guard;
        bool isAdmin = IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0));
        if (!isGuard && !isAdmin) revert NotGuard(msg.sender);
        guard = newGuard;
    }

    function setWhitelistManager(address newWhitelistManager) external {
        bool isManager = msg.sender == whitelistManager;
        bool isAdmin = IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0));
        if (!isManager && !isAdmin) revert NotWhitelistManager(msg.sender);
        emit WhitelistManagerUpdated(whitelistManager, newWhitelistManager);
        whitelistManager = newWhitelistManager;
    }

    function setTokenWhitelist(address token, TokenType tokenType) external {
        bool isManager = msg.sender == whitelistManager;
        bool isAdmin = IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0));
        if (!isManager && !isAdmin) revert NotWhitelistManager(msg.sender);
        tokenWhitelist[token] = tokenType;
        emit TokenWhitelistUpdated(token, tokenType);
    }

    function setTokenWhitelistBatch(address[] calldata tokens, TokenType[] calldata tokenTypes) external {
        bool isManager = msg.sender == whitelistManager;
        bool isAdmin = IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0));
        if (!isManager && !isAdmin) revert NotWhitelistManager(msg.sender);
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
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0))) {
            revert UpgradeNotAuthorized(msg.sender);
        }
        if (_shieldedTransferVerifier == address(0)) revert ZeroAddress();
        if (_shieldedWithdrawalVerifier == address(0)) revert ZeroAddress();
        if (_shieldedSwapVerifier == address(0)) revert ZeroAddress();
        shieldedTransferVerifier = _shieldedTransferVerifier;
        shieldedWithdrawalVerifier = _shieldedWithdrawalVerifier;
        shieldedSwapVerifier = _shieldedSwapVerifier;
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
    function shieldedTransfer(ShieldedTransferParams calldata params, bytes calldata proof) external nonReentrant {
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);
        if (!isKnownKeyRegistryRoot(uint256(params.rkRoot))) revert InvalidKeyRegistryRoot(params.rkRoot);

        bytes32[] memory publicInputs = new bytes32[](46);
        publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
        assembly {
            calldatacopy(add(publicInputs, 0x40), 4, 1440) // 45 * 32, offset 4 (after selector)
        }
        _validatePublicInputs(publicInputs);

        if (!IVerifier(shieldedTransferVerifier).verify(proof, publicInputs)) revert InvalidProof();

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
    function shieldedWithdrawal(ShieldedWithdrawalParams calldata params, bytes calldata proof) external nonReentrant {
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);

        bytes32[] memory publicInputs = new bytes32[](38);
        publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
        assembly {
            calldatacopy(add(publicInputs, 0x40), 4, 1184) // 37 * 32, offset 4 (after selector)
        }
        _validatePublicInputs(publicInputs);

        if (!IVerifier(shieldedWithdrawalVerifier).verify(proof, publicInputs)) revert InvalidProof();

        _spendNotes(params.noteNullifiers);
        txNullifiers[params.txNullifier] = true;
        _addNote(params.noteChangeCommitment, params.ciphertextChange);
        _addNote(params.noteFeeChangeCommitment, params.ciphertextFeeChange);

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
                IUniswapV2Router(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
            } else {
                IUniswapV2Router(UNISWAP_V2_ROUTER)
                    .swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
            }
        } else if (selector == bytes4(0x7ff36ab5)) {
            // swapExactETHForTokens
            if (feeOnTransfer) {
                IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                );
            } else {
                IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: amountIn}(
                    amountOutMin, path, address(this), deadline
                );
            }
        } else if (selector == bytes4(0x18cbafe5)) {
            // swapExactTokensForETH
            IERC20(path[0]).forceApprove(UNISWAP_V2_ROUTER, amountIn);
            if (feeOnTransfer) {
                IUniswapV2Router(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
            } else {
                IUniswapV2Router(UNISWAP_V2_ROUTER)
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

    function shieldedSwap(ShieldedSwapParams calldata params, bytes calldata proof) external nonReentrant {
        if (txNullifiers[params.txNullifier]) revert TxNullifierAlreadyUsed(params.txNullifier);
        if (!isKnownNoteTreeRoot(uint256(params.root))) revert InvalidNoteTreeRoot(params.root);

        // Verify ZK proof (50 public inputs for shielded swap)
        {
            bytes32[] memory publicInputs = new bytes32[](52);
            publicInputs[0] = bytes32(VIRTUAL_CHAIN_ID);
            publicInputs[1] = bytes32(uint256(uint160(UNISWAP_V2_ROUTER)));
            assembly {
                calldatacopy(add(publicInputs, 0x60), 4, 1600) // 50 * 32, offset 4 (after selector)
            }
            _validatePublicInputs(publicInputs);
            if (!IVerifier(shieldedSwapVerifier).verify(proof, publicInputs)) revert InvalidProof();
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

    function ROOT_HISTORY_SIZE() external pure returns (uint32) {
        return Constants.rootHistorySize();
    }

    function MAX_TREE_DEPTH() external pure returns (uint32) {
        return Constants.maxTreeDepth();
    }

    function noteTreeRoots(uint256 _index) external view returns (uint256) {
        return _noteTree.roots[_index];
    }

    function noteTreeRootIndex() external view returns (uint32) {
        return _noteTree.currentRootIndex;
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

    function isKnownNoteTreeRoot(uint256 _root) public view returns (bool) {
        return _noteTree.isKnownRoot(_root);
    }

    function isKnownKeyRegistryRoot(uint256 _root) public view returns (bool) {
        return _keyRegistryTree.isKnownRoot(_root);
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
