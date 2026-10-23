//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT } from "./Constants.sol";

// 3 types of mutually exclusive shMON balances:
// - Uncommitted: shMON that can be transferred freely.
// - Committed: shMON that is committed to a Policy and has not yet started uncommitting.
// - Uncommitting: shMON that is in the process of uncommitting from a Policy.

// NOTE: we do not track an account's total uncommitting balance.
// Would need to add array of policies active per account to calc total uncommitting balance.
struct Balance {
    uint128 uncommitted; // Account's uncommitted shMON balance
    uint128 committed; // Account's committed shMON balance across all policies
}

struct Supply {
    uint128 total;
    uint128 committedTotal;
}

struct CommittedData {
    uint128 committed; // Account's committed amount in the current Policy (excl. uncommitting)
    uint128 minCommitted; // Account's minimum committed amount in the current Policy
}

struct UncommittingData {
    uint128 uncommitting; // Account's uncommitting amount in the current Policy
    uint48 uncommitStartBlock; // Block at which account last started uncommitting
    uint80 placeholder; // Placeholder for future use
}

struct TopUpData {
    uint128 totalPeriodTopUps; // Sum of all top-ups in the current top-up period
    uint48 topUpPeriodStartBlock; // block.number of start of last top-up period
    uint80 placeholder; // Placeholder for future use
}

struct TopUpSettings {
    uint128 maxTopUpPerPeriod; // Max uncommitted shMON allowed per top-up of committed
    uint32 topUpPeriodDuration; // Duration of the top-up period, in blocks
    uint96 placeholder; // Placeholder for future use
}

struct Policy {
    uint48 escrowDuration; // Uncommitting period of the Policy
    bool active; // Whether the Policy is active or not
    address primaryAgent; // Most frequently-calling agent (for gas efficiency)
}

// For HoldsLib - never used in storage
struct PolicyAccount {
    uint64 policyID;
    address account;
}

struct UncommitApproval {
    address completor; // Account allowed to `completeUncommit()` on user's behalf
    uint96 shares; // Max shares where uncommit can be completed on user's behalf
}

enum Delivery {
    Committed,
    Uncommitted,
    Underlying
}

// ================================================== //
//                 CapitalAllocator Types             //
// ================================================== //

// Lightweight view snapshot assembled from validator epoch/reward trackers.
struct ValidatorStats {
    bool isActive;
    address coinbase;
    uint64 lastEpoch;
    uint128 targetStakeAmount;
    uint128 rewardsPayableLast;
    uint128 earnedRevenueLast;
    uint128 rewardsPayableCurrent;
    uint128 earnedRevenueCurrent;
}

// UnstakeRequest at the User <> ShMonad level
struct UserUnstakeRequest {
    uint128 amountMon; // Amount in MON being unstaked
    uint64 completionEpoch; // Epoch when the unstake request is able to be completed
}

// Tracks the full v1.2 traditional-unstake request set for 1 account in 1 mapping entry.
// `occupiedBitmap` uses 1 bit per request slot, including the dedicated matured aggregate slot.
struct UserUnstakesState {
    UserUnstakeRequest[TRADITIONAL_UNSTAKE_REQUEST_SLOT_COUNT] requests;
    uint8 occupiedBitmap; // Active-slot bitmap across the fixed per-account request set
}

struct IsolatedUnstakeRequest {
    uint128 amountMon; // Locked principal amount in MON
    uint64 completionEpoch; // Earliest internal epoch at which completion is allowed
}

struct IsolatedPendingStakeCohort {
    uint120 amount; // Isolated MON scheduled for the same native activation epoch
    uint64 activationEpoch; // Monad epoch in which the cohort becomes active
}

struct IsolatedPendingStakeState {
    uint120 rewardProductiveStake; // Mature isolated stake awaiting source-verified principal activation
    // At any current epoch, isolated delegations can only target current, current + 1, or current + 2.
    IsolatedPendingStakeCohort[3] cohorts;
}

// ================================================== //
//                 StakeTracker Types                 //
// ================================================== //

struct Epoch {
    uint64 epoch;
    uint8 withdrawalId;
    bool hasWithdrawal;
    bool hasDeposit;
    bool crankedInBoundaryPeriod;
    bool wasCranked; // refers to the placeholder validator if global, or the validator if specific
    bool frozen;
    bool closed;
    uint128 targetStakeAmount;
}

struct RevenueSmoother {
    uint120 earnedRevenueLast; // Notional balance at the active schedule's start; may be rebased
    uint64 epochChangeBlockNumber; // Active schedule start block; not necessarily the latest epoch roll
}

