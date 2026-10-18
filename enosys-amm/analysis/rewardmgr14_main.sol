// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

/**
 * Copyright (C) 2024 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IHistoryStateTrackerByEpoch.sol';
import './interfaces/INonfungiblePositionManager.sol';
import './interfaces/IEnosysDexV3Factory.sol';
import './interfaces/IRewardManager.sol';
import './interfaces/IRewardManagerFactory.sol';
import './interfaces/external/IEpochManager.sol';

import './libraries/TransferHelper.sol';
import './libraries/PoolSnapshotHelper.sol';
import './libraries/FullMath.sol';
import './libraries/FixedPoint128.sol';
import './libraries/TickState.sol';
import './libraries/OracleLibrary.sol';
import './libraries/FixedPoint96.sol';

contract RewardManager is IRewardManager, AccessControlUpgradeable {
    using SafeMath for uint256;
    using FullMath for uint256;
    using SafeMath for uint128;

    string public constant VERSION = '1.0.0';

    /// @dev HistoryStateTracker contract by epoch. Stores snapshots per epoch.
    IHistoryStateTrackerByEpoch public historyStateTracker;
    /// @dev NonfungiblePositionManager contract.
    INonfungiblePositionManager public nftManager;
    /// @dev EnosysDexV3Factory contract.
    IEnosysDexV3Factory public factory;
    /// @dev EpochManager contract.
    IEpochManager public epochManager;
    /// @dev Reward token contract.
    IERC20 public rewardToken;
    /// @dev Address of user who provides rewards for the pool.
    address public rewardsProvider;

    struct RewardForEpoch {
        // Stores whether rewards were received for the epoch by the pool.
        bool isRewardsReceived;
        // Total amount of rewards for the epoch by the pool.
        uint256 totalRewards;
    }

    /**
     * @notice Saves split of rewards of token0 and token1 for the epoch for pool.
     */
    struct RewardPerTokenCache {
        // Whether cache saved at that epoch
        bool initialized;
        // Portion of rewards to be dtsctributed in propotion to all fees in token0
        uint256 rewardsToken0;
        // Portion of rewards to be dtsctributed in propotion to all fees in token1
        uint256 rewardsToken1;
    }

    /// @dev Configured rewards for the epoch by the pool.
    mapping(address => RewardForEpoch) public rewardsForEpoch; // key is pool address

    /// @dev Last epoch when position rewards was claimed.
    mapping(uint256 => uint256) public epochToClaimNext; // key is nftId
    /// @dev Whether rewards were claimed by user for the epoch.
    mapping(uint256 => mapping(uint256 => bool)) rewardsClaimedByUserForEpoch; // key is nftId and epoch number
    /// @dev Rewards per token cache for the epoch by the pool. For gas optimization can be calculated once per epoch and served from cache.
    mapping(address => mapping(uint256 => RewardPerTokenCache)) public rewardsPerTokenCache; // key is pool address and epoch number
    /// @dev Last epoch when rewards were cached for the pool.
    mapping(address => uint256) rewardsLastCachedEpoch; // key is pool address

    /// @dev Oldest epoch to be processed.
    uint256 public epochLowest;
    /// @dev Last epoch to be processed.
    uint256 public epochHighest;

    /**
     * @dev Initialize the contract.
     * @param historyStateTrackerByEpoch Address of the HistoryStateTrackerByEpoch contract.
     * @param nonFungiblePositionsManager Address of the NonfungiblePositionManager contract.
     * @param rewardTokenAddress Address of the reward token.
     * @param factoryAddress Address of the EnosysDexV3Factory contract.
     * @param epochToStart Epoch to start from.
     * @param durationEpochs Duration in epochs. Validated for minimal duration by factory depending on current epooch duration
     */
    function initialize(
        address historyStateTrackerByEpoch,
        address nonFungiblePositionsManager,
        address rewardTokenAddress,
        address factoryAddress,
        address epochManagerAddress,
        address rewardsProviderAddress,
        uint256 epochToStart,
        uint256 durationEpochs
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        require(Address.isContract(historyStateTrackerByEpoch), 'RewardManager: historyStateTracker is not a contract');
        historyStateTracker = IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch);

        require(Address.isContract(nonFungiblePositionsManager), 'RewardManager: nftManager is not a contract');
        nftManager = INonfungiblePositionManager(nonFungiblePositionsManager);

        require(Address.isContract(factoryAddress), 'RewardManager: router is not a contract');
        factory = IEnosysDexV3Factory(factoryAddress);

        require(Address.isContract(rewardTokenAddress), 'RewardManager: rewardToken is not a contract');
        rewardToken = IERC20(rewardTokenAddress);

        require(Address.isContract(epochManagerAddress), 'RewardManager: epochManager is not a contract');
        epochManager = IEpochManager(epochManagerAddress);

        require(durationEpochs > 0, 'RewardManager: durationEpochs should be greater than 0');

        rewardsProvider = rewardsProviderAddress;
        epochLowest = epochToStart;
        epochHighest = epochToStart.add(durationEpochs);
    }

    modifier onlyPositionOwner(uint256 nftId) {
        require(nftManager.ownerOf(nftId) == msg.sender, 'RewardManager: caller is not the owner of the position');
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'RewardManager: caller is not an admin');
        _;
    }

    /**
     * @dev Set rewards for the epoch by the pool.
     * @param pool Address of the pool.
     * @param rewardsPerEpoch Total amount of rewards for the epoch.
     */
    function setupRewardForPoolPerEpoch(address pool, uint256 rewardsPerEpoch) external onlyAdmin {
        require(rewardsPerEpoch > 0, 'RewardManager: rewards should be greater than 0');
        require(!rewardsForEpoch[pool].isRewardsReceived, 'RewardManager: rewards are already set for the pool');

        uint256 totalPoolReward = rewardsPerEpoch.mul(epochHighest.sub(epochLowest));

        TransferHelper.safeTransferFrom(address(rewardToken), _msgSender(), address(this), totalPoolReward);

        rewardsForEpoch[pool].totalRewards = rewardsPerEpoch;
        rewardsForEpoch[pool].isRewardsReceived = true;

        emit RewardsSetForPool(pool, rewardsPerEpoch);
    }

    // @inheritdoc IRewardManager
    function cachePoolRewards(address pool, uint256 upToEpoch) public override {
        require(rewardsForEpoch[pool].isRewardsReceived, 'RewardManager: rewards are not set for the pool');

        uint256 epochStart = rewardsLastCachedEpoch[pool];

        if (upToEpoch < epochStart) {
            // all rewards already finalised up to that epoch
            return;
        }

        if (epochStart < epochLowest) {
            epochStart = epochLowest;
        }

        uint256 epochEnd;

        if (upToEpoch > historyStateTracker.getCurrentCheckpointIndex() || upToEpoch > epochHighest) {
            epochEnd = Math.min(historyStateTracker.getCurrentCheckpointIndex(), epochHighest);
        } else {
            epochEnd = upToEpoch;
        }

        for (uint256 epoch = epochStart; epoch < epochEnd; epoch++) {
            RewardPerTokenCache storage cache = rewardsPerTokenCache[pool][epoch];

            (uint256 totalFees0ForEpoch, uint256 totalFees1ForEpoch) = _computeTotalFeesForEpoch(pool, epoch);
            (uint256 totalRewardsToken0ForEpoch, uint256 totalRewardsToken1ForEpoch) = _computeRewardsPerToken(
                pool,
                epoch,
                totalFees0ForEpoch,
                totalFees1ForEpoch
            );

            cache.rewardsToken0 = totalRewardsToken0ForEpoch;
            cache.rewardsToken1 = totalRewardsToken1ForEpoch;
            cache.initialized = true;

            emit RewardsPerTokenCached(pool, epoch, totalRewardsToken0ForEpoch, totalRewardsToken1ForEpoch);
        }

        rewardsLastCachedEpoch[pool] = epochEnd;
    }

    // @inheritdoc IRewardManager
    function claim(
        uint256[] memory nftIds,
        uint256 epochsToClaimCnt,
        address recipient
    ) external override returns (uint256) {
        uint256 totalReward;

        for (uint256 i = 0; i < nftIds.length; i++) {
            require(
                matchPositionOwner(nftIds[i], _msgSender()),
                'RewardManager: caller is not the owner of the position'
            );
            address pool = nftManager.poolByTokenId(nftIds[i]);

            require(rewardsForEpoch[pool].isRewardsReceived, 'RewardManager: rewards are not set for the pool');
            (uint256 epochClaimStart, uint256 epochClaimEnd) = _getPositionClaimableEpochs(nftIds[i], epochsToClaimCnt);

            // compute rewards in each pool's token for the epoch.
            // execute only once per epoch for each pool
            cachePoolRewards(pool, epochClaimEnd);

            uint256 reward = _getUnclaimedForPosition(nftIds[i], pool, epochClaimStart, epochClaimEnd);
            totalReward = totalReward.add(reward);

            epochToClaimNext[nftIds[i]] = epochClaimEnd;
            emit RewardClaimed(nftIds[i], epochClaimStart, epochClaimEnd, reward);
        }

        rewardToken.transfer(recipient, totalReward);

        return totalReward;
    }

    // @inheritdoc IRewardManager
    function getUnclaimed(
        uint256[] memory nftIds,
        uint256 epochsToClaimCnt
    ) external view override returns (uint256 totalReward) {
        for (uint256 i = 0; i < nftIds.length; i++) {
            address pool = nftManager.poolByTokenId(nftIds[i]);
            (uint256 epochClaimStart, uint256 epochClaimEnd) = _getPositionClaimableEpochs(nftIds[i], epochsToClaimCnt);
            totalReward = totalReward.add(_getUnclaimedForPosition(nftIds[i], pool, epochClaimStart, epochClaimEnd));
        }
    }

    // @inheritdoc IRewardManager
    function getPending(uint256[] memory nftIds) external view override returns (uint256 totalReward) {
        for (uint256 i = 0; i < nftIds.length; i++) {
            address pool = nftManager.poolByTokenId(nftIds[i]);
            uint256 currentEpoch = historyStateTracker.getCurrentCheckpointIndex();
            totalReward = totalReward.add(_getUnclaimedForPosition(nftIds[i], pool, currentEpoch, currentEpoch + 1));
        }
    }

    // @inheritdoc IRewardManager
    function withdrawUnclaimedRewards() external override returns (uint256) {
        require(msg.sender == rewardsProvider, 'RewardManager: caller is not the rewards provider');
        require(
            historyStateTracker.getCleanupCheckpointIndex() > epochHighest,
            'RewardManager: rewards are still claimable'
        );

        uint256 totalReward = rewardToken.balanceOf(address(this));
        rewardToken.transfer(rewardsProvider, totalReward);

        return totalReward;
    }

    struct PositionRewardsStateCache {
        int24 tickLower;
        int24 tickUpper;
        uint256 totalPositionFees0ForEpoch;
        uint256 totalPositionFees1ForEpoch;
        uint256 totalPositionRewardsToken0ForEpoch;
        uint256 totalPositionRewardsToken1ForEpoch;
        uint256 totalFees0ForEpoch;
        uint256 totalFees1ForEpoch;
        uint256 totalRewardsToken0ForEpoch;
        uint256 totalRewardsToken1ForEpoch;
    }

    /**
     * @dev Get the total amount of rewards for the position for the specified epochs.
     * Doesn't check epochs, required to validate `fromEpoch` and `toEpoch` before calling this function.
     * `toEpoch` will always be excluded from the calculation.
     *
     * ## Exampels
     * To get total earned fees:
     * ```
     *      _getUnclaimedForPosition(nftId, pool, epochOfPositionCreated, currentEpoch);
     * ```
     * To get pending fees:
     * ```
     *     _getUnclaimedForPosition(nftId, pool, currentEpoch, currentEpoch + 1);
     * ```
     * @param nftId Position ID on Nonfungible Position Manager.
     * @param pool Address of pool.
     * @param fromEpoch Epoch number to start from.
     * @param toEpoch Epoch number to end at.
     */
    function _getUnclaimedForPosition(
        uint256 nftId,
        address pool,
        uint256 fromEpoch,
        uint256 toEpoch
    ) internal view returns (uint256) {
        uint256 totalReward;
        PositionRewardsStateCache memory cache = PositionRewardsStateCache(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        (, , , , , cache.tickLower, cache.tickUpper, , , , , ) = INonfungiblePositionManager(nftManager).positions(
            nftId
        );

        if (fromEpoch < historyStateTracker.getCleanupCheckpointIndex()) {
            fromEpoch = historyStateTracker.getCleanupCheckpointIndex();
        }

        for (uint256 epoch = fromEpoch; epoch < toEpoch; epoch++) {
            // reset cache for each epoch, ticks are constant for same position
            cache = PositionRewardsStateCache(cache.tickLower, cache.tickUpper, 0, 0, 0, 0, 0, 0, 0, 0);

            IHistoryStateTrackerByEpoch.PositionFeesState memory positionFeesState = historyStateTracker
                .positionFeesState(nftId, epoch);

            if (positionFeesState.initialized) {
                uint256 feeGrowth0AtTheEndOfEpoch = TickState.computeFeeGrowth0TillEpoch(
                    address(historyStateTracker),
                    pool,
                    epoch,
                    cache.tickLower,
                    cache.tickUpper
                );
                uint256 feeGrowth1AtTheEndOfEpoch = TickState.computeFeeGrowth1TillEpoch(
                    address(historyStateTracker),
                    pool,
                    epoch,
                    cache.tickLower,
                    cache.tickUpper
                );

                // when all positions in range was decreased, it can happen that feeGrowth is less than inside feeGrowth
                // which means, that there was no rewards since last liquidity update and to the end of epoch
                if (feeGrowth0AtTheEndOfEpoch > positionFeesState.feeGrowthInside0ForEpoch) {
                    // calculate add rewards, collected since last position update for epoch
                    cache.totalPositionFees0ForEpoch = positionFeesState.feesCollected0.add(
                        FullMath.mulDiv(
                            fetchPositionLiquidityAt(nftId, epoch),
                            feeGrowth0AtTheEndOfEpoch.sub(positionFeesState.feeGrowthInside0ForEpoch),
                            FixedPoint128.Q128
                        )
                    );
                } else {
                    cache.totalPositionFees0ForEpoch = positionFeesState.feesCollected0;
                }

                // when all positions in range was decreased, it can happen that feeGrowth is less than inside feeGrowth
                // which means, that there was no rewards since last liquidity update and to the end of epoch
                if (feeGrowth1AtTheEndOfEpoch > positionFeesState.feeGrowthInside1ForEpoch) {
                    // calculate add rewards, collected since last position update for epoch
                    cache.totalPositionFees1ForEpoch = positionFeesState.feesCollected1.add(
                        FullMath.mulDiv(
                            fetchPositionLiquidityAt(nftId, epoch),
                            feeGrowth1AtTheEndOfEpoch.sub(positionFeesState.feeGrowthInside1ForEpoch),
                            FixedPoint128.Q128
                        )
                    );
                } else {
                    cache.totalPositionFees1ForEpoch = positionFeesState.feesCollected1;
                }
            } else {
                // if position liquidity didn't change during epoch, calculate fees for the whole epoch at the same rate
                (
                    cache.totalPositionFees0ForEpoch,
                    cache.totalPositionFees1ForEpoch
                ) = _computePositionFeesForWholeEpoch(
                    address(pool),
                    fetchPositionLiquidityAt(nftId, epoch),
                    cache.tickLower,
                    cache.tickUpper,
                    epoch
                );
            }

            (cache.totalFees0ForEpoch, cache.totalFees1ForEpoch) = _computeTotalFeesForEpoch(pool, epoch);

            (cache.totalRewardsToken0ForEpoch, cache.totalRewardsToken1ForEpoch) = _computeRewardsPerTokenOrCached(
                pool,
                epoch,
                cache.totalFees0ForEpoch,
                cache.totalFees1ForEpoch
            );

            //we need second condition (totalFees0ForEpoch >= cache.totalPositionFees0ForEpoch) to protect from inconsistent snapshot (missing feeGrowthInside0ForEpoch because of old underflow protection)
            if (cache.totalFees0ForEpoch > 0 && cache.totalFees0ForEpoch >= cache.totalPositionFees0ForEpoch) {
                cache.totalPositionRewardsToken0ForEpoch = cache
                    .totalRewardsToken0ForEpoch
                    .mul(cache.totalPositionFees0ForEpoch)
                    .div(cache.totalFees0ForEpoch);
            }

            //we need second condition (totalFees1ForEpoch >= cache.totalPositionFees1ForEpoch) to protect from inconsistent snapshot (missing feeGrowthInside1ForEpoch because of old underflow protection)
            if (cache.totalFees1ForEpoch > 0 && cache.totalFees1ForEpoch >= cache.totalPositionFees1ForEpoch) {
                cache.totalPositionRewardsToken1ForEpoch = cache
                    .totalRewardsToken1ForEpoch
                    .mul(cache.totalPositionFees1ForEpoch)
                    .div(cache.totalFees1ForEpoch);
            }

            totalReward = totalReward.add(cache.totalPositionRewardsToken0ForEpoch).add(
                cache.totalPositionRewardsToken1ForEpoch
            );
        }

        return totalReward;
    }

    function _computeTotalFeesForEpoch(address pool, uint256 epoch) private view returns (uint256, uint256) {
        (uint256 totalFeesForEpoch0, uint256 totalFeesForEpoch1) = PoolSnapshotHelper.getTotalSwapFeesForPoolAtEpoch(
            address(historyStateTracker),
            pool,
            epoch
        );
        (uint256 totalFeesForEpoch0Before, uint256 totalFeesForEpoch1Before) = PoolSnapshotHelper
            .getTotalSwapFeesForPoolAtEpoch(address(historyStateTracker), pool, epoch - 1);

        return (totalFeesForEpoch0.sub(totalFeesForEpoch0Before), totalFeesForEpoch1.sub(totalFeesForEpoch1Before));
    }

    /**
     * @dev Total amount of fees earned through the position for the epoch.
     * Can be applied for epoch when postion liquidity hasn't changed.
     * @param pool Address of pool.
     * @param liquidity Amount of liquidity in the position at epoch.
     * @param tickLower Lower tick of the position.
     * @param tickUpper Upper tick of the position.
     * @param epoch Epoch number.
     * @return fees0SinceLastInteractionForEpoch
     * @return fees1SinceLastInteractionForEpoch
     */
    function _computePositionFeesForWholeEpoch(
        address pool,
        uint256 liquidity,
        int24 tickLower,
        int24 tickUpper,
        uint256 epoch
    ) private view returns (uint256 fees0SinceLastInteractionForEpoch, uint256 fees1SinceLastInteractionForEpoch) {
        uint256 feeGrowth0AtEpoch = TickState.computeFeeGrowth0TillEpoch(
            address(historyStateTracker),
            pool,
            epoch,
            tickLower,
            tickUpper
        );
        uint256 feeGrowth1AtEpoch = TickState.computeFeeGrowth1TillEpoch(
            address(historyStateTracker),
            pool,
            epoch,
            tickLower,
            tickUpper
        );

        uint256 feeGrowth0AtEpochBefore = TickState.computeFeeGrowth0TillEpoch(
            address(historyStateTracker),
            pool,
            epoch - 1,
            tickLower,
            tickUpper
        );
        uint256 feeGrowth1AtEpochBefore = TickState.computeFeeGrowth1TillEpoch(
            address(historyStateTracker),
            pool,
            epoch - 1,
            tickLower,
            tickUpper
        );

        if (feeGrowth0AtEpoch > feeGrowth0AtEpochBefore) {
            fees0SinceLastInteractionForEpoch = FullMath.mulDiv(
                liquidity,
                feeGrowth0AtEpoch.sub(feeGrowth0AtEpochBefore),
                FixedPoint128.Q128
            );
        } else {
            fees0SinceLastInteractionForEpoch = 0;
        }

        if (feeGrowth1AtEpoch > feeGrowth1AtEpochBefore) {
            fees1SinceLastInteractionForEpoch = FullMath.mulDiv(
                liquidity,
                feeGrowth1AtEpoch.sub(feeGrowth1AtEpochBefore),
                FixedPoint128.Q128
            );
        } else {
            fees1SinceLastInteractionForEpoch = 0;
        }
    }

    /**
     * @dev Compute reward epoch to be claimed next for the position.
     * @param nftId Position ID on Nonfungible Position Manager.
     * @param epochsToClaimCnt Number of epochs to claim rewards for starting from last claimed epoch.
     * @return epochClaimStart Epoch number to start from.
     * @return epochClaimEnd Epoch number to end at.
     */
    function _getPositionClaimableEpochs(
        uint256 nftId,
        uint256 epochsToClaimCnt
    ) private view returns (uint256, uint256) {
        // estimate first epoch that position could have fees
        // for new position, `historyStateTracker.epochOfFirstPositionUpdate(nftId)` will return epoch of position mint
        // for position that was claimed before, `epochToClaimNext[nftId]` will represent next epoch that wasn't claimed
        uint256 epochClaimStart = epochToClaimNext[nftId] > 0
            ? epochToClaimNext[nftId]
            : historyStateTracker.epochOfFirstPositionUpdate(nftId);

        if (epochClaimStart < epochLowest) {
            epochClaimStart = epochLowest;
        }

        // estimate last epoch with claimable fees or last epoch possible to claim without running out of gas
        uint256 epochClaimEnd = epochClaimStart + epochsToClaimCnt > historyStateTracker.getCurrentCheckpointIndex()
            ? historyStateTracker.getCurrentCheckpointIndex()
            : epochClaimStart + epochsToClaimCnt;

        if (epochClaimEnd > epochHighest) {
            epochClaimEnd = epochHighest;
        }

        return (epochClaimStart, epochClaimEnd);
    }

    /**
     * @dev Returns rewards from cache or calculates using `_computeRewardsPerToken`.
     * @param pool Address of pool.
     * @param epoch Epoch number.
     * @param totalFeesForEpoch0 Total earned fees for token0 for the epoch.
     * @param totalFeesForEpoch1 Total earned fees for token1 for the epoch.
     * @return rewardsForToken0 Total amount of reward token to be distributed for epoch for all token0 fees of the specified pool.
     * @return rewardsForToken1 Total amount of reward token to be distributed for epoch for all token1 fees of the specified pool.
     */
    function _computeRewardsPerTokenOrCached(
        address pool,
        uint256 epoch,
        uint256 totalFeesForEpoch0,
        uint256 totalFeesForEpoch1
    ) internal view returns (uint256, uint256) {
        RewardPerTokenCache memory cache = rewardsPerTokenCache[pool][epoch];

        if (!cache.initialized) {
            return _computeRewardsPerToken(pool, epoch, totalFeesForEpoch0, totalFeesForEpoch1);
        }

        return (cache.rewardsToken0, cache.rewardsToken1);
    }

    /**
     * @dev Compute rewards per token of a pool in proportion of total fees for the epoch.
     * @param pool Address of pool.
     * @param epoch Epoch number.
     * @param totalFees0 Total earned fees for token0 for the epoch.
     * @param totalFees1 Total earned fees for token1 for the epoch.
     * @return rewardsForToken0 Total amount of reward token to be distributed for epoch for all token0 fees of the specified pool.
     * @return rewardsForToken1 Total amount of reward token to be distributed for epoch for all token1 fees of the specified pool.
     */
    function _computeRewardsPerToken(
        address pool,
        uint256 epoch,
        uint256 totalFees0,
        uint256 totalFees1
    ) private view returns (uint256, uint256) {
        // rewards should be 0 outside of rewards manager duration
        if (epoch < epochLowest || epoch > epochHighest) {
            return (0, 0);
        }

        uint256 priceEpochAvg = getPoolAvgEpochPrice(pool, epoch);
        uint256 totalFees1AsToken0 = totalFees1.mul(priceEpochAvg).div(1e18);
        uint256 totalFeesAsToken0 = totalFees0.add(totalFees1AsToken0);

        if (totalFeesAsToken0 == 0) {
            return (0, 0);
        }

        return (
            rewardsForEpoch[pool].totalRewards.mul(totalFees0).div(totalFeesAsToken0),
            rewardsForEpoch[pool].totalRewards.mul(totalFees1AsToken0).div(totalFeesAsToken0)
        );
    }

    /// @dev Check if the position owner is the caller.
    function matchPositionOwner(uint256 nftId, address owner) internal view returns (bool) {
        return nftManager.ownerOf(nftId) == owner;
    }

    function fetchPositionLiquidityAt(uint256 nftId, uint256 epoch) internal view returns (uint256) {
        return
            historyStateTracker.stateOfAt(
                PoolSnapshotHelper.getPositionSnapshotKey(
                    PoolSnapshotHelper.SnapshotType.PositionLiquidity,
                    address(nftManager),
                    nftId
                ),
                epoch
            );
    }

    /**
     * @dev Fetch average price of the pool for the epoch.
     * @param poolAddress Address of the pool.
     * @param epoch Epoch number.
     */
    function getPoolAvgEpochPrice(address poolAddress, uint256 epoch) internal view returns (uint256) {
        require(epoch >= epochLowest && epoch < epochHighest, 'RewardManager: epoch is out of range of RewardManager');
        require(epoch <= historyStateTracker.getCurrentCheckpointIndex(), 'RewardManager: epoch is not finalised');

        IEnosysDexV3Pool pool = IEnosysDexV3Pool(poolAddress);
        uint256 timestampEpochStart = epochManager.getEpochStartTime(epoch);
        uint256 timestampEpochEnd = epochManager.getEpochStartTime(epoch + 1);

        uint32 oldestSecondsAgo = OracleLibrary.getOldestObservationSecondsAgo(poolAddress);

        uint256 startSecondsAgo = block.timestamp - timestampEpochStart;
        uint256 endSecondsAgo;

        // if epoch is current and not finalised yet, set end to 0 which will represent latest available checkpoint
        if (epoch == historyStateTracker.getCurrentCheckpointIndex()) {
            endSecondsAgo = 0;
        } else {
            endSecondsAgo = block.timestamp - timestampEpochEnd;
        }

        int24 tickAvg;

        // if price for epoch start in no longer available, fetch price for the oldest available
        // if price for epoch end is no longer available, fetch price for the latest available
        if (startSecondsAgo > oldestSecondsAgo && endSecondsAgo < oldestSecondsAgo) {
            (tickAvg, ) = OracleLibrary.consultForPeriod(poolAddress, oldestSecondsAgo, uint32(endSecondsAgo));
        } else if (startSecondsAgo > oldestSecondsAgo && endSecondsAgo >= oldestSecondsAgo) {
            if (oldestSecondsAgo > 1 hours) {
                (tickAvg, ) = OracleLibrary.consultForPeriod(poolAddress, oldestSecondsAgo, oldestSecondsAgo - 1 hours);
            } else {
                (tickAvg, ) = OracleLibrary.consultForPeriod(poolAddress, oldestSecondsAgo, 0);
            }
        } else {
            (tickAvg, ) = OracleLibrary.consultForPeriod(poolAddress, uint32(startSecondsAgo), uint32(endSecondsAgo));
        }

        uint256 priceAvg = OracleLibrary.getQuoteAtTick(tickAvg, 1e18, pool.token1(), pool.token0());

        return priceAvg;
    }
}
