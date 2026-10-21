// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IVersionable.sol";

/// @title Reward Pool Interface
/// @notice Interface for managing a pool of rewards that can be claimed by stakers
/// @dev This interface defines the core functionality for reward distribution and configuration
interface IRewardPool is IVersionable {
    /// @notice State for the reward pool
    /// @param feeBps Fee percentage in basis points (100 = 1%)
    /// @param restakedRewards Amount of rewards that have been restaked
    /// @custom:storage-location erc7201:VerioIP.RewardPool.RewardPoolState
    struct RewardPoolState {
        uint256 feeBps;
        uint256 restakedRewards;
    }

    /// @notice Configuration structure for the reward pool
    /// @param feeBps Fee percentage in basis points (100 = 1%)
    struct RewardPoolConfig {
        uint256 feeBps;
    }

    /// @notice Emitted when rewards are claimed from the pool
    /// @param recipient Address receiving the rewards
    /// @param amount Amount of rewards claimed
    event RewardClaimed(address indexed recipient, uint256 amount);

    /// @notice Emitted when the reward pool receives funding
    /// @param amount Amount of funds added to the pool (in IP)
    event RewardPoolFunded(uint256 amount);

    /// @notice Emitted when the reward pool is updated
    /// @param rewardPoolState The new reward pool state
    event RewardPoolStateUpdated(RewardPoolState rewardPoolState);

    /// @notice Error when fee basis points exceed maximum
    /// @param maxFeeBps The maximum allowed fee basis points
    error MaxFeeBpsExceeded(uint256 maxFeeBps);

    /// @notice Error when transfer to treasury fails
    /// @param treasury The treasury address
    /// @param amount The amount that failed to transfer
    error TreasuryTransferFailed(address treasury, uint256 amount);

    /// @notice Error when transfer to caller fails
    /// @param caller The caller address
    /// @param amount The amount that failed to transfer
    error RewardTransferFailed(address caller, uint256 amount);

    /// @notice Funds the reward pool with IP
    function fund() external payable;

    /// @notice Claims available rewards from the pool
    /// @dev Can only be called by the stake pool contract
    function claimRewards() external;

    /// @notice Returns the current balance of unclaimed rewards
    /// @return Amount of available rewards (in IP)
    function getRewards() external view returns (uint256);

    /// @notice Returns the total amount of rewards that have been restaked
    /// @return Amount of restaked rewards (in IP)
    function getRestakedRewards() external view returns (uint256);

    /// @notice Returns the current fee in basis points
    /// @return Current fee percentage in basis points (100 = 1%)
    function getFeeBps() external view returns (uint256);

    /// @notice Updates the fee percentage
    /// @param _feeBps New fee percentage in basis points (100 = 1%)
    function setFeeBps(uint256 _feeBps) external;
}
