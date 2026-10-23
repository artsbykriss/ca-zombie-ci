//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";
import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";

import { BPS_SCALE } from "../Constants.sol";

/// @title QueueLib
/// @notice Pure helpers for global stake/unstake queue math and turnover queue classification.
library QueueLib {
    using SafeCastLib for uint256;

    struct ExcessQueueOffsetPlan {
        // Amount netted out of both queues before later capacity clamps roll leftovers forward.
        uint120 targetOffsetAmount;
        // Liquid MON redirected into reserves before any queue-to-stake value remains.
        uint120 reserveIncrease;
        uint120 reducedQueueToStake;
        uint120 reducedQueueForUnstake;
        uint120 reducedTurnoverQueueForUnstake;
        // Tracks whether reserves were short, even when the capped reserve increase is zero.
        bool hasReserveDeficit;
    }

    function reducePreferNonTurnover(
        uint256 queueForUnstake,
        uint256 turnoverQueueForUnstake,
        uint256 amount
    )
        internal
        pure
        returns (uint120 reducedQueueForUnstake, uint120 reducedTurnoverQueueForUnstake, uint120 turnoverConsumed)
    {
        // Liability coverage should consume user-facing / non-turnover withdrawals first, preserving any deliberate
        // rebalancing budget unless we are forced to dip into it.
        uint256 nonTurnoverQueueForUnstake =
            queueForUnstake > turnoverQueueForUnstake ? queueForUnstake - turnoverQueueForUnstake : 0;
        // Spend non-turnover first so liability offsets preserve rebalance intent where possible.
        uint256 nonTurnoverConsumed = Math.min(amount, nonTurnoverQueueForUnstake);
        turnoverConsumed = (amount - nonTurnoverConsumed).toUint120();
        reducedQueueForUnstake = (queueForUnstake - amount).toUint120();
        reducedTurnoverQueueForUnstake = (turnoverQueueForUnstake - turnoverConsumed).toUint120();
    }

    function reducePreferTurnover(
        uint256 queueForUnstake,
        uint256 turnoverQueueForUnstake,
        uint256 amount
    )
        internal
        pure
        returns (uint120 reducedQueueForUnstake, uint120 reducedTurnoverQueueForUnstake, uint120 turnoverConsumed)
    {
        // Capacity clamps shed turnover first so user requests keep their stake-proportional semantics
        // whenever aggregate queue pressure forces us to reduce withdrawals.
        // Any amount beyond turnover falls through to non-turnover by reducing the aggregate queue.
        turnoverConsumed = Math.min(amount, turnoverQueueForUnstake).toUint120();
        reducedQueueForUnstake = (queueForUnstake - amount).toUint120();
        reducedTurnoverQueueForUnstake = (turnoverQueueForUnstake - turnoverConsumed).toUint120();
    }

    function getTurnoverAmountToRequeue(
        uint256 requestedWithdrawal,
        uint256 requestedTurnoverWithdrawal,
        uint256 fulfilledWithdrawal
    )
        internal
        pure
        returns (uint120 turnoverAmountToRequeue)
    {
        // Decreases conceptually satisfy non-turnover withdrawals first, then turnover. When an unstake is only
        // partially fulfilled, only the unsatisfied tail that belonged to turnover should keep its turnover label.
        if (requestedTurnoverWithdrawal == 0 || fulfilledWithdrawal >= requestedWithdrawal) return 0;
        // Defensive cap: callers should already pass a turnover slice within the requested withdrawal.
        if (requestedTurnoverWithdrawal > requestedWithdrawal) requestedTurnoverWithdrawal = requestedWithdrawal;

        uint256 requestedNonTurnoverWithdrawal = requestedWithdrawal - requestedTurnoverWithdrawal;
        // Fulfillment only reaches turnover after it has covered the non-turnover prefix.
        uint256 turnoverSatisfied = fulfilledWithdrawal > requestedNonTurnoverWithdrawal
            ? fulfilledWithdrawal - requestedNonTurnoverWithdrawal
            : 0;
        if (turnoverSatisfied >= requestedTurnoverWithdrawal) return 0;

        turnoverAmountToRequeue = (requestedTurnoverWithdrawal - turnoverSatisfied).toUint120();
    }

    function backedRedemptions(
        uint256 reservedAmount,
        uint256 pendingUnstaking,
        uint256 rewardsPayable,
        uint256 redemptionsPayable
    )
        internal
        pure
        returns (uint256)
    {
        // Rewards are senior to redemptions in the shared reserve bucket. Only reserves above rewards, plus
        // already-pending unstaking, can replace a redemption-backed validator withdrawal.
        uint256 reservedForRedemptions = reservedAmount > rewardsPayable ? reservedAmount - rewardsPayable : 0;
        return Math.min(redemptionsPayable, reservedForRedemptions + pendingUnstaking);
    }

    function _calculateDesiredCapacityOffset(
        uint256 queuedForUnstakeAmount,
        uint256 globalUnstakableAmount,
        uint256 queuedToStakeAmount,
        uint256 globalStakableAmount
    )
        private
        pure
        returns (uint256 capacityOffsetBudget)
    {
        uint256 unstakeCapacityShortfall;
        if (queuedForUnstakeAmount > globalUnstakableAmount) {
            unstakeCapacityShortfall = queuedForUnstakeAmount - globalUnstakableAmount;
        }

        uint256 stakeCapacityShortfall;
        if (queuedToStakeAmount > globalStakableAmount) {
            stakeCapacityShortfall = queuedToStakeAmount - globalStakableAmount;
        }

        // Net against the larger capacity shortfall, capped by the smaller live queue because both sides are consumed.
        capacityOffsetBudget = unstakeCapacityShortfall;
        if (stakeCapacityShortfall > capacityOffsetBudget) capacityOffsetBudget = stakeCapacityShortfall;

        uint256 maxOffsetAmount = queuedForUnstakeAmount;
        if (queuedToStakeAmount < maxOffsetAmount) maxOffsetAmount = queuedToStakeAmount;
        if (capacityOffsetBudget > maxOffsetAmount) capacityOffsetBudget = maxOffsetAmount;
    }

    function _calculateReserveIncrease(
        uint256 targetReservedAmount,
        uint256 currentReservedAmount,
        uint256 globalStakableAmount,
        uint256 capacityOffsetBudget
    )
        private
        pure
        returns (uint256 reserveIncrease)
    {
        if (targetReservedAmount <= currentReservedAmount) return 0;

        reserveIncrease = targetReservedAmount - currentReservedAmount;
        // Reserves can only be filled by liquid MON and only up to the capacity offset budget.
        if (reserveIncrease > globalStakableAmount) reserveIncrease = globalStakableAmount;
        if (reserveIncrease > capacityOffsetBudget) reserveIncrease = capacityOffsetBudget;
    }

    function planExcessQueueOffset(
        uint256 queuedForUnstakeAmount,
        uint256 turnoverQueueForUnstake,
        uint256 globalUnstakableAmount,
        uint256 queuedToStakeAmount,
        uint256 globalStakableAmount,
        uint256 targetReservedAmount,
        uint256 currentReservedAmount,
        uint256 pendingUnstaking,
        uint256 rewardsPayable,
        uint256 redemptionsPayable
    )
        internal
        pure
        returns (ExcessQueueOffsetPlan memory plan)
    {
        uint256 capacityOffsetBudget = _calculateDesiredCapacityOffset(
            queuedForUnstakeAmount, globalUnstakableAmount, queuedToStakeAmount, globalStakableAmount
        );

        plan.hasReserveDeficit = targetReservedAmount > currentReservedAmount;
        uint256 reserveIncrease = _calculateReserveIncrease(
            targetReservedAmount, currentReservedAmount, globalStakableAmount, capacityOffsetBudget
        );
        plan.reserveIncrease = reserveIncrease.toUint120();

        uint256 reducedQueueForUnstake = queuedForUnstakeAmount;
        uint256 reducedTurnoverQueueForUnstake = turnoverQueueForUnstake;
        uint256 appliedOffsetAmount;

        if (capacityOffsetBudget > 0) {
            uint256 backedRedemptionAmount = backedRedemptions(
                currentReservedAmount + reserveIncrease, pendingUnstaking, rewardsPayable, redemptionsPayable
            );
            uint256 uncoveredRedemptionAmount = redemptionsPayable - backedRedemptionAmount;
            uint256 nonTurnoverQueueForUnstake =
                queuedForUnstakeAmount > turnoverQueueForUnstake ? queuedForUnstakeAmount - turnoverQueueForUnstake : 0;

            // Non-turnover is a routing class shared by redemption and pool-liquidity withdrawals. Protect only
            // the portion still needed for uncovered redemptions; demand above that floor can cancel stake demand.
            uint256 protectedNonTurnover = Math.min(nonTurnoverQueueForUnstake, uncoveredRedemptionAmount);
            uint256 nettableNonTurnover = nonTurnoverQueueForUnstake - protectedNonTurnover;
            uint256 nonTurnoverOffset = Math.min(capacityOffsetBudget, nettableNonTurnover);

            if (nonTurnoverOffset > 0) {
                (uint120 reducedQueue120, uint120 reducedTurnover120,) =
                    reducePreferNonTurnover(reducedQueueForUnstake, reducedTurnoverQueueForUnstake, nonTurnoverOffset);
                reducedQueueForUnstake = reducedQueue120;
                reducedTurnoverQueueForUnstake = reducedTurnover120;
                appliedOffsetAmount = nonTurnoverOffset;
            }

            uint256 remainingCapacityOffset = capacityOffsetBudget - appliedOffsetAmount;
            uint256 turnoverOffset = Math.min(remainingCapacityOffset, reducedTurnoverQueueForUnstake);
            if (turnoverOffset > 0) {
                // Consume turnover only after all non-turnover above the redemption floor has been netted.
                (uint120 reducedQueue120, uint120 reducedTurnover120,) =
                    reducePreferTurnover(reducedQueueForUnstake, reducedTurnoverQueueForUnstake, turnoverOffset);
                reducedQueueForUnstake = reducedQueue120;
                reducedTurnoverQueueForUnstake = reducedTurnover120;
                appliedOffsetAmount += turnoverOffset;
            }
        }

        plan.targetOffsetAmount = appliedOffsetAmount.toUint120();
        plan.reducedQueueToStake = (queuedToStakeAmount - appliedOffsetAmount).toUint120();
        plan.reducedQueueForUnstake = reducedQueueForUnstake.toUint120();
        plan.reducedTurnoverQueueForUnstake = reducedTurnoverQueueForUnstake.toUint120();
    }

    function clampTurnoverToOverallocation(
        uint256 queueForUnstake,
        uint256 turnoverQueueForUnstake,
        uint256 totalOverallocatedStake
    )
        internal
        pure
        returns (uint120 clampedQueueForUnstake, uint120 clampedTurnoverQueueForUnstake, uint120 strippedTurnover)
    {
        clampedQueueForUnstake = queueForUnstake.toUint120();
        clampedTurnoverQueueForUnstake = turnoverQueueForUnstake.toUint120();

        if (totalOverallocatedStake == 0 && turnoverQueueForUnstake > 0) {
            // No overallocation denominator means there is nothing valid to rebalance.
            strippedTurnover = turnoverQueueForUnstake.toUint120();
            clampedQueueForUnstake = (queueForUnstake - turnoverQueueForUnstake).toUint120();
            clampedTurnoverQueueForUnstake = 0;
        } else if (turnoverQueueForUnstake > totalOverallocatedStake) {
            // Turnover should not ask validators to unwind more than measured overallocation.
            strippedTurnover = (turnoverQueueForUnstake - totalOverallocatedStake).toUint120();
            clampedQueueForUnstake = (queueForUnstake - strippedTurnover).toUint120();
            clampedTurnoverQueueForUnstake = (turnoverQueueForUnstake - strippedTurnover).toUint120();
        }
    }

    function calculateTurnoverTopUp(
        uint256 activeValidatorCount,
        uint256 globalUnstakableAmount,
        uint256 totalOverallocatedStake,
        uint256 incentiveAlignmentPercentage,
        uint256 queueForUnstake,
        uint256 turnoverQueueForUnstake
    )
        internal
        pure
        returns (uint120 topUpAmount)
    {
        if (
            activeValidatorCount <= 1 || globalUnstakableAmount == 0 || totalOverallocatedStake == 0
                || incentiveAlignmentPercentage == 0
        ) {
            return 0;
        }

        // Divide by four because unstaking takes two epochs and depositing takes another two epochs.
        uint256 alignmentUnstakeAmount = globalUnstakableAmount * incentiveAlignmentPercentage / BPS_SCALE / 4;
        // Existing user/non-turnover withdrawals already create turnover-like movement through the active set.
        uint256 nonTurnoverQueueForUnstake =
            queueForUnstake > turnoverQueueForUnstake ? queueForUnstake - turnoverQueueForUnstake : 0;
        uint256 requiredTurnoverQueueForUnstake = alignmentUnstakeAmount > nonTurnoverQueueForUnstake
            ? alignmentUnstakeAmount - nonTurnoverQueueForUnstake
            : 0;

        if (requiredTurnoverQueueForUnstake > totalOverallocatedStake) {
            requiredTurnoverQueueForUnstake = totalOverallocatedStake;
        }
        if (turnoverQueueForUnstake >= requiredTurnoverQueueForUnstake) return 0;

        uint256 remainingUnstakableCapacity =
            globalUnstakableAmount > queueForUnstake ? globalUnstakableAmount - queueForUnstake : 0;
        uint256 topUp = requiredTurnoverQueueForUnstake - turnoverQueueForUnstake;
        // Never add incentive turnover that would exceed this epoch's unstakable capacity.
        if (topUp > remainingUnstakableCapacity) topUp = remainingUnstakableCapacity;
        topUpAmount = topUp.toUint120();
    }
}
