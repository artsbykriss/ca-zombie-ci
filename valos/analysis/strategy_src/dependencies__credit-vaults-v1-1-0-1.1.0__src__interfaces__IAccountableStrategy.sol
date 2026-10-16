// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @notice Struct containing loan terms and state
struct Loan {
    /// @notice Minimum deposit amount allowed
    uint256 minDeposit;
    /// @notice Minimum redeem amount allowed
    uint256 minRedeem;
    /// @notice Maximum loan amount that can be drawn
    ///         The full threshold can be met after deposit period if the loan is not locked
    uint256 maxCapacity;
    /// @notice Minimum loan amount for the loan to be accepted
    ///         The threshold needs to be met during deposit period or loan can be rejected
    uint256 minCapacity;
    /// @notice Liquidity ratio that has to be maintained in the vault at all times
    ///         Expressed in basis points and cannot exceed 1e6, defaults to 0
    uint256 reserveThreshold;
    /// @notice Principal amount still to be repaid
    uint256 outstandingPrincipal;
    /// @notice Interest amount still to be paid
    uint256 outstandingInterest;
    /// @notice all funds accepted and available for borrowing
    uint256 drawableFunds;
    /// @notice Annual interest rate in basis points
    uint256 interestRate;
    /// @notice Late interest penalty in basis points
    uint256 lateInterestPenalty;
    /// @notice Total claimable interest available for users
    uint256 claimableInterest;
    /// @notice Time interval between interest payments
    uint256 interestInterval;
    /// @notice Time of loan start
    uint256 startTime;
    /// @notice Time of terms set
    uint256 termsSetTime;
    /// @notice Time of terms update
    uint256 termsUpdateTime;
    /// @notice Loan duration in seconds
    uint256 duration;
    /// @notice Deposit period in seconds
    uint256 depositPeriod;
    /// @notice Grace period after deposit period for borrower to accept loan
    uint256 acceptGracePeriod;
    /// @notice Withdrawal window period in seconds
    ///         If set it allows redemption requests
    uint256 withdrawalPeriod;
    /// @notice Late interest payment grace period in seconds
    ///         This is the time period before a loan is considered delinquent
    uint256 lateInterestGracePeriod;
}

/// @notice Struct containing loan terms
struct LoanTerms {
    /// @notice Minimum deposit amount allowed
    uint256 minDeposit;
    /// @notice Minimum redeem amount allowed
    uint256 minRedeem;
    /// @notice Maximum loan capacity
    uint256 maxCapacity;
    /// @notice Minimum loan capacity
    uint256 minCapacity;
    /// @notice Annual interest rate in basis points
    uint256 interestRate;
    /// @notice Late interest penalty in basis points
    uint256 lateInterestPenalty;
    /// @notice Late interest grace period in seconds
    uint256 lateInterestGracePeriod;
    /// @notice Time interval between interest payments
    uint256 interestInterval;
    /// @notice Duration of the loan in seconds
    uint256 duration;
    /// @notice Deposit period in seconds
    uint256 depositPeriod;
    /// @notice Grace period after deposit period for borrower to accept loan
    uint256 acceptGracePeriod;
    /// @notice Withdrawal window period in seconds
    uint256 withdrawalPeriod;
}

/// @notice Struct containing DVN proof data
struct DVNProof {
    /// @notice Merkle root of the DVN merkle tree
    bytes32 root;
    /// @notice Signature of the DVN payload
    bytes32 signature;
    /// @notice Message hash that was signed
    bytes32 messageHash;
}

/// @notice Enum representing different loan states
enum LoanState {
    /// @notice Loan terms are not set
    Initialized,
    /// @notice Loan terms are set
    TermsSet,
    /// @notice Loan is accepted by borrower and locked
    OngoingLocked,
    /// @notice Loan is accepted by borrower and dynamic deposits are allowed
    OngoingDynamic,
    /// @notice Loan is rejected
    Rejected,
    /// @notice Loan is repaid
    Repaid,
    /// @notice Loan is in default
    InDefault,
    /// @notice Loan is in default claims
    InDefaultClaims
}

