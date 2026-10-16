// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "../constants/Errors.sol";

import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {IAccountableWithdrawalQueue} from "../interfaces/IAccountableWithdrawalQueue.sol";
import {IAccountableVault, IAccountableAsyncRedeemVault} from "../interfaces/IAccountableAsyncVault.sol";
import {
    IAccountableOpenTerm,
    OpenTermInitParams,
    WithdrawalBatch,
    DVNRateUpdate
} from "../interfaces/IAccountableOpenTerm.sol";

import {
    IAccountableStrategy,
    IStrategyVaultHooks,
    IFeeManagerHooks,
    IAccountableLoan,
    LoanState,
    LoanTerms
} from "../interfaces/IAccountableStrategy.sol";

import {AccountableStrategy} from "../strategies/AccountableStrategy.sol";
import {OpenTermStorage} from "../strategies/storage/OpenTermStorage.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title AccountableOpenTerm
/// @notice Implementation of an open term loan
/// @dev Implements IAccountableOpenTerm interface and extends AccountableStrategy for managing loan lifecycle and payments
/// @custom:security-contact security@accountable.capital
contract AccountableOpenTerm is UUPSUpgradeable, ReentrancyGuardUpgradeable, AccountableStrategy, OpenTermStorage {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @notice Rollback window duration (12 hours)
    uint256 public constant ROLLBACK_WINDOW = 12 hours;

    /// @notice Maximum publish rate allowed (1000%)
    uint256 public constant MAX_PUBLISH_RATE = 1e7; // 1000%

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ========================================================================== //
    //                          Initialization                                    //
    // ========================================================================== //

    function initialize(OpenTermInitParams memory params) external initializer {
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (params.asset == address(0)) revert ZeroAddress();
        if (params.globals == address(0)) revert ZeroAddress();
        if (params.feeManager == address(0)) revert ZeroAddress();
        if (params.investmentManager == address(0)) revert ZeroAddress();

        asset = params.asset;
        globals = params.globals;
        feeManager = params.feeManager;
        loanState = LoanState.Initialized;
        investmentManager = params.investmentManager;
        managerFeeRecipient = params.investmentManager;

        penaltiesEnabled = true;

        _makeVault(IERC20(params.asset), params.sharesTransferable, params.permissionLevel, params.name, params.symbol);

        IERC20(params.asset).approve(vault, type(uint256).max);
        IERC20(params.asset).approve(params.feeManager, type(uint256).max);
    }

    // ========================================================================== //
    //                          Loan Terms Management                             //
    // ========================================================================== //

    /// @inheritdoc IAccountableLoan
    function setTerms(LoanTerms memory terms) public onlyManager {
        _requireLoanTermsNotSet();

        if (borrower == address(0)) revert ZeroAddress();
        if (terms.interestInterval == 0) revert InvalidIntervalLength();
        if (terms.withdrawalPeriod >= terms.interestInterval) revert InvalidWithdrawalPeriod();

        terms.duration = 0;
        _setTerms(terms);

        _scaleFactor = PRECISION;

        loanState = LoanState.TermsSet;
        _loan.termsSetTime = block.timestamp;

        emit LoanTermsSet(
            terms.minCapacity,
            terms.maxCapacity,
            terms.interestRate,
            terms.lateInterestPenalty,
            terms.interestInterval,
            terms.duration
        );
    }

    /// @inheritdoc IAccountableLoan
    function updateTerms(LoanTerms memory terms) external onlyManager {
        _requireLoanOngoing();

        _accrueInterest();

        _pendingTerms = terms;

        emit LoanTermsSet(
            terms.minCapacity,
            terms.maxCapacity,
            terms.interestRate,
            terms.lateInterestPenalty,
            terms.interestInterval,
            terms.duration
        );
    }

    /// @inheritdoc IAccountableOpenTerm
    function acceptTerms() external nonReentrant onlyBorrower whenNotPaused {
        if (loanState == LoanState.TermsSet) {
            loanState = LoanState.OngoingDynamic;

            _accruedAt = block.timestamp + _loan.depositPeriod;
            _loan.startTime = block.timestamp;
            _lastPaidTime = block.timestamp;

            emit TermsAccepted();
            return;
        }

        _accrueInterest();
        _processAvailableWithdrawals();

        LoanTerms memory terms = _pendingTerms;
        delete _pendingTerms;

        uint256 currentMaxCap = _loan.maxCapacity;
        if (currentMaxCap > terms.maxCapacity) {
            uint256 diff = currentMaxCap - terms.maxCapacity;
            if (diff > maxDeposit(address(0), address(0))) revert CapacityTooLow();
        }
        if (terms.interestInterval == 0) revert InvalidIntervalLength();
        if (terms.withdrawalPeriod >= terms.interestInterval) revert InvalidWithdrawalPeriod();
        if (terms.withdrawalPeriod > 0 && _loan.withdrawalPeriod == 0) {
            if (IAccountableWithdrawalQueue(vault).totalQueuedShares() > 0) revert WithdrawalQueueNotEmpty();
        }

        _loan.minDeposit = terms.minDeposit;
        _loan.minRedeem = terms.minRedeem;
        _loan.maxCapacity = terms.maxCapacity;

        _loan.interestRate = terms.interestRate;
        _loan.interestInterval = terms.interestInterval;
        _loan.lateInterestPenalty = terms.lateInterestPenalty;

        _loan.withdrawalPeriod = terms.withdrawalPeriod;
        _loan.lateInterestGracePeriod = terms.lateInterestGracePeriod;

        _loan.termsUpdateTime = block.timestamp;

        emit TermsAccepted();
    }

    /// @inheritdoc IAccountableOpenTerm
    function rejectTerms() external onlyBorrower whenNotPaused {
        if (loanState == LoanState.TermsSet) {
            delete _loan;

            loanState = LoanState.Initialized;

            emit TermsRejected();
            return;
        }

        delete _pendingTerms;

        emit TermsRejected();
    }

    /// @inheritdoc IAccountableStrategy
    function setReserveThreshold(uint256 threshold)
        external
        override(AccountableStrategy, IAccountableStrategy)
        onlyManager
    {
        if (threshold > BASIS_POINTS) revert ThresholdTooHigh();
        _loan.reserveThreshold = threshold;

        if (loanState == LoanState.OngoingDynamic) {
            _accrueInterest();
            _updateDelinquentStatus();
        }

        emit ReserveThresholdSet(threshold);
    }

    /// @inheritdoc IAccountableOpenTerm
    function setProposer(address proposer, bool approved) external onlyManager {
        _proposers[proposer] = approved;

        emit ProposerSet(proposer, approved);
    }

    /// @inheritdoc IAccountableOpenTerm
    function proposeInterestRate(uint256 interestRate) external {
        if (msg.sender != borrower && !_proposers[msg.sender]) revert Unauthorized();
        if (interestRate >= MAX_PUBLISH_RATE) revert RateTooHigh();

        pendingInterestRate = interestRate;

        emit InterestRateProposed(interestRate);
    }

    /// @inheritdoc IAccountableOpenTerm
    function approveInterestRateChange() external onlyManager {
        _accrueInterest();

        emit InterestRateApproved(pendingInterestRate);
        _loan.interestRate = pendingInterestRate;
        delete pendingInterestRate;
    }

    // ========================================================================== //
    //                          DVN Publisher Management                          //
    // ========================================================================== //

    /// @inheritdoc IAccountableStrategy
    function setDVNPublisher(address publisher) external onlyManager {
        if (publisher == address(0)) revert ZeroAddress();
        dvnPublisher = publisher;

        emit DVNPublisherSet(publisher);
    }

    /// @inheritdoc IAccountableStrategy
    function publishRate(uint256 newRate, uint256) external {
        if (msg.sender != dvnPublisher) revert Unauthorized();
        if (newRate >= MAX_PUBLISH_RATE) revert RateTooHigh();
        _requireLoanOngoing();

        _accrueInterest();

        uint256 oldRate = _loan.interestRate;

        lastRateUpdate = DVNRateUpdate({
            rate: newRate,
            previousRate: oldRate,
            timestamp: block.timestamp,
            scaleFactorSnapshot: _scaleFactor
        });

        _loan.interestRate = newRate;

        _updateDelinquentStatus();

        emit RatePublished(msg.sender, oldRate, newRate);
    }

    /// @inheritdoc IAccountableOpenTerm
    function rollbackRate() external onlyOperationsAdmin {
        _requireLoanOngoing();

        DVNRateUpdate memory update = lastRateUpdate;

        if (block.timestamp > update.timestamp + ROLLBACK_WINDOW) revert RollbackWindowExpired();

        uint256 rolledBackRate = _loan.interestRate;

        _accruedAt = update.timestamp;
        _loan.interestRate = update.previousRate;
        _scaleFactor = update.scaleFactorSnapshot;

        delete lastRateUpdate;

        (uint256 newScaleFactor,) = _previewAccruedInterest();
        _scaleFactor = newScaleFactor;
        _accruedAt = block.timestamp;

        _updateDelinquentStatus();

        emit RateRolledBack(rolledBackRate, update.previousRate, update.timestamp);
    }

    // ========================================================================== //
    //                          Loan Lifecycle Functions                          //
    // ========================================================================== //

    /// @inheritdoc IAccountableLoan
    /// @dev This should be callable when paused
    ///      It is safer to pause and then default to first prevent other operations
    function defaultLoan() external onlySafetyModuleOrManager {
        _requireLoanOngoing();

        _defaultValidAt = block.timestamp + 1 days;

        emit LoanDefaultInitiated();
    }

    /// @inheritdoc IAccountableLoan
    /// @dev This should be callable when paused
    ///      Default coverage should be possible at all times if loan is in default
    function coverDefault(uint256 assets) external nonReentrant onlySafetyModuleOrManager {
        _requireLoanInDefault();

        loanState = LoanState.InDefaultClaims;

        IAccountableVault(vault).lockAssets(assets, msg.sender);

        _updateDelinquentStatus();

        emit DefaultCovered(safetyModule, msg.sender, assets);
    }

    /// @inheritdoc IAccountableLoan
    function borrow(uint256 assets) external nonReentrant onlyBorrower whenNotPaused {
        _requireLoanOngoing();

        _accrueInterest();

        uint256 borrowable = _borrowable(msg.sender);
        uint256 maxBorrowable = Math.min(borrowable, assets);

        if (maxBorrowable == 0) revert InsufficientAmount();

        /// track net principal for maxDeposit bounds
        netPrincipal += maxBorrowable;
        /// In the open term loan, outstanding principal is tracked in debt share units
        _loan.outstandingPrincipal += maxBorrowable.mulDiv(PRECISION, _scaleFactor, Math.Rounding.Ceil);
        IAccountableVault(vault).releaseAssets(maxBorrowable, msg.sender);

        _updateDelinquentStatus();

        emit Borrowed(msg.sender, maxBorrowable);
    }

    /// @inheritdoc IAccountableLoan
    function repay(uint256 assets) external nonReentrant onlyBorrower whenNotPaused {
        _requireLoanOngoing();

        if (assets == 0) revert InsufficientAmount();

        _accrueInterest();

        address asset_ = asset;
        address vault_ = vault;
        address feeManager_ = feeManager;
        uint256 scaleFactor_ = _scaleFactor;

        uint256 principalShares = _loan.outstandingPrincipal;
        uint256 principalAssets = principalShares.mulDiv(scaleFactor_, PRECISION, Math.Rounding.Ceil);

        uint256 establishmentFee =
            _prorataFee(principalAssets, IFeeManager(feeManager_).establishmentFee(address(this)));
        if (establishmentFee > assets) revert InsufficientAmount();

        uint256 repaymentPrincipal = Math.min(assets - establishmentFee, principalAssets);
        netPrincipal = netPrincipal >= repaymentPrincipal ? netPrincipal - repaymentPrincipal : 0;
        IERC20(asset_).safeTransferFrom(msg.sender, address(this), repaymentPrincipal + establishmentFee);

        _lastPaidTime = block.timestamp;
        if (establishmentFee > 0) {
            IFeeManager(feeManager_).collect(asset_, 0, 0, establishmentFee);
        }

        IAccountableVault(vault_).lockAssets(repaymentPrincipal, address(this));

        _loan.outstandingPrincipal -= repaymentPrincipal.mulDiv(PRECISION, scaleFactor_, Math.Rounding.Floor);

        _processAvailableWithdrawals();

        if (_loan.outstandingPrincipal == 0) {
            loanState = LoanState.Repaid;
        }
        _updateDelinquentStatus();

        emit LoanRepaid(repaymentPrincipal + establishmentFee);
    }

    /// @inheritdoc IAccountableLoan
    function prepay() external pure {
        revert NotSupportedByStrategy();
    }

    /// @inheritdoc IAccountableLoan
    function pay(uint256) external pure {
        revert NotSupportedByStrategy();
    }

    // ========================================================================== //
    //                          Hook Overrides                                    //
    // ========================================================================== //

    /// @dev Overriden deposit hook with extra validation logic and balances update
    function onDeposit(address share, uint256 assets, address, address)
        public
        override(AccountableStrategy, IStrategyVaultHooks)
        nonReentrant
        onlyVault
        whenNotPaused
        returns (uint256 price)
    {
        _requireCanDeposit();
        _requireMinDepositAmount(assets);

        _accrueInterest();

        _requireBelowMaxCapacity(assets);

        price = _sharePrice(share);
    }

    /// @dev Overriden mint hook with extra validation logic and balances update
    function onMint(address share, uint256 shares, address, address)
        public
        override(AccountableStrategy, IStrategyVaultHooks)
        nonReentrant
        onlyVault
        whenNotPaused
        returns (uint256 price)
    {
        _requireCanDeposit();

        _accrueInterest();

        price = _sharePrice(share);
        uint256 assets = shares.mulDiv(price, PRECISION, Math.Rounding.Ceil);

        _requireMinDepositAmount(assets);
        _requireBelowMaxCapacity(assets);
    }

    /// @dev Overriden onRequestRedeem hook for allocating a redemption request
    function onRequestRedeem(address share, uint256 shares, address controller, address)
        public
        override(AccountableStrategy, IStrategyVaultHooks)
        nonReentrant
        onlyVault
        whenNotPaused
        returns (bool canFulfill, uint256 price)
    {
        if (shares < _loan.minRedeem) revert InsufficientShares();

        _accrueInterest();

        price = _sharePrice(share);

        uint256 assets = shares.mulDiv(price, PRECISION);

        if (_isInstantRedeem()) {
            canFulfill = true;
        } else {
            uint256 availableLiquidity = _getAvailableLiquidity();
            if (availableLiquidity >= assets) {
                canFulfill = true;
            } else if (_loan.withdrawalPeriod != 0) {
                _createOrAddWithdrawalBatch(shares, controller);
                canFulfill = false;
            }
        }
    }

    /// @dev Overriden onCancelRedeemRequest hook for updating batches upon cancellation
    function onCancelRedeemRequest(address share, address controller)
        public
        override(AccountableStrategy, IStrategyVaultHooks)
        nonReentrant
        onlyVault
        whenNotPaused
        returns (bool canCancel)
    {
        // 0 id since state is controller based and the queue id does not change result
        uint256 pending = IAccountableAsyncRedeemVault(share).pendingRedeemRequest(0, controller);

        uint256 tracked;
        for (uint256 batch = pendingBatch; batch <= currentBatch;) {
            tracked += _controllerBatchShares[controller][batch];
            unchecked {
                ++batch;
            }
        }

        uint256 processed = tracked > pending ? tracked - pending : 0;

        for (uint256 batch = pendingBatch; batch <= currentBatch;) {
            uint256 allocated = _controllerBatchShares[controller][batch];

            if (allocated > 0) {
                if (processed > 0) {
                    uint256 amountProcessed = Math.min(processed, allocated);
                    allocated -= amountProcessed;
                    processed -= amountProcessed;
                }

                if (allocated > 0) {
                    _withdrawalBatches[batch].totalShares -= allocated;
                }

                delete _controllerBatchShares[controller][batch];
            }
            unchecked {
                ++batch;
            }
        }

        return true;
    }

    function onFeeStructureChange() public override(AccountableStrategy, IFeeManagerHooks) nonReentrant {
        super.onFeeStructureChange();
        if (loanState == LoanState.OngoingDynamic) {
            _accrueInterest();
        }
    }

    /// @dev Overriden maxDeposit hook
    /// @dev Uses virtual accrual to return accurate capacity based on current timestamp
    function maxDeposit(address, address)
        public
        view
        override(AccountableStrategy, IStrategyVaultHooks)
        returns (uint256 maxAssets)
    {
        uint256 netPrincipal_ = netPrincipal;
        uint256 maxCapacity_ = _loan.maxCapacity;
        uint256 totalAssets = IAccountableVault(vault).totalAssets();
        uint256 capMinusDebt = maxCapacity_ > netPrincipal_ ? maxCapacity_ - netPrincipal_ : 0;
        maxAssets = totalAssets >= capMinusDebt ? 0 : capMinusDebt - totalAssets;
    }

    /// @dev Updates the late status of the loan
    function updateLateStatus() external {
        _requireLoanOngoing();

        _accrueInterest();
        _updateDelinquentStatus();
    }

    /// @inheritdoc IAccountableOpenTerm
    function accrueInterest() external returns (uint256 newScaleFactor) {
        _accrueInterest();
        _updateDelinquentStatus();

        newScaleFactor = _scaleFactor;
    }

    /// @inheritdoc IAccountableOpenTerm
    function processAvailableWithdrawals() external nonReentrant whenNotPaused returns (uint256 usedAssets) {
        _accrueInterest();
        usedAssets = _processAvailableWithdrawals();
    }

    /// @inheritdoc IAccountableOpenTerm
    function scaleFactor() external view returns (uint256 scaleFactor_) {
        (scaleFactor_,) = _previewAccruedInterest();
    }

    /// @inheritdoc IAccountableOpenTerm
    function lastPaidTime() external view returns (uint256) {
        return _lastPaidTime;
    }

    /// @inheritdoc IAccountableLoan
    function timeDelinquent() external view returns (uint256) {
        uint256 delinquencyStartTime_ = delinquencyStartTime;
        return delinquencyStartTime_ > 0 ? block.timestamp - delinquencyStartTime_ : 0;
    }

    /// @inheritdoc IAccountableOpenTerm
    function pendingTerms() external view returns (LoanTerms memory) {
        return _pendingTerms;
    }

    /// @inheritdoc IAccountableOpenTerm
    function withdrawalBatches(uint256 id) external view returns (WithdrawalBatch memory) {
        return _withdrawalBatches[id];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IAccountableLoan).interfaceId
            || interfaceId == type(IAccountableStrategy).interfaceId
            || interfaceId == type(IAccountableOpenTerm).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Calculate establishment fee prorated by time elapsed
    function _prorataFee(uint256 principal, uint256 fee) internal view returns (uint256) {
        if (fee == 0) return 0;

        uint256 timeDelta = block.timestamp - _lastPaidTime;
        if (timeDelta == 0) return 0;

        return Math.mulDiv(principal * fee, timeDelta, DAYS_365_SECONDS * BASIS_POINTS, Math.Rounding.Ceil);
    }

    /// @dev Returns whether the loan is delinquent based on reserves available
    function _isDelinquent() internal view returns (bool) {
        address vault_ = vault;
        uint256 totalAssets = IAccountableVault(vault_).totalAssets();
        uint256 requiredLiquidity = _calculateRequiredLiquidity(vault_);

        return totalAssets < requiredLiquidity;
    }

    /// @notice Computes the accrued interest factors without modifying state
    /// @dev Used by view functions to return accurate values based on current timestamp
    function _previewAccruedInterest() internal view returns (uint256 scaleFactor_, uint256 baseInterest_) {
        scaleFactor_ = _scaleFactor;

        uint256 accruedAt_ = _accruedAt;
        if (block.timestamp <= accruedAt_) return (scaleFactor_, 0);

        uint256 timeDelta = block.timestamp - accruedAt_;
        if (timeDelta == 0) return (scaleFactor_, 0);

        uint256 delinquencyFee_ = _penaltyFee(timeDelta);

        baseInterest_ = _linearInterest(_loan.interestRate, timeDelta);
        scaleFactor_ += baseInterest_ + delinquencyFee_;
    }

    /// @notice Computes the virtual fee assets that would be deducted during accrual
    /// @dev Used by _sharePrice to return accurate net share price with virtual fee deduction
    function _previewFeeAssets(uint256 baseInterest_, uint256 scaleFactor_) internal view returns (uint256) {
        if (baseInterest_ == 0) return 0;

        uint256 realizedPerformance = netPrincipal.mulDiv(baseInterest_, PRECISION);
        uint256 aum = _loan.outstandingPrincipal.mulDiv(scaleFactor_, PRECISION);

        (uint256 perfFeeAssets, uint256 mgmtFeeAssets) =
            _calculateFeeAssets(IFeeManager(feeManager), realizedPerformance, aum);

        return perfFeeAssets + mgmtFeeAssets;
    }

    /// @dev Calculates fee assets from realized performance and AUM
    function _calculateFeeAssets(IFeeManager fm, uint256 realizedPerformance_, uint256 aum_)
        internal
        view
        returns (uint256 perfFeeAssets, uint256 mgmtFeeAssets)
    {
        perfFeeAssets = realizedPerformance_.mulDiv(fm.performanceFee(address(this)), BASIS_POINTS);
        mgmtFeeAssets = aum_.mulDiv(
            fm.managementFee(address(this)) * (block.timestamp - _accruedAt), DAYS_365_SECONDS * BASIS_POINTS
        );
    }

    /// @notice Accrues interest based time delta since last accrual
    function _accrueInterest() internal {
        (uint256 scaleFactor_, uint256 baseInterest_) = _previewAccruedInterest();
        if (scaleFactor_ == _scaleFactor) return;

        uint256 interest_ = netPrincipal.mulDiv(baseInterest_, PRECISION);
        uint256 aum_ = _loan.outstandingPrincipal.mulDiv(scaleFactor_, PRECISION);

        _accrueFeeShares(interest_, aum_);

        _scaleFactor = scaleFactor_;
        _accruedAt = block.timestamp;
    }

    /// @dev Accrues fee shares based on the realized performance and aum
    function _accrueFeeShares(uint256 realizedPerformance_, uint256 aum_) internal {
        IFeeManager fm = IFeeManager(feeManager);

        (uint256 perfFeeAssets, uint256 mgmtFeeAssets) = _calculateFeeAssets(fm, realizedPerformance_, aum_);

        uint256 totalFeeAssets = perfFeeAssets + mgmtFeeAssets;
        if (totalFeeAssets == 0) return;

        address vault_ = vault;

        uint256 totalSupply = IAccountableVault(vault_).totalSupply();
        if (totalSupply == 0) return;

        uint256 totalAssets = aum_ + IAccountableVault(vault_).totalAssets();
        if (totalAssets <= totalFeeAssets) return;

        uint256 managementFeeShares;
        uint256 performanceFeeShares;
        if (perfFeeAssets > 0) {
            // performanceFeeShares = perfFeeAssets * totalSupply / (totalAssets - totalFeeAssets)
            performanceFeeShares = perfFeeAssets.mulDiv(totalSupply, totalAssets - totalFeeAssets);
        }
        if (mgmtFeeAssets > 0) {
            // managementFeeShares = mgmtFeeAssets * totalSupply / (totalAssets - totalFeeAssets)
            managementFeeShares = mgmtFeeAssets.mulDiv(totalSupply, totalAssets - totalFeeAssets);
        }

        // Split and mint fee shares between manager and protocol
        _mintFeeShares(vault_, fm, performanceFeeShares, managementFeeShares);
    }

    function _mintFeeShares(address vault_, IFeeManager fm, uint256 perfFeeShares, uint256 mgmtFeeShares) private {
        uint256 managerShares;
        uint256 protocolShares;
        if (perfFeeShares > 0) {
            uint256 managerPerf = perfFeeShares.mulDiv(fm.managerSplit(address(this), true), BASIS_POINTS);
            protocolShares += perfFeeShares - managerPerf;
            managerShares += managerPerf;
        }
        if (mgmtFeeShares > 0) {
            uint256 managerMgmt = mgmtFeeShares.mulDiv(fm.managerSplit(address(this), false), BASIS_POINTS);
            protocolShares += mgmtFeeShares - managerMgmt;
            managerShares += managerMgmt;
        }

        address treasury_ = fm.treasury();
        address managerFeeRecipient_ = managerFeeRecipient;

        if (managerShares > 0) {
            IAccountableVault(vault_).mintShares(managerShares, managerFeeRecipient_);
            emit FeeSharesMinted(managerFeeRecipient_, managerShares);
        }
        if (protocolShares > 0) {
            IAccountableVault(vault_).mintShares(protocolShares, treasury_);
            emit FeeSharesMinted(treasury_, protocolShares);
        }
    }

    /// @notice Calculates the max borrowable amount based on the current liquidity
    function _borrowable(address) private view returns (uint256) {
        address vault_ = vault;
        uint256 requiredReserves = _calculateRequiredLiquidity(vault_);
        uint256 totalAssets = IAccountableVault(vault_).totalAssets();

        return totalAssets > requiredReserves ? totalAssets - requiredReserves : 0;
    }

    /// @notice Automatically process pending withdrawals when liquidity becomes available
    function _processAvailableWithdrawals() internal returns (uint256 usedAssets) {
        address vault_ = vault;
        uint256 liquidity = _getAvailableLiquidityForProcessing(vault_);
        if (liquidity == 0) return 0;

        IAccountableWithdrawalQueue q = IAccountableWithdrawalQueue(vault_);

        if (_loan.withdrawalPeriod == 0) {
            (uint256 maxShares,) = q.previewRequiredShares(liquidity);
            if (maxShares == 0) return 0;

            usedAssets = q.processUpToShares(maxShares);
            return usedAssets;
        }

        while (pendingBatch <= currentBatch && liquidity > 0) {
            WithdrawalBatch memory batch = _withdrawalBatches[pendingBatch];
            if (block.timestamp < batch.expiry) break;

            (uint256 maxShares,) = q.previewRequiredShares(liquidity);

            if (maxShares == 0) {
                if (batch.totalShares > 0) {
                    _withdrawalBatches[pendingBatch++].totalShares = 0;
                    continue;
                }
                break;
            }

            uint256 sharesToProcess = maxShares > batch.totalShares ? batch.totalShares : maxShares;

            uint256 processedAssets = q.processUpToShares(sharesToProcess);
            liquidity -= processedAssets;
            usedAssets += processedAssets;

            if (sharesToProcess >= batch.totalShares) {
                _withdrawalBatches[pendingBatch++].totalShares = 0;
            } else {
                _withdrawalBatches[pendingBatch].totalShares -= sharesToProcess;
                break;
            }
        }
    }

    /// @dev Calculates the delinquency fee for the given time delta
    function _penaltyFee(uint256 timeDelta) internal view returns (uint256) {
        if (!penaltiesEnabled) return 0;

        uint256 delinquencyStart_ = delinquencyStartTime;
        uint256 lateInterestPenalty_ = _loan.lateInterestPenalty;

        if (delinquencyStart_ == 0 || lateInterestPenalty_ == 0) return 0;

        uint256 gracePeriod = _loan.lateInterestGracePeriod;
        uint256 delinquencyTime = block.timestamp - delinquencyStart_;
        if (delinquencyTime <= gracePeriod) return 0;

        uint256 penaltyTime = Math.min(delinquencyTime - gracePeriod, timeDelta);
        return lateInterestPenalty_.mulDiv(penaltyTime * PRECISION, DAYS_1_SECONDS * BASIS_POINTS);
    }

    /// @notice Calculate linear interest for the given time delta and annualized rate
    function _linearInterest(uint256 interestRate, uint256 timeDelta) internal pure returns (uint256) {
        return interestRate.mulDiv(timeDelta * PRECISION, DAYS_365_SECONDS * BASIS_POINTS);
    }

    /// @dev Updates the late status of the loan payments
    function _updateDelinquentStatus() internal {
        bool wasDelinquent = delinquencyStartTime > 0;
        bool isCurrentlyDelinquent = _isDelinquent();

        if (isCurrentlyDelinquent && !wasDelinquent) {
            delinquencyStartTime = block.timestamp;

            emit DelinquencyStatusChanged(true, block.timestamp);
        } else if (!isCurrentlyDelinquent && wasDelinquent) {
            delinquencyStartTime = 0;

            emit DelinquencyStatusChanged(false, block.timestamp);
        }
    }

    /// @dev Creates or adds a withdrawal batch
    function _createOrAddWithdrawalBatch(uint256 shares, address controller) internal {
        uint256 startTime = _loan.startTime;
        uint256 period = _loan.withdrawalPeriod;
        uint256 interval = _loan.interestInterval;

        if (period == 0) return;

        // Bounds: [batchStart, batchStart + period]
        uint256 currInterval = ((block.timestamp - startTime) / interval);
        uint256 currBatchStartTime = startTime + (currInterval * interval);

        WithdrawalBatch memory batch = _withdrawalBatches[currentBatch];

        // Can add to existing batch
        if (block.timestamp <= batch.expiry) {
            _controllerBatchShares[controller][currentBatch] += shares;
            _withdrawalBatches[currentBatch].totalShares += shares;
            return;
        }
        // No active batch - create new batch
        if (block.timestamp <= currBatchStartTime + period) {
            if (batch.expiry == 0) {
                _withdrawalBatches[currentBatch] =
                    WithdrawalBatch(currBatchStartTime + period, currBatchStartTime, shares);
            } else {
                _withdrawalBatches[++currentBatch] =
                    WithdrawalBatch(currBatchStartTime + period, currBatchStartTime, shares);
            }
            _controllerBatchShares[controller][currentBatch] += shares;
            return;
        }

        // Otherwise advance and create the future batch
        uint256 targetStartTime = currBatchStartTime + interval;
        _withdrawalBatches[++currentBatch] = WithdrawalBatch(targetStartTime + period, targetStartTime, shares);
        _controllerBatchShares[controller][currentBatch] += shares;
    }

    /// @dev Returns the required reserves accounting for the queued/processed withdrawals
    function _calculateRequiredLiquidity(address vault_) internal view returns (uint256) {
        uint256 totalShares = IAccountableVault(vault_).totalSupply();
        uint256 queuedShares = IAccountableWithdrawalQueue(vault_).totalQueuedShares();

        uint256 scaleFactor_ = _scaleFactor;

        uint256 debtShares = totalShares - queuedShares;
        uint256 debtValue = debtShares.mulDiv(scaleFactor_, PRECISION);

        uint256 baseReserves = debtValue.mulDiv(_loan.reserveThreshold, BASIS_POINTS);

        uint256 queuedWithdrawalValue = queuedShares.mulDiv(scaleFactor_, PRECISION);
        uint256 processedWithdrawals = IAccountableWithdrawalQueue(vault_).reservedLiquidity();

        return baseReserves + queuedWithdrawalValue + processedWithdrawals;
    }

    /// @dev Returns the available liquidity after accounting for the required reserves
    function _getAvailableLiquidity() internal view returns (uint256) {
        address vault_ = vault;
        uint256 totalAssets = IAccountableVault(vault_).totalAssets();
        uint256 queuedShares = IAccountableWithdrawalQueue(vault_).totalQueuedShares();
        uint256 processedWithdrawals = IAccountableWithdrawalQueue(vault_).reservedLiquidity();
        uint256 requiredReserves = queuedShares.mulDiv(_scaleFactor, PRECISION) + processedWithdrawals;

        return totalAssets > requiredReserves ? totalAssets - requiredReserves : 0;
    }

    /// @dev Returns the available liquidity for processing
    function _getAvailableLiquidityForProcessing(address vault_) internal view returns (uint256) {
        uint256 totalAssets = IAccountableVault(vault_).totalAssets();
        uint256 reservedLiquidity = IAccountableWithdrawalQueue(vault_).reservedLiquidity();

        return totalAssets > reservedLiquidity ? totalAssets - reservedLiquidity : 0;
    }

    /// @dev Returns the share price at current moment, based on scaleFactor and totalSupply
    ///      Share price required to use decimals precision stored as PRECION in the vault
    ///      Uses virtual accrual to return accurate value based on current timestamp
    /// @return The share price
    function _sharePrice(address) internal view override returns (uint256) {
        if (_isInDepositPeriod()) {
            return PRECISION;
        }

        address vault_ = vault;

        if (loanState == LoanState.Repaid || loanState == LoanState.InDefaultClaims) {
            return IAccountableVault(vault_).assetShareRatio();
        }

        (uint256 scaleFactor_, uint256 baseInterest_) = _previewAccruedInterest();
        uint256 feeAssets = _previewFeeAssets(baseInterest_, scaleFactor_);

        uint256 totalSupply = IAccountableVault(vault_).totalSupply();
        uint256 liquidAssets = IAccountableVault(vault_).totalAssets();
        uint256 debt = _loan.outstandingPrincipal.mulDiv(scaleFactor_, PRECISION);

        uint256 totalAssets = (liquidAssets + debt) - feeAssets;
        return totalSupply == 0 ? PRECISION : totalAssets.mulDiv(PRECISION, totalSupply);
    }

    /// @dev Returns the total amount of reserved accrued assets
    function _accruedAssets(address) internal pure override returns (uint256) {
        return 0;
    }

    /// @dev Checks if the current timestamp is within the deposit period
    function _isInDepositPeriod() internal view returns (bool) {
        return block.timestamp <= _loan.startTime + _loan.depositPeriod;
    }

    /// @dev Checks whether the loan accepts instant redeem/withdrawal
    function _isInstantRedeem() internal view returns (bool) {
        return loanState == LoanState.Repaid || loanState == LoanState.InDefaultClaims;
    }

    /// @dev Checks that deposits are allowed
    function _requireCanDeposit() internal view {
        if (loanState != LoanState.OngoingDynamic) revert DepositNotAllowed();
    }

    /// @dev Checks that the deposit amount is below the max capacity
    function _requireBelowMaxCapacity(uint256 assets) internal view {
        if (assets > maxDeposit(address(0), address(0))) revert ExceedsMaxDeposit();
    }

    /// @dev Hook for UUPS upgradeable contract
    function _authorizeUpgrade(address newImplementation) internal override onlyManagerOrSecurityAdmin {}
}
