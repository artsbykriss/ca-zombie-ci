// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {LoanTerms} from "../../interfaces/IAccountableStrategy.sol";
import {IAccountableOpenTerm, WithdrawalBatch, DVNRateUpdate} from "../../interfaces/IAccountableOpenTerm.sol";

/// @title OpenTermStorage
/// @notice Storage layout for AccountableOpenTerm with upgrade safety gap
/// @dev Centralizes storage to avoid collisions and simplify upgradeable contract development
///      All storage variables MUST be declared here
abstract contract OpenTermStorage is IAccountableOpenTerm {
    /// @notice Scale factor of all interest accrual
    uint256 internal _scaleFactor;

    /// @notice Scale factor of interest accrual excluding performance fee
    uint256 internal _scaleFactorNet;

    /// @notice Interest rate excluding performance fee rate
    uint256 internal _netInterestRate;

    /// @notice Last interest accrual timestamp
    uint256 internal _accruedAt;

    /// @notice Last interest payment timestamp
    uint256 internal _lastPaidTime;

    /// @dev Pending terms update
    LoanTerms internal _pendingTerms;

    /// @dev Approved interest rate proposers
    mapping(address proposer => bool approved) internal _proposers;

    /// @dev Withdrawal batches
    mapping(uint256 id => WithdrawalBatch batch) internal _withdrawalBatches;

    /// @notice address of base token
    address public asset;

    /// @dev Current withdrawal batch
    uint256 public currentBatch;

    /// @dev Pending withdrawal batch
    uint256 public pendingBatch;

    /// @dev Time when delinquency started
    uint256 public delinquencyStartTime;

    /// @dev Pending interest rate
    uint256 public pendingInterestRate;

    /// @notice Last DVN rate update (for rollback)
    DVNRateUpdate public lastRateUpdate;

    /// @dev Net principal borrowed for capacity tracking
    uint256 public netPrincipal;

    /// @dev Controller share mapping for tracking batch shares on cancellation
    mapping(address controller => mapping(uint256 batchId => uint256 shares)) internal _controllerBatchShares;

    /// @dev Gap for future storage variables in AccountableOpenTerm
    /// @dev Reserves slots for future additions to AccountableOpenTerm
    uint256[44] private __gap;
}