/// @notice Interface for managing strategy vault hooks
interface IStrategyVaultHooks {
    /// @notice Hook for handling deposit requests
    /// @param share The address of the share token
    /// @param assets The amount of assets requested
    /// @param controller The address of the controller
    /// @param owner The address of the owner of the assets
    /// @return canFulfill Whether the deposit can be fulfilled instantly
    /// @return price The price of the share
    function onRequestDeposit(address share, uint256 assets, address controller, address owner)
        external
        returns (bool canFulfill, uint256 price);

    /// @notice Hook for handling redeem requests
    /// @param share The address of the share token
    /// @param shares The amount of shares requested
    /// @param controller The address of the controller
    /// @param owner The address of the owner of the shares
    /// @return canFulfill Whether the redeem can be fulfilled instantly
    /// @return price The price of the share
    function onRequestRedeem(address share, uint256 shares, address controller, address owner)
        external
        returns (bool canFulfill, uint256 price);

    /// @notice Hook for handling cancel deposit requests
    /// @param share The address of the share token
    /// @param controller The address of the controller
    /// @return canCancel Whether the deposit can be cancelled instantly
    function onCancelDepositRequest(address share, address controller) external returns (bool canCancel);

    /// @notice Hook for handling cancel redeem requests
    /// @param share The address of the share token
    /// @param controller The address of the controller
    /// @return canCancel Whether the redeem can be cancelled instantly
    function onCancelRedeemRequest(address share, address controller) external returns (bool canCancel);

    /// @notice Hook for handling deposit requests
    /// @param share The address of the share token
    /// @param assets The amount of assets to deposit
    /// @param receiver The address of the receiver
    /// @param controller The address of the controller
    function onDeposit(address share, uint256 assets, address receiver, address controller)
        external
        returns (uint256 price);

    /// @notice Hook for handling mint requests
    /// @param share The address of the share token
    /// @param shares The amount of shares to mint
    /// @param receiver The address of the receiver
    /// @param controller The address of the controller
    function onMint(address share, uint256 shares, address receiver, address controller)
        external
        returns (uint256 price);

    /// @notice Hook for handling redeem requests
    /// @param share The address of the share token
    /// @param shares The amount of shares to redeem
    /// @param receiver The address of the receiver
    function onRedeem(address share, uint256 shares, address receiver, address controller) external;

    /// @notice Hook for handling withdraw requests
    /// @param share The address of the share token
    /// @param assets The amount of assets to withdraw
    /// @param receiver The address of the receiver
    /// @param controller The address of the controller
    function onWithdraw(address share, uint256 assets, address receiver, address controller) external;

    /// @notice Hook for handling vault transfers
    /// @param from The address of the sender
    /// @param to The address of the receiver
    /// @param amount The amount of shares to transfer
    function onTransfer(address share, address from, address to, uint256 amount) external;

    /// @notice Operator authorization
    /// @param operator The address of the operator
    /// @dev Reverts for unauthorized operator. Operator should not be an input value of another call
    function authOperator(address operator) external;

    /// @notice Centralized share price
    /// @param share The address of the share token
    function sharePrice(address share) external view returns (uint256 price);

    /// @notice Centralized accrued assets
    /// @param share The address of the share token
    /// @return assets The accrued assets to be distributed
    function accruedAssets(address share) external view returns (uint256 assets);

    /// @notice Centralized max deposit capacity
    /// @param share The address of the share token
    /// @param controller The address of the controller
    /// @return maxAssets The maximum amount of assets that can be deposited
    function maxDeposit(address share, address controller) external view returns (uint256 maxAssets);

