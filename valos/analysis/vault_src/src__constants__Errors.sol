// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

// ========================================================================== //
//                             Authorization Errors                           //
// ========================================================================== //

/// @notice Error thrown when unauthorized
error Unauthorized();

/// @notice Thrown when a signature verification fails due to invalid signer
error InvalidSigner();

/// @notice Thrown when a nonce verification fails due to invalid nonce
error InvalidNonce();

/// @notice Thrown when an operation is attempted with invalid operator permissions
error InvalidOperator();

/// @notice Error thrown when invalid pending borrower is provided
error InvalidPendingBorrower();

/// @notice Thrown when KYC status is not verified
error KYCNotVerified();

/// @notice Thrown when a block expiration is invalid (e.g. in the past)
error InvalidBlockExpiration();

/// @notice Thrown when a signature verification fails
error InvalidSignature();

/// @notice Thrown when a message data length is invalid
error InvalidMsgDataLength();

/// @notice Thrown when an accounts array is empty
error EmptyAccountsArray();

/// @notice Error thrown when the state is invalid
error InvalidState();

/// @notice Error thrown when a value is invalid
error InvalidValue();

// ========================================================================== //
//                             Vault operations errors                        //
// ========================================================================== //

/// @notice Error thrown when trying to cancel a redeem request failed
error CancelRedeemRequestFailed();

/// @notice Error thrown when deposit amount exceeds max deposit
error ExceedsMaxDeposit();

/// @notice Error thrown when assets exceed redemption limits
error ExceedsRedeemLimit();

/// @notice Error thrown when redeem amount exceeds max redeem
error ExceedsMaxRedeem();

/// @notice Error thrown when deposit/withdraw amount is insufficient
error InsufficientAmount();

/// @notice Error thrown when redeem share amount is insufficient
error InsufficientShares();

/// @notice Error thrown when no redeem request exists
error NoRedeemRequest();

/// @notice Error thrown when no pending redeem request exists
error NoPendingRedeemRequest();

/// @notice Thrown when attempting to transfer shares that are not transferable
error SharesNotTransferable();

/// @notice Error thrown when withdrawal queue is not empty
error WithdrawalQueueNotEmpty();

/// @notice Error thrown when no queue request exists
error NoQueueRequest();

/// @notice Error thrown when redeem amount exceeds liquidity
error InsufficientLiquidity();

/// @notice Error thrown when asset is not whitelisted
error AssetNotWhitelisted();

// ========================================================================== //
//                             Loan operations errors                         //
// ========================================================================== //

/// @notice Error thrown when loan terms are already set
error LoanTermsAlreadySet();

/// @notice Error thrown when loan terms are not set
error LoanTermsNotSet();

/// @notice Error thrown when loan is ongoing
error LoanOngoing();

/// @notice Error thrown when loan is not ongoing
error LoanNotOngoing();

/// @notice Error thrown when loan is not in default
error LoanNotInDefault();

/// @notice Error thrown when default is already pending
error DefaultAlreadyPending();

/// @notice Error thrown when loan terms are not met
error LoanTermsNotMet();

/// @notice Error thrown when loan has not matured
error LoanNotMatured();

/// @notice Error thrown when repayment terms are not met
error LoanCannotBeRepaid();

/// @notice Error thrown when there are outstanding interest payments
error OutstandingInterestPayments();

/// @notice Thrown when an operation is attempted with invalid controller permissions
error InvalidController();

/// @notice Thrown when an operation is attempted with invalid interval duration pair
error InvalidIntervalDurationPair();

/// @notice Thrown when an operation is attempted with invalid interval length
error InvalidIntervalLength();

/// @notice Thrown when an operation is attempted with invalid withdrawal period
error InvalidWithdrawalPeriod();

/// @notice Error thrown when capacity is set to a lower value than acceptable
error CapacityTooLow();

/// @notice Error thrown when accept grace period is longer than acceptable for the loan
error AcceptGracePeriodTooLong();

/// @notice Error thrown when a threshold exceeds the max bound
error ThresholdTooHigh();

/// @notice Error thrown when attempting to pay when no payment is due
error NoPaymentDue();

/// @notice Error thrown when NAV is stale
error NAVGracePeriodExpired();

/// @notice Error thrown when DVN measurement is stale relative to state changes
error StaleMeasurement();

/// @notice Error thrown when early exit debt mismatch
error EarlyExitDebtMismatch();

// ========================================================================== //
//                            General errors                                  //
// ========================================================================== //

/// @notice Thrown when an index is out of bounds
error OutOfBounds();

/// @notice Thrown when an invalid range is provided
error InvalidRange();

/// @notice Thrown when an input address is address(0)
error ZeroAddress();

/// @notice Thrown when a value is zero
error ZeroValue();

/// @notice Thrown when deployment of a loan proxy contract fails
/// @param reason The reason for the failed deployment
error FailedDeployment(string reason);

/// @notice Thrown when a deposit is not allowed
error DepositNotAllowed();

/// @notice Thrown when a redeem is not allowed
error RedeemNotAllowed();

/// @notice Thrown when input arrays lengths don't match
error ArrayLengthMismatch();

/// @notice Error thrown when an operation is not required/allowed for the current permission level
error PermissionLevelMismatch();

/// @notice Error thrown when an operation is not supported by the strategy
error NotSupportedByStrategy();

// ========================================================================== //
//                            Fee Manager errors                              //
// ========================================================================== //

/// @notice Error thrown when manager split is invalid
error InvalidManagerSplit();

/// @notice Error thrown when prepayment fee is invalid
error InvalidPrepaymentFee();

/// @notice Error thrown when establishment and management fees are set together
error InvalidFeeStructure();

/// @notice Error thrown when establishment fee is invalid
error InvalidEstablishmentFee();

/// @notice Error thrown when performance fee is invalid
error InvalidPerformanceFee();

/// @notice Error thrown when management fee is invalid
error InvalidManagementFee();

// ========================================================================== //
//                            Rewards errors                                  //
// ========================================================================== //

/// @notice Error thrown when a root is already set
error RootAlreadySet();

/// @notice Error thrown when no root is set
error RootNotSet();

/// @notice Error thrown when a root is already pending
error RootAlreadyPending();

/// @notice Error thrown when no pending root is set
error NoPendingRoot();

/// @notice Error thrown when timelock is not expired
error TimelockNotExpired();

/// @notice Error thrown when a proof is invalid
error InvalidProof();

/// @notice Error thrown when the amount to claim is not enough
error NotEnoughClaimableAmount();

/// @notice Error thrown when an invalid rewards type is provided
error InvalidRewardsType();

// ========================================================================== //
//                            Rate change errors                              //
// ========================================================================== //

/// @notice Error thrown when rollback window has expired
error RollbackWindowExpired();

/// @notice Error thrown when rate is too high
error RateTooHigh();

// ========================================================================== //
//                            Publisher errors                                 //
// ========================================================================== //

/// @notice Error thrown when threshold is too high
error InvalidThreshold();

/// @notice Error thrown when the threshold is not reached
error ThresholdNotReached();

/// @notice Error thrown when no batch has been published yet
error NoBatchPublished();

/// @notice Error thrown when request targets wrong batch
error InvalidBatchId();

/// @notice Error thrown when a publish request has expired (too stale)
error RequestExpired();

/// @notice Error thrown when too many pending requests exist
error TooManyRequests();

/// @notice Error thrown when deviation from previous value is too high
error DeviationTooHigh();

/// @notice Error thrown when request timestamp is in the future
error InvalidTimestamp();

/// @notice Error thrown when NAV grace period is invalid
error InvalidNavGracePeriod();
