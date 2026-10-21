// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IVersionable.sol";
import "./Story/IIPTokenStaking.sol";

/// @title Stake Pool Interface
/// @notice Interface for the main staking pool contract that handles IP to vIP conversions
/// @dev Manages staking, unstaking, and configuration of the staking pool
interface IStakePool is IVersionable {
    /// @notice Configuration structure for the stake pool
    /// @dev Contains all configurable parameters
    /// @custom:storage-location erc7201:VerioIP.StakePool.StakePoolState
    struct StakePoolState {
        uint256 singularity;
        uint256 minStake;
        uint256 maxStakeIterations;
        uint256 maxStake;
        uint256 delegationSize;
        uint256 unbondingPeriod;
        uint256 mintFeeBps;
        uint256 burnFeeBps;
        uint256 pendingUnstake;
        uint256 excessUnstake;
        bool mintFeeEnabled;
        bool burnFeeEnabled;
    }

    /// @notice Configuration structure for the stake pool
    /// @dev Contains all configurable parameters
    struct StakePoolConfig {
        uint256 singularity;
        uint256 minStake;
        uint256 maxStakeIterations;
        uint256 maxStake;
        uint256 delegationSize;
        uint256 unbondingPeriod;
        uint256 mintFeeBps;
        uint256 burnFeeBps;
        bool mintFeeEnabled;
        bool burnFeeEnabled;
    }

    /// @notice Emitted when a user stakes IP
    /// @param staker Address of the staking user
    /// @param amount Amount of IP staked
    event Staked(address staker, uint256 amount);

    /// @notice Emitted when a user unstakes vIP
    /// @param staker Address of the unstaking user
    /// @param amount Amount of IP unstaked
    event Unstaked(address staker, uint256 amount);

    /// @notice Emitted when rewards are received
    /// @param amount Amount of rewards received
    event RewardReceived(uint256 amount);

    /// @notice Emitted when the stake pool is updated
    /// @param stakePoolState The new stake pool state
    event StakePoolStateUpdated(StakePoolState stakePoolState);

    /// @notice Error when singularity is invalid
    error InvalidSingularity();

    /// @notice Error when max stake iterations is invalid
    error InvalidMaxStakeIterations();

    /// @notice Error when delegation size is invalid
    error InvalidDelegationSize();

    /// @notice Error when min stake is invalid
    error InvalidMinStake();

    /// @notice Error when mint fee exceeds maximum
    /// @param maxMintFeeBps The maximum mint fee in basis points
    error MaxMintFeeExceeded(uint256 maxMintFeeBps);

    /// @notice Error when burn fee exceeds maximum
    /// @param maxBurnFeeBps The maximum burn fee in basis points
    error MaxBurnFeeExceeded(uint256 maxBurnFeeBps);

    /// @notice Error when max stake is invalid
    error InvalidMaxStake();

    /// @notice Error when stake amount is not a multiple of 1 gwei
    error StakeNotGweiMultiple();

    /// @notice Error when stake is less than minimum
    /// @param minStake The minimum stake amount
    error StakeLessThanMinimum(uint256 minStake);

    /// @notice Error when admin stake is less than delegation size
    /// @param delegationSize The minimum delegation size
    error AdminStakeLessThanDelegationSize(uint256 delegationSize);

    /// @notice Error when unstaking before singularity
    /// @param singularity The singularity block height
    error CannotUnstakeBeforeSingularity(uint256 singularity);

    /// @notice Error when unstaking 0 IP
    error CannotUnstakeZeroIP();

    /// @notice Funds the contract with native currency
    function fund() external payable;

    /// @notice Stakes native currency and receives vIP tokens
    /// @param _evaluate Whether to evaluate the stakePool immediately
    function stake(bool _evaluate) external payable;

    /// @notice Evaluates the stake pool and updates the state
    function evaluateStakePool() external;

    /// @notice Allows admin to stake with specific validator and maturity
    /// @param _validator Validator identification bytes
    /// @param _maturity Staking period enum value
    function adminStake(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity) external payable;

    /// @notice Triggers a reward claim and restaking process
    function restake() external;

    /// @notice Unstakes vIP tokens and initiates withdrawal
    /// @param _vIPAmount Amount of vIP to unstake
    function unstake(uint256 _vIPAmount) external;

