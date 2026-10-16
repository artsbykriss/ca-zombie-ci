// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IAccountableStrategy, Loan, DVNProof, LoanState} from "../../interfaces/IAccountableStrategy.sol";

/// @title StrategyStorage
/// @notice Storage layout for AccountableStrategy with upgrade safety gap
/// @dev Centralizes storage to avoid collisions and simplify upgradeable contract development
///      All storage variables MUST be declared here
abstract contract StrategyStorage is IAccountableStrategy {
    /// @dev whether paused by admin
    bool internal _pausedByAdmin;

    /// @dev loan terms and state
    Loan internal _loan;

    /// @dev DVN proof
    DVNProof internal _dvnProof;

    /// @dev timestamp when the default is valid
    uint256 internal _defaultValidAt;

    /// @dev whether penalties are enabled
    bool public penaltiesEnabled;

    /// @dev whether security admin is enabled
    bool public securityAdminEnabled;

    /// @dev whether operations admin is enabled
    bool public operationsAdminEnabled;

    /// @notice loan borrower
    address public borrower;

    /// @notice pending loan borrower
    address public pendingBorrower;

    /// @dev loan state
    LoanState public loanState;

    /// @notice address of global registry
    address public globals;

    /// @notice address of fee manager
    address public feeManager;

    /// @notice address of safety module
    address public safetyModule;

    /// @notice address of proof signer
    /// @dev This is the public key of the DVN proof signer
    ///      It can be used to verify the published DVN proofs
    address public proofSigner;

    /// @notice address of vault
    address public vault;

    /// @notice address of investment manager
    address public investmentManager;

    /// @notice address of rewards distributor
    address public rewards;

    /// @notice address of price oracle
    address public priceOracle;

    /// @notice address of DVN publisher
    address public dvnPublisher;

    /// @notice address of manager fee recipient
    address public managerFeeRecipient;

    /// @dev Gap for future storage variables in base contract
    /// @dev Reserves 50 slots for future additions to AccountableStrategy
    uint256[48] private __gap;
}
