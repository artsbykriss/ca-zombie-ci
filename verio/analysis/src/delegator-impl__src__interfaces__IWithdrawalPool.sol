// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IVersionable.sol";

/// @title Withdrawal Pool Interface
/// @notice Interface for managing withdrawals with unbonding periods
/// @dev Handles the withdrawal process for staked assets including unbonding periods and insurance coverage
interface IWithdrawalPool is IVersionable {
    /// @notice State of the withdrawal pool
    /// @dev Tracks withdrawals by recipient and total pending withdrawals
    /// @custom:storage-location erc7201:VerioIP.WithdrawalPool.WithdrawalPoolState
    struct WithdrawalPoolState {
        mapping(address => Withdrawal[]) withdrawalsByRecipient;
        uint256 totalPendingWithdrawals;
    }

    /// @notice Configuration of the withdrawal pool
    /// @dev Placeholder in case we need config in the future
    struct WithdrawalPoolConfig {
        bytes[32] buffer;
    }

    /// @notice Structure representing a single withdrawal request
    /// @dev Tracks both the amount and when it becomes available
    struct Withdrawal {
        uint256 amount;
        uint256 unbondedTimestamp;
    }

    /// @notice Emitted when the withdrawal pool receives funds
    /// @param _amount The amount of funds added to the pool
    event WithdrawalPoolFunded(uint256 _amount);

    /// @notice Emitted when a new withdrawal request is added
    /// @param _recipient Address of the withdrawal recipient
    /// @param _amount Amount requested for withdrawal
    /// @param _unbondedTimestamp Timestamp when the withdrawal becomes available
    event WithdrawalAdded(address _recipient, uint256 _amount, uint256 _unbondedTimestamp);

    /// @notice Emitted when a withdrawal is claimed
    /// @param _recipient Address of the recipient claiming the withdrawal
    /// @param _amount Amount claimed
    event WithdrawalClaimed(address _recipient, uint256 _amount);

    /// @notice Error when there are no withdrawals to claim
    error NoWithdrawalsToProcess();

    /// @notice Error when withdrawals are still unbonding
    error WithdrawalsStillUnbonding();

    /// @notice Error when funds transfer fails
    /// @param recipient The address that should receive the funds
    /// @param amount The amount that failed to transfer
    error TransferFailed(address recipient, uint256 amount);

    /// @notice Error when caller is not authorized
    /// @param admin The admin address
    /// @param stakePool The stake pool address
    error OnlyAdminOrStakePool(address admin, address stakePool);

    /// @notice Funds the withdrawal pool
    function fund() external payable;

    /// @notice Allows users to claim their available withdrawals
    function withdraw() external;

    /// @notice Adds a new withdrawal request for a recipient
    /// @param _recipient Address that can claim the withdrawal
    /// @param _amount Amount to be withdrawn
    /// @param _unbondingPeriod Duration before the withdrawal becomes available
    function addWithdrawal(address _recipient, uint256 _amount, uint256 _unbondingPeriod) external;

    /// @notice Manages excess balance in the withdrawal pool
    function handleBalance() external;

    /// @notice Returns the total balance in the withdrawal pool
    /// @return Total amount of funds in the pool
    function getTotalWithdrawalPool() external view returns (uint256);

    /// @notice Returns the total amount of pending withdrawals
    /// @return Sum of all pending withdrawal amounts
    function getTotalPendingWithdrawals() external view returns (uint256);

    /// @notice Gets all withdrawals for a specific recipient
    /// @param _recipient Address to check withdrawals for
    /// @return Array of all withdrawals for the recipient
    function getWithdrawalsByRecipient(address _recipient) external view returns (Withdrawal[] memory);

    /// @notice Gets only the unbonded withdrawals for a specific recipient
    /// @param _recipient Address to check withdrawals for
    /// @return Array of withdrawals that have completed their unbonding period
    function getUnbondedWithdrawalsByRecipient(address _recipient) external view returns (Withdrawal[] memory);
}
