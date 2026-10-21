// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {IEpochWithdrawalProtection} from "src/interfaces/extensions/IEpochWithdrawalProtection.sol";

/**
 * @title EpochWithdrawalProtection
 * @notice Mixin for epoch-based withdrawal limits to prevent rapid vault depletion
 * @dev Tracks withdrawals between harvests (epochs) and limits total outflows.
 *
 * How it works:
 * - Each harvest starts a new "epoch" via _resetEpoch(totalAssets, idle)
 * - Max outflow per epoch = epochStartAssets * maxEpochOutflowBps / BPS
 * - Total outflows tracked: _freeFunds-served (epochWithdrawals) + idle-served (estimated)
 * - Idle-served withdrawals are estimated as: max(0, epochStartIdle - currentIdle)
 *
 * Example with 20% max outflow:
 * - Harvest sets epochStartAssets = 100k, epochStartIdle = 5k
 * - Max outflow = 20k
 * - User withdraws 15k from _freeFunds → epochWithdrawals = 15k
 * - User withdraws 3k from idle → currentIdle = 2k, idleConsumed = 3k
 * - Total outflow = 15k + 3k = 18k, remaining capacity = 2k
 *
 * Inheriting contracts must:
 * - Call _recordWithdrawal() in _freeFunds()
 * - Call _resetEpoch(totalAssets, idle) at end of _harvestAndReport()
 * - Call _syncEpochIdleAfterDeploy(currentIdle) in _deployFunds()
 * - Use _getEpochWithdrawalLimit(currentIdle) in availableWithdrawLimit()
 */
abstract contract EpochWithdrawalProtection is IEpochWithdrawalProtection {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Basis points denominator
    uint256 public constant EPOCH_BPS_DENOMINATOR = 10_000;

    /// @notice Default max epoch outflow (20% of epoch start assets)
    uint16 public constant DEFAULT_MAX_EPOCH_OUTFLOW_BPS = 2_000;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Assets at epoch start (set during harvest, 6 decimals)
    uint128 private s_epochStartAssets;

    /// @dev Cumulative _freeFunds withdrawals this epoch (6 decimals)
    uint128 private s_epochWithdrawals;

    /// @dev Idle balance at epoch start (for idle-served withdrawal tracking, 6 decimals)
    uint128 private s_epochStartIdle;

    /// @dev Timestamp of last epoch reset (harvest)
    uint32 private s_epochStartTime;

    /// @dev Maximum net outflow per epoch in basis points
    uint16 private s_maxEpochOutflowBps;

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEpochWithdrawalProtection
    function epochStartAssets() public view returns (uint128) {
        return s_epochStartAssets;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function epochWithdrawals() public view returns (uint128) {
        return s_epochWithdrawals;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function epochStartIdle() public view returns (uint128) {
        return s_epochStartIdle;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function epochStartTime() public view returns (uint32) {
        return s_epochStartTime;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function maxEpochOutflowBps() public view returns (uint16) {
        return s_maxEpochOutflowBps;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function getEpochMaxWithdrawable() external view returns (uint256) {
        return
            (s_epochStartAssets * s_maxEpochOutflowBps) / EPOCH_BPS_DENOMINATOR;
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function getEpochWithdrawalCapacity(
        uint256 currentIdle
    ) external view returns (uint256) {
        return _getEpochWithdrawalLimit(currentIdle);
    }

    /// @inheritdoc IEpochWithdrawalProtection
    function getEpochDuration() external view returns (uint256) {
        return block.timestamp - s_epochStartTime;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initialize epoch protection with default values
     * @param initialAssets Initial total assets (usually 0 at deployment)
     */
    function _initEpochProtection(uint128 initialAssets) internal {
        s_epochStartAssets = initialAssets;
        s_epochStartTime = uint32(block.timestamp);
        s_maxEpochOutflowBps = DEFAULT_MAX_EPOCH_OUTFLOW_BPS;
    }

    /**
     * @dev Record a withdrawal in the current epoch
     * @param amount Amount withdrawn via _freeFunds (in asset decimals)
     */
    function _recordWithdrawal(uint128 amount) internal {
        s_epochWithdrawals += amount;
    }

    /**
     * @dev Reset epoch counters - call at end of harvest
     * @param currentAssets Current total assets to start new epoch
     * @param currentIdle Current idle balance to start new epoch
     */
    function _resetEpoch(uint128 currentAssets, uint128 currentIdle) internal {
        emit EpochReset(currentAssets, s_epochWithdrawals);

        s_epochStartAssets = currentAssets;
        s_epochStartIdle = currentIdle;
        s_epochWithdrawals = 0;
        s_epochStartTime = uint32(block.timestamp);
    }

    /// @dev Correct epoch withdrawal overcount when adapter returns less than requested
    function _correctWithdrawalOvercount(uint128 correction) internal {
        s_epochWithdrawals -= correction;
    }

    /// @dev Reset epoch idle baseline after internal redeployment so the epoch
    ///      tracker does not misclassify the idle drop as user outflow.
    function _syncEpochIdleAfterDeploy(uint128 currentIdle) internal {
        s_epochStartIdle = currentIdle;
    }

    /**
     * @dev Estimate idle-served withdrawals this epoch.
     *      TokenizedStrategy serves withdrawals from idle without calling _freeFunds,
     *      so those withdrawals are not recorded in epochWithdrawals.
     *      We estimate them as: max(0, epochStartIdle - currentIdle).
     *
     *      _deployFunds() calls _syncEpochIdleAfterDeploy() to reset the baseline,
     *      so internal redeployments of pre-existing idle are not misclassified as
     *      user outflow. If idle somehow grew (e.g. adapter returns excess, direct
     *      transfer), we conservatively report 0 idle consumed — this is safe because
     *      idle growth means net inflow, not depletion.
     *
     * @param currentIdle Current idle balance
     * @return Estimated idle-served withdrawals this epoch
     */
    function _getEstimatedIdleWithdrawals(
        uint256 currentIdle
    ) internal view returns (uint256) {
        if (s_epochStartIdle > currentIdle) {
            return s_epochStartIdle - currentIdle;
        }
        return 0;
    }

    /**
     * @dev Calculate remaining withdrawal capacity for this epoch.
     *      Accounts for both _freeFunds-served and idle-served withdrawals.
     * @param currentIdle Current idle balance of the strategy
     * @return Remaining amount that can be withdrawn without exceeding epoch limit
     */
    function _getEpochWithdrawalLimit(
        uint256 currentIdle
    ) internal view returns (uint256) {
        uint256 maxWithdrawable = (s_epochStartAssets * s_maxEpochOutflowBps) /
            EPOCH_BPS_DENOMINATOR;

        // Total epoch outflows = _freeFunds-served + idle-served (estimated)
        uint256 totalOutflows = s_epochWithdrawals +
            _getEstimatedIdleWithdrawals(currentIdle);

        if (totalOutflows >= maxWithdrawable) {
            return 0;
        }

        return maxWithdrawable - totalOutflows;
    }

    /**
     * @dev Set the max epoch outflow in basis points
     * @param newBps New max outflow (e.g., 2000 = 20%)
     */
    function _setMaxEpochOutflowBps(uint16 newBps) internal {
        require(newBps <= EPOCH_BPS_DENOMINATOR, InvalidEpochOutflowBps());

        uint16 oldBps = s_maxEpochOutflowBps;
        s_maxEpochOutflowBps = newBps;

        emit MaxEpochOutflowUpdated(oldBps, newBps);
    }
}
