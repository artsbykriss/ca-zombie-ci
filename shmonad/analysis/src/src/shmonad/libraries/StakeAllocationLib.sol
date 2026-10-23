//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";

import {
    CashFlows,
    Epoch,
    StakingEscrow,
    WorkingCapital,
    AllocationRevenue,
    StakeAllocationConfig,
    AllocationTotals,
    IsolatedValidatorState
} from "../Types.sol";
import { BPS_SCALE, DUST_THRESHOLD, DEFAULT_NON_STAKING_REVENUE_MULTIPLIER_RAY, RAY } from "../Constants.sol";

library StakeAllocationLib {
    using Math for uint256;
    using SafeCastLib for uint256;

    struct AllocationScoring {
        uint256 totalPooledTargetStake;
        uint256 totalOverallocatedStake;
        uint256 totalAllocationSignalStake;
        uint256 totalAdjustedWeightedRevenue;
        uint256 validatorSignalStake;
        uint256 nonStakingRevenueMultiplierRay;
        uint256 stakingYieldDeadbandBps;
        bool useAdjustedScoring;
    }

    /// @dev Average of two unsigned integers.
    function _avg(uint256 a, uint256 b) private pure returns (uint256) {
        return (a + b) / 2;
    }

    /// @dev Saturating subtraction: returns a - b if a > b, else 0.
    function _saturatingSub(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function defaultedNonStakingRevenueMultiplierRay(StakeAllocationConfig memory config)
        internal
        pure
        returns (uint256 multiplierRay)
    {
        multiplierRay = config.nonStakingRevenueMultiplierRay;
        return multiplierRay == 0 ? DEFAULT_NON_STAKING_REVENUE_MULTIPLIER_RAY : multiplierRay;
    }

    function allocationSignalAmount(
        StakeAllocationConfig memory config,
        uint256 pooledAmount,
        uint256 isolatedAmount
    )
        internal
        pure
        returns (uint120)
    {
        return
            (config.includeIsolatedRewardsInStakeAllocation ? pooledAmount + isolatedAmount : pooledAmount).toUint120();
    }

    function allocationSignalStake(
        uint256 pooledTargetStake,
        IsolatedValidatorState memory isolatedState,
        StakeAllocationConfig memory config
    )
        internal
        pure
        returns (uint256 signalStake)
    {
        signalStake = pooledTargetStake;
        if (config.includeIsolatedRewardsInStakeAllocation) {
            // Snapshot state remains fixed until the validator's end-of-crank roll, so the validator numerator stays
            // consistent with the global denominator even if live isolated stake activates or exits in between.
            signalStake += isolatedState.snapshotIsolatedStake;
        }
    }

    function buildAllocationScoring(
        AllocationTotals memory totals,
        uint256 validatorSignalStake,
        uint256 nonStakingRevenueMultiplierRay,
        uint256 stakingYieldDeadbandBps,
        bool useAdjustedScoring
    )
        internal
        pure
        returns (AllocationScoring memory scoring)
    {
        scoring = AllocationScoring({
            totalPooledTargetStake: totals.totalPooledTargetStake,
            totalOverallocatedStake: totals.totalOverallocatedStake,
            totalAllocationSignalStake: totals.totalAllocationSignalStake,
            totalAdjustedWeightedRevenue: totals.totalAdjustedWeightedRevenue,
            validatorSignalStake: validatorSignalStake,
            nonStakingRevenueMultiplierRay: nonStakingRevenueMultiplierRay,
            stakingYieldDeadbandBps: stakingYieldDeadbandBps,
            useAdjustedScoring: useAdjustedScoring
        });
    }

    /// @dev Weighted revenue signal: `Wi = Yi + m * Ri`, using the same two-epoch smoothing window as legacy
    /// allocation.
    function getSmoothedWeightedRevenue(
        AllocationRevenue memory revenue_LastLast,
        AllocationRevenue memory revenue_Last,
        uint256 nonStakingRevenueMultiplierRay
    )
        internal
        pure
        returns (uint256 weightedRevenue)
    {
        uint256 stakingYield = _avg(revenue_Last.stakingYield, revenue_LastLast.stakingYield);
        uint256 nonStakingRevenue = _avg(revenue_Last.nonStakingRevenue, revenue_LastLast.nonStakingRevenue);
        weightedRevenue = stakingYield + Math.mulDiv(nonStakingRevenue, nonStakingRevenueMultiplierRay, RAY);
    }

    function _adjustedStakingYield(
        AllocationRevenue memory globalRevenue_LastLast,
        AllocationRevenue memory globalRevenue_Last,
        AllocationRevenue memory validatorRevenue_LastLast,
        AllocationRevenue memory validatorRevenue_Last,
        AllocationScoring memory scoring
    )
        private
        pure
        returns (uint256 adjustedYield)
    {
        adjustedYield = _avg(validatorRevenue_Last.stakingYield, validatorRevenue_LastLast.stakingYield);
        if (adjustedYield == 0 || scoring.totalAllocationSignalStake == 0 || scoring.validatorSignalStake == 0) {
            return adjustedYield;
        }

        uint256 globalStakingYield = _avg(globalRevenue_Last.stakingYield, globalRevenue_LastLast.stakingYield);
        uint256 expectedYield =
            Math.mulDiv(globalStakingYield, scoring.validatorSignalStake, scoring.totalAllocationSignalStake);
        uint256 floor = Math.mulDiv(expectedYield, scoring.stakingYieldDeadbandBps, BPS_SCALE);
        return _saturatingSub(adjustedYield, floor);
    }

    function getSmoothedAllocationWeightedRevenue(
        AllocationRevenue memory globalRevenue_LastLast,
        AllocationRevenue memory globalRevenue_Last,
        AllocationRevenue memory validatorRevenue_LastLast,
        AllocationRevenue memory validatorRevenue_Last,
        AllocationScoring memory scoring
    )
        internal
        pure
        returns (uint256 weightedRevenue)
    {
        if (scoring.useAdjustedScoring) {
            // Filter most stake-proportional staking yield while leaving commission/outperformance above the floor.
            uint256 stakingYield = _adjustedStakingYield(
                globalRevenue_LastLast, globalRevenue_Last, validatorRevenue_LastLast, validatorRevenue_Last, scoring
            );
            uint256 nonStakingRevenue =
                _avg(validatorRevenue_Last.nonStakingRevenue, validatorRevenue_LastLast.nonStakingRevenue);
            return stakingYield + Math.mulDiv(nonStakingRevenue, scoring.nonStakingRevenueMultiplierRay, RAY);
        }

        return getSmoothedWeightedRevenue(
            validatorRevenue_LastLast, validatorRevenue_Last, scoring.nonStakingRevenueMultiplierRay
        );
    }

    /// @dev Returns max(0, currentStake - idealWeightedStake) for turnover routing.
    /// If a validator has pooled stake but zero weighted revenue, we treat its full stake as overallocated so the
    /// active-set denominator still captures stake that should rotate away from zero-signal validators.
    function calculateOverallocatedStake(
        Epoch memory validatorEpoch_Last,
        AllocationRevenue memory globalRevenue_LastLast,
        AllocationRevenue memory globalRevenue_Last,
        AllocationRevenue memory validatorRevenue_LastLast,
        AllocationRevenue memory validatorRevenue_Last,
        AllocationScoring memory scoring
    )
        internal
        pure
        returns (uint256 overallocatedStake)
    {
        if (validatorEpoch_Last.targetStakeAmount == 0 || scoring.totalPooledTargetStake == 0) return 0;

        if (scoring.totalAdjustedWeightedRevenue == 0) return 0;

        uint256 smoothedValidatorWeightedRevenue = getSmoothedAllocationWeightedRevenue(
            globalRevenue_LastLast, globalRevenue_Last, validatorRevenue_LastLast, validatorRevenue_Last, scoring
        );
        if (smoothedValidatorWeightedRevenue == 0) return uint256(validatorEpoch_Last.targetStakeAmount);

        uint256 idealWeightedStake = Math.mulDiv(
            scoring.totalPooledTargetStake, smoothedValidatorWeightedRevenue, scoring.totalAdjustedWeightedRevenue
        );
        return _saturatingSub(validatorEpoch_Last.targetStakeAmount, idealWeightedStake);
    }

    /// @notice Computes a validator's stake delta for the current epoch.
    /// @dev Combines:
    ///  (1) cash-flow driven increases proportional to smoothed weighted revenue share,
    ///  (2) non-turnover decreases proportional to available-to-unstake capacity,
    ///  (3) turnover decreases proportional to over-allocation vs weighted revenue share.
    /// `stakeAllocationDecrease` is the gross requested decrease, while `turnoverAllocationDecrease` is the gross
    /// subset that came from turnover routing. Both remain unnetted so replaced instructions can be restored exactly.
    function calculateValidatorEpochStakeDelta(
        CashFlows memory globalCashFlows_Last,
        uint120 turnoverQueueForUnstake_Last,
        AllocationRevenue memory globalRevenue_LastLast,
        AllocationRevenue memory globalRevenue_Last,
        AllocationRevenue memory validatorRevenue_LastLast,
        AllocationRevenue memory validatorRevenue_Last,
        Epoch memory validatorEpoch_Last,
        uint256 validatorAmountAvailableToUnstake,
        uint256 globalAmountAvailableToUnstake,
        AllocationScoring memory scoring
    )
        internal
        pure
        returns (
            uint128 targetValidatorStake,
            uint128 netAmount,
            bool isWithdrawal,
            uint256 stakeAllocationIncrease,
            uint256 stakeAllocationDecrease,
            uint256 turnoverAllocationDecrease
        )
    {
        uint256 smoothedValidatorWeightedRevenue =
            getSmoothedAllocationWeightedRevenue(
                globalRevenue_LastLast, globalRevenue_Last, validatorRevenue_LastLast, validatorRevenue_Last, scoring
            );
        uint256 smoothedGlobalWeightedRevenue = scoring.totalAdjustedWeightedRevenue;

        if (
            smoothedValidatorWeightedRevenue > DUST_THRESHOLD && globalCashFlows_Last.queueToStake > DUST_THRESHOLD
                && smoothedGlobalWeightedRevenue > 0
        ) {
            // Stake inflows still divide the aggregate stake queue, but the split now uses the weighted signal rather
            // than legacy earnedRevenue alone.
            stakeAllocationIncrease =
                globalCashFlows_Last.queueToStake * smoothedValidatorWeightedRevenue / smoothedGlobalWeightedRevenue;
        }

        uint256 nonTurnoverQueueForUnstake =
            _saturatingSub(globalCashFlows_Last.queueForUnstake, turnoverQueueForUnstake_Last);
        if (
            nonTurnoverQueueForUnstake > DUST_THRESHOLD && globalAmountAvailableToUnstake > 0
                && validatorAmountAvailableToUnstake > 0
        ) {
            // User / liability / pool-replenishment withdrawals remain stake-proportional.
            stakeAllocationDecrease = nonTurnoverQueueForUnstake.mulDivUp(
                validatorAmountAvailableToUnstake, globalAmountAvailableToUnstake
            );
        }

        if (
            turnoverQueueForUnstake_Last > DUST_THRESHOLD && scoring.totalOverallocatedStake > 0
                && scoring.totalPooledTargetStake > 0 && smoothedGlobalWeightedRevenue > 0
        ) {
            uint256 remainingDecreaseCapacity = validatorEpoch_Last.targetStakeAmount > stakeAllocationDecrease
                ? uint256(validatorEpoch_Last.targetStakeAmount) - stakeAllocationDecrease
                : 0;

            // Only the turnover slice is routed by overallocation versus ideal weighted stake.
            uint256 overallocatedStake = calculateOverallocatedStake(
                validatorEpoch_Last,
                globalRevenue_LastLast,
                globalRevenue_Last,
                validatorRevenue_LastLast,
                validatorRevenue_Last,
                scoring
            );
            if (overallocatedStake > 0 && remainingDecreaseCapacity > 0) {
                turnoverAllocationDecrease =
                    uint256(turnoverQueueForUnstake_Last).mulDivUp(overallocatedStake, scoring.totalOverallocatedStake);
                turnoverAllocationDecrease = Math.min(turnoverAllocationDecrease, remainingDecreaseCapacity);
                stakeAllocationDecrease += turnoverAllocationDecrease;
            }
        }

        if (stakeAllocationIncrease > stakeAllocationDecrease) {
            netAmount = uint128(stakeAllocationIncrease - stakeAllocationDecrease);
            targetValidatorStake = validatorEpoch_Last.targetStakeAmount + netAmount;
            isWithdrawal = false;
        } else {
            netAmount = uint128(stakeAllocationDecrease - stakeAllocationIncrease);
            targetValidatorStake = validatorEpoch_Last.targetStakeAmount - netAmount;
            isWithdrawal = true;
        }

        return (
            targetValidatorStake,
            netAmount,
            isWithdrawal,
            stakeAllocationIncrease,
            stakeAllocationDecrease,
            turnoverAllocationDecrease
        );
    }

    /// @notice Returns per-validator amount that is was eligible to unstake at the end of last epoch.
    /// @dev Snapshotted amount, corresponds with globalCapitalLast and doesnt change throughout an epoch.
    /// @param validatorEpoch_Last Validator epoch at n-1.
    /// @param validatorEpoch_LastLast Validator epoch at n-2.
    /// @param validatorPendingEscrow_Last Pending escrow at n-1.
    /// @param validatorPendingEscrow_LastLast Pending escrow at n-2.
    /// @return amount Snapshot of end of last epoch's amount to unstake.
    function getValidatorAmountAvailableToUnstakeSnapshot(
        Epoch memory validatorEpoch_Last,
        Epoch memory validatorEpoch_LastLast,
        StakingEscrow memory validatorPendingEscrow_Last,
        StakingEscrow memory validatorPendingEscrow_LastLast
    )
        internal
        pure
        returns (uint256 amount)
    {
        amount = validatorEpoch_Last.targetStakeAmount;
        if (validatorEpoch_Last.hasDeposit) {
            uint256 _unavailable_Last = validatorPendingEscrow_Last.pendingStaking;
            amount = _saturatingSub(amount, _unavailable_Last);
        }
        if (validatorEpoch_LastLast.hasDeposit && validatorEpoch_LastLast.crankedInBoundaryPeriod) {
            uint256 _unavailable_LastLast = validatorPendingEscrow_LastLast.pendingStaking;
            amount = _saturatingSub(amount, _unavailable_LastLast);
        }
    }

    /// @notice Returns global amount currently eligible to unstake (excludes pending staking/unstaking).
    /// @dev total = staked; unavailable = pendingStaking + pendingUnstaking; amount = total - unavailable (saturating).
    /// @param globalCapital Working capital snapshot.
    /// @param globalPending Global pending escrow snapshot.
    /// @return amount Eligible global amount to unstake.
    function getGlobalAmountAvailableToUnstake(
        WorkingCapital memory globalCapital,
        StakingEscrow memory globalPending
    )
        internal
        pure
        returns (uint256 amount)
    {
        // MON can have four states:
        // 1. Floating, regular MON (address(this).balance))
        // 2. Pending Staking MON
        // 3. Pending Unstaking MON
        // 4. Staked, Productive MON
        // All staked, productive MON is eligible to be unstaked, thus:
        uint256 _total = globalCapital.stakedAmount;
        uint256 _unavailable = globalPending.pendingStaking + globalPending.pendingUnstaking;
        // NOTE: pendingStaking and pendingUnstaking are both considered a part of the total stakedAmount.
        amount = _saturatingSub(_total, _unavailable);
    }
}