    /// @notice Centralized max redeem capacity
    /// @param share The address of the share token
    /// @param controller The address of the controller
    /// @return maxShares The maximum amount of shares that can be redeemed
    function maxRedeem(address share, address controller) external view returns (uint256 maxShares);
}

/// @notice Interface for managing fee manager hooks
interface IFeeManagerHooks {
    /// @notice Hook for handling fee structure changes
    function onFeeStructureChange() external;
}

interface IUpdateLateStatus {
    /// @notice Updates the late status of the loan
    function updateLateStatus() external;
}

/// @notice Interface for managing base strategy components
interface IAccountableStrategy is IStrategyVaultHooks, IFeeManagerHooks, IERC165 {
    /// @notice Event emitted when the borrower is changed
    event BorrowerChanged(address indexed oldBorrower, address indexed newBorrower);

    /// @notice Event emitted when the pending borrower is set
    event PendingBorrowerSet(address indexed pendingBorrower);

    /// @notice Event emitted when the safety module is set
    event SafetyModuleSet(address indexed safetyModule);

    /// @notice Event emitted when the investment manager is set
    event InvestmentManagerSet(address indexed investmentManager);

    /// @notice Event emitted when the proof signer is set
    event ProofSignerSet(address indexed proofSigner);

    /// @notice Event emitted when the DVN publisher is set
    event DVNPublisherSet(address indexed publisher);

    /// @notice Event emitted when the manager fee recipient is set
    event ManagerFeeRecipientSet(address indexed managerFeeRecipient);

    /// @notice Event emitted when the DVN proof is published
    event DVNProofPublished(bytes32 indexed root, bytes32 indexed signature, bytes32 indexed messageHash);

    /// @notice Event emitted when a rate is published
    event RatePublished(address indexed publisher, uint256 oldRate, uint256 newRate);

    /// @notice Event emitted when the default is rejected
    event LoanDefaultRejected();

    /// @notice Event emitted when the default is accepted
    event LoanDefaulted(uint256 principal, uint256 collateral);

    /// @notice Event emitted when the penalties enabled flag is set
    event PenaltiesEnabledSet(bool enabled);

    /// @notice Event emitted when the security admin enabled flag is set
    event SecurityAdminEnabledSet(bool enabled);

    /// @notice Event emitted when the operations admin enabled flag is set
    event OperationsAdminEnabledSet(bool enabled);

    /// @notice Event emitted when the reserve threshold is set
    event ReserveThresholdSet(uint256 threshold);

    /// @notice Event emitted when the rewards distributor is set
    event RewardsDistributorSet(address indexed rewardsDistributor);

    /// @notice Event emitted when the price oracle is set
    event PriceOracleSet(address indexed priceOracle);

    /// @notice Set a new pending borrower
    /// @param newBorrower Address of the new pending borrower
    function setPendingBorrower(address newBorrower) external;

    /// @notice Accept the borrower role as pending borrower
    function acceptBorrowerRole() external;

    /// @notice Set a new safety module contract
    /// @dev It can act as a factory in a deploy-and-set manner
    /// @param safetyModule Address of the new safety module
    function setSafetyModule(address safetyModule) external;

    /// @notice Set a new rewards distributor contract
    /// @dev It can act as a factory in a deploy-and-set manner
    /// @param rewards Address of the new rewards distributor
    function setRewardsDistributor(address rewards) external;

    /// @notice Set a new price oracle contract
    /// @param priceOracle Address of the new price oracle
    function setPriceOracle(address priceOracle) external;

    /// @notice Set a new investment manager contract
    /// @param investmentManager Address of the new investment manager
    function setInvestmentManager(address investmentManager) external;

    /// @notice Set the auth signer address
    /// @dev This is function relays data to the vault's access module
    ///      It sets the kyc verification signer when permission level is `KYC`
    /// @param authSigner Address of the new auth signer
    function setAuthSigner(address authSigner) external;

