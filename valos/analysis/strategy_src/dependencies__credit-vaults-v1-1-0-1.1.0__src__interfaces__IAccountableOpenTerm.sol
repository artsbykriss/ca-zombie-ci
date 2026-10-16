// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {PermissionLevel} from "./IAccess.sol";
import {IAccountableLoan, LoanTerms, IUpdateLateStatus} from "./IAccountableStrategy.sol";

/// @notice Struct for withdrawal batches
struct WithdrawalBatch {
    /// @notice The expiry time of the withdrawal batch
    uint256 expiry;
    /// @notice The start time of the withdrawal batch
    uint256 startTime;
    /// @notice The total shares of the withdrawal batch
    uint256 totalShares;
}

/// @notice DVN rate update state for rollback capability
struct DVNRateUpdate {
    /// @notice The new rate that was applied
    uint256 rate;
    /// @notice The rate before the update (for rollback)
    uint256 previousRate;
    /// @notice When the update was applied
    uint256 timestamp;
    /// @notice Scale factor at time of update (for rollback)
    uint256 scaleFactorSnapshot;
}

/// @notice Parameters for initializing the AccountableOpenTerm contract
struct OpenTermInitParams {
    /// @notice The asset of the loan
    address asset;
    /// @notice The global registry address
    address globals;
    /// @notice The fee manager of the loan
    address feeManager;
    /// @notice The investment manager of the loan
    address investmentManager;
    /// @notice The permission level of the loan
    PermissionLevel permissionLevel;
    /// @notice Whether the shares are transferable
    bool sharesTransferable;
    /// @notice The name of the share token
    string name;
    /// @notice The symbol of the share token
    string symbol;
}

/// @notice Interface for the AccountableOpenTerm contract
interface IAccountableOpenTerm is IAccountableLoan, IUpdateLateStatus {
    /// @notice Event emitted when the terms are accepted
    event TermsAccepted();

    /// @notice Event emitted when the terms are rejected
    event TermsRejected();

    /// @notice Event emitted when the interest rate is proposed
    event InterestRateProposed(uint256 interestRate);

    /// @notice Event emitted when the interest rate is approved
    event InterestRateApproved(uint256 interestRate);

    /// @notice Event emitted when a proposer is set
    event ProposerSet(address indexed proposer, bool approved);

    /// @notice Event emitted when the delinquency status changes
    /// @param isDelinquent Whether the loan is currently delinquent
    /// @param timestamp The timestamp of the delinquency status change
    event DelinquencyStatusChanged(bool isDelinquent, uint256 timestamp);

    /// @notice Emitted when a rate update is rolled back
    event RateRolledBack(uint256 rolledBackRate, uint256 restoredRate, uint256 originalTimestamp);

    /// @notice Emitted when fee shares are minted
    /// @param recipient The address of the recipient
    /// @param shares The amount of fee shares minted
    event FeeSharesMinted(address indexed recipient, uint256 shares);

    /// @notice Accepts the terms of the loan
    function acceptTerms() external;

    /// @notice Rejects the new terms of the loan
    function rejectTerms() external;

    /// @notice Sets a proposer as approved or not
    /// @param proposer The interest rate proposer
    /// @param approved Whether the proposer is approved
    function setProposer(address proposer, bool approved) external;

    /// @notice Proposes a new interest rate for the loan
    /// @param interestRate The new pending interest rate
    /// @dev Proposal made by a borrower and pending approval
    function proposeInterestRate(uint256 interestRate) external;

    /// @notice Accepts the interest rate change of the loan
    /// @dev Only operational roles should have this authorization
    function approveInterestRateChange() external;

    /// @notice Rolls back the most recent DVN rate update within the rollback window
    function rollbackRate() external;

    /// @notice Manual interest accrual
    /// @return newScaleFactor The new scale factor
    function accrueInterest() external returns (uint256 newScaleFactor);

    /// @notice Processes available withdrawals
    /// @return usedAssets The number of assets used to process the withdrawals
    function processAvailableWithdrawals() external returns (uint256 usedAssets);

    /// @notice The withdrawal batches
    /// @param id Withdrawal batch id
    /// @return withdrawalBatch The withdrawal batch
    function withdrawalBatches(uint256 id) external view returns (WithdrawalBatch memory);

    /// @notice The new pending loan terms
    /// @return The loan terms
    function pendingTerms() external view returns (LoanTerms memory);

    /// @notice The current withdrawal batch
    /// @return The current withdrawal batch
    function currentBatch() external view returns (uint256);

    /// @notice The pending withdrawal batch
    /// @return The pending withdrawal batch
    function pendingBatch() external view returns (uint256);

    /// @notice The interest accrual factor
    /// @return The last valid scaleFactor recorded
    /// @dev This value can be stale and not reflect the current interest accrual
    function scaleFactor() external view returns (uint256);

    /// @notice Last repayment time
    /// @return The timestamp of the last repayment
    function lastPaidTime() external view returns (uint256);

    /// @notice The proposed interest rate
    function pendingInterestRate() external view returns (uint256);

    /// @notice The delinquency start time
    function delinquencyStartTime() external view returns (uint256);
}
