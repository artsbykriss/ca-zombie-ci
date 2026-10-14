// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title IPrintrStaking
 * @notice Interface for the PrintrStaking contract that manages staking pools and positions
 * @dev Positions are ERC-721 NFTs — transferable, composable, and self-enumerating
 */
interface IPrintrStaking {

    struct LockTier {
        uint256 duration;
        uint16 multiplierBps;
    }

    struct PoolState {
        address basePairToken;
        uint256 totalWeightedStake;
        uint256 basePairAccumulator;
        uint256 telecoinAccumulator;
        uint256 lastTelecoinVaultBalance;
        uint256 lastRefreshedBlock;
        uint256 accumulatedBasePairFees;
    }

    struct Position {
        address telecoin;
        uint8 lockTierIndex;
        uint256 staked;
        uint256 stakedAt;
        uint256 basePairLastAccumulator;
        uint256 telecoinLastAccumulator;
    }

    // Errors
    error StakingNotEnabled();
    error StakingAlreadyEnabled();
    error ZeroStakeAmount();
    error InvalidLockTierIndex();
    error PositionNotFound();
    error PositionLocked();
    error OnlyPrintr();

    // Events
    event StakingEnabled(address indexed telecoin, address indexed basePair);
    event StakePositionCreated(
        uint256 indexed tokenId,
        address indexed telecoin,
        address indexed owner,
        uint256 amount,
        uint8 lockTierIndex,
        uint256 weightedStake,
        uint256 basePairAccumulator,
        uint256 telecoinAccumulator
    );
    event StakingRewardsClaimed(
        uint256 indexed tokenId,
        address indexed telecoin,
        address indexed owner,
        uint256 basePairRewards,
        uint256 telecoinRewards,
        uint256 basePairAccumulator,
        uint256 telecoinAccumulator
    );
    event PositionUnstaked(
        uint256 indexed tokenId,
        address indexed telecoin,
        address indexed owner,
        uint256 returnedStake,
        uint256 basePairRewards,
        uint256 telecoinRewards,
        uint256 basePairAccumulator,
        uint256 telecoinAccumulator
    );
    event StakingRefreshed(
        address indexed telecoin,
        uint256 basePairRewards,
        uint256 telecoinRewards,
        uint256 totalWeightedStake,
        uint256 basePairAccumulator,
        uint256 telecoinAccumulator
    );

    // State-changing
    function initialize(
        address owner_,
        LockTier[] calldata lockTiers_,
        string calldata name_,
        string calldata symbol_
    ) external;
    function stake(
        address telecoin,
        uint256 amount,
        uint8 lockTierIndex
    ) external returns (uint256 tokenId);
    function stakeFor(
        address recipient,
        address telecoin,
        uint256 amount,
        uint8 lockTierIndex
    ) external returns (uint256 tokenId);
    function claimRewards(
        uint256 tokenId
    ) external;
    function unstake(
        uint256 tokenId
    ) external;
    function refreshStaking(
        address telecoin
    ) external;
    function depositBasePairFees(
        address telecoin,
        uint256 amount
    ) external;
    function enableStaking(
        address telecoin,
        address basePair
    ) external;
    function pause() external;
    function unpause() external;

    // View
    function pendingRewards(
        uint256 tokenId
    ) external view returns (uint256 basePairRewards, uint256 telecoinRewards);
    function getPosition(
        uint256 tokenId
    ) external view returns (Position memory);
    function getPoolState(
        address telecoin
    ) external view returns (PoolState memory);
    function isStakingEnabled(
        address telecoin
    ) external view returns (bool);
    function isUnlocked(
        uint256 tokenId
    ) external view returns (bool);
    function getLockTiers() external view returns (LockTier[] memory);

}