    /// @notice Set the lenders addresses and permissions
    /// @dev This is function relays data to the vault's access module
    ///      It whitelists lenders when permission level is `Whitelist`
    /// @param lenders Addresses of the lenders to be whitelisted
    /// @param allowed Whether the lenders are allowed to perform actions
    function setLenders(address[] calldata lenders, bool[] calldata allowed) external;

    /// @notice Set the proof signer address
    /// @param proofSigner Address of the new proof signer
    function setProofSigner(address proofSigner) external;

    /// @notice Set the DVN publisher address
    /// @param publisher Address of the new DVN publisher
    function setDVNPublisher(address publisher) external;

    /// @notice Set the manager fee recipient address
    /// @param managerFeeRecipient Address of the new manager fee recipient
    function setManagerFeeRecipient(address managerFeeRecipient) external;

    /// @notice Publish a new DVN proof
    /// @param proof Latest DVN proof data
    function publishDVNProof(DVNProof memory proof) external;

    /// @notice Publish a new rate
    /// @param newRate The new rate to publish (can be interest rate, NAV etc.)
    /// @param measuredAt The timestamp of the measurement being published
    function publishRate(uint256 newRate, uint256 measuredAt) external;

    /// @notice Accept the default of the loan
    function acceptDefault() external;

    /// @notice Reject the default of the loan
    function rejectDefault() external;

    /// @notice Set the penalties enabled flag
    /// @param enabled Whether penalties are enabled
    function setPenaltiesEnabled(bool enabled) external;

    /// @notice Set the security admin enabled flag
    /// @param enabled Whether security admin is enabled
    function setSecurityAdminEnabled(bool enabled) external;

    /// @notice Set the operations admin enabled flag
    /// @param enabled Whether operations admin is enabled
    function setOperationsAdminEnabled(bool enabled) external;

    /// @notice Set the shares transferable flag
    /// @param transferable Whether shares are transferable
    function setSharesTransferable(bool transferable) external;

    /// @notice Set the min reserve threshold required in the vault
    /// @param threshold The threshold expressed in basis points
    function setReserveThreshold(uint256 threshold) external;

    /// @notice Get the global registry contract address
    /// @return The global registry address
    function globals() external view returns (address);

    /// @notice Get the current borrower address
    /// @return The borrower address
    function borrower() external view returns (address);

    /// @notice Get the pending borrower address
    /// @return The pending borrower address
    function pendingBorrower() external view returns (address);

    /// @notice Get the investment manager contract address
    /// @return The investment manager address
    function investmentManager() external view returns (address);

    /// @notice Get the fee manager contract address
    /// @return The fee manager address
    function feeManager() external view returns (address);

    /// @notice Get the safety module contract address
    /// @return The safety module address
    function safetyModule() external view returns (address);

    /// @notice Get the rewards distributor contract address
    /// @return The rewards distributor address
    function rewards() external view returns (address);

    /// @notice Get the price oracle contract address
    /// @return The price oracle address
    function priceOracle() external view returns (address);

    /// @notice Get the DVN publisher contract address
    /// @return The DVN publisher address
    function dvnPublisher() external view returns (address);

    /// @notice Get the manager fee recipient address
    /// @return The manager fee recipient address
    function managerFeeRecipient() external view returns (address);

    /// @notice Get the proof signer address
    /// @return The proof signer address
    /// @dev Returns the pub key of the node signing proofs
    function proofSigner() external view returns (address);

    /// @notice Get the vault contract address
    /// @return The vault address
    function vault() external view returns (address);

    /// @notice Get the current loan state
    /// @return The loan struct
    function loan() external view returns (Loan memory);

    /// @notice Get the DVN proof
    /// @return The latest DVN proof data
    function dvnProof() external view returns (DVNProof memory);

    /// @notice Get the loan state
    /// @return The loan state enum value
    function loanState() external view returns (LoanState);

    /// @notice Get the penalties enabled flag
    /// @return The penalties enabled flag
    function penaltiesEnabled() external view returns (bool);