struct ValidatorDataStorage {
    uint64 epoch;
    uint64 id;
    bool isActive;
    bool inActiveSet_Current;
    bool inActiveSet_Last;
    uint64 activeSetObservationEpoch; // Raw Monad epoch of the latest native membership observation
}

struct ValidatorData {
    uint64 epoch;
    uint64 id;
    bool isPlaceholder;
    bool isActive;
    bool inActiveSet_Current;
    bool inActiveSet_Last;
    address coinbase;
}

struct AdminValues {
    uint64 internalEpoch;
    uint16 targetLiquidityPercentage;
    uint16 incentiveAlignmentPercentage;
    uint16 stakingCommission;
    uint16 boostCommissionRate; // measured in basis points
    uint128 totalZeroYieldPayable; // liability, total zero-yield tranche funds, incl owner commission
}

struct FeeParams {
    uint128 mRay; // slope rate (RAY)
    uint128 cRay; // y-intercept/base fee rate (RAY)
}

struct CashFlows {
    uint120 queueToStake; // MON units,
    uint120 queueForUnstake; // MON units
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct AtomicCapital {
    uint128 allocatedAmount;
    uint128 distributedAmount;
}

struct StakingEscrow {
    uint120 pendingStaking; // MON units
    uint120 pendingUnstaking; // MON units
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct Revenue {
    uint120 allocatedRevenue; // earnedRevenue already consumed or reserved by same-epoch accounting sinks
    uint120 earnedRevenue; // MON units retained by protocol
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct AllocationRevenue {
    uint120 stakingYield; // MON units sourced from staking yield, tracked only for stake-allocation weighting
    uint120 nonStakingRevenue; // MON units sourced from MEV / boosts / donations, tracked only for weighting
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct TurnoverQueue {
    uint120 queueForUnstake; // MON units attributable to turnover only; always a subset of aggregate queueForUnstake
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct StakeAllocationConfig {
    uint128 nonStakingRevenueMultiplierRay; // Zero means the default launch multiplier
    uint64 splitStartEpoch; // First allocation round using split weighting; zero means active immediately
    uint16 stakingYieldDeadbandBps; // Basis points of expected staking yield filtered from allocation scoring
    bool includeIsolatedRewardsInStakeAllocation; // Include isolated rewards in the pooled allocation signal
}

struct AllocationTotals {
    uint128 totalPooledTargetStake; // Cached sum of pooled validator target stake in the active set for the round
    uint128 totalOverallocatedStake; // Cached sum of max(0, stake - idealWeightedStake) across the active set
    uint128 totalAllocationSignalStake; // Cached sum of stake used for allocation scoring
    uint128 totalAdjustedWeightedRevenue; // Cached sum of validator weighted revenue for the active set
}

struct PendingBoost {
    uint120 rewardsPayable; // MON units earmarked for validator payouts
    uint120 earnedRevenue; // MON units retained by protocol
    bool alwaysTrue; // Avoids storing a zero slot to save gas on future writes
}

struct WorkingCapital {
    uint128 stakedAmount;
    uint128 reservedAmount; // portion reserved for validator payments or withdrawals
}

struct CurrentLiabilities {
    uint128 rewardsPayable; // to validators
    uint128 redemptionsPayable; // illiquid
}

struct IsolatedValidatorState {
    uint120 activeStake; // isolated productive stake with the validator
    uint120 pendingStake; // isolated stake not yet locally classified as active and withdrawable
    uint120 pendingUnstake; // isolated stake currently in the withdrawal delay
    uint120 queuedRestake; // liquid isolated MON queued to re-stake into the same validator
    uint120 queuedUnstake; // principal amount still needing undelegation
    uint120 idleAssets; // liquid isolated MON held for claims / direct exits
    uint120 redemptionsPayable; // locked principal owed to exited isolated users
    uint120 snapshotPooledStake; // last-epoch pooled stake snapshot for reward splits
    uint120 snapshotIsolatedStake; // last-epoch isolated stake snapshot for reward splits and allocation signal
    uint120 snapshotProductiveIsolatedStake; // reward-productive isolated stake snapshot for staking-yield splits
    uint8 pooledWithdrawalCursor; // next pooled withdrawal id candidate, range 1-128
    uint8 isolatedWithdrawalCursor; // next isolated withdrawal id candidate, range 129-255
    uint8 isolatedWithdrawalId; // isolated withdrawal id currently in flight
    bool isolatedWithdrawalPending; // whether isolatedWithdrawalId is live in the precompile
    bool snapshotsInitialized; // whether the validator completed an isolated snapshot roll
}

enum CashFlowType {
    Goodwill, // The null value
    Deposit,
    Revenue,
    AllocationReduction
}
