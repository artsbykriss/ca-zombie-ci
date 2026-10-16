// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "../constants/Errors.sol";

import {IAccess, PermissionLevel} from "../interfaces/IAccess.sol";
import {IAsyncVaultFactory} from "../interfaces/IAsyncVaultFactory.sol";
import {IGlobalRegistry} from "../interfaces/IGlobalRegistry.sol";
import {IAccountableVault} from "../interfaces/IAccountableAsyncVault.sol";
import {
    IAccountableStrategy,
    IStrategyVaultHooks,
    IFeeManagerHooks,
    LoanState,
    LoanTerms,
    DVNProof,
    Loan
} from "../interfaces/IAccountableStrategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {StrategyStorage} from "./storage/StrategyStorage.sol";

/// @title AccountableStrategy
/// @notice Abstract contract that implements the IAccountableStrategy interface
/// @dev It holds the state of an accountable strategy and implements the IAccountableStrategy interface
/// @custom:security-contact security@accountable.capital
abstract contract AccountableStrategy is PausableUpgradeable, StrategyStorage {
    // ========================================================================== //
    //                              Constants                                     //
    // ========================================================================== //

    /// @dev precision for calculations
    uint256 public constant PRECISION = 1e36;
    /// @dev 1e6 basis points representing 100%
    uint256 public constant BASIS_POINTS = 1e6;
    /// @dev seconds in a days
    uint256 public constant DAYS_1_SECONDS = 1 days;
    /// @dev seconds in a year considered 365 days
    uint256 public constant DAYS_365_SECONDS = 365 days;

    // ========================================================================== //
    //                              Modifiers                                     //
    // ========================================================================== //

    /// @notice modifier to check if caller is the borrower
    modifier onlyBorrower() {
        if (msg.sender != borrower) revert Unauthorized();
        _;
    }

    /// @notice modifier to check if caller is the investment manager
    modifier onlyManager() {
        if (msg.sender != investmentManager) revert Unauthorized();
        _;
    }

    /// @notice modifier to check if caller is the operations admin
    modifier onlyOperationsAdmin() {
        if (!operationsAdminEnabled) revert Unauthorized();
        if (msg.sender != IGlobalRegistry(globals).operationsAdmin()) revert Unauthorized();
        _;
    }

    /// @notice modifier to check if caller is the safety module or the manager
    modifier onlySafetyModuleOrManager() {
        if (safetyModule != address(0)) {
            revert_AtLeastOne(safetyModule, investmentManager);
        } else {
            if (msg.sender != investmentManager) revert Unauthorized();
        }
        _;
    }

    /// @notice modifier to check if caller is the manager or the security admin (if enabled)
    modifier onlyManagerOrSecurityAdmin() {
        if (securityAdminEnabled) {
            revert_AtLeastOne(IGlobalRegistry(globals).securityAdmin(), investmentManager);
        } else {
            if (msg.sender != investmentManager) revert Unauthorized();
        }
        _;
    }

    /// @notice modifier to check if caller is the manager or the operations admin (if enabled)
    modifier onlyManagerOrOperationsAdmin() {
        if (operationsAdminEnabled) {
            revert_AtLeastOne(IGlobalRegistry(globals).operationsAdmin(), investmentManager);
        } else {
            if (msg.sender != investmentManager) revert Unauthorized();
        }
        _;
    }

    /// @notice modifier to check if caller is the proof signer
    modifier onlyProofSigner() {
        if (msg.sender != proofSigner) revert Unauthorized();
        _;
    }

    /// @notice modifier to check if caller is the vault
    modifier onlyVault() {
        if (msg.sender != vault) revert Unauthorized();
        _;
    }

    /// @dev Reverts if the caller is not one of the two addresses
    function revert_AtLeastOne(address a, address b) internal view {
        if (msg.sender != a && msg.sender != b) revert Unauthorized();
    }

    // ========================================================================== //
    //                          Pausable Functions                                //
    // ========================================================================== //

    /// @dev Pauses the contract
    function pause() public onlyManagerOrSecurityAdmin {
        if (msg.sender == IGlobalRegistry(globals).securityAdmin()) {
            _pausedByAdmin = true;
        }
        _pause();
    }

    /// @dev Unpauses the contract and checks whether msg.sender is admin when loan was paused by admin
    function unpause() public onlyManagerOrSecurityAdmin {
        if (_pausedByAdmin && msg.sender != IGlobalRegistry(globals).securityAdmin()) {
            revert Unauthorized();
        }
        _pausedByAdmin = false;
        _unpause();
    }

    // ========================================================================== //
    //                          Configuration Functions                           //
    // ========================================================================== //

    /// @inheritdoc IAccountableStrategy
    function setPendingBorrower(address newBorrower) external virtual onlyManager {
        if (newBorrower == address(0)) revert ZeroAddress();
        pendingBorrower = newBorrower;

        emit PendingBorrowerSet(newBorrower);
    }

    /// @inheritdoc IAccountableStrategy
    function acceptBorrowerRole() external virtual {
        if (msg.sender != pendingBorrower) revert InvalidPendingBorrower();
        emit BorrowerChanged(borrower, msg.sender);
        borrower = msg.sender;
        pendingBorrower = address(0);
    }

    /// @inheritdoc IAccountableStrategy
    function setInvestmentManager(address investmentManager_) external virtual onlyManager {
        if (investmentManager_ == address(0)) revert ZeroAddress();
        investmentManager = investmentManager_;

        emit InvestmentManagerSet(investmentManager_);
    }

    /// @inheritdoc IAccountableStrategy
    function setAuthSigner(address authSigner_) external onlyManager {
        IAccess(vault).setSigner(authSigner_);
    }

    /// @inheritdoc IAccountableStrategy
    function setLenders(address[] calldata lenders, bool[] calldata allowed) external onlyManager {
        IAccess(vault).setAllowed(lenders, allowed);
    }

    /// @inheritdoc IAccountableStrategy
    function setProofSigner(address proofSigner_) external virtual onlyManager {
        if (proofSigner_ == address(0)) revert ZeroAddress();
        proofSigner = proofSigner_;

        emit ProofSignerSet(proofSigner_);
    }

    /// @inheritdoc IAccountableStrategy
    function setManagerFeeRecipient(address managerFeeRecipient_) external virtual onlyManager {
        if (managerFeeRecipient_ == address(0)) revert ZeroAddress();
        managerFeeRecipient = managerFeeRecipient_;

        emit ManagerFeeRecipientSet(managerFeeRecipient_);
    }

    /// @inheritdoc IAccountableStrategy
    function publishDVNProof(DVNProof memory proof) external virtual onlyProofSigner {
        _dvnProof = proof;

        emit DVNProofPublished(proof.root, proof.signature, proof.messageHash);
    }

    /// @inheritdoc IAccountableStrategy
    function acceptDefault() external {
        if (block.timestamp < _defaultValidAt || _defaultValidAt == 0) revert TimelockNotExpired();

        loanState = LoanState.InDefault;

        emit LoanDefaulted(_loan.outstandingPrincipal, IAccountableVault(vault).totalAssets());
    }

    /// @inheritdoc IAccountableStrategy
    function rejectDefault() external onlyManager {
        _defaultValidAt = 0;

        emit LoanDefaultRejected();
    }

    /// @inheritdoc IAccountableStrategy
    function setPenaltiesEnabled(bool enabled) external virtual onlyManager {
        penaltiesEnabled = enabled;

        emit PenaltiesEnabledSet(enabled);
    }

    /// @inheritdoc IAccountableStrategy
    function setSecurityAdminEnabled(bool enabled) external virtual onlyManager {
        securityAdminEnabled = enabled;

        emit SecurityAdminEnabledSet(enabled);
    }

    /// @inheritdoc IAccountableStrategy
    function setOperationsAdminEnabled(bool enabled) external virtual onlyManager {
        operationsAdminEnabled = enabled;

        emit OperationsAdminEnabledSet(enabled);
    }

    /// @inheritdoc IAccountableStrategy
    function setSharesTransferable(bool transferable) external virtual onlyManager {
        IAccountableVault(vault).setSharesTransferable(transferable);
    }

    /// @inheritdoc IAccountableStrategy
    function setReserveThreshold(uint256 threshold) external virtual onlyManager {
        if (threshold > BASIS_POINTS) revert ThresholdTooHigh();
        _loan.reserveThreshold = threshold;

        emit ReserveThresholdSet(threshold);
    }

    /// @inheritdoc IAccountableStrategy
    function setSafetyModule(address safetyModule_) external virtual onlyManager {
        if (safetyModule_ == address(0)) revert ZeroAddress();
        safetyModule = safetyModule_;

        emit SafetyModuleSet(safetyModule_);
    }

    /// @inheritdoc IAccountableStrategy
    function setRewardsDistributor(address rewards_) external virtual onlyManager {
        if (rewards_ == address(0)) revert ZeroAddress();
        rewards = rewards_;

        emit RewardsDistributorSet(rewards_);
    }

    /// @inheritdoc IAccountableStrategy
    function setPriceOracle(address priceOracle_) external virtual onlyManager {
        _requireLoanNotOngoing();

        if (priceOracle_ == address(0)) revert ZeroAddress();
        priceOracle = priceOracle_;

        emit PriceOracleSet(priceOracle_);
    }

    // ========================================================================== //
    //                              View Functions                                //
    // ========================================================================== //

    /// @inheritdoc IAccountableStrategy
    function loan() external view returns (Loan memory) {
        return _loan;
    }

    /// @inheritdoc IAccountableStrategy
    function dvnProof() external view returns (DVNProof memory) {
        return _dvnProof;
    }

    // ========================================================================== //
    //                          Strategy Vault Hooks                              //
    // ========================================================================== //

    /// @inheritdoc IStrategyVaultHooks
    function onRequestDeposit(address share, uint256, address, address)
        public
        virtual
        onlyVault
        whenNotPaused
        returns (bool canFulfill, uint256 price)
    {
        return (false, _sharePrice(share));
    }

    /// @inheritdoc IStrategyVaultHooks
    function onRequestRedeem(address share, uint256, address, address)
        public
        virtual
        onlyVault
        whenNotPaused
        returns (bool canFulfill, uint256 price)
    {
        return (false, _sharePrice(share));
    }

    /// @inheritdoc IStrategyVaultHooks
    function onCancelDepositRequest(address, address) public virtual onlyVault whenNotPaused returns (bool canCancel) {
        return true;
    }

    /// @inheritdoc IStrategyVaultHooks
    function onCancelRedeemRequest(address, address) public virtual onlyVault whenNotPaused returns (bool canCancel) {
        return true;
    }

    /// @inheritdoc IStrategyVaultHooks
    function onDeposit(address share, uint256, address, address)
        public
        virtual
        onlyVault
        whenNotPaused
        returns (uint256 price)
    {
        price = _sharePrice(share);
    }

    /// @inheritdoc IStrategyVaultHooks
    function onMint(address share, uint256, address, address)
        public
        virtual
        onlyVault
        whenNotPaused
        returns (uint256 price)
    {
        price = _sharePrice(share);
    }

    /// @inheritdoc IStrategyVaultHooks
    function onRedeem(address, uint256, address, address) public virtual onlyVault whenNotPaused {}

    /// @inheritdoc IStrategyVaultHooks
    function onWithdraw(address, uint256, address, address) public virtual onlyVault whenNotPaused {}

    /// @inheritdoc IStrategyVaultHooks
    function onTransfer(address, address, address, uint256) public virtual onlyVault whenNotPaused {}

    /// @inheritdoc IStrategyVaultHooks
    function authOperator(address operator) external virtual {
        if (msg.sender != vault) revert Unauthorized();
        if (operator != investmentManager && operator != borrower) revert Unauthorized();
    }

    /// @inheritdoc IStrategyVaultHooks
    function sharePrice(address share) external view virtual returns (uint256 price) {
        return _sharePrice(share);
    }

    /// @dev Computes the share price. To be overridden by the derived strategy
    function _sharePrice(address share) internal view virtual returns (uint256 price);

    /// @inheritdoc IStrategyVaultHooks
    function accruedAssets(address share) external view virtual returns (uint256 assets) {
        assets = _accruedAssets(share);
    }

    /// @dev Computes the accrued assets. To be overridden by the derived strategy
    function _accruedAssets(address share) internal view virtual returns (uint256 assets);

    /// @inheritdoc IStrategyVaultHooks
    function maxDeposit(address, address) public view virtual returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    /// @inheritdoc IStrategyVaultHooks
    function maxRedeem(address, address) public view virtual returns (uint256 maxShares) {
        return type(uint256).max;
    }

    // ========================================================================== //
    //                          Fee Manager Hooks                                 //
    // ========================================================================== //

    /// @inheritdoc IFeeManagerHooks
    function onFeeStructureChange() public virtual whenNotPaused {
        if (msg.sender != feeManager) revert Unauthorized();
    }

    /// @inheritdoc IAccountableStrategy
    function version() external view virtual returns (uint256) {
        return 2;
    }

    // ========================================================================== //
    //                          Internal Helper Functions                         //
    // ========================================================================== //

    /// @dev Calls the factory to create a new async redeem vault
    function _makeVault(
        IERC20 asset_,
        bool sharesTransferable_,
        PermissionLevel permissionLevel_,
        string memory name_,
        string memory symbol_
    ) internal {
        vault = IAsyncVaultFactory(IGlobalRegistry(globals).vaultFactory()).createAsyncRedeemVault(
            asset_, address(this), sharesTransferable_, permissionLevel_, name_, symbol_, PRECISION
        );
    }

    /// @dev Sets the loan terms and initializes the loan state
    function _setTerms(LoanTerms memory terms) internal {
        _loan = Loan({
            lateInterestGracePeriod: terms.lateInterestGracePeriod == 0 ? 2 days : terms.lateInterestGracePeriod,
            acceptGracePeriod: terms.acceptGracePeriod == 0 ? 2 days : terms.acceptGracePeriod,
            depositPeriod: terms.depositPeriod,
            withdrawalPeriod: terms.withdrawalPeriod,
            lateInterestPenalty: terms.lateInterestPenalty,
            interestInterval: terms.interestInterval,
            interestRate: terms.interestRate,
            minDeposit: terms.minDeposit,
            minRedeem: terms.minRedeem,
            maxCapacity: terms.maxCapacity,
            minCapacity: terms.minCapacity,
            duration: terms.duration,
            reserveThreshold: 0,
            outstandingPrincipal: 0,
            outstandingInterest: 0,
            claimableInterest: 0,
            drawableFunds: 0,
            termsSetTime: 0,
            termsUpdateTime: 0,
            startTime: 0
        });
    }

    /// @dev Checks that the loan terms have been set
    function _requireLoanTermsSet() internal view {
        if (loanState != LoanState.TermsSet) revert LoanTermsNotSet();
    }

    /// @dev Checks that the loan terms have not been set
    function _requireLoanTermsNotSet() internal view {
        if (loanState != LoanState.Initialized) revert LoanTermsAlreadySet();
    }

    /// @dev Checks that the loan is not ongoing
    function _requireLoanNotOngoing() internal view {
        if (loanState == LoanState.OngoingLocked || loanState == LoanState.OngoingDynamic) revert LoanOngoing();
    }

    /// @dev Checks that the loan is ongoing
    function _requireLoanOngoing() internal view {
        if (loanState != LoanState.OngoingLocked && loanState != LoanState.OngoingDynamic) revert LoanNotOngoing();
    }

    /// @dev Checks that the loan is in default
    function _requireLoanInDefault() internal view {
        if (loanState != LoanState.InDefault) revert LoanNotInDefault();
    }

    /// @dev Checks that the deposit amount is greater than the minimum deposit amount
    function _requireMinDepositAmount(uint256 amount) internal view {
        if (amount < _loan.minDeposit) revert InsufficientAmount();
    }
}