    /// @notice Get the security admin enabled flag
    /// @return The security admin enabled flag
    function securityAdminEnabled() external view returns (bool);

    /// @notice Get the operations admin enabled flag
    /// @return The operations admin enabled flag
    function operationsAdminEnabled() external view returns (bool);

    /// @notice Get the precision for the strategy
    /// @return The precision
    function PRECISION() external view returns (uint256);

    /// @notice Get the basis points for the strategy
    /// @return The basis points
    function BASIS_POINTS() external view returns (uint256);

    /// @notice Get the version of the strategy
    /// @dev Increment when upgrading the strategy
    function version() external view returns (uint256);
}

/// @notice Interface for managing loan lifecycle and payments
interface IAccountableLoan is IAccountableStrategy {
    /// @notice Event emitted when the loan is initialized
    /// @param minCapacity The minimum loan capacity
    /// @param maxCapacity The maximum loan capacity
    /// @param interestRate The interest rate of the loan
    /// @param lateInterestPenalty The late interest penalty
    /// @param interestInterval The interest interval
    /// @param duration The duration of the loan
    event LoanTermsSet(
        uint256 minCapacity,
        uint256 maxCapacity,
        uint256 interestRate,
        uint256 lateInterestPenalty,
        uint256 interestInterval,
        uint256 duration
    );

    /// @notice Event emitted when the default is initiated
    event LoanDefaultInitiated();

    /// @notice Event emitted when a default is covered by safety collateral
    /// @param safetyModule The address of the safety module
    /// @param provider The address of the provider
    /// @param collateral The amount of collateral covered
    event DefaultCovered(address indexed safetyModule, address indexed provider, uint256 collateral);

    /// @notice Event emitted when funds are borrowed
    /// @param borrower The address of the borrower
    /// @param assets The amount of funds borrowed
    event Borrowed(address indexed borrower, uint256 assets);

    /// @notice Event emitted when the loan is repaid
    /// @param assets The amount of funds repaid
    event LoanRepaid(uint256 assets);

    /// @notice Event emitted when the loan is partially repaid
    /// @param amount The amount of funds repaid to close loan
    /// @param remainingInterest The remaining interest amount
    event LoanPrepaid(uint256 amount, uint256 remainingInterest);

    /// @notice Event emitted when interest is paid
    /// @param borrower The address of the borrower
    /// @param totalAmount The total amount paid
    /// @param interestPenalty The interest penalty amount paid
    /// @param performanceFee The performance fee amount paid
    /// @param managementFee The management fee amount paid
    /// @param paymentInterval The interval of the payment
    event InterestPaid(
        address indexed borrower,
        uint256 totalAmount,
        uint256 interestPenalty,
        uint256 performanceFee,
        uint256 establishmentFee,
        uint256 managementFee,
        uint256 paymentInterval
    );

    /// @notice Initialize a new loan with the given terms
    /// @param terms The loan terms to initialize with
    function setTerms(LoanTerms memory terms) external;

    /// @notice Update an existing loan with new terms
    /// @param terms The new loan terms to update to
    function updateTerms(LoanTerms memory terms) external;

    /// @notice Initialize loan default state
    function defaultLoan() external;

    /// @notice Cover the default of the loan
    /// @param assets The amount of assets to cover
    function coverDefault(uint256 assets) external;

    /// @notice Borrow funds from the loan
    /// @param assets The amount of funds to borrow
    function borrow(uint256 assets) external;

    /// @notice Repay the loan amount
    /// @param assets The amount of funds to repay
    function repay(uint256 assets) external;

    /// @notice Make a partial loan repayment
    function prepay() external;

    /// @notice Make an interest payment
    /// @param assets The interest amount to pay
    function pay(uint256 assets) external;

    /// @notice Get the period of time the loan has been delinquent
    /// @return The period of time the loan has been delinquent
    function timeDelinquent() external view returns (uint256);
}
