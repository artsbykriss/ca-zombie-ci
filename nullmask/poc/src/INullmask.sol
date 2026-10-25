// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Minimal interface for the Nullmask shielded pool (deployed logic behind
///         the ERC-1967 NullmaskProxy). Only the surface the PoC exercises.
interface INullmask {
    // ---- custom errors used by the access-control / state gates ----
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

    // ---- views ----
    function guard() external view returns (address);
    function shieldedTransferVerifier() external view returns (address);
    function shieldedWithdrawalVerifier() external view returns (address);
    function shieldedSwapVerifier() external view returns (address);
    function upgradeController() external view returns (address);
    function whitelistManager() external view returns (address);
    function treasury() external view returns (address);
    function paused() external view returns (bool);
    function withdrawalsPaused() external view returns (bool);
    function depositFeeBps() external view returns (uint16);
    function withdrawalFeeBps() external view returns (uint16);
    function noteTreeSize() external view returns (uint256);
    function noteTreeRoot() external view returns (uint256);
    function keyRegistrySize() external view returns (uint256);
    function keyRegistryRoot() external view returns (uint256);
    function VIRTUAL_CHAIN_ID() external view returns (uint256);
    function UNISWAP_V2_ROUTER() external view returns (address);
    function protocolFeesAccrued(address token) external view returns (uint256);
    function tokenWhitelist(address token) external view returns (uint8);
    function minDeposit(address token) external view returns (uint256);
    function MAX_PROTOCOL_FEE_BPS() external view returns (uint256);
    function isKnownNoteTreeRoot(uint256 root) external view returns (bool);

    // ---- state-changing surface (all probed from a fresh EOA) ----
    function initialize(address, address, address, address, address) external;
    function setGuard(address) external;
    function setRelayer(address, bool) external;
    function setTreasury(address) external;
    function setVerifiers(address, address, address) external;
    function setWhitelistManager(address) external;
    function setUpgradeController(address) external;
    function setFeeConfig(uint16, uint16, bool, uint32) external;
    function setTokenParams(address, uint256, uint256, uint256) external;
    function setDepositLimits(address, uint256, uint256) external;
    function setTokenWhitelist(address, uint8) external;
    function setPaused(bool) external;
    function setWithdrawalsPaused(bool) external;
    function upgradeToAndCall(address, bytes calldata) external payable;
    function approveDeposit(uint256, address, address, uint256, address, uint256, uint256, uint256, uint256) external;
    function rejectDeposit(uint256, address, address, uint256, address, uint256, uint256) external;
    function withdrawPendingDeposit(uint256, address, address, uint256, uint256) external;
    function sweepProtocolFees(address token) external;
    function registerReceivingKey(bytes32 pkX, bytes32 pkY, bytes32 keyData, bytes32 pnk, bytes32 ekX, bytes32 ekY) external;
    function deposit(uint256 amount, address token) external payable returns (uint256);
}

/// @notice The tiny ERC-1967 proxy in front of the pool. Its only extra entry point is
///         `setImplementationAndCall`, which reverts once an implementation is set.
interface INullmaskProxy {
    error ImplementationAlreadySet();
    function setImplementationAndCall(address implementation, bytes calldata data) external payable;
}

/// @notice Gnosis Safe 1.5.0 read surface.
interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
    function VERSION() external view returns (string memory);
}

/// @notice The single-admin upgrade controller. `canUpgrade` is exactly `caller == admin`.
interface IAdminUpgradeController {
    function admin() external view returns (address);
    function canUpgrade(address caller, address newImplementation) external view returns (bool);
    function transferAdmin(address newAdmin) external;
    function execute(address target, bytes calldata data) external returns (bytes memory);
}

/// @notice An UltraHonk (Barretenberg/Noir) verifier, as deployed for Nullmask.
interface IHonkVerifier {
    function verify(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bool);
}