    /// @notice Calculates amount of vIP to mint for a given IP amount
    /// @param _ipAmount Amount of IP to calculate vIP for
    /// @return Amount of vIP that would be minted
    function calculateVIPMint(uint256 _ipAmount) external view returns (uint256);

    /// @notice Calculates amount of IP to withdraw for a given vIP amount
    /// @param _vIPToBurn Amount of vIP to calculate IP withdrawal for
    /// @return Amount of IP that would be withdrawn
    function calculateIPWithdrawal(uint256 _vIPToBurn) external view returns (uint256);

    /// @notice Gets the current balance of the stake pool
    /// @return Current balance in native currency
    function getStakePoolAmount() external view returns (uint256);

    /// @notice Gets the total amount of IP staked
    /// @return Total amount of IP staked across all validators
    function getTotalStake() external view returns (uint256);

    /// @notice Gets the amount of unstaked IP available
    /// @return Amount of excess IP from unstaking operations
    function getUnstaked() external view returns (uint256);

    /// @notice Gets the minimum stake amount required
    /// @return Minimum amount of IP that can be staked
    function getMinStake() external view returns (uint256);

    /// @notice Sets the minimum stake amount
    /// @param _minStake New minimum stake amount
    /// @dev Only callable by admin
    function setMinStake(uint256 _minStake) external;

    /// @notice Gets the current mint fee in basis points
    /// @return Current mint fee (100 = 1%)
    function getMintFeeBps() external view returns (uint256);

    /// @notice Sets the mint fee in basis points
    /// @param _mintFeeBps New mint fee (100 = 1%)
    /// @dev Only callable by admin
    function setMintFeeBps(uint256 _mintFeeBps) external;

    /// @notice Gets the current burn fee in basis points
    /// @return Current burn fee (100 = 1%)
    function getBurnFeeBps() external view returns (uint256);

    /// @notice Sets the burn fee in basis points
    /// @param _burnFeeBps New burn fee (100 = 1%)
    /// @dev Only callable by admin
    function setBurnFeeBps(uint256 _burnFeeBps) external;

    /// @notice Gets the unbonding period
    /// @return Unbonding period in seconds
    function getUnbondingPeriod() external view returns (uint256);

    /// @notice Sets the unbonding period
    /// @param _unbondingPeriod New unbonding period in seconds
    /// @dev Only callable by admin
    function setUnbondingPeriod(uint256 _unbondingPeriod) external;

    /// @notice Gets the pending unstake amount
    /// @return Pending unstake amount
    function getPendingUnstake() external view returns (uint256);

    /// @notice Checks if mint fee is enabled
    /// @return True if mint fee is enabled, false otherwise
    function getMintFeeEnabled() external view returns (bool);

    /// @notice Enables or disables mint fee
    /// @param _mintFeeEnabled True to enable mint fee, false to disable
    /// @dev Only callable by admin
    function setMintFeeEnabled(bool _mintFeeEnabled) external;

    /// @notice Checks if burn fee is enabled
    /// @return True if burn fee is enabled, false otherwise
    function getBurnFeeEnabled() external view returns (bool);

    /// @notice Enables or disables burn fee
    /// @param _burnFeeEnabled True to enable burn fee, false to disable
    /// @dev Only callable by admin
    function setBurnFeeEnabled(bool _burnFeeEnabled) external;

    /// @notice Gets the minimum delegation size
    /// @return Minimum amount required for delegation
    function getDelegationSize() external view returns (uint256);

    /// @notice Sets the minimum delegation size
    /// @param _delegationSize New minimum delegation size
    /// @dev Only callable by admin
    function setDelegationSize(uint256 _delegationSize) external;

    /// @notice Gets the maximum stake iterations
    /// @return Maximum stake iterations
    function getMaxStakeIterations() external view returns (uint256);

    /// @notice Sets the maximum stake iterations
    /// @param _maxStakeIterations New maximum stake iterations
    /// @dev Only callable by admin
    function setMaxStakeIterations(uint256 _maxStakeIterations) external;

    /// @notice Gets the maximum stake amount
    /// @return Maximum stake amount
    function getMaxStake() external view returns (uint256);

    /// @notice Sets the maximum stake amount
    /// @param _maxStake New maximum stake amount
    /// @dev Only callable by admin
    function setMaxStake(uint256 _maxStake) external;
}
