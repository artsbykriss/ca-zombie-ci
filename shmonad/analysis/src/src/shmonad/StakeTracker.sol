//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "@solady/utils/SafeTransferLib.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";

import { ValidatorRegistry } from "./ValidatorRegistry.sol";
import {
    Epoch,
    PendingBoost,
    CashFlows,
    StakingEscrow,
    AtomicCapital,
    ValidatorData,
    ValidatorDataStorage,
    WorkingCapital,
    CashFlowType,
    CurrentLiabilities,
    RevenueSmoother,
    Revenue,
    AllocationRevenue,
    TurnoverQueue,
    AllocationTotals,
    IsolatedValidatorState,
    IsolatedPendingStakeCohort,
    IsolatedPendingStakeState,
    IsolatedUnstakeRequest
} from "./Types.sol";
import { StakeAllocationLib } from "./libraries/StakeAllocationLib.sol";
import { StorageLib } from "./libraries/StorageLib.sol";
import { IMonadStaking } from "./interfaces/IMonadStaking.sol";
import { ICoinbase } from "./interfaces/ICoinbase.sol";
import { IHolisticMON } from "./interfaces/IHolisticMON.sol";
import {
    MIN_VALIDATOR_DEPOSIT,
    SCALE,
    TARGET_FLOAT,
    STAKING,
    SHMONAD_VALIDATOR_DEACTIVATION_PERIOD,
    FLOAT_PLACEHOLDER,
    FLOAT_REBALANCE_SENSITIVITY,
    BPS_SCALE,
    EPOCHS_TRACKED,
    UINT120_MASK,
    DUST_THRESHOLD,
    DEFAULT_STAKING_YIELD_DEADBAND_BPS,
    UNKNOWN_VAL_ID,
    UNKNOWN_VAL_ADDRESS,
    LAST_VAL_ID,
    FIRST_VAL_ID,
    MAX_EXTERNAL_REWARD,
    OWNER_COMMISSION_ACCOUNT,
    COINBASE_PROCESS_GAS_LIMIT,
    VALIDATOR_CRANK_LIMIT,
    COINBASE_HANDLE_MEV_GAS_LIMIT,
    RAY,
    MAX_ACTIVE_VALIDATORS_FOR_ALLOCATION,
    MONAD_EPOCH_LENGTH
} from "./Constants.sol";
import {
    POOLED_WITHDRAW_ID_MIN,
    POOLED_WITHDRAW_ID_MAX,
    ISOLATED_WITHDRAW_ID_MIN,
    ISOLATED_WITHDRAW_ID_MAX
} from "./Constants.sol";

import { AccountingLib } from "./libraries/AccountingLib.sol";
import { QueueLib } from "./libraries/QueueLib.sol";

/// @notice Consolidated StakeTracker using Monad precompile epochs and a single crank() entrypoint.
/// @dev Stake allocation uses a smoothed weighted revenue signal `Wi = max(Yi - d * Ei, 0) + m * Ri`, where `Yi` is
/// staking yield, `Ei` is expected stake-proportional yield, `d` is the configured deadband, and `Ri` is non-staking
/// revenue such as MEV, boosts, and donations. By default the signal stays pooled-only; when the
/// owner enables isolated rewards in stake allocation, validator-attributed isolated rewards are also counted in the
/// signal while the stake-position side stays pooled-only. Inflows are assigned by weighted revenue share. Outflows
/// are split between a non-turnover queue that remains stake-proportional and a turnover queue that is routed by
/// `max(0, Stake_i - IdealWeightedStake_i)`. The global crank caches the active-set totals used by that turnover path
/// before validator cranking so every validator reads a consistent denominator for the round. It replaces legacy
/// queue/bitmap epoch flows and relies on _crankGlobal + _crankValidators.
abstract contract StakeTracker is ValidatorRegistry {
    using SafeTransferLib for address;
    using SafeCastLib for uint256;
    using SafeCastLib for uint128;
    using Math for uint256;
    using AccountingLib for WorkingCapital;
    using AccountingLib for AtomicCapital;
    using AccountingLib for CurrentLiabilities;
    using StorageLib for CashFlows;
    using StorageLib for StakingEscrow;
    using StorageLib for PendingBoost;
    using StorageLib for Revenue;
    using StorageLib for AllocationRevenue;
    using StorageLib for TurnoverQueue;

    // ================================================== //
    //                        Init                        //
    // ================================================== //

    /// @notice Initializes the StakeTracker contract with initial state and validator setup
    /// @dev Sets up the initial epoch structure, registers placeholder validators, and initializes global state
    function __StakeTracker_init() internal {
        // For adding s_globalPendingLast and s_globalCapitalLast mid-epoch
        if (!s_globalPendingLast.alwaysTrue) {
            StakingEscrow memory _pendingStaking = s_globalPending;
            _pendingStaking.alwaysTrue = true;
            s_globalPendingLast = _pendingStaking;
            WorkingCapital memory _globalCapital = s_globalCapital;
            s_globalCapitalLast = _globalCapital;
            s_isolatedTotalAssetsLast = s_isolatedTotalAssets;
            s_isolatedLiquidAssetsLast = s_isolatedLiquidAssets;
        }

        if (globalEpochPtr_N(0).epoch != 0) return;

        if (s_admin.internalEpoch == 0) {
            // Register the "unregistered" validator placeholder
            s_valLinkNext[FIRST_VAL_ID] = LAST_VAL_ID;
            s_valLinkPrevious[LAST_VAL_ID] = FIRST_VAL_ID;
            _addValidator(UNKNOWN_VAL_ID, UNKNOWN_VAL_ADDRESS);
            s_nextValidatorToCrank = UNKNOWN_VAL_ID;

            // Do not count the placeholder validator as an active validator
            // for purposes of rolling stake / unstake queue forward
            --s_activeValidatorCount;

            s_validatorData[UNKNOWN_VAL_ID].inActiveSet_Last = true;
            s_validatorData[UNKNOWN_VAL_ID].inActiveSet_Current = true;

            // we initialize the epoch to 10 to avoid the first epoch being 0, which is not valid.
            // internal, the epoch is independent of the monad epoch.
            uint64 _currentEpoch = 10;

            // Start s_admin off as the current monad epoch
            // NOTE: They will diverge over time.
            s_admin.internalEpoch = _currentEpoch;

            globalEpochPtr_N(-3).epoch = _currentEpoch < 3 ? 0 : _currentEpoch - 3;
            globalEpochPtr_N(-2).epoch = _currentEpoch < 2 ? 0 : _currentEpoch - 2;
            globalEpochPtr_N(-1).epoch = _currentEpoch < 1 ? 0 : _currentEpoch - 1;
            globalEpochPtr_N(0).epoch = _currentEpoch;
            globalEpochPtr_N(1).epoch = _currentEpoch + 1;
            globalEpochPtr_N(2).epoch = _currentEpoch + 2;

            s_pendingTargetAtomicLiquidityPercent = TARGET_FLOAT;

            for (int256 i; i < int256(EPOCHS_TRACKED); i++) {
                globalRevenuePtr_N(i).alwaysTrue = true;
                globalCashFlowsPtr_N(i).alwaysTrue = true;
                globalAllocationRevenuePtr_N(i).alwaysTrue = true;
                turnoverQueuePtr_N(i).alwaysTrue = true;
            }

            uint256 _goodwill = _pooledGoodwill(address(this).balance);

            // this is a hack to get the legacy balance into the system. We should remove this migration after the
            // initial testnet upgrade.
            if (_goodwill > 0) {
                (bool _delegationsDone,, uint64[] memory _delegatedValidators) =
                    STAKING.getDelegations(address(this), 0);
                require(_delegationsDone, LegacyDelegationsPaginationIncomplete());
                require(_delegatedValidators.length == 0, LegacyDelegationsDetected());

                require(s_globalCapital.stakedAmount == 0 && s_globalCapital.reservedAmount == 0, LegacyStakeDetected());
                require(
                    s_globalLiabilities.rewardsPayable == 0 && s_globalLiabilities.redemptionsPayable == 0
                        && s_admin.totalZeroYieldPayable == 0,
                    LegacyLiabilitiesDetected()
                );
                require(
                    s_atomicAssets.allocatedAmount == 0 && s_atomicAssets.distributedAmount == 0,
                    LegacyAtomicStateDetected()
                );
                globalCashFlowsPtr_N(0).queueToStake += _goodwill.toUint120();
            }

            _crankGlobal();
            _crankValidators();
        }
    }

    function _emitZeroYieldTransfer(address from, address to, uint256 amount) internal {
        if (amount == 0) return;
        IHolisticMON(HMON_TOKEN_ADDRESS).emitTransfer(from, to, amount);
    }

    function _activateZeroYieldAccount(address account) internal {
        if (account == address(0)) return;
        IHolisticMON(HMON_TOKEN_ADDRESS).activate(account);
    }

    function _increaseZeroYieldBalance(address fromEvent, address to, uint256 amount, bool emitDepositEvent) internal {
        if (amount == 0) return;
        _activateZeroYieldAccount(to);
        s_zeroYieldBalances[to] += amount;
        _emitZeroYieldTransfer(address(0), to, amount);
        if (emitDepositEvent) emit DepositToZeroYieldTranche(fromEvent, to, amount);
    }

    function _decreaseZeroYieldBalance(address from, uint256 amount) internal {
        uint256 available = s_zeroYieldBalances[from];
        require(available >= amount, InsufficientZeroYieldBalance(available, amount));
        _activateZeroYieldAccount(from);
        unchecked {
            s_zeroYieldBalances[from] = available - amount;
        }
        _emitZeroYieldTransfer(from, address(0), amount);
    }

    function _transferZeroYieldBalance(address from, address to, uint256 amount) internal {
        require(to != address(0), ZeroAddress());
        uint256 available = s_zeroYieldBalances[from];
        require(available >= amount, InsufficientZeroYieldBalance(available, amount));
        _activateZeroYieldAccount(from);
        if (to != from) _activateZeroYieldAccount(to);

        unchecked {
            s_zeroYieldBalances[from] = available - amount;
        }
        s_zeroYieldBalances[to] += amount;
    }

    // ================================================== //
    //                Isolated Stake Helpers              //
    // ================================================== //

    function _isolatedHasClaimants(uint64 valId, IsolatedValidatorState memory state) internal view returns (bool) {
        return s_isolatedVTotalShares[valId] != 0 || state.redemptionsPayable != 0;
    }

    function _sweepOrphanedIsolatedIdleAssets(uint64 valId, IsolatedValidatorState storage state) internal {
        if (_isolatedHasClaimants(valId, state)) return;
        if (
            state.activeStake != 0 || state.pendingStake != 0 || state.pendingUnstake != 0 || state.queuedRestake != 0
                || state.isolatedWithdrawalPending
        ) {
            return;
        }

        // With no claimants or recoverable principal, queuedUnstake is an unbacked scheduling marker that no later
        // crank can consume. Clear it before releasing any ownerless idle assets.
        state.queuedUnstake = 0;

        uint120 orphanedIdleAssets = state.idleAssets;
        if (orphanedIdleAssets == 0) return;

        // Once the isolated owner set is empty, any residual liquid MON must rejoin pooled equity immediately.
        // Leaving it in isolated accounting would silently strand value and poison future isolated share pricing.
        state.idleAssets = 0;
        s_isolatedIdleAssets -= orphanedIdleAssets;
        s_isolatedLiquidAssets -= orphanedIdleAssets;
        s_isolatedTotalAssets -= orphanedIdleAssets;

        // Releasing ownerless isolated MON raises pooled equity. Smooth that one-time reclassification so newly minted
        // pooled shares cannot immediately claim value that accrued before they joined.
        globalRevenuePtr_N(0).earnedRevenue += orphanedIdleAssets;
    }

    function _isolatedValidatorTotalAssets(IsolatedValidatorState memory state)
        internal
        pure
        returns (uint256 totalAssets)
    {
        return uint256(state.activeStake) + state.pendingStake + state.pendingUnstake + state.queuedRestake
            + state.idleAssets;
    }

    function _isolatedValidatorEquity(uint64 valId) internal view returns (uint256 equity) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        if (!_isolatedHasClaimants(valId, state)) return 0;
        uint256 totalAssets = _isolatedValidatorTotalAssets(state);
        uint256 redemptionsPayable = state.redemptionsPayable;
        // Exits are priced and locked when vShares are burned, so remaining holders only own the residual equity.
        return totalAssets > redemptionsPayable ? totalAssets - redemptionsPayable : 0;
    }

    function _convertToIsolatedShares(uint64 valId, uint256 assets) internal view returns (uint256) {
        uint256 totalShares = s_isolatedVTotalShares[valId];
        uint256 equity = _isolatedValidatorEquity(valId);
        return Math.mulDiv(assets, totalShares + 10 ** _decimalsOffset(), equity + 1);
    }

    function _convertToIsolatedAssets(uint64 valId, uint256 vShares) internal view returns (uint256) {
        uint256 totalShares = s_isolatedVTotalShares[valId];
        uint256 equity = _isolatedValidatorEquity(valId);
        return Math.mulDiv(vShares, equity + 1, totalShares + 10 ** _decimalsOffset());
    }

    function _pooledCurrentAssets(uint256 nativeTokenBalance) internal view returns (uint256) {
        return s_globalCapital.currentAssets(s_atomicAssets, nativeTokenBalance, s_isolatedLiquidAssets);
    }

    function _pooledGoodwill(uint256 nativeTokenBalance) internal view returns (uint256) {
        return AccountingLib.goodwill(
            s_globalCapital, s_atomicAssets, globalCashFlowsPtr_N(0), nativeTokenBalance, s_isolatedLiquidAssets
        );
    }

    function _splitIsolatedAndPooledBySnapshot(
        uint64 valId,
        uint256 amount
    )
        internal
        view
        returns (uint256 pooledAmount, uint256 isolatedAmount)
    {
        if (amount == 0) return (0, 0);

        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        if (!_isolatedHasClaimants(valId, state)) return (amount, 0);

        uint256 pooledStake = state.snapshotPooledStake;
        uint256 isolatedStake = state.snapshotIsolatedStake;

        // Zero is an authoritative snapshot. Using live stake here would let a post-snapshot deposit claim value that
        // was earned before it arrived and would make allocation signals mutable during the current crank round.
        if (isolatedStake == 0) return (amount, 0);
        if (pooledStake == 0) return (0, amount);

        uint256 totalStake = pooledStake + isolatedStake;
        isolatedAmount = Math.mulDiv(amount, isolatedStake, totalStake);
        pooledAmount = amount - isolatedAmount;
    }

    function _productivePooledStakeSnapshot(uint64 valId, uint256 pooledFallback) internal view returns (uint256) {
        Epoch memory validatorEpochLast = validatorEpochPtr_N(-1, valId);
        if (validatorEpochLast.targetStakeAmount == 0) return pooledFallback;

        // Pooled target stake includes pending deposits; staking yield only accrues to productive stake.
        return StakeAllocationLib.getValidatorAmountAvailableToUnstakeSnapshot(
            validatorEpochLast,
            validatorEpochPtr_N(-2, valId),
            validatorPendingPtr_N(-1, valId),
            validatorPendingPtr_N(-2, valId)
        );
    }

    function _splitStakingYieldByProductiveSnapshot(
        uint64 valId,
        uint256 amount,
        uint256 pooledFallback
    )
        internal
        view
        returns (uint256 pooledAmount, uint256 isolatedAmount)
    {
        if (amount == 0) return (0, 0);

        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        if (!_isolatedHasClaimants(valId, state)) return (amount, 0);

        uint256 pooledStake = _productivePooledStakeSnapshot(valId, pooledFallback);
        uint256 isolatedStake = state.snapshotProductiveIsolatedStake;

        if (isolatedStake == 0) return (amount, 0);
        if (pooledStake == 0) return (0, amount);

        uint256 totalStake = pooledStake + isolatedStake;
        isolatedAmount = Math.mulDiv(amount, isolatedStake, totalStake);
        pooledAmount = amount - isolatedAmount;
    }

    function _reserveQueuedIsolatedLiquidityForRedemptions(uint64 valId) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        uint256 covered = uint256(state.idleAssets) + state.pendingUnstake + state.queuedUnstake;
        uint256 redemptionsPayable = state.redemptionsPayable;
        if (covered >= redemptionsPayable || state.queuedRestake == 0) return;

        uint120 amountToMove = Math.min(redemptionsPayable - covered, uint256(state.queuedRestake)).toUint120();
        state.queuedRestake -= amountToMove;
        state.idleAssets += amountToMove;
        s_isolatedIdleAssets += amountToMove;
    }

    function _creditIsolatedRewards(
        uint64 valId,
        uint120 grossAmount,
        uint120 netAmount,
        uint120 commissionAmount
    )
        internal
    {
        if (netAmount == 0) {
            if (commissionAmount > 0) {
                emit IsolatedRewardsQueued(valId, grossAmount, 0, commissionAmount);
            }
            return;
        }

        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];

        // Design note: isolated rewards and withdrawal surplus are attributed at settlement time. Snapshots decide
        // only the isolated-vs-pooled amount; they do not checkpoint historical isolated vShare holders. Once credited
        // here, value becomes current validator equity owned pro rata by the current isolated vShare supply.
        s_isolatedTotalAssets += netAmount;
        s_isolatedLiquidAssets += netAmount;

        // If every isolated share has already been burned into exit requests, newly-attributed rewards must stay
        // liquid for those exits instead of being re-staked into an ownerless isolated position.
        if (s_validatorData[valId].isActive && s_isolatedVTotalShares[valId] != 0) {
            state.queuedRestake += netAmount;
        } else {
            state.idleAssets += netAmount;
            s_isolatedIdleAssets += netAmount;
        }

        emit IsolatedRewardsQueued(valId, grossAmount, netAmount, commissionAmount);
    }

    function _chargeStakingCommission(uint120 grossAmount)
        internal
        returns (uint120 netAmount, uint120 commissionAmount)
    {
        uint256 stakingCommissionRate = s_admin.stakingCommission;
        if (stakingCommissionRate == 0) return (grossAmount, 0);

        commissionAmount = (grossAmount * stakingCommissionRate / BPS_SCALE).toUint120();
        if (commissionAmount > 0) {
            // Staking commission is realized yield owed through the zero-yield tranche, not protocol equity.
            s_admin.totalZeroYieldPayable += commissionAmount;
            _increaseZeroYieldBalance(address(this), OWNER_COMMISSION_ACCOUNT, commissionAmount, true);
        }

        netAmount = grossAmount - commissionAmount;
    }

    function _handleIsolatedWithdrawalSurplus(uint64 valId, uint120 surplus) internal {
        (uint120 netSurplus, uint120 stakingCommission) = _chargeStakingCommission(surplus);

        // The surplus is known to have come from an isolated withdrawal, so do not use the generic snapshot split.
        // Only the net isolated reward can affect isolated accounting or optional isolated allocation signal.
        _recordStakingYieldAllocationSignal(valId, _allocationSignalAmount(0, netSurplus));

        _creditIsolatedRewards(valId, surplus, netSurplus, stakingCommission);
        // The commission cut is no longer isolated value, so keep it in the pooled stake queue with other commission.
        globalCashFlowsPtr_N(0).queueToStake += stakingCommission;
    }

    function _handlePooledWithdrawalSurplus(uint64 valId, uint120 surplus) internal {
        (uint120 netSurplus,) = _chargeStakingCommission(surplus);

        // The withdrawal request already identifies this yield as pooled. Productive snapshots are only needed for
        // source-ambiguous rewards claimed from the validator's combined pooled and isolated delegation.
        validatorRewardsPtr_N(0, valId).earnedRevenue += netSurplus;
        globalRevenuePtr_N(0).earnedRevenue += netSurplus;
        _recordStakingYieldAllocationSignal(valId, netSurplus);
    }

    function _isIsolatedValidatorFullyIdle(uint64 valId) internal view returns (bool) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        return state.activeStake == 0 && state.pendingStake == 0 && state.pendingUnstake == 0
            && state.queuedRestake == 0 && state.queuedUnstake == 0 && !state.isolatedWithdrawalPending;
    }

    function _hasPendingIsolatedCrankWork(uint64 valId) internal view returns (bool) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        return state.activeStake != 0 || state.pendingStake != 0 || state.pendingUnstake != 0
            || state.queuedRestake != 0 || state.queuedUnstake != 0 || state.isolatedWithdrawalPending;
    }

    function _hasResidualPooledState(uint64 valId) internal returns (bool) {
        // The current target was just rolled from this crank's allocation result. A failed forced exit restores it,
        // while live deposit and withdrawal flags can remain in any physical ring-buffer slot until settlement.
        if (validatorEpochPtr_N(0, valId).targetStakeAmount != 0) return true;
        for (uint256 i; i < EPOCHS_TRACKED; ++i) {
            Epoch storage validatorEpoch = s_validatorEpoch[valId][i];
            if (validatorEpoch.hasDeposit || validatorEpoch.hasWithdrawal) return true;
        }

        // Registry deletion is destructive, so an unreadable precompile position is not proof that it is empty.
        (bool readSucceeded, uint256 activeStake, uint256 pendingDeposits,,) = _getStakeInfo(valId);
        return !readSucceeded || activeStake != 0 || pendingDeposits != 0;
    }

    function _hasResidualIsolatedState(uint64 valId) internal view returns (bool) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        return s_isolatedVTotalShares[valId] != 0 || s_isolatedUnstakeRequestCount[valId] != 0 || state.activeStake != 0
            || state.pendingStake != 0 || state.pendingUnstake != 0 || state.queuedRestake != 0
            || state.queuedUnstake != 0 || state.idleAssets != 0 || state.redemptionsPayable != 0
            || state.isolatedWithdrawalPending;
    }

    function _currentWithdrawalCursor(uint64 valId, bool isolated) internal view returns (uint8 cursor) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        if (isolated) {
            cursor = state.isolatedWithdrawalCursor;
            return cursor == 0 ? ISOLATED_WITHDRAW_ID_MIN : cursor;
        }
        cursor = state.pooledWithdrawalCursor;
        return cursor == 0 ? POOLED_WITHDRAW_ID_MIN : cursor;
    }

    function _setNextWithdrawalCursor(uint64 valId, bool isolated, uint8 usedId) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        uint8 minId = isolated ? ISOLATED_WITHDRAW_ID_MIN : POOLED_WITHDRAW_ID_MIN;
        uint8 maxId = isolated ? ISOLATED_WITHDRAW_ID_MAX : POOLED_WITHDRAW_ID_MAX;
        uint8 nextId = usedId == maxId ? minId : usedId + 1;
        if (isolated) {
            state.isolatedWithdrawalCursor = nextId;
        } else {
            state.pooledWithdrawalCursor = nextId;
        }
    }

    function _isWithdrawalIdOccupied(uint64 valId, uint8 withdrawalId) internal returns (bool) {
        IsolatedValidatorState memory state = s_isolatedValidatorState[valId];
        if (state.isolatedWithdrawalPending && state.isolatedWithdrawalId == withdrawalId) {
            return true;
        }

        // Check both tracked ShMonad withdrawals and the live precompile state so isolated ids cannot reuse a
        // withdrawal slot that was already consumed by legacy pooled flows before the range split.
        for (uint256 i; i < EPOCHS_TRACKED; ++i) {
            Epoch storage validatorEpoch = s_validatorEpoch[valId][i];
            if (validatorEpoch.hasWithdrawal && validatorEpoch.withdrawalId == withdrawalId) {
                return true;
            }
        }

        return _getWithdrawalAmount(valId, withdrawalId) > 0;
    }

    function _consumeWithdrawalId(uint64 valId, bool isolated) internal returns (uint8 withdrawalId) {
        uint8 minId = isolated ? ISOLATED_WITHDRAW_ID_MIN : POOLED_WITHDRAW_ID_MIN;
        uint8 maxId = isolated ? ISOLATED_WITHDRAW_ID_MAX : POOLED_WITHDRAW_ID_MAX;
        uint8 cursor = _currentWithdrawalCursor(valId, isolated);
        uint8 candidate = cursor;
        uint256 rangeSize = uint256(maxId) - uint256(minId) + 1;

        // The first use per validator/range seeds from the first free id in that partition. After that we only
        // advance from the stored cursor and rescan if the candidate collides with a live or legacy withdrawal.
        for (uint256 i; i < rangeSize; ++i) {
            if (!_isWithdrawalIdOccupied(valId, candidate)) {
                _setNextWithdrawalCursor(valId, isolated, candidate);
                return candidate;
            }

            unchecked {
                candidate = candidate == maxId ? minId : candidate + 1;
            }
        }

        revert NoWithdrawalIdsAvailable(valId, isolated);
    }

    function _syncIsolatedPendingStake(uint64 valId, uint256 actualPendingDeposits) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        if (state.pendingStake == 0) return;

        // Native pending deposits are aggregate for the delegator and do not identify whether pending stake came from
        // pooled or isolated deposits. Attribute ambiguous native pending to isolated stake first so isolated exits
        // only use stake whose activation is forced by the aggregate pending balance.
        if (actualPendingDeposits >= state.pendingStake) return;

        uint120 activatedAmount = (uint256(state.pendingStake) - actualPendingDeposits).toUint120();
        state.pendingStake -= activatedAmount;
        state.activeStake += activatedAmount;
        _consumeIsolatedPendingStakeMetadata(valId, activatedAmount);
    }

    function _recordIsolatedPendingStake(
        uint64 valId,
        uint120 amount,
        uint64 monadEpoch,
        bool inEpochDelayPeriod
    )
        internal
    {
        if (amount == 0) return;

        uint64 activationEpoch = monadEpoch + (inEpochDelayPeriod ? 2 : 1);
        IsolatedPendingStakeState storage pendingState = s_isolatedPendingStakeState[valId];
        uint256 emptyIndex = pendingState.cohorts.length;
        s_isolatedValidatorState[valId].pendingStake += amount;

        for (uint256 i; i < pendingState.cohorts.length; ++i) {
            IsolatedPendingStakeCohort storage cohort = pendingState.cohorts[i];
            if (cohort.amount != 0 && cohort.activationEpoch == activationEpoch) {
                cohort.amount += amount;
                return;
            }
            if (cohort.amount == 0 && emptyIndex == pendingState.cohorts.length) emptyIndex = i;
        }

        // Refreshing before each isolated delegation keeps live cohorts within the native current/current+1/current+2
        // activation window, so all three slots being occupied by other epochs is an internal invariant failure.
        assert(emptyIndex != pendingState.cohorts.length);
        pendingState.cohorts[emptyIndex] =
            IsolatedPendingStakeCohort({ amount: amount, activationEpoch: activationEpoch });
    }

    function _refreshProductiveIsolatedPendingStake(uint64 valId, uint64 monadEpoch) internal {
        IsolatedPendingStakeState storage pendingState = s_isolatedPendingStakeState[valId];
        uint120 newlyProductive;

        for (uint256 i; i < pendingState.cohorts.length; ++i) {
            IsolatedPendingStakeCohort storage cohort = pendingState.cohorts[i];
            // Activation alone is not enough: the cohort enters the split only after one native reward period.
            if (cohort.amount == 0 || cohort.activationEpoch >= monadEpoch) continue;
            newlyProductive += cohort.amount;
            delete pendingState.cohorts[i];
        }

        if (newlyProductive != 0) pendingState.rewardProductiveStake += newlyProductive;

        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        state.snapshotProductiveIsolatedStake =
            (uint256(state.activeStake) + pendingState.rewardProductiveStake).toUint120();
    }

    function _activateProductiveIsolatedPendingStake(
        uint64 valId,
        uint64 monadEpoch,
        uint64 deltaEpoch,
        uint64 nextDeltaEpoch
    )
        internal
    {
        IsolatedPendingStakeState storage pendingState = s_isolatedPendingStakeState[valId];
        uint120 activatedAmount = pendingState.rewardProductiveStake;
        if (activatedAmount == 0) return;

        // Productive cohorts have activationEpoch < monadEpoch. A native pending track from an earlier epoch would
        // contradict that source-timing proof, so leave principal pending rather than making it withdrawable.
        if ((deltaEpoch != 0 && deltaEpoch < monadEpoch) || (nextDeltaEpoch != 0 && nextDeltaEpoch < monadEpoch)) {
            return;
        }

        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        pendingState.rewardProductiveStake = 0;
        state.pendingStake -= activatedAmount;
        state.activeStake += activatedAmount;
    }

    function _consumeIsolatedPendingStakeMetadata(uint64 valId, uint120 amount) internal {
        IsolatedPendingStakeState storage pendingState = s_isolatedPendingStakeState[valId];
        uint120 remaining = amount;

        // Reward-productive pending stake is necessarily the oldest isolated pending principal.
        uint120 productiveAmount = Math.min(remaining, pendingState.rewardProductiveStake).toUint120();
        pendingState.rewardProductiveStake -= productiveAmount;
        remaining -= productiveAmount;

        for (uint256 consumed; consumed < pendingState.cohorts.length && remaining != 0; ++consumed) {
            uint256 oldestIndex = pendingState.cohorts.length;
            uint64 oldestEpoch = type(uint64).max;
            for (uint256 i; i < pendingState.cohorts.length; ++i) {
                IsolatedPendingStakeCohort storage cohort = pendingState.cohorts[i];
                if (cohort.amount != 0 && cohort.activationEpoch < oldestEpoch) {
                    oldestEpoch = cohort.activationEpoch;
                    oldestIndex = i;
                }
            }
            // Supports pre-metadata test/migration state without weakening principal synchronization.
            if (oldestIndex == pendingState.cohorts.length) break;

            IsolatedPendingStakeCohort storage oldestCohort = pendingState.cohorts[oldestIndex];
            uint120 consumedAmount = Math.min(remaining, oldestCohort.amount).toUint120();
            oldestCohort.amount -= consumedAmount;
            remaining -= consumedAmount;
            if (oldestCohort.amount == 0) delete pendingState.cohorts[oldestIndex];
        }
    }

    function _setIsolatedSnapshots(uint64 valId, uint128 pooledStakeForNextEpoch) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        state.snapshotPooledStake = pooledStakeForNextEpoch.toUint120();
        // Non-staking rewards use all isolated stake. Staking yield also includes cohorts whose native activation and
        // first reward period are known complete, even if aggregate pooled pending keeps their principal ambiguous.
        state.snapshotIsolatedStake = (uint256(state.activeStake) + state.pendingStake).toUint120();
        state.snapshotProductiveIsolatedStake =
            (uint256(state.activeStake) + s_isolatedPendingStakeState[valId].rewardProductiveStake).toUint120();
        // Set readiness only after every snapshot used by reward attribution and allocation has been written.
        state.snapshotsInitialized = true;
    }

    // Turnover is tracked separately so the aggregate queue can stay backward compatible while the stake allocation
    // system decides which slice should be routed by overallocation instead of stake-proportional capacity.
    function _setCurrentTurnoverQueueForUnstake(uint120 newTurnoverQueueForUnstake, uint120 queueForUnstake) internal {
        TurnoverQueue storage turnoverQueue = turnoverQueuePtr_N(0);
        uint120 previousTurnoverQueue = turnoverQueue.queueForUnstake;
        if (newTurnoverQueueForUnstake > queueForUnstake) newTurnoverQueueForUnstake = queueForUnstake;
        turnoverQueue.queueForUnstake = newTurnoverQueueForUnstake;
        turnoverQueue.alwaysTrue = true;

        if (previousTurnoverQueue != newTurnoverQueueForUnstake) {
            emit TurnoverQueueUpdated(
                s_admin.internalEpoch, previousTurnoverQueue, newTurnoverQueueForUnstake, queueForUnstake
            );
        }
    }

    function _addTurnoverQueueToNextEpoch(uint120 turnoverQueueForUnstake) internal {
        if (turnoverQueueForUnstake == 0) return;

        TurnoverQueue storage nextTurnoverQueue = turnoverQueuePtr_N(1);
        nextTurnoverQueue.queueForUnstake += turnoverQueueForUnstake;
        nextTurnoverQueue.alwaysTrue = true;
    }

    function _requeueWithdrawalAmount(uint120 amount, uint120 turnoverAmount) internal {
        if (amount == 0) return;
        if (turnoverAmount > amount) turnoverAmount = amount;

        CashFlows storage globalCashFlows = globalCashFlowsPtr_N(0);
        uint120 updatedQueueForUnstake = (uint256(globalCashFlows.queueForUnstake) + amount).toUint120();
        // The turnover component is carried in parallel and must remain <= aggregate queue after every requeue path.
        uint120 updatedTurnoverQueue = (uint256(turnoverQueuePtr_N(0).queueForUnstake) + turnoverAmount).toUint120();

        globalCashFlows.queueForUnstake = updatedQueueForUnstake;
        _setCurrentTurnoverQueueForUnstake(updatedTurnoverQueue, updatedQueueForUnstake);
    }

    function _isAllocationRoundInProgress() internal view returns (bool) {
        return s_nextValidatorToCrank != LAST_VAL_ID;
    }

    function _assertAllocationRoundIdle() internal view override {
        require(!_isAllocationRoundInProgress(), AllocationRoundInProgress());
    }

    function _useLegacyAllocationWeightingForPendingRound() internal view returns (bool) {
        uint64 splitStartEpoch = s_stakeAllocationConfig.splitStartEpoch;
        return splitStartEpoch != 0 && s_admin.internalEpoch + 1 < splitStartEpoch;
    }

    function _useLegacyAllocationWeightingForCurrentRound() internal view returns (bool) {
        uint64 splitStartEpoch = s_stakeAllocationConfig.splitStartEpoch;
        return splitStartEpoch != 0 && s_admin.internalEpoch < splitStartEpoch;
    }

    function _allocationRevenueFromLegacyEarned(uint120 earnedRevenue)
        internal
        pure
        returns (AllocationRevenue memory revenue)
    {
        revenue.nonStakingRevenue = earnedRevenue;
        revenue.alwaysTrue = true;
    }

    function _globalAllocationRevenueWindow(
        int256 epochPointer,
        bool useLegacyWeighting
    )
        internal
        view
        returns (AllocationRevenue memory revenue)
    {
        if (useLegacyWeighting) {
            return _allocationRevenueFromLegacyEarned(globalRevenuePtr_N(epochPointer).earnedRevenue);
        }
        return globalAllocationRevenuePtr_N(epochPointer);
    }

    function _validatorAllocationRevenueWindow(
        int256 epochPointer,
        uint64 validatorId,
        bool useLegacyWeighting
    )
        internal
        view
        returns (AllocationRevenue memory revenue)
    {
        if (useLegacyWeighting) {
            return _allocationRevenueFromLegacyEarned(validatorRewardsPtr_N(epochPointer, validatorId).earnedRevenue);
        }
        return validatorAllocationRevenuePtr_N(epochPointer, validatorId);
    }

    function _pendingRoundAllocationMultiplierRay() internal view returns (uint256 multiplierRay) {
        return _useLegacyAllocationWeightingForPendingRound() ? RAY : getNonStakingRevenueMultiplierRay();
    }

    function _snapshotPendingRoundAllocationMultiplier() internal returns (uint256 multiplierRay) {
        multiplierRay = _pendingRoundAllocationMultiplierRay();
        s_allocationMultiplierSnapshots[N(0)] = multiplierRay.toUint128();
    }

    function _snapshotPendingRoundStakingYieldDeadbandBps() internal returns (uint16 deadbandBps) {
        deadbandBps = getStakingYieldDeadbandBps();
        s_stakingYieldDeadbandBpsSnapshots[N(0)] = deadbandBps;
    }

    function _allocationMultiplierSnapshotRay(int256 epochPointer) internal view returns (uint256 multiplierRay) {
        multiplierRay = s_allocationMultiplierSnapshots[N(epochPointer)];
        if (multiplierRay == 0) multiplierRay = RAY;
    }

    function _stakingYieldDeadbandSnapshotBps(int256 epochPointer) internal view returns (uint16 deadbandBps) {
        return s_stakingYieldDeadbandBpsSnapshots[N(epochPointer)];
    }

    function _allocationSignalAmount(uint256 pooledAmount, uint256 isolatedAmount) internal view returns (uint120) {
        // This toggle only changes the signal used to route pooled stake. The underlying pooled-versus-isolated
        // accounting remains split at each booking site below.
        return StakeAllocationLib.allocationSignalAmount(s_stakeAllocationConfig, pooledAmount, isolatedAmount);
    }

    function _allocationSignalStake(uint64 validatorId, Epoch memory validatorEpoch) internal view returns (uint256) {
        return StakeAllocationLib.allocationSignalStake(
            validatorEpoch.targetStakeAmount, s_isolatedValidatorState[validatorId], s_stakeAllocationConfig
        );
    }

    function _allocationScoring(
        AllocationTotals memory totals,
        uint256 validatorSignalStake,
        uint256 multiplierRay,
        uint256 deadbandBps,
        bool useAdjustedScoring
    )
        internal
        pure
        returns (StakeAllocationLib.AllocationScoring memory)
    {
        return StakeAllocationLib.buildAllocationScoring(
            totals, validatorSignalStake, multiplierRay, deadbandBps, useAdjustedScoring
        );
    }

    function _recomputeCurrentAllocationTotals() internal {
        AllocationTotals storage totals = allocationTotalsPtr_N(0);
        totals.totalPooledTargetStake = 0;
        totals.totalOverallocatedStake = 0;
        totals.totalAllocationSignalStake = 0;
        totals.totalAdjustedWeightedRevenue = 0;

        if (s_activeValidatorCount == 0) return;

        bool useLegacyWeighting = _useLegacyAllocationWeightingForPendingRound();
        bool useAdjustedScoring = !useLegacyWeighting;
        uint256 multiplierRay = _snapshotPendingRoundAllocationMultiplier();
        uint16 deadbandBps = _snapshotPendingRoundStakingYieldDeadbandBps();
        AllocationRevenue memory globalRevenueLast = _globalAllocationRevenueWindow(-1, useLegacyWeighting);
        AllocationRevenue memory globalRevenueCurrent = _globalAllocationRevenueWindow(0, useLegacyWeighting);

        uint256 totalPooledTargetStake;
        uint256 totalAllocationSignalStake;
        uint256 activeStakingYieldLast;
        uint256 activeStakingYieldCurrent;
        uint64 cursorId = s_valLinkNext[FIRST_VAL_ID];
        while (cursorId != LAST_VAL_ID) {
            if (cursorId != UNKNOWN_VAL_ID && s_validatorData[cursorId].isActive) {
                // These totals are stored in pre-advance N(0), then read by validators as post-advance N(-1).
                // Use pre-advance N(0) target stake so the cached denominator matches each validator's numerator.
                Epoch memory validatorEpochCurrent = validatorEpochPtr_N(0, cursorId);
                totalPooledTargetStake += validatorEpochCurrent.targetStakeAmount;
                totalAllocationSignalStake += _allocationSignalStake(cursorId, validatorEpochCurrent);
                if (useAdjustedScoring) {
                    activeStakingYieldLast += validatorAllocationRevenuePtr_N(-1, cursorId).stakingYield;
                    activeStakingYieldCurrent += validatorAllocationRevenuePtr_N(0, cursorId).stakingYield;
                }
            }
            cursorId = s_valLinkNext[cursorId];
        }

        totals.totalPooledTargetStake = totalPooledTargetStake.toUint128();
        totals.totalAllocationSignalStake = totalAllocationSignalStake.toUint128();

        if (useAdjustedScoring) {
            // The deadband floor divides global staking yield by active signal stake. Snapshot the same active set into
            // the global staking-yield windows that validator cranks will read after the epoch pointer advances.
            uint120 activeStakingYieldLast120 = activeStakingYieldLast.toUint120();
            uint120 activeStakingYieldCurrent120 = activeStakingYieldCurrent.toUint120();
            globalAllocationRevenuePtr_N(-1).stakingYield = activeStakingYieldLast120;
            globalAllocationRevenuePtr_N(0).stakingYield = activeStakingYieldCurrent120;
            globalRevenueLast.stakingYield = activeStakingYieldLast120;
            globalRevenueCurrent.stakingYield = activeStakingYieldCurrent120;
        }

        AllocationTotals memory scoringTotals = totals;
        uint256 totalAdjustedWeightedRevenue;
        cursorId = s_valLinkNext[FIRST_VAL_ID];
        while (cursorId != LAST_VAL_ID) {
            if (cursorId != UNKNOWN_VAL_ID && s_validatorData[cursorId].isActive) {
                Epoch memory validatorEpochCurrent = validatorEpochPtr_N(0, cursorId);
                totalAdjustedWeightedRevenue += StakeAllocationLib.getSmoothedAllocationWeightedRevenue(
                    globalRevenueLast,
                    globalRevenueCurrent,
                    _validatorAllocationRevenueWindow(-1, cursorId, useLegacyWeighting),
                    _validatorAllocationRevenueWindow(0, cursorId, useLegacyWeighting),
                    _allocationScoring(
                        scoringTotals,
                        _allocationSignalStake(cursorId, validatorEpochCurrent),
                        multiplierRay,
                        deadbandBps,
                        useAdjustedScoring
                    )
                );
            }
            cursorId = s_valLinkNext[cursorId];
        }

        totals.totalAdjustedWeightedRevenue = totalAdjustedWeightedRevenue.toUint128();
        if (totalPooledTargetStake == 0 || totalAdjustedWeightedRevenue == 0) return;

        uint256 totalOverallocatedStake;
        scoringTotals = totals;
        cursorId = s_valLinkNext[FIRST_VAL_ID];
        while (cursorId != LAST_VAL_ID) {
            if (cursorId != UNKNOWN_VAL_ID && s_validatorData[cursorId].isActive) {
                Epoch memory validatorEpochCurrent = validatorEpochPtr_N(0, cursorId);
                totalOverallocatedStake += StakeAllocationLib.calculateOverallocatedStake(
                    validatorEpochCurrent,
                    globalRevenueLast,
                    globalRevenueCurrent,
                    _validatorAllocationRevenueWindow(-1, cursorId, useLegacyWeighting),
                    _validatorAllocationRevenueWindow(0, cursorId, useLegacyWeighting),
                    _allocationScoring(
                        scoringTotals,
                        _allocationSignalStake(cursorId, validatorEpochCurrent),
                        multiplierRay,
                        deadbandBps,
                        useAdjustedScoring
                    )
                );
            }
            cursorId = s_valLinkNext[cursorId];
        }

        totals.totalOverallocatedStake = totalOverallocatedStake.toUint128();
    }

    // ================================================== //
    //                `receive()` Function                //
    // ================================================== //

    /// @notice Handles incoming ETH payments and classifies them for proper accounting
    /// @dev Processes received ETH and updates transient capital tracking for staking operations
    receive() external payable {
        (CashFlowType flowType, uint256 existingAmountIn, uint256 lastKnownBalance) = _getTransientCapital();

        // Goodwill is the null type of CashFlowType
        if (flowType == CashFlowType.Goodwill) {
            // NOTE: must clear if contract does any payments in between receives.
            if (address(this).balance >= lastKnownBalance + msg.value) {
                globalCashFlowsPtr_N(0).queueToStake += msg.value.toUint120();
            }
        } else if (
            flowType == CashFlowType.Revenue && t_cashFlowExpectedSender != address(0)
                && msg.sender != t_cashFlowExpectedSender
        ) {
            // Coinbase settlement only attributes MON from the coinbase currently being processed. Other transfers
            // can still arrive during callbacks, but they remain generic goodwill for shMON holders.
            if (address(this).balance >= lastKnownBalance + msg.value) {
                globalCashFlowsPtr_N(0).queueToStake += msg.value.toUint120();
            }
            // Preserve the expected sender for any later transfers in the same coinbase settlement.
            _setTransientCapital(flowType, existingAmountIn);
            return;
        }
        _setTransientCapital(flowType, existingAmountIn + msg.value);
    }

    /// @notice Records unpaid delegate rewards recovered from a deterministic coinbase proxy.
    /// @dev Recovery is global-only pooled yield: it should be smoothed for exits, but should not charge boost
    /// commission or alter validator-level attribution / allocation revenue.
    /// @custom:selector 0x5ae6caa8
    function donateRecoveredCoinbaseRewards(uint64 validatorId) external payable cbPooledShareRate {
        require(validatorId != 0 && validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));
        require(msg.sender == _predictCoinbaseAddress(validatorId), InvalidValidatorAddress(msg.sender));

        uint120 amount = msg.value.toUint120();
        globalRevenuePtr_N(0).earnedRevenue += amount;
        globalCashFlowsPtr_N(0).queueToStake += amount;
    }

    // t_cashFlowClassifier pack layout (uint256):
    // [255..128] lastKnownBalance
    // [127..8]   existingAmountIn (uint120)
    // [7..0]     flowType (CashFlowType as uint8)
    /// @notice Retrieves current transient capital state for cash flow classification
    /// @return flowType The type of cash flow currently being processed
    /// @return existingAmountIn The amount already processed in the current flow
    /// @return lastKnownBalance The last recorded contract balance
    function _getTransientCapital()
        internal
        view
        returns (CashFlowType flowType, uint256 existingAmountIn, uint256 lastKnownBalance)
    {
        uint256 _checkValue = t_cashFlowClassifier;
        flowType = CashFlowType(uint8(_checkValue));
        existingAmountIn = (_checkValue >> 8) & UINT120_MASK;
        lastKnownBalance = _checkValue >> 128;
    }

    /// @notice Updates transient capital state with new flow type and amount
    /// @dev Does not modify t_cashFlowExpectedSender; settlement entry/exit sets and clears it explicitly.
    /// @param flowType The type of cash flow being processed
    /// @param existingAmount The amount to set for the current flow
    function _setTransientCapital(CashFlowType flowType, uint256 existingAmount) internal {
        require(existingAmount <= type(uint120).max, WillOverflowOnBitshift());
        uint256 _setValue = (address(this).balance << 128) | existingAmount << 8 | uint256(uint8(flowType));
        t_cashFlowClassifier = _setValue;
    }

    function _setTransientCapital(CashFlowType flowType, uint256 existingAmount, address expectedSender) internal {
        t_cashFlowExpectedSender = expectedSender;
        _setTransientCapital(flowType, existingAmount);
    }

    /// @notice Clears transient capital state and resets cash flow classification
    /// @dev This also deletes the last known balance - watch out!
    function _clearTransientCapital() internal {
        t_cashFlowClassifier = 0;
        t_cashFlowExpectedSender = address(0);
    }

    // ================================================== //
    //                 Crank Entry Point                  //
    // ================================================== //

    /// @notice Single public entrypoint to advance global + per-validator state.
    /// @dev Permissionless and resumable. Global accounting executes only when epoch readiness checks pass; until a
    /// pending global roll is processed, ERC4626 exit quotes may still treat the current revenue bucket as fresh.
    /// `nonReentrant` blocks coinbase/commission callbacks from reentering while rewards and balances are being
    /// settled.
    /// @return complete True if all cranking operations completed successfully
    /// @custom:selector 0x9c16a9e8
    function crank() public notWhenFrozen nonReentrant returns (bool complete) {
        complete = _crankGlobal();
        if (!complete) {
            complete = _crankValidators();
            // Completing a pending validator pass can expose a Monad epoch that arrived while the cursor was pending.
            // Keep the public completion signal aligned with the documented keeper loop: false means another crank is
            // due.
            if (complete && _isGlobalCrankAvailable()) complete = false;
        }
    }

    /// @notice Processes validator state updates for all validators
    /// @dev Iterates through validators and updates their state within gas limits
    /// @return allValidatorsCranked True if all validators were processed successfully
    function _crankValidators() internal returns (bool allValidatorsCranked) {
        // If upgrading from a version without s_globalPendingLast and s_globalCapitalLast, seed the
        // snapshot once so validators in the current round read a consistent cached view instead of
        // live-mutating pending values.
        if (!s_globalPendingLast.alwaysTrue) {
            StakingEscrow memory _pending = s_globalPending;
            _pending.alwaysTrue = true;
            s_globalPendingLast = _pending;
            WorkingCapital memory _globalCapital = s_globalCapital;
            s_globalCapitalLast = _globalCapital;
            s_isolatedTotalAssetsLast = s_isolatedTotalAssets;
            s_isolatedLiquidAssetsLast = s_isolatedLiquidAssets;
        }

        uint64 _nextValidatorToCrank = s_nextValidatorToCrank;

        // NOTE: VALIDATOR_CRANK_LIMIT is a conservative gas floor for one validator crank plus cursor persistence.
        // Keep it configuration-driven so gas snapshots can tighten the value without changing loop semantics.
        while (gasleft() > VALIDATOR_CRANK_LIMIT) {
            if (_nextValidatorToCrank == LAST_VAL_ID) break;
            t_validatorActiveSetCheckValId = 0;
            _crankValidator(_nextValidatorToCrank);
            t_validatorActiveSetCheckValId = 0;
            if (globalEpochPtr_N(0).frozen) break;
            _nextValidatorToCrank = s_valLinkNext[_nextValidatorToCrank];
        }

        s_nextValidatorToCrank = _nextValidatorToCrank;
        return _nextValidatorToCrank == LAST_VAL_ID;
    }

    // ================================================== //
    //        Core Crank Functions & Accounting           //
    // ================================================== //

    /// @notice Advances global epoch state and updates global accounting in one pass.
    /// @dev Steps (ordering matters):
    ///  1) Prime next epoch storage (carry flags, compute target stake)
    ///  2) Apply goodwill, offset uncovered liabilities using deposits, and reconcile atomic pool accounting
    ///  3) Carry over atomic-unstake into the global unstake queue
    ///  4) Cache allocation totals for the validator round
    ///  5) Net excess queue capacity, roll unassignable stake, and clamp queues to capacity
    ///  6) Roll aggregate non-turnover unstake dust forward before validator allocation snapshots it
    ///  7) Update revenue smoother, snapshot current state, bump internal epoch, and reset validator cursor
    /// Returns false early if monad epoch did not advance or validators are still pending from prior round.
    /// @return complete True if global crank completed (epoch advanced and validators ready to crank)
    function _crankGlobal() internal returns (bool complete) {
        (uint64 _monadEpoch, bool _inEpochDelayPeriod) = _getEpochInfo();

        // All validators must have finished cranking in the previous round
        if (s_nextValidatorToCrank != LAST_VAL_ID) return false;

        // During Monad's boundary delay window, barrier-adjusted staking timing can point at the next raw epoch.
        // Wait until the raw epoch is stable so the global marker remains proof that this epoch's roll executed.
        if (_inEpochDelayPeriod) return true;

        // This marker is advanced only by successful global rolls. Validator cranks must not stamp it, because this
        // guard treats the marker as proof that global accounting has already run for the live Monad epoch.
        if (globalEpochPtr_N(0).epoch >= _monadEpoch) return true;

        // Load the just-ended epoch's data into memory to help with rolling the epoch forwards
        Epoch memory _epochThatJustEnded = globalEpochPtr_N(0);

        _primeNextGlobalEpoch(_epochThatJustEnded);

        // Prepare the upcoming epoch's data by zeroing out any previous values and setting any carryovers.
        // NOTE: We clear N(+2) instead of N(+1) because _advanceEpochPointersAndResetValidatorCursor bumps
        // s_admin.internalEpoch later in this function; the cleared slot becomes N(+1) for the next crank cycle,
        // ensuring the circular buffer slot is clean one epoch ahead without changing behavior.
        globalRevenuePtr_N(2).clear();
        globalCashFlowsPtr_N(2).clear();
        globalAllocationRevenuePtr_N(2).clear();
        turnoverQueuePtr_N(2).clear();
        delete s_allocationTotals[N(2)];
        s_allocationMultiplierSnapshots[N(2)] = 0;
        s_stakingYieldDeadbandBpsSnapshots[N(2)] = DEFAULT_STAKING_YIELD_DEADBAND_BPS;

        // Adjust for any goodwill (unexpected donations) by adding them to the staking queue prior to netting
        // against any outstanding liabilities
        _applyGoodwillToStakeQueue();

        // Handle any net staking allocations to the reserved MON amount
        _offsetLiabilitiesWithDeposits();

        // Update (if applicable) and adjust the global net cash flow (MON) for flows to the atomic unstaking pool,
        // while being sure to keep the utilization rate unchanged.
        _settleGlobalNetMONAgainstAtomicUnstaking();

        // Calculate and carry forward the unstaking amount from the atomic unstaking pool
        _carryOverAtomicUnstakeIntoQueue();

        // Cache the exact active-set totals for the upcoming validator crank using the existing historical allocation
        // windows. This is read-only over the active validator set.
        _recomputeCurrentAllocationTotals();

        // Net excess queue capacity, roll unassignable stake/capacity, then carry aggregate non-turnover
        // dust forward before validators read the just-ended queue as their allocation snapshot.
        _offsetExcessQueueCapacityWithNet();
        _rollUnassignableStakingQueue();
        _clampQueuesToCapacityOrRoll();
        _rollDustNonTurnoverUnstakeQueue();

        _updateRevenueSmootherAfterEpochChange();

        // Update s_globalPendingLast and s_globalCapitalLast with the current values from storage
        s_globalPendingLast = s_globalPending;
        s_globalCapitalLast = s_globalCapital;
        s_isolatedTotalAssetsLast = s_isolatedTotalAssets;
        s_isolatedLiquidAssetsLast = s_isolatedLiquidAssets;

        _advanceEpochPointersAndResetValidatorCursor();

        return false;
    }

    /// @notice Offsets uncovered liabilities using available deposits and current assets.
    /// @dev Increases reservedAmount and reduces both `queueToStake` and `queueForUnstake` by the settled amount.
    /// Caps by: uncovered liabilities, `queueForUnstake`, `queueToStake`, and current assets.
    function _offsetLiabilitiesWithDeposits() internal {
        uint256 _queueToStake = globalCashFlowsPtr_N(0).queueToStake;
        uint256 _queueForUnstake = globalCashFlowsPtr_N(0).queueForUnstake;
        uint256 _turnoverQueueForUnstake = turnoverQueuePtr_N(0).queueForUnstake;

        // Check for any outstanding liabilities
        uint256 _currentLiabilities = s_globalLiabilities.currentLiabilities();
        uint256 _reserves = s_globalCapital.reservedAmount;

        // This occurs during the global crank, so use current s_globalPending
        uint256 _pendingUnstaking = s_globalPending.pendingUnstaking;

        if (_currentLiabilities > _reserves + _pendingUnstaking) {
            // Start with the max value of the uncovered liabilities
            uint256 _liabilitiesToSettleWithDeposits = _currentLiabilities - _reserves - _pendingUnstaking;

            // Do not settle more than is currently requested to queue for unstaking
            if (_liabilitiesToSettleWithDeposits > _queueForUnstake) {
                _liabilitiesToSettleWithDeposits = _queueForUnstake;
            }

            // Do not use more than is currently queued for staking in the settlement process
            if (_liabilitiesToSettleWithDeposits > _queueToStake) {
                _liabilitiesToSettleWithDeposits = _queueToStake;
            }

            // We can only settle with MON (currentAssets) that hasn't been allocated for another purpose
            uint256 _currentAssets = _pooledCurrentAssets(address(this).balance);
            if (_liabilitiesToSettleWithDeposits > _currentAssets) {
                _liabilitiesToSettleWithDeposits = _currentAssets;
            }

            // If we have enough funds to offset, perform the offset
            if (_liabilitiesToSettleWithDeposits > 0) {
                // queueToStake is not source-tagged, so conservatively earmark available current-epoch revenue first.
                // This prevents the later atomic carryover step from reusing MON already routed into reserves.
                _allocateCurrentEpochRevenue(_liabilitiesToSettleWithDeposits);

                // Increase the reserved amount
                s_globalCapital.reservedAmount += _liabilitiesToSettleWithDeposits.toUint128();
                // Implied: currentAssets -= _liabilitiesToSettleWithDeposits

                emit ReservesIncreasedBySurplusDeposits(_liabilitiesToSettleWithDeposits);

                // Remove the funds from both the queueToStake and the queueForUnstake - the deposit offsets the
                // withdrawal.
                globalCashFlowsPtr_N(0).queueToStake = (_queueToStake - _liabilitiesToSettleWithDeposits).toUint120();
                (uint120 _reducedQueueForUnstake, uint120 _reducedTurnoverQueueForUnstake,) = QueueLib.reducePreferNonTurnover(
                    _queueForUnstake, _turnoverQueueForUnstake, _liabilitiesToSettleWithDeposits
                );
                globalCashFlowsPtr_N(0).queueForUnstake = _reducedQueueForUnstake;
                _setCurrentTurnoverQueueForUnstake(_reducedTurnoverQueueForUnstake, _reducedQueueForUnstake);
            }
        }
    }

    /// @notice Marks current-epoch revenue as consumed by another accounting sink.
    /// @dev Cash-flow queues are not source-tagged, so callers conservatively allocate available revenue first. This
    /// keeps later carryover and view math from spending the same native MON a second time.
    function _allocateCurrentEpochRevenue(uint256 amount) internal returns (uint120 allocatedAmount) {
        if (amount == 0) return 0;

        Revenue storage _globalRevenue = globalRevenuePtr_N(0);
        uint256 _availableRevenue = uint256(_globalRevenue.earnedRevenue - _globalRevenue.allocatedRevenue);
        allocatedAmount = Math.min(amount, _availableRevenue).toUint120();
        if (allocatedAmount > 0) _globalRevenue.allocatedRevenue += allocatedAmount;
    }

    /// @notice Carries over atomic pool unstake amount into the global unstake queue for the current epoch.
    /// @dev Settles distributedAmount against only the "available" portion of earnedRevenue. Revenue tracked in
    /// allocatedRevenue has already been consumed or reserved by atomic withdrawal shortfalls, reserve fills, or
    /// target settlement, and must not be reused here. Reuse would double-count that revenue, reduce
    /// distributedAmount, and overstate atomic liquidity as (allocatedAmount - distributedAmount).
    function _carryOverAtomicUnstakeIntoQueue() internal {
        Revenue memory _globalRevenue = globalRevenuePtr_N(0);

        // Only settle against revenue that has not already been earmarked. Atomic shortfalls, reserve fills, and
        // target-settlement queue consumption all mark revenue unavailable before this carryover step runs.
        uint256 _availableRevenue = uint256(_globalRevenue.earnedRevenue - _globalRevenue.allocatedRevenue);

        // Settle the minimum of available revenue and what's been distributed (utilized).
        // This ensures no "jump" in fee cost at crank time, matching the view function behavior.
        uint120 _amountToSettle = Math.min(_availableRevenue, s_atomicAssets.distributedAmount).toUint120();

        s_atomicAssets.distributedAmount -= _amountToSettle; // -Contra_Asset Dr _amountToSettle
        // Implied: currentAssets -= _amountToSettle; // -Asset Cr _amountToSettle

        globalCashFlowsPtr_N(0).queueForUnstake += _amountToSettle;
    }

    /// @notice Applies any goodwill (unexpected donations) to the queueToStake and emits tracking event.
    function _applyGoodwillToStakeQueue() internal {
        uint256 _goodwill = _pooledGoodwill(address(this).balance);
        if (_goodwill > 0) {
            globalCashFlowsPtr_N(0).queueToStake += _goodwill.toUint120();
            emit UnexpectedGoodwill(s_admin.internalEpoch, _goodwill);
        }
    }

    /// @notice Updates the single smoother using the larger hidden cohort's release schedule.
    function _updateRevenueSmootherAfterEpochChange() internal {
        uint256 _currentRevenue = globalRevenuePtr_N(0).earnedRevenue;
        if (_currentRevenue == 0) return;

        RevenueSmoother memory _smoother = s_revenueSmoother;
        uint256 _unvestedRevenue = _unvestedSmootherRevenue(_smoother);
        uint256 _combinedRevenue = _currentRevenue + _unvestedRevenue;

        // Let the larger cohort control the one available schedule. This prevents dust revenue from extending a
        // large prior cohort and bounds timing distortion at each overlap to the smaller hidden amount.
        if (_currentRevenue >= _unvestedRevenue) {
            s_revenueSmoother = RevenueSmoother({
                earnedRevenueLast: _combinedRevenue.toUint120(), epochChangeBlockNumber: uint64(block.number)
            });
            return;
        }

        uint256 _blocksSinceLastUpdate = block.number - uint256(_smoother.epochChangeBlockNumber);
        // Positive unvested revenue means the schedule has not expired, so this subtraction cannot produce zero.
        uint256 _blocksRemaining = MONAD_EPOCH_LENGTH - _blocksSinceLastUpdate;

        // Preserve the prior expiry and rebase its starting balance so the hidden offset is continuous at this block.
        s_revenueSmoother.earnedRevenueLast = _combinedRevenue.mulDiv(MONAD_EPOCH_LENGTH, _blocksRemaining).toUint120();
    }

    /// @notice Advances internal epoch pointer and resets validator crank cursor to the start of the list.
    function _advanceEpochPointersAndResetValidatorCursor() internal {
        // Increase the global internal epoch.
        // NOTE: After incrementing the internal epoch:
        //      epoch_N(-1) is now epoch_N(-2)
        //      epoch_N(0) is now epoch_N(-1)
        //      epoch_N(1) is now epoch_N(0)
        // ETC...
        ++s_admin.internalEpoch;

        // Set the next validator to crank - always start off with the FIRST_VAL_ID sentinel
        s_nextValidatorToCrank = FIRST_VAL_ID;
    }

    /// @notice Primes the next global epoch storage entry with carried flags and new target.
    function _primeNextGlobalEpoch(Epoch memory epochThatJustEnded) internal {
        // Prepare the upcoming epoch's storage slot
        _setEpochStorage(
            globalEpochPtr_N(1),
            Epoch({
                epoch: _getEpochBarrierAdj(), // Use the potentially higher epoch check here to make sure at least one
                // full epoch passes
                withdrawalId: 0, // unused
                hasWithdrawal: false, // unused
                hasDeposit: false, // unused
                crankedInBoundaryPeriod: _inEpochDelayPeriod(), // can probably use later on
                wasCranked: false, // bool indicating if the placeholder validator was cranked
                frozen: epochThatJustEnded.frozen,
                closed: epochThatJustEnded.closed,
                targetStakeAmount: 0 // unused at the Global Epoch level, only used at Validator Epoch level
            })
        );
    }

    /// @notice Records one phase-appropriate native active-set observation per validator and Monad epoch.
    /// @dev The persistent epoch guard keeps a retryable crank from consuming both inactive observations in one epoch.
    /// A zero marker denotes legacy flags with no native-epoch provenance, so their first observation is rebaselined.
    function _advanceActiveSetFlags(uint64 validatorId, uint64 monadEpoch, bool inEpochDelayPeriod) internal {
        ValidatorDataStorage storage validator = s_validatorData[validatorId];
        if (!validator.isActive || validator.activeSetObservationEpoch == monadEpoch) {
            return;
        }

        validator.inActiveSet_Last = validator.activeSetObservationEpoch == 0 ? true : validator.inActiveSet_Current;
        validator.inActiveSet_Current = _isValidatorInActiveSetTransient(validatorId, inEpochDelayPeriod);
        validator.activeSetObservationEpoch = monadEpoch;
    }

    /// @notice Returns whether both cached native-membership observations are inactive.
    function _hasConfirmedNativeInactivity(uint64 validatorId) internal view returns (bool) {
        ValidatorDataStorage storage validator = s_validatorData[validatorId];
        return !validator.inActiveSet_Last && !validator.inActiveSet_Current;
    }

    function _requiresForcedExit(uint64 validatorId, uint128 nextTargetStakeAmount) internal view returns (bool) {
        return !s_validatorData[validatorId].isActive || _hasConfirmedNativeInactivity(validatorId)
            || nextTargetStakeAmount < MIN_VALIDATOR_DEPOSIT;
    }

    /// @notice Returns native epoch progress beyond the Monad epoch captured by the previous global snapshot.
    function _getMonadEpochDistance(uint64 _monadEpoch) internal view returns (uint64 distance) {
        uint64 _lastGlobalMonadEpoch = globalEpochPtr_N(-1).epoch;
        if (_monadEpoch > _lastGlobalMonadEpoch) distance = _monadEpoch - _lastGlobalMonadEpoch;
    }

    /// @notice Clears deposit edges that have completed a productive native reward period.
    /// @dev A skipped-epoch claim can aggregate rewards earned both before and after activation. ShMonad does not
    /// reconstruct ownership for every missed native epoch; once the deposit has completed a productive period, the
    /// aggregate claim uses the refreshed endpoint snapshot. Deposits merely activating remain pending on timely and
    /// boundary-period cranks.
    function _settleRewardProductiveDepositEdges(uint64 valId, uint64 monadEpochDistance, uint64 monadEpoch) internal {
        // Preserve settlement of pre-upgrade edges that have no per-validator activation metadata.
        if (monadEpochDistance > 1) {
            Epoch storage _validatorEpochPtr = validatorEpochPtr_N(-2, valId);
            if (
                _validatorEpochPtr.hasDeposit && _validatorEpochPtr.crankedInBoundaryPeriod
                    && s_pooledDepositActivationEpochs[valId][N(-2)] == 0
            ) {
                _settlePooledDepositEdge(valId, -2);
            }

            _validatorEpochPtr = validatorEpochPtr_N(-1, valId);
            if (
                _validatorEpochPtr.hasDeposit && (!_validatorEpochPtr.crankedInBoundaryPeriod || monadEpochDistance > 2)
                    && s_pooledDepositActivationEpochs[valId][N(-1)] == 0
            ) {
                _settlePooledDepositEdge(valId, -1);
            }
        }

        // An activated deposit must complete one reward period before it belongs in a productive snapshot.
        // Scan the live ring because a gas-bounded round can leave deposits on different native timelines.
        for (int256 epochPointer = -3; epochPointer < 0; ++epochPointer) {
            Epoch storage epoch = validatorEpochPtr_N(epochPointer, valId);
            uint64 activationEpoch = s_pooledDepositActivationEpochs[valId][N(epochPointer)];
            if (epoch.hasDeposit && activationEpoch != 0 && activationEpoch < monadEpoch) {
                _settlePooledDepositEdge(valId, epochPointer);
            }
        }
    }

    /// @notice Settles ready staking/unstaking edges across the last three epochs for a validator.
    function _settlePastEpochEdges(uint64 valId, uint64 monadEpochDistance, uint64 monadEpoch) internal {
        // Check the last three epochs for completion of staking and unstaking actions
        Epoch storage _validatorEpochPtr = validatorEpochPtr_N(-3, valId);
        if (_validatorEpochPtr.crankedInBoundaryPeriod) {
            // The "three-epochs-ago" slot should have a withdrawal if it was initiated late during the boundary period.
            if (_validatorEpochPtr.hasWithdrawal) {
                _settleCompletedStakeAllocationDecrease(valId, _validatorEpochPtr, validatorPendingPtr_N(-3, valId));
                if (globalEpochPtr_N(0).frozen) return;
            }
        }

        _validatorEpochPtr = validatorEpochPtr_N(-2, valId);
        if (!_validatorEpochPtr.crankedInBoundaryPeriod) {
            // The unstaking initiated in epoch n-2 should be ready as long as it didn't start in a boundary period
            if (_validatorEpochPtr.hasWithdrawal) {
                _settleCompletedStakeAllocationDecrease(valId, _validatorEpochPtr, validatorPendingPtr_N(-2, valId));
                if (globalEpochPtr_N(0).frozen) return;
            }
        } else {
            // The staking initiated in epoch n-2 that was delayed by the boundary period should now be ready
            if (_validatorEpochPtr.hasDeposit && s_pooledDepositActivationEpochs[valId][N(-2)] == 0) {
                _settlePooledDepositEdge(valId, -2);
            }
        }

        // Metadata-free upgrade edges retain their original global-distance settlement rules. New deposits use their
        // validator-local activation epoch in the scan below instead of inferring maturity from this round marker.
        bool _hasJumpedMonadEpochs = monadEpochDistance > 1;

        _validatorEpochPtr = validatorEpochPtr_N(-1, valId);
        if (!_validatorEpochPtr.crankedInBoundaryPeriod || _hasJumpedMonadEpochs) {
            // The staking initiated in epoch n-1 should be ready now if an epoch was skipped OR if it wasn't cranked in
            // a boundary period
            if (_validatorEpochPtr.hasDeposit && s_pooledDepositActivationEpochs[valId][N(-1)] == 0) {
                _settlePooledDepositEdge(valId, -1);
            }
        }

        if (!_validatorEpochPtr.crankedInBoundaryPeriod && _hasJumpedMonadEpochs) {
            // The unstaking initiated in epoch n-1 should be ready if it didn't start in a boundary period AND if an
            // epoch was skipped
            if (_validatorEpochPtr.hasWithdrawal) {
                _settleCompletedStakeAllocationDecrease(valId, _validatorEpochPtr, validatorPendingPtr_N(-1, valId));
                if (globalEpochPtr_N(0).frozen) return;
            }
        }

        // After the preceding reward claim, principal can join the next productive snapshot once its activation epoch
        // arrives. The epoch delay period is at the end of the current epoch, so equal-epoch stake is already active.
        for (int256 epochPointer = -3; epochPointer < 0; ++epochPointer) {
            Epoch storage epoch = validatorEpochPtr_N(epochPointer, valId);
            uint64 activationEpoch = s_pooledDepositActivationEpochs[valId][N(epochPointer)];
            if (epoch.hasDeposit && activationEpoch != 0 && activationEpoch <= monadEpoch) {
                _settlePooledDepositEdge(valId, epochPointer);
            }
        }
    }

    function _settlePooledDepositEdge(uint64 valId, int256 epochPointer) internal {
        _handleCompleteIncreasedAllocation(
            validatorEpochPtr_N(epochPointer, valId), validatorPendingPtr_N(epochPointer, valId)
        );
        delete s_pooledDepositActivationEpochs[valId][N(epochPointer)];
    }

    /// @notice Computes per-validator stake delta using last windows and availability snapshots.
    function _computeStakeDelta(
        uint64 validatorId,
        uint256 validatorUnstakableAmount
    )
        internal
        view
        returns (
            uint128 nextTarget,
            uint128 netAmount,
            bool isWithdrawal,
            uint256 stakeAllocationIncrease,
            uint256 stakeAllocationDecrease,
            uint256 turnoverAllocationDecrease
        )
    {
        Epoch memory _validatorEpochLast = validatorEpochPtr_N(-1, validatorId);
        bool useLegacyWeighting = _useLegacyAllocationWeightingForCurrentRound();

        require(
            validatorUnstakableAmount <= uint256(_validatorEpochLast.targetStakeAmount),
            ValidatorAvailableExceedsTargetStake(validatorUnstakableAmount, _validatorEpochLast.targetStakeAmount)
        );

        // This occurs during the validator crank, so use s_globalPendingLast and s_globalCapitalLast
        uint256 _globalUnstakableAmount =
            StakeAllocationLib.getGlobalAmountAvailableToUnstake(s_globalCapitalLast, s_globalPendingLast);
        uint256 _isolatedIlliquidAmount = s_isolatedTotalAssetsLast > s_isolatedLiquidAssetsLast
            ? s_isolatedTotalAssetsLast - s_isolatedLiquidAssetsLast
            : 0;
        _globalUnstakableAmount =
            _globalUnstakableAmount > _isolatedIlliquidAmount ? _globalUnstakableAmount - _isolatedIlliquidAmount : 0;

        // Global has already been cranked into the "last" snapshot seen by validators. The active-set totals were
        // cached during that global step, so every validator reads the same denominator even as current-epoch validator
        // storage starts changing throughout this loop.
        AllocationTotals memory allocationTotals = allocationTotalsPtr_N(-1);
        uint256 multiplierRay = _allocationMultiplierSnapshotRay(-1);
        uint16 deadbandBps = _stakingYieldDeadbandSnapshotBps(-1);
        uint256 validatorSignalStake = _allocationSignalStake(validatorId, _validatorEpochLast);
        CashFlows memory globalCashFlowsLast = globalCashFlowsPtr_N(-1);
        uint120 turnoverQueueForUnstakeLast = turnoverQueuePtr_N(-1).queueForUnstake;

        if (!s_validatorData[validatorId].isActive) {
            // Inactive validators are excluded from the allocation denominator. They may still carry their share of
            // pool-wide withdrawal demand so a failed forced exit can restore it, but must not receive stake or
            // turnover allocations that the active set already partitions.
            globalCashFlowsLast.queueToStake = 0;
            globalCashFlowsLast.queueForUnstake = globalCashFlowsLast.queueForUnstake > turnoverQueueForUnstakeLast
                ? globalCashFlowsLast.queueForUnstake - turnoverQueueForUnstakeLast
                : 0;
            turnoverQueueForUnstakeLast = 0;
        }

        (
            nextTarget,
            netAmount,
            isWithdrawal,
            stakeAllocationIncrease,
            stakeAllocationDecrease,
            turnoverAllocationDecrease
        ) =
            StakeAllocationLib.calculateValidatorEpochStakeDelta(
                globalCashFlowsLast,
                turnoverQueueForUnstakeLast,
                _globalAllocationRevenueWindow(-2, useLegacyWeighting),
                _globalAllocationRevenueWindow(-1, useLegacyWeighting),
                _validatorAllocationRevenueWindow(-2, validatorId, useLegacyWeighting),
                _validatorAllocationRevenueWindow(-1, validatorId, useLegacyWeighting),
                _validatorEpochLast,
                validatorUnstakableAmount,
                _globalUnstakableAmount,
                _allocationScoring(
                    allocationTotals, validatorSignalStake, multiplierRay, deadbandBps, !useLegacyWeighting
                )
            );
    }

    /// @notice Applies the computed stake delta via skip/decrease/increase helpers and returns updated values.
    function _applyStakeDelta(
        uint64 valId,
        uint256 validatorUnstakableAmount,
        uint128 nextTarget,
        uint128 netAmount,
        bool isWithdrawal,
        uint256 turnoverAllocationDecrease,
        bool requeueFailedWithdrawal
    )
        internal
        returns (uint128 nextTargetOut, uint128 netAmountOut)
    {
        nextTargetOut = nextTarget;
        netAmountOut = netAmount;

        if (isWithdrawal && uint256(netAmountOut) > validatorUnstakableAmount) {
            uint256 requestedWithdrawal = netAmountOut;
            uint256 requestedTurnover = Math.min(turnoverAllocationDecrease, requestedWithdrawal);
            uint256 unavailableWithdrawal = requestedWithdrawal - validatorUnstakableAmount;
            uint120 unavailableTurnover = QueueLib.getTurnoverAmountToRequeue(
                requestedWithdrawal, requestedTurnover, validatorUnstakableAmount
            );

            // Targets include pending stake, but native undelegation can only consume active pooled stake. Keep the
            // unavailable tail in the target and queue so it can be retried after that stake becomes active.
            nextTargetOut += unavailableWithdrawal.toUint128();
            netAmountOut = validatorUnstakableAmount.toUint128();
            turnoverAllocationDecrease = requestedTurnover - unavailableTurnover;
            if (requeueFailedWithdrawal) {
                // Forced exits reconcile their original global action in the caller; ordinary decreases do it here.
                _requeueWithdrawalAmount(unavailableWithdrawal.toUint120(), unavailableTurnover);
            }
        }

        if (netAmountOut < DUST_THRESHOLD) {
            // CASE: Amount is too small to warrant staking or unstaking
            (nextTargetOut, netAmountOut) = _initiateStakeAllocationSkip(
                valId,
                nextTargetOut,
                netAmountOut.toUint120(),
                isWithdrawal,
                uint120(Math.min(turnoverAllocationDecrease, netAmountOut)),
                requeueFailedWithdrawal
            );
        } else if (isWithdrawal) {
            // CASE: Decrease allocation to validator
            (nextTargetOut, netAmountOut) = _initiateStakeAllocationDecrease(
                valId,
                validatorUnstakableAmount,
                nextTargetOut,
                netAmountOut,
                Math.min(turnoverAllocationDecrease, netAmountOut),
                requeueFailedWithdrawal
            );
        } else {
            // CASE: Increase allocation to validator
            (nextTargetOut, netAmountOut) = _initiateStakeAllocationIncrease(valId, nextTargetOut, netAmountOut);
        }
    }

    /// @notice Restores the queue instructions replaced by a forced validator-local withdrawal.
    function _reconcileForcedExitQueues(
        uint256 forcedPooledWithdrawal,
        uint256 stakeAllocationIncrease,
        uint256 stakeAllocationDecrease,
        uint256 turnoverAllocationDecrease
    )
        internal
    {
        if (stakeAllocationIncrease != 0) {
            globalCashFlowsPtr_N(0).queueToStake += stakeAllocationIncrease.toUint120();
        }

        // The post-apply amount is zero on failure / dust skip and excludes isolated dust swept by the native call.
        uint256 fulfilledWithdrawal = Math.min(forcedPooledWithdrawal, stakeAllocationDecrease);
        uint120 withdrawalToRequeue = (stakeAllocationDecrease - fulfilledWithdrawal).toUint120();
        uint120 turnoverToRequeue = QueueLib.getTurnoverAmountToRequeue(
            stakeAllocationDecrease, turnoverAllocationDecrease, fulfilledWithdrawal
        );
        _requeueWithdrawalAmount(withdrawalToRequeue, turnoverToRequeue);
    }

    /// @dev Returns liquid stake-queue MON removed by capacity netting but not routed to reserves.
    function _capacityNettedStakeQueueCarryForward(
        uint256 queuedToStakeAmount,
        uint256 reducedQueueToStake,
        uint256 reserveIncrease,
        uint256 globalStakableAmount
    )
        private
        pure
        returns (uint256 carryForward)
    {
        uint256 stakeQueueReduction = queuedToStakeAmount - reducedQueueToStake;

        // Reserve-backed reduction already has an accounting destination.
        uint256 reserveBackedReduction = Math.min(stakeQueueReduction, reserveIncrease);
        uint256 reductionWithoutDestination = stakeQueueReduction - reserveBackedReduction;
        if (reductionWithoutDestination == 0) return 0;

        uint256 stakableAfterReserve = globalStakableAmount - reserveIncrease;

        // Carry only liquid MON that is no longer represented by the reduced current stake queue.
        uint256 stillQueuedLiquid = Math.min(stakableAfterReserve, reducedQueueToStake);
        uint256 liquidWithoutCurrentQueue = stakableAfterReserve - stillQueuedLiquid;

        carryForward = Math.min(reductionWithoutDestination, liquidWithoutCurrentQueue);
    }

    /// @notice Net any excess stake/unstake queue capacity against each other
    function _offsetExcessQueueCapacityWithNet() internal {
        // Perform this prior to clamping and rolling queue capacity but after adjusting queues
        // for the atomic unstaking pool deltas.

        // Get the available amounts and their respective queues
        // This occurs during the global crank, so use current s_globalPending
        uint256 _globalUnstakableAmount =
            StakeAllocationLib.getGlobalAmountAvailableToUnstake(s_globalCapital, s_globalPending);
        uint256 _isolatedIlliquidAmount =
            s_isolatedTotalAssets > s_isolatedLiquidAssets ? s_isolatedTotalAssets - s_isolatedLiquidAssets : 0;
        _globalUnstakableAmount =
            _globalUnstakableAmount > _isolatedIlliquidAmount ? _globalUnstakableAmount - _isolatedIlliquidAmount : 0;
        uint256 _queuedForUnstakeAmount = globalCashFlowsPtr_N(0).queueForUnstake;
        uint256 _turnoverQueueForUnstake = turnoverQueuePtr_N(0).queueForUnstake;

        uint256 _globalStakableAmount = _pooledCurrentAssets(address(this).balance);
        uint256 _queuedToStakeAmount = globalCashFlowsPtr_N(0).queueToStake;

        // Get the amount that needs to be reserved
        CurrentLiabilities memory _globalLiabilities = s_globalLiabilities;
        uint256 _targetReservedAmount = _globalLiabilities.currentLiabilities();
        uint256 _currentReservedAmount = s_globalCapital.reservedAmount;

        QueueLib.ExcessQueueOffsetPlan memory _queuePlan = QueueLib.planExcessQueueOffset(
            _queuedForUnstakeAmount,
            _turnoverQueueForUnstake,
            _globalUnstakableAmount,
            _queuedToStakeAmount,
            _globalStakableAmount,
            _targetReservedAmount,
            _currentReservedAmount,
            s_globalPending.pendingUnstaking,
            _globalLiabilities.rewardsPayable,
            _globalLiabilities.redemptionsPayable
        );

        if (_queuePlan.reserveIncrease != 0) {
            emit ReservesIncreasedByExcessQueueCapacity(_queuePlan.reserveIncrease);

            // Increase the reserved amount
            s_globalCapital.reservedAmount += _queuePlan.reserveIncrease; // +Asset Dr reserveIncrease
            // Implied: currentAssets -= reserveIncrease // -Asset Cr reserveIncrease
        }

        emit QueuesOffsetViaNet(
            _queuePlan.targetOffsetAmount,
            _globalUnstakableAmount,
            _queuedForUnstakeAmount,
            _globalStakableAmount,
            _queuedToStakeAmount
        );

        uint256 _stakeQueueCarryForward = _capacityNettedStakeQueueCarryForward({
            queuedToStakeAmount: _queuedToStakeAmount,
            reducedQueueToStake: _queuePlan.reducedQueueToStake,
            reserveIncrease: _queuePlan.reserveIncrease,
            globalStakableAmount: _globalStakableAmount
        });

        // Net the offsets against each other
        globalCashFlowsPtr_N(0).queueToStake = _queuePlan.reducedQueueToStake;
        globalCashFlowsPtr_N(0).queueForUnstake = _queuePlan.reducedQueueForUnstake;
        _setCurrentTurnoverQueueForUnstake(_queuePlan.reducedTurnoverQueueForUnstake, _queuePlan.reducedQueueForUnstake);

        if (_stakeQueueCarryForward > 0) {
            globalCashFlowsPtr_N(1).queueToStake += _stakeQueueCarryForward.toUint120();
        }

        // Any remaining queue surpluses will get rolled forward to the next epoch
    }

    /// @notice Rolls any staking queued balance forward if the target validator is unassignable
    function _rollUnassignableStakingQueue() internal {
        // Stake deposits are assigned by the cached adjusted revenue denominator. A positive denominator can still
        // split a large stake queue even when the deadband-adjusted signal is below the validator deposit minimum.
        uint256 _weightedRevenue = allocationTotalsPtr_N(0).totalAdjustedWeightedRevenue;
        if (s_activeValidatorCount > 0 && _weightedRevenue <= DUST_THRESHOLD) {
            uint120 _stakeQueue = globalCashFlowsPtr_N(0).queueToStake;

            emit StakeUnassignableNoGlobalRevenue(_stakeQueue);

            globalCashFlowsPtr_N(0).queueToStake = 0;
            globalCashFlowsPtr_N(1).queueToStake += _stakeQueue;
        }
        // NOTE: if s_activeValidatorCount == 0, the _clampQueuesToCapacityOrRoll() method called next will handle
        // rolling the stake queue forwards.
    }

    /// @notice Clamps queues to available stake/unstake capacity or rolls forward when no validators are active.
    function _clampQueuesToCapacityOrRoll() internal {
        uint120 _turnoverQueueForUnstake = turnoverQueuePtr_N(0).queueForUnstake;

        // Handle accounting for max / min amounts that can be staked / unstaked, but only if there are
        // validators to stake / unstake with
        if (s_activeValidatorCount > 0) {
            // Calculate and carry forward any unstakable amount that cannot be covered by the global unstakable assets
            // during the next epoch. This could occur when the majority of assets are stuck in staking escrow or
            // unstaking escrow.

            // This occurs during the global crank, so use current s_globalPending
            uint256 _globalUnstakableAmount =
                StakeAllocationLib.getGlobalAmountAvailableToUnstake(s_globalCapital, s_globalPending);
            uint256 _isolatedIlliquidAmount =
                s_isolatedTotalAssets > s_isolatedLiquidAssets ? s_isolatedTotalAssets - s_isolatedLiquidAssets : 0;
            _globalUnstakableAmount = _globalUnstakableAmount > _isolatedIlliquidAmount
                ? _globalUnstakableAmount - _isolatedIlliquidAmount
                : 0;
            uint120 _queuedForUnstakeAmount = globalCashFlowsPtr_N(0).queueForUnstake;

            uint256 _totalOverallocatedStake = allocationTotalsPtr_N(0).totalOverallocatedStake;
            (_queuedForUnstakeAmount, _turnoverQueueForUnstake,) = QueueLib.clampTurnoverToOverallocation(
                _queuedForUnstakeAmount, _turnoverQueueForUnstake, _totalOverallocatedStake
            );

            if (_queuedForUnstakeAmount > _globalUnstakableAmount) {
                uint256 _unstakeQueueDeficit = _queuedForUnstakeAmount - _globalUnstakableAmount;

                emit UnstakingQueueExceedsUnstakableAmount(_queuedForUnstakeAmount, _globalUnstakableAmount);

                uint120 _unstakeQueueDeficit120 = _unstakeQueueDeficit.toUint120();
                uint120 _turnoverRolled;
                (_queuedForUnstakeAmount, _turnoverQueueForUnstake, _turnoverRolled) = QueueLib.reducePreferTurnover(
                    _queuedForUnstakeAmount, _turnoverQueueForUnstake, _unstakeQueueDeficit
                );
                globalCashFlowsPtr_N(1).queueForUnstake += _unstakeQueueDeficit120;
                // Preserve the turnover label on the amount we rolled so the next epoch can continue rebalancing
                // before touching non-turnover semantics.
                _addTurnoverQueueToNextEpoch(_turnoverRolled);
            }
            uint256 _queuedToStakeAmount = globalCashFlowsPtr_N(0).queueToStake;
            uint256 _globalStakableAmount = _pooledCurrentAssets(address(this).balance);
            if (_queuedToStakeAmount > _globalStakableAmount) {
                uint256 _stakeQueueSurplus = _queuedToStakeAmount - _globalStakableAmount;

                emit StakingQueueExceedsStakableAmount(_queuedToStakeAmount, _globalStakableAmount);

                uint120 _stakeQueueSurplus120 = _stakeQueueSurplus.toUint120();
                globalCashFlowsPtr_N(0).queueToStake -= _stakeQueueSurplus120;
                globalCashFlowsPtr_N(1).queueToStake += _stakeQueueSurplus120;
            }

            // Next, we add in the "turnover" / "incentive-aligning" amount to the unstaking queue. This happens after
            // the settling of deposits against withdrawals in order to promote the rebalancing even when the net
            // cashflow is flat.
            // NOTE: The "staking" portion happens when this amount finishes unstaking.
            // NOTE: We only do this if there are multiple active validators from which to rebalance between.
            uint120 _turnoverTopUpAmount = QueueLib.calculateTurnoverTopUp(
                s_activeValidatorCount,
                _globalUnstakableAmount,
                _totalOverallocatedStake,
                s_admin.incentiveAlignmentPercentage,
                _queuedForUnstakeAmount,
                _turnoverQueueForUnstake
            );
            if (_turnoverTopUpAmount > 0) {
                _queuedForUnstakeAmount += _turnoverTopUpAmount;
                _turnoverQueueForUnstake += _turnoverTopUpAmount;
            }

            globalCashFlowsPtr_N(0).queueForUnstake = _queuedForUnstakeAmount;
            _setCurrentTurnoverQueueForUnstake(_turnoverQueueForUnstake, _queuedForUnstakeAmount);

            // If there are no active validators, roll forward any balances since there wont be anyone to stake them
            // with, then net them out since performance-weighting is not relevant
        } else {
            uint256 _queueToStake = globalCashFlowsPtr_N(0).queueToStake;
            uint256 _queueForUnstake = globalCashFlowsPtr_N(0).queueForUnstake;

            if (_turnoverQueueForUnstake > 0) {
                // With no active set there is nothing to rebalance across, so turnover semantics are meaningless.
                _queueForUnstake -= _turnoverQueueForUnstake;
                _turnoverQueueForUnstake = 0;
            }

            emit UnexpectedNoValidators(s_admin.internalEpoch, _queueToStake, _queueForUnstake);

            if (_queueToStake > _queueForUnstake) {
                uint256 _netQueueToStake = _queueToStake - _queueForUnstake;
                globalCashFlowsPtr_N(1).queueToStake += _netQueueToStake.toUint120();
                // Implied: globalCashFlowsPtr_N(1).queueForUnstake = 0;
            } else {
                uint256 _netQueueForUnstake = _queueForUnstake - _queueToStake;
                globalCashFlowsPtr_N(1).queueForUnstake += _netQueueForUnstake.toUint120();
                // Implied: globalCashFlowsPtr_N(1).queueToStake = 0;
            }
            globalCashFlowsPtr_N(0).clear();
            _setCurrentTurnoverQueueForUnstake(0, 0);
        }
    }

    function _rollDustNonTurnoverUnstakeQueue() internal {
        uint120 _queueForUnstake = globalCashFlowsPtr_N(0).queueForUnstake;
        uint120 _turnoverQueueForUnstake = turnoverQueuePtr_N(0).queueForUnstake;
        if (_queueForUnstake <= _turnoverQueueForUnstake) return;

        uint120 _nonTurnoverQueueForUnstake = _queueForUnstake - _turnoverQueueForUnstake;
        if (_nonTurnoverQueueForUnstake > DUST_THRESHOLD) return;

        // Aggregate non-turnover dust cannot produce a validator withdrawal delta, so carry it forward before the
        // current queue becomes the validator allocation snapshot. Turnover dust is not a redemption liability.
        uint120 _remainingQueueForUnstake = _queueForUnstake - _nonTurnoverQueueForUnstake;
        globalCashFlowsPtr_N(0).queueForUnstake = _remainingQueueForUnstake;
        globalCashFlowsPtr_N(1).queueForUnstake += _nonTurnoverQueueForUnstake;
        _setCurrentTurnoverQueueForUnstake(_turnoverQueueForUnstake, _remainingQueueForUnstake);

        emit UnstakingDustQueueRolledForward(
            s_admin.internalEpoch,
            _nonTurnoverQueueForUnstake,
            _remainingQueueForUnstake,
            globalCashFlowsPtr_N(1).queueForUnstake
        );
    }

    /// @notice Processes one validator's epoch roll, yield settlement, and (un)stake delta.
    /// @dev Skips placeholder and already-cranked validators to be idempotent within an epoch.
    /// Steps:
    ///  1) Guard for sentinel/unknown/zero-id validators
    ///  2) Mark last epoch as cranked (idempotency)
    ///  3) Advance active set flags and eligibility
    ///  4) Refresh pooled and isolated deposits already productive for a completed native reward period
    ///  5) Pull and book validator yield (precompile), updating rewards/liabilities
    ///  6) Settle remaining past epoch edges and pay or redirect rewards
    ///  7) Compute per-validator stake delta (increase/decrease)
    ///  8) Apply delta (stake or unstake), respecting availability and dust rules
    ///  9) Roll validator epoch forwards with the next target
    /// @param valId The validator ID to process
    function _crankValidator(uint64 valId) internal {
        // If at start of the linked list, skip to the next, first real validator in list
        if (valId == FIRST_VAL_ID) return;

        // Make sure we have a valid valId before proceeding.
        uint64 _valId = valId;
        if (_valId == UNKNOWN_VAL_ID) {
            _crankPlaceholderValidator();
            return;
        } else if (_valId == 0) {
            // This should be unreachable, but emits diagnostic event just in case
            emit CrankSkippedOnValidatorIdZero(block.coinbase);
            return;
        }

        // Crank only once per epoch per validator and only after the global state advanced.
        Epoch storage _lastEpoch = validatorEpochPtr_N(-1, _valId);
        if (_lastEpoch.wasCranked) return;
        _lastEpoch.wasCranked = true;

        // NOTE:
        // Global has already been cranked.
        // The epoch that is currently ongoing is validatorEpochPtr_N(0, coinbase)
        // The most recent epoch that has fully completed is is validatorEpochPtr_N(-1, coinbase)

        // Load the native epoch once for membership, settlement timing, and isolated stake handling below.
        (uint64 _monadEpoch, bool _inEpochDelayPeriod) = _getEpochInfo();
        _advanceActiveSetFlags(_valId, _monadEpoch, _inEpochDelayPeriod);

        // Compute the validator's unstakable amount prior to settling this epoch's cashflow
        uint256 _validatorUnstakableAmount = StakeAllocationLib.getValidatorAmountAvailableToUnstakeSnapshot(
            validatorEpochPtr_N(-1, _valId),
            validatorEpochPtr_N(-2, _valId),
            validatorPendingPtr_N(-1, _valId),
            validatorPendingPtr_N(-2, _valId)
        );

        // Keep allocation capacity on the pre-settlement snapshot above. For a skipped-epoch aggregate reward claim,
        // refresh deposits that have completed a productive period and use that endpoint snapshot for attribution.
        uint64 _monadEpochDistance = _getMonadEpochDistance(_monadEpoch);
        _settleRewardProductiveDepositEdges(_valId, _monadEpochDistance, _monadEpoch);
        _refreshProductiveIsolatedPendingStake(_valId, _monadEpoch);

        // Pull validator rewards (net of commission). Note: this updates earnedRevenue at offset 0,
        // but stake allocation uses offsets -1 and -2, so it does not affect the upcoming rebalancing.
        _settleEarnedStakingYield(_valId);

        _settlePastEpochEdges(_valId, _monadEpochDistance, _monadEpoch);
        if (globalEpochPtr_N(0).frozen) {
            // Preserve the fail-stop state but leave this validator retryable after governance unfreezes.
            _lastEpoch.wasCranked = false;
            return;
        }
        _settleCompletedIsolatedWithdrawal(_valId);

        // Send any unsent rewardsPayable (i.e., MEV payments)
        address _coinbase = _validatorCoinbase(_valId);
        _settleValidatorRewardsPayable(_valId, _coinbase);

        // Monad does not currently support staking principal slashing. A lower-than-expected precompile position is an
        // invariant failure, so balance verification freezes/closes instead of writing down pooled or isolated stake.
        bool haltedByPrincipalDeficit =
            _handleStakeBalanceVerification(_valId, validatorEpochPtr_N(-1, _valId), _monadEpoch);
        if (haltedByPrincipalDeficit) {
            // The freeze/close state is already persisted; clear the optimistic crank marker so recovery can retry.
            _lastEpoch.wasCranked = false;
            return;
        }

        _restakeIsolatedRewards(_valId, _monadEpoch, _inEpochDelayPeriod);
        _queueAndInitiateIsolatedUnstake(_valId);

        // Calculate and then handle the net staking / unstaking
        (
            uint128 _nextTargetStakeAmount,
            uint128 _netAmount,
            bool _isWithdrawal,
            uint256 _stakeAllocationIncrease,
            uint256 _stakeAllocationDecrease,
            uint256 _turnoverAllocationDecrease
        ) = _computeStakeDelta(_valId, _validatorUnstakableAmount);

        uint256 _appliedTurnoverAllocationDecrease = _turnoverAllocationDecrease;
        bool _isForcedExit = _requiresForcedExit(_valId, _nextTargetStakeAmount);

        // CASE: Validator was tagged as inactive for the cranked period
        if (_isForcedExit) {
            _netAmount = _validatorUnstakableAmount.toUint128();
            _nextTargetStakeAmount = validatorEpochPtr_N(-1, _valId).targetStakeAmount - _netAmount;
            _isWithdrawal = true;
            _appliedTurnoverAllocationDecrease = 0;
        }

        (_nextTargetStakeAmount, _netAmount) = _applyStakeDelta(
            _valId,
            _validatorUnstakableAmount,
            _nextTargetStakeAmount,
            _netAmount,
            _isWithdrawal,
            _appliedTurnoverAllocationDecrease,
            !_isForcedExit
        );

        if (_isForcedExit) {
            _reconcileForcedExitQueues(
                _netAmount, _stakeAllocationIncrease, _stakeAllocationDecrease, _turnoverAllocationDecrease
            );
        }

        // Process the coinbase before refreshing isolated snapshots. Any ShMonad donation produced here should use the
        // previous split basis when this crank has just moved isolated stake into an exit path.
        if (_coinbase.code.length > 0 && _coinbase.balance > 0) {
            _settleCoinbaseContract(_valId, _coinbase);
        }

        // Roll the storage slots forwards
        _rollValidatorEpochForwards(_valId, _nextTargetStakeAmount);
    }

    /// @notice Handles cranking for the placeholder validator (unregistered validators)
    /// @dev Processes revenue attribution for unregistered validators
    function _crankPlaceholderValidator() internal {
        Epoch storage _completedEpoch = globalEpochPtr_N(-1);
        if (_completedEpoch.wasCranked) return;
        _completedEpoch.wasCranked = true;

        // Global cranking has already advanced the internal epoch, so the completed UNKNOWN bucket is N(-1).
        PendingBoost memory _completedUnknownRewards = validatorRewardsPtr_N(-1, UNKNOWN_VAL_ID);

        emit UnregisteredValidatorRevenue(
            _completedEpoch.epoch,
            uint256(_completedUnknownRewards.rewardsPayable),
            uint256(_completedUnknownRewards.earnedRevenue)
        );

        // Roll forward the placeholder validator's epoch storage
        _rollValidatorEpochForwards(UNKNOWN_VAL_ID, 0);
    }

    /// @notice Advances validator epoch state and updates validator accounting
    /// @param valId The validator's ID
    /// @param newTargetStakeAmount The new target stake amount for the validator
    function _rollValidatorEpochForwards(uint64 valId, uint128 newTargetStakeAmount) internal {
        // Load the ongoing validator epoch into memory for convenience
        Epoch memory _ongoingValidatorEpoch = validatorEpochPtr_N(0, valId);
        uint64 _internalEpoch = s_admin.internalEpoch;

        // Set the target stake amount
        validatorEpochPtr_N(0, valId).targetStakeAmount = newTargetStakeAmount;

        // Clear out the next next shmonad epoch's slots
        // NOTE: Clearing N(+2) here means that after the global epoch pointer advances, this slot becomes N(+1)
        // for the next validator crank, keeping the ring buffer pre-zeroed while preserving existing behavior.
        validatorRewardsPtr_N(2, valId).clear();
        validatorPendingPtr_N(2, valId).clear();
        validatorAllocationRevenuePtr_N(2, valId).clear();
        _setEpochStorage(
            validatorEpochPtr_N(1, valId),
            Epoch({
                epoch: _internalEpoch + 1,
                withdrawalId: _currentWithdrawalCursor(valId, false),
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                wasCranked: false,
                frozen: _ongoingValidatorEpoch.frozen,
                closed: _ongoingValidatorEpoch.closed,
                targetStakeAmount: 0
            })
        );

        _setIsolatedSnapshots(valId, newTargetStakeAmount);

        // Update ValidatorData
        if (s_validatorData[valId].isActive) {
            s_validatorData[valId].epoch = _internalEpoch;

            // Pending native activation receives no onboarding grace once native inactivity is confirmed.
            if (_hasConfirmedNativeInactivity(valId)) {
                _beginDeactivatingValidator(valId);
            }
        } else {
            // Once the minimum delay has passed, attempt removal; residual isolated or pooled state can defer it.
            if (_internalEpoch >= s_validatorData[valId].epoch + SHMONAD_VALIDATOR_DEACTIVATION_PERIOD) {
                _completeDeactivatingValidator(valId);
            }
        }
    }

    /// @notice Checks and sets new atomic liquidity target based on current conditions
    /// @param oldAllocatedAmount The previous allocated amount for comparison
    /// @return scaledTargetPercent The new scaled target percentage
    /// @return newAllocatedAmount The new allocated amount for atomic unstaking
    function _checkSetNewAtomicLiquidityTarget(uint128 oldAllocatedAmount)
        internal
        returns (uint256 scaledTargetPercent, uint128 newAllocatedAmount)
    {
        // Load any pending atomic liquidity percentage
        uint256 _newScaledTargetPercent = s_pendingTargetAtomicLiquidityPercent;

        // Load relevant values
        WorkingCapital memory _globalCapital = s_globalCapital;
        uint256 _totalEquity =
            _globalCapital.totalEquity(s_globalLiabilities, s_admin, address(this).balance, s_isolatedTotalAssets);
        uint256 _currentAssets = _pooledCurrentAssets(address(this).balance);

        // See if there is a new target percent - if not, check for minor rebalances and then return the old data.

        if (_newScaledTargetPercent == FLOAT_PLACEHOLDER) {
            // Check to see if the allocated amount has drifted too far away due to increases during
            // _accountForWithdraw
            uint256 _scaledTargetAllocatedPercentage = _scaledTargetLiquidityPercentage();
            uint256 _scaledCurrentAllocatedPercentage = _scaledPercentFromAmounts(oldAllocatedAmount, _totalEquity);

            if (_scaledTargetAllocatedPercentage > _scaledCurrentAllocatedPercentage + FLOAT_REBALANCE_SENSITIVITY) {
                // CASE: Need to rebalance up
                _newScaledTargetPercent = _scaledTargetAllocatedPercentage;
                s_pendingTargetAtomicLiquidityPercent = _scaledTargetAllocatedPercentage;
            } else if (
                // CASE: rebalance down
                _scaledTargetAllocatedPercentage + FLOAT_REBALANCE_SENSITIVITY < _scaledCurrentAllocatedPercentage
            ) {
                _newScaledTargetPercent = _scaledTargetAllocatedPercentage;
                s_pendingTargetAtomicLiquidityPercent = _scaledTargetAllocatedPercentage;
            } else {
                // CASE: Allocation is within threshold
                return (_scaledTargetAllocatedPercentage, oldAllocatedAmount);
            }
        }

        // Calculate an initial allocation amount for the atomic unstaking pool
        newAllocatedAmount = _amountFromScaledPercent(_totalEquity, _newScaledTargetPercent).toUint128();

        if (newAllocatedAmount > oldAllocatedAmount) {
            // CASE: Increasing the liquidity target
            uint128 _maxNetAmount = _currentAssets.toUint128();

            if (oldAllocatedAmount + _maxNetAmount < newAllocatedAmount) {
                // CASE: we cannot increase by the full max amount, so calculate the new scaledTargetPercent
                newAllocatedAmount = oldAllocatedAmount + _maxNetAmount;
                _newScaledTargetPercent = _scaledPercentFromAmounts(newAllocatedAmount, _totalEquity);
            } else {
                // CASE: we can increase by the full net amount, so we fully remove the
                // s_pendingTargetAtomicLiquidityPercent and consider the update complete.

                // Clear the pending target - we can fully update.
                s_pendingTargetAtomicLiquidityPercent = FLOAT_PLACEHOLDER;
            }
        } else {
            // Target decreases need no liquidity cap. Settlement scales adjusted utilization with allocation, so the
            // pool releases only the proportional share of liquidity that is still available.
            s_pendingTargetAtomicLiquidityPercent = FLOAT_PLACEHOLDER;
        }

        // Store data and return
        s_admin.targetLiquidityPercentage = _unscaledTargetLiquidityPercentage(Math.min(_newScaledTargetPercent, SCALE));

        return (_newScaledTargetPercent, newAllocatedAmount);
    }

    /// @notice Settles completed stake allocation changes (staking/unstaking) for a validator
    /// @param valId The validator ID
    /// @param validatorEpochPtr Storage pointer to validator epoch data
    /// @param validatorPendingPtr Storage pointer to validator pending data
    function _settleCompletedStakeAllocationDecrease(
        uint64 valId,
        Epoch storage validatorEpochPtr,
        StakingEscrow storage validatorPendingPtr
    )
        internal
    {
        address coinbase = _validatorCoinbase(valId);
        (uint128 _amountReceived, bool _success, bool _delayed) =
            _completeWithdrawal(valId, validatorEpochPtr.withdrawalId);
        if (_delayed) {
            // Treat boundary-period delays as cranked-in-boundary so the N(-3) path retries next epoch.
            validatorEpochPtr.crankedInBoundaryPeriod = true;
            // NOTE: This frame is just for testing purposes - it indicates a timing synchronization problem
            emit WithdrawSettlementDelayed(
                coinbase,
                valId,
                _getEpoch(),
                validatorPendingPtr.pendingUnstaking,
                _amountReceived,
                validatorEpochPtr.withdrawalId
            );
        } else if (_success) {
            bool _settled = _handleCompleteDecreasedAllocation(
                valId, validatorEpochPtr, validatorPendingPtr, _amountReceived.toUint120()
            );
            if (!_settled) return;

            emit ValidatorUnstakeCompleted(valId, _amountReceived, validatorEpochPtr.withdrawalId);
        } else {
            _markValidatorNotInActiveSet(valId, 2);

            emit UnexpectedStakeSettlementError(coinbase, valId, _amountReceived, 2);
        }
    }

    function _settleCompletedIsolatedWithdrawal(uint64 valId) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        if (!state.isolatedWithdrawalPending) return;

        uint8 withdrawalId = state.isolatedWithdrawalId;
        uint120 expectedAmount = state.pendingUnstake;
        (uint128 amountReceived, bool success, bool delayed) = _completeWithdrawal(valId, withdrawalId);

        if (delayed || !success) return;

        _finalizeCompletedIsolatedWithdrawal(valId, withdrawalId, expectedAmount, amountReceived);
    }

    function _finalizeCompletedIsolatedWithdrawal(
        uint64 valId,
        uint8 withdrawalId,
        uint120 expectedAmount,
        uint128 amountReceived
    )
        internal
    {
        require(
            amountReceived >= expectedAmount, UnexpectedIsolatedWithdrawalAmount(valId, expectedAmount, amountReceived)
        );

        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        state.isolatedWithdrawalPending = false;
        state.isolatedWithdrawalId = 0;
        state.pendingUnstake = 0;
        s_globalCapital.stakedAmount -= expectedAmount;

        if (expectedAmount > 0) {
            state.idleAssets += expectedAmount;
            s_isolatedLiquidAssets += expectedAmount;
            s_isolatedIdleAssets += expectedAmount;
        }

        if (amountReceived > expectedAmount) {
            uint120 surplus = (amountReceived - expectedAmount).toUint120();
            _handleIsolatedWithdrawalSurplus(valId, surplus);
        }

        // The last redemption may already have consumed replacement liquidity. Reconcile only after principal and
        // surplus are booked so the complete ownerless settlement returns to pooled equity.
        _sweepOrphanedIsolatedIdleAssets(valId, state);

        emit ValidatorIsolatedWithdrawalCompleted(valId, withdrawalId, amountReceived);
    }

    function _restakeIsolatedRewards(uint64 valId, uint64 monadEpoch, bool inEpochDelayPeriod) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];
        if (state.queuedRestake == 0) return;

        // Once native inactivity is confirmed, keep isolated rewards liquid while the validator begins unwinding.
        if (
            !s_validatorData[valId].isActive || _hasConfirmedNativeInactivity(valId)
                || s_isolatedVTotalShares[valId] == 0
        ) {
            uint120 queuedRestake = state.queuedRestake;
            state.queuedRestake = 0;
            state.idleAssets += queuedRestake;
            s_isolatedIdleAssets += queuedRestake;
            _sweepOrphanedIsolatedIdleAssets(valId, state);
            return;
        }

        _reserveQueuedIsolatedLiquidityForRedemptions(valId);

        uint120 amountToStake = state.queuedRestake;
        if (amountToStake == 0) return;

        (bool success, uint128 actualAmount) = _initiateStaking(valId, amountToStake);
        if (!success || actualAmount == 0) return;

        uint120 actualAmount120 = actualAmount.toUint120();
        state.queuedRestake -= actualAmount120;
        _recordIsolatedPendingStake(valId, actualAmount120, monadEpoch, inEpochDelayPeriod);
        s_isolatedLiquidAssets -= actualAmount120;
        s_globalCapital.stakedAmount += actualAmount120;
    }

    function _queueAndInitiateIsolatedUnstake(uint64 valId) internal {
        IsolatedValidatorState storage state = s_isolatedValidatorState[valId];

        if (
            (!s_validatorData[valId].isActive || _hasConfirmedNativeInactivity(valId))
                && state.activeStake > state.queuedUnstake
        ) {
            state.queuedUnstake = state.activeStake;
        }

        if (state.isolatedWithdrawalPending || state.queuedUnstake == 0 || state.activeStake == 0) return;

        uint120 amountToWithdraw = Math.min(uint256(state.queuedUnstake), uint256(state.activeStake)).toUint120();
        uint120 remainingActiveStake = state.activeStake - amountToWithdraw;
        if (remainingActiveStake != 0 && remainingActiveStake < DUST_THRESHOLD) {
            // Monad rounds an undelegation up when it would leave native stake dust behind, so mirror that full
            // withdrawal in ShMonad accounting before balance verification sees a false principal deficit.
            amountToWithdraw = state.activeStake;
        }

        uint8 withdrawalId = _consumeWithdrawalId(valId, true);
        bool success = _initiateWithdrawal(valId, amountToWithdraw, withdrawalId);
        if (!success) return;

        state.isolatedWithdrawalPending = true;
        state.isolatedWithdrawalId = withdrawalId;
        state.pendingUnstake += amountToWithdraw;
        state.queuedUnstake = amountToWithdraw >= state.queuedUnstake ? 0 : state.queuedUnstake - amountToWithdraw;
        state.activeStake -= amountToWithdraw;

        emit ValidatorIsolatedWithdrawalRequested(valId, withdrawalId, amountToWithdraw);
    }

    /// @notice Settles earned (received) staking yield from a validator
    /// @param valId The validator ID
    function _settleEarnedStakingYield(uint64 valId) internal {
        (uint120 _amountRewarded, bool _success) = _claimRewards(valId);
        if (_success) {
            _handleEarnedStakingYield(valId, _amountRewarded);
        } else {
            _markValidatorNotInActiveSet(valId, 1);

            address coinbase = _validatorCoinbase(valId);
            emit UnexpectedYieldSettlementError(coinbase, valId, _amountRewarded, address(this).balance, 1);
        }
    }

    /// @notice Settles validator rewards payable (MEV payments *TO* a validator).
    /// @param valId The validator ID
    function _settleValidatorRewardsPayable(uint64 valId, address coinbase) internal {
        uint120 _validatorRewardsPayable = validatorRewardsPtr_N(-1, valId).rewardsPayable;
        // Return early if there are no rewards to pay
        if (_validatorRewardsPayable == 0) return;

        // If validator is inactive (pending or completed deactivation), internalize the escrowed MEV
        // as additional shMON yield. This is an intentional donation, not an error path.
        if (!s_validatorData[valId].isActive) {
            _handleRewardsRedirect(valId, _validatorRewardsPayable);
            emit InactiveValidatorRewardsRedirected(valId, _validatorRewardsPayable);
            return;
        }

        // If coinbase contract is set up to process the validator rewards payable, send to it and
        // process the external reward at the end of the validator crank (at same time as priority fees).
        // The coinbase applies its live MEV commission rate; ShMonad does not snapshot it at accrual.
        if (coinbase.code.length > 0 && address(this).balance >= _validatorRewardsPayable) {
            if (_isNot7702Enabled(coinbase)) {
                try ICoinbase(coinbase)
                .handleMEVPayable{ gas: COINBASE_HANDLE_MEV_GAS_LIMIT, value: _validatorRewardsPayable }() {
                    _handleRewardsPaidSuccess(valId, _validatorRewardsPayable);
                    return;
                } catch {
                    // If payment via coinbase contract isn't successful, handle inside this function
                    // pass
                }
            }
        }

        if (_validatorRewardsPayable >= MIN_VALIDATOR_DEPOSIT) {
            // NOTE: if _sendRewards fails it means the validator is no longer a part of the active validator set
            (bool _success, uint120 _actualAmountSent) = _sendRewards(valId, _validatorRewardsPayable);
            if (_success) {
                if (_actualAmountSent < _validatorRewardsPayable) {
                    if (_validatorRewardsPayable > MAX_EXTERNAL_REWARD) {
                        emit PartialValidatorRewardsPayment(
                            valId, _actualAmountSent, _validatorRewardsPayable, address(this).balance
                        );
                    } else {
                        emit InsufficientLocalBalance(
                            _validatorRewardsPayable, _actualAmountSent, address(this).balance, _totalEquity(false), 2
                        );
                        emit UnexpectedValidatorRewardsPayError(
                            coinbase, valId, _validatorRewardsPayable, address(this).balance, 1
                        );
                    }

                    _handleRewardsPaidFail(valId, _validatorRewardsPayable - _actualAmountSent);
                    _handleRewardsPaidSuccess(valId, _actualAmountSent);
                } else {
                    _handleRewardsPaidSuccess(valId, _validatorRewardsPayable);
                }

                // externalReward uses the validator's live stake mix immediately. Pull any direct payment back now,
                // before this crank can change stake or refresh the snapshot used for pooled/isolated attribution.
                if (_actualAmountSent > 0) _settleEarnedStakingYield(valId);
            } else {
                emit UnexpectedValidatorRewardsPayError(
                    coinbase, valId, _validatorRewardsPayable, address(this).balance, 2
                );
                _handleRewardsRedirect(valId, _validatorRewardsPayable);
                _markValidatorNotInActiveSet(valId, 3);
            }
        } else if (_validatorRewardsPayable > 0) {
            emit UnexpectedValidatorRewardsPayError(coinbase, valId, _validatorRewardsPayable, address(this).balance, 3);
            _handleRewardsPaidFail(valId, _validatorRewardsPayable);
        }
    }

    /// @notice Settles the coinbase contract of a validator - existence check is performed prior
    /// @param valId The validator ID
    function _settleCoinbaseContract(
        uint64 valId,
        address coinbaseContract
    )
        internal
        override
        expectsRewardsFrom(coinbaseContract)
    {
        if (_isNot7702Enabled(coinbaseContract)) {
            try ICoinbase(coinbaseContract).process{ gas: COINBASE_PROCESS_GAS_LIMIT }() { } catch { }
            // receive() has already filtered this amount to MON sent by coinbaseContract.
            (, uint256 _rewardAmount,) = _getTransientCapital();

            if (_rewardAmount > 0) {
                _handleValidatorRewards(valId, _rewardAmount, SCALE);
            }
        }
    }

    function _isNot7702Enabled(address coinbaseContract) internal view returns (bool) {
        // First, we must verify that the coinbase contract isn't an EOA that has been 7702-enabled
        // NOTE: When adding non-contract coinbase addresses for a validator, it must be manually verified offchain
        // that the coinbase is a wallet with a known private key and not an undeployed create2 smart contract.

        bytes3 _coinbasePrefix;
        // Assembly justification: need to read only the first 3 bytes of runtime code without allocating memory.
        // Pseudocode: `_coinbasePrefix = bytes3(coinbaseContract.code[:3]);`
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            extcodecopy(coinbaseContract, ptr, 0, 3)
            _coinbasePrefix := mload(ptr)
            mstore(0x40, add(ptr, 0x20))
        }

        // 7702 EOAs have a code prefix of 0xef0100. If not 7702, process the coinbase contract
        return _coinbasePrefix != 0xef0100;
    }

    /// @notice Handles stake allocation skip when amount is below dust threshold
    /// @param valId The validator ID
    /// @param nextTargetStakeAmount The next target stake amount
    /// @param netAmount The net amount to process
    /// @param isWithdrawal Whether this is a withdrawal operation
    /// @param requeueFailedWithdrawal Whether a skipped withdrawal should be restored to the global queue
    /// @return The updated target stake amount and net amount
    function _initiateStakeAllocationSkip(
        uint64 valId,
        uint128 nextTargetStakeAmount,
        uint120 netAmount,
        bool isWithdrawal,
        uint120 turnoverAllocationDecrease,
        bool requeueFailedWithdrawal
    )
        internal
        returns (uint128, uint120)
    {
        if (netAmount == 0) {
            // pass
            address coinbase = _validatorCoinbase(valId);
            emit LowValidatorStakeDeltaNetZero(
                coinbase,
                valId,
                globalEpochPtr_N(-1).epoch,
                nextTargetStakeAmount,
                netAmount,
                s_validatorData[valId].inActiveSet_Current,
                s_validatorData[valId].inActiveSet_Last
            );
        } else if (isWithdrawal) {
            nextTargetStakeAmount += netAmount;
            if (requeueFailedWithdrawal) _requeueWithdrawalAmount(netAmount, turnoverAllocationDecrease);
            netAmount = 0;

            address coinbase = _validatorCoinbase(valId);
            emit LowValidatorStakeDeltaOnDecrease(
                coinbase,
                valId,
                globalEpochPtr_N(-1).epoch,
                nextTargetStakeAmount,
                netAmount,
                s_validatorData[valId].inActiveSet_Current,
                s_validatorData[valId].inActiveSet_Last
            );
        } else {
            // Adjust the target, then resubmit the amount into the staking queue
            nextTargetStakeAmount -= netAmount;
            globalCashFlowsPtr_N(0).queueToStake += netAmount;
            netAmount = 0;

            address coinbase = _validatorCoinbase(valId);
            emit LowValidatorStakeDeltaOnIncrease(
                coinbase,
                valId,
                globalEpochPtr_N(-1).epoch,
                nextTargetStakeAmount,
                netAmount,
                s_validatorData[valId].inActiveSet_Current,
                s_validatorData[valId].inActiveSet_Last
            );
        }
        return (nextTargetStakeAmount, netAmount);
    }

    /// @notice Initiates stake allocation decrease for a validator
    /// @param valId The validator ID
    /// @param nextTargetStakeAmount The next target stake amount
    /// @param netAmount The net amount to decrease
    /// @param requeueFailedWithdrawal Whether a failed withdrawal should be restored to the global queue
    /// @return The updated target stake amount and net amount
    function _initiateStakeAllocationDecrease(
        uint64 valId,
        uint256 validatorUnstakableAmount,
        uint128 nextTargetStakeAmount,
        uint128 netAmount,
        uint256 turnoverAllocationDecrease,
        bool requeueFailedWithdrawal
    )
        internal
        returns (uint128, uint128)
    {
        turnoverAllocationDecrease = Math.min(turnoverAllocationDecrease, netAmount);

        uint128 withdrawalAmount = netAmount;
        uint120 isolatedDustToSweep;
        if (netAmount < validatorUnstakableAmount) {
            uint256 remainingActiveStake = validatorUnstakableAmount - netAmount;
            if (remainingActiveStake < DUST_THRESHOLD) {
                // Monad rounds this undelegation up to full active stake, so mirror the native withdrawal amount
                // before recording the next target and pending unstake.
                uint128 dustRemainder = remainingActiveStake.toUint128();
                nextTargetStakeAmount -= dustRemainder;
                netAmount += dustRemainder;
                withdrawalAmount = netAmount;
            }
        }

        if (uint256(withdrawalAmount) == validatorUnstakableAmount) {
            uint120 isolatedActiveStake = s_isolatedValidatorState[valId].activeStake;
            if (isolatedActiveStake != 0 && isolatedActiveStake < DUST_THRESHOLD) {
                // This full pooled exit may be direct or caused by pooled dust rounding above. Either way, the native
                // delegator position would be left with only isolated dust, so Monad sweeps it into this withdrawal.
                isolatedDustToSweep = isolatedActiveStake;
                withdrawalAmount += isolatedDustToSweep;
            }
        }

        // Kick off the next-stage unstake;
        uint8 _withdrawalId = _consumeWithdrawalId(valId, false);
        validatorEpochPtr_N(0, valId).withdrawalId = _withdrawalId;
        bool _success = _initiateWithdrawal(valId, withdrawalAmount, _withdrawalId);

        if (_success) {
            // CASE: Unstaking initiated successfully
            _handleInitiateDecreasedAllocation(valId, withdrawalAmount.toUint120());
            if (isolatedDustToSweep != 0) {
                s_isolatedValidatorState[valId].activeStake = 0;
                s_isolatedTotalAssets -= isolatedDustToSweep;
            }
        } else {
            // CASE: Unstaking failed to initiate
            _markValidatorNotInActiveSet(valId, 4);
            // Always restore validator accounting. Forced exits reconcile their original queue intent in the caller.
            nextTargetStakeAmount += netAmount;
            if (requeueFailedWithdrawal) {
                _requeueWithdrawalAmount(netAmount.toUint120(), turnoverAllocationDecrease.toUint120());
            }
            netAmount = 0;

            address coinbase = _validatorCoinbase(valId);
            emit UnexpectedFailureInitiateUnstake(coinbase, valId, nextTargetStakeAmount, netAmount);
        }
        return (nextTargetStakeAmount, netAmount);
    }

    /// @notice Initiates stake allocation increase for a validator
    /// @param valId The validator ID
    /// @param nextTargetStakeAmount The next target stake amount
    /// @param netAmount The net amount to increase
    /// @return The updated target stake amount and net amount
    function _initiateStakeAllocationIncrease(
        uint64 valId,
        uint128 nextTargetStakeAmount,
        uint128 netAmount
    )
        internal
        returns (uint128, uint128)
    {
        // Pooled allocation may only consume unreserved pooled MON. Raw balance also includes atomic liquidity,
        // isolated liquid assets, and reserves held for liabilities.
        uint128 _amountToStake = Math.min(netAmount, _pooledCurrentAssets(address(this).balance)).toUint128();
        (bool _success, uint128 _actualAmount) = _initiateStaking(valId, _amountToStake);

        if (_success) {
            // CASE: Staking initiated successfully
            if (_actualAmount < netAmount) {
                // CASE: Staking initiated successfully but unable to initiate the intended amount
                emit InsufficientLocalBalance(netAmount, _actualAmount, address(this).balance, _totalEquity(false), 1);

                // Reduce the nextTargetStakeAmount and the netAmount by the missing allocation and then
                // resubmit the amount to the staking queue.
                uint120 _deficit = (netAmount - _actualAmount).toUint120();
                nextTargetStakeAmount -= _deficit;
                globalCashFlowsPtr_N(0).queueToStake += _deficit;
                netAmount = _actualAmount;
            }
            if (netAmount != 0) _handleInitiateIncreasedAllocation(valId, netAmount.toUint120());
        } else {
            // CASE: Staking failed to initiate
            _markValidatorNotInActiveSet(valId, 5);

            // Remove the netAmount from the nextTargetStakeAmount and resubmit the missing amount to the staking queue.
            nextTargetStakeAmount -= netAmount;
            globalCashFlowsPtr_N(0).queueToStake += netAmount.toUint120();
            netAmount = 0;

            address coinbase = _validatorCoinbase(valId);
            emit UnexpectedFailureInitiateStake(coinbase, valId, nextTargetStakeAmount, netAmount);
        }
        return (nextTargetStakeAmount, netAmount);
    }

    // ================================================== //
    //       Accounting Handlers - MEV and Revenue        //
    // ================================================== //

    /// @notice Handles the accounting, collection and escrow of MEV rewards that will be paid out to a validator in the
    /// next epoch. This also collects and processes shMonad's share of the MEV payments.
    /// @param valId The validator ID
    /// @param amount The total reward amount
    /// @param feeRate The fee rate to apply
    /// @return validatorPayout The amount paid to the validator
    /// @return feeTaken The fee amount taken by the protocol
    function _handleValidatorRewards(
        uint64 valId,
        uint256 amount,
        uint256 feeRate
    )
        internal
        override
        returns (uint120 validatorPayout, uint120 feeTaken)
    {
        // NOTE: The `feeTaken` portion is earnedRevenue - realized as shMON yield immediately.
        // The validator payout after fees is delayed until the next epoch's crank is called.
        uint120 _grossFeeTaken = _amountFromScaledPercent(amount, feeRate).toUint120();
        uint256 _boostCommissionRate = s_admin.boostCommissionRate;

        uint120 _commissionTaken = (_grossFeeTaken * _boostCommissionRate / BPS_SCALE).toUint120();
        feeTaken = _grossFeeTaken - _commissionTaken;
        validatorPayout = amount.toUint120() - feeTaken - _commissionTaken;
        uint256 pooledYield;
        uint256 isolatedYield;

        // Load the validator's data
        ValidatorData memory _vData = _getValidatorData(valId);
        bool _escrowEligible = !_vData.isPlaceholder && _vData.isActive;
        bool _allocationEligible = _escrowEligible && _vData.inActiveSet_Current;

        if (_escrowEligible) {
            // CASE: Validator is registered and protocol-active - hold their MEV rewards (net of FastLane fee)
            // in escrow for them and pay them out next epoch. Native active-set flags are a cached settlement signal,
            // not an ownership signal; a failed native settlement redirects the escrow through the holder-yield path.
            // This escrow is unsplit by coinbase MEV commission until settlement through the validator coinbase.
            PendingBoost storage validatorRewardsPtr = validatorRewardsPtr_N(0, valId);
            validatorRewardsPtr.rewardsPayable += validatorPayout;
            (pooledYield, isolatedYield) = _splitIsolatedAndPooledBySnapshot(valId, feeTaken);
            uint120 pooledYield120 = pooledYield.toUint120();

            // Native activity gates performance attribution, not payout ownership. Fail closed to the placeholder
            // signal while the cache is false so a natively-ineligible validator cannot steer pooled allocation.
            if (_allocationEligible) {
                validatorRewardsPtr.earnedRevenue += pooledYield120;
                uint120 allocationSignalAmount = _allocationSignalAmount(pooledYield, isolatedYield);
                validatorAllocationRevenuePtr_N(0, valId).nonStakingRevenue += allocationSignalAmount;
                globalAllocationRevenuePtr_N(0).nonStakingRevenue += allocationSignalAmount;
            } else {
                validatorRewardsPtr_N(0, UNKNOWN_VAL_ID).earnedRevenue += pooledYield120;
                validatorAllocationRevenuePtr_N(0, UNKNOWN_VAL_ID).nonStakingRevenue += pooledYield120;
            }
            globalRevenuePtr_N(0).earnedRevenue += pooledYield120;
            _creditIsolatedRewards(valId, isolatedYield.toUint120(), isolatedYield.toUint120(), 0);

            s_globalLiabilities.rewardsPayable += validatorPayout; // +Liability Cr validatorPayout
            s_admin.totalZeroYieldPayable += _commissionTaken; // +Liability Cr _commissionTaken
            s_globalCapital.reservedAmount += validatorPayout; // +Asset Dr validatorPayout,
            // Implied currentAssets += _commissionTaken //  +Asset Dr +_commissionTaken
        } else {
            // CASE: Validator is unregistered, a placeholder, or protocol-inactive - use all the MEV to boost shMON
            // yield.
            // Keep validator-level attribution out of active validators, but still record pooled MON-backed
            // revenue globally so ERC4626 exit pricing smooths it like other newly-realized pooled yield.
            PendingBoost storage validatorRewardsPtr = validatorRewardsPtr_N(0, UNKNOWN_VAL_ID);
            uint120 _fullStakerYield = feeTaken + validatorPayout;
            validatorPayout = 0;
            if (valId != UNKNOWN_VAL_ID) {
                (pooledYield, isolatedYield) = _splitIsolatedAndPooledBySnapshot(valId, _fullStakerYield);
            } else {
                pooledYield = _fullStakerYield;
            }
            uint120 pooledYield120 = pooledYield.toUint120();
            validatorRewardsPtr.earnedRevenue += pooledYield120;
            globalRevenuePtr_N(0).earnedRevenue += pooledYield120;
            validatorAllocationRevenuePtr_N(0, UNKNOWN_VAL_ID).nonStakingRevenue += pooledYield120;
            _creditIsolatedRewards(valId, isolatedYield.toUint120(), isolatedYield.toUint120(), 0);

            // Treat the full staker-facing amount as a debit. The pooled portion has been recorded as global
            // earned revenue above for smoothing, while global allocation revenue stays unchanged so inactive
            // validators do not dilute active-validator routing weights.
            feeTaken = _fullStakerYield;
            validatorPayout = 0;
            s_admin.totalZeroYieldPayable += _commissionTaken; // +Liability Cr _commissionTaken
            // Implied currentAssets += _commissionTaken; // +Asset Dr _commissionTaken
            // Implied currentAssets += feeTaken; // +Asset Dr feeTaken
            // Implied equity += feeTaken; // +Equity Cr feeTaken
        }

        _increaseZeroYieldBalance(address(this), OWNER_COMMISSION_ACCOUNT, _commissionTaken, false);

        // Queue the net new unencumbered MON for staking
        globalCashFlowsPtr_N(0).queueToStake += (pooledYield + _commissionTaken).toUint120();

        // Re-add _commissionTaken to feeTaken when returning the amount that doesn't go to the validator
        return (validatorPayout, feeTaken + _commissionTaken);
    }

    /// @notice Handles the accounting for contract interactions that boost shMonad's yield.
    /// @param amount The boost yield amount to distribute
    function _handleBoostYield(uint128 amount) internal override {
        // NOTE: `amount` is pure earnedRevenue - realized as shMON yield immediately.

        uint128 _grossBoostCommission = amount * s_admin.boostCommissionRate / BPS_SCALE;

        if (_grossBoostCommission > 0) {
            s_admin.totalZeroYieldPayable += _grossBoostCommission; // +Liability Cr _grossBoostCommission
            // Implied: currentAssets +=  _grossBoostCommission // +Asset Dr _grossBoostCommission

            _increaseZeroYieldBalance(address(this), OWNER_COMMISSION_ACCOUNT, _grossBoostCommission, false);

            amount -= _grossBoostCommission;
        }

        // Implied currentAssets += amount; // +Asset Dr amount
        // Implied equity += amount; // +Equity Cr amount

        // Load the validator's data
        uint64 _currentValId = _getCurrentValidatorId();
        ValidatorData memory _vData = _getValidatorData(_currentValId);
        uint256 pooledAmount;
        uint256 isolatedAmount;

        // Validator attribution and global smoothing are separate concerns. Active proposers get validator-specific
        // attribution, while inactive or unknown proposers still produce pooled shMON revenue that must be smoothed.
        if (!_vData.isPlaceholder && _vData.inActiveSet_Current && _vData.isActive) {
            // CASE: Active, valid validator
            (pooledAmount, isolatedAmount) = _splitIsolatedAndPooledBySnapshot(_currentValId, amount);
            validatorRewardsPtr_N(0, _currentValId).earnedRevenue += pooledAmount.toUint120();
            globalRevenuePtr_N(0).earnedRevenue += pooledAmount.toUint120();
            // Boost / MEV / donation-style revenue only enters the non-staking bucket.
            uint120 allocationSignalAmount = _allocationSignalAmount(pooledAmount, isolatedAmount);
            validatorAllocationRevenuePtr_N(0, _currentValId).nonStakingRevenue += allocationSignalAmount;
            globalAllocationRevenuePtr_N(0).nonStakingRevenue += allocationSignalAmount;
            _creditIsolatedRewards(_currentValId, isolatedAmount.toUint120(), isolatedAmount.toUint120(), 0);
        } else {
            // CASE: Inactive or placeholder validator
            if (_currentValId != UNKNOWN_VAL_ID) {
                (pooledAmount, isolatedAmount) = _splitIsolatedAndPooledBySnapshot(_currentValId, amount);
                _creditIsolatedRewards(_currentValId, isolatedAmount.toUint120(), isolatedAmount.toUint120(), 0);
            } else {
                pooledAmount = amount;
            }
            uint120 pooledAmount120 = pooledAmount.toUint120();
            validatorRewardsPtr_N(0, UNKNOWN_VAL_ID).earnedRevenue += pooledAmount120;
            globalRevenuePtr_N(0).earnedRevenue += pooledAmount120;
            // Keep validator-level attribution isolated from active validators, but record the pooled donation globally
            // so recent-revenue smoothing and aggregate allocation signals include all shMON-holder revenue.
            validatorAllocationRevenuePtr_N(0, UNKNOWN_VAL_ID).nonStakingRevenue += pooledAmount120;
            globalAllocationRevenuePtr_N(0).nonStakingRevenue += pooledAmount120;
        }
        globalCashFlowsPtr_N(0).queueToStake += (pooledAmount + _grossBoostCommission).toUint120();
    }

    /// @notice Handles the accounting for contract interactions that boost shMonad's yield.
    /// @param assetValueOfShares The boost yield amount to distribute that came from existing
    /// shares
    function _handleBoostYieldFromShares(uint128 assetValueOfShares) internal override {
        // NOTE: `assetValueOfShares` comes from burning existing shMON shares without paying out
        // the equivalent amount of MON to any party. No unstaking required, but we must be mindful
        // of accounting invariants - specifically that an increase in earnedRevenue is assumed to be matched entirely
        // by MON in this contract and that no portion of that earnedRevenue increase is currently staked.
        // see `_accountForWithdraw()`

        uint128 _grossBoostCommission = assetValueOfShares * s_admin.boostCommissionRate / BPS_SCALE;

        if (_grossBoostCommission > 0) {
            s_admin.totalZeroYieldPayable += _grossBoostCommission; // +Liability Cr _grossBoostCommission
            // Implied: currentAssets +=  _grossBoostCommission // +Asset Dr _grossBoostCommission

            _increaseZeroYieldBalance(address(this), OWNER_COMMISSION_ACCOUNT, _grossBoostCommission, false);

            assetValueOfShares -= _grossBoostCommission;
        }

        // No accounting entries - equity stays the same, it's just divided up among fewer issued shares.

        // Load the validator's data
        uint64 _currentValId = _getCurrentValidatorId();
        ValidatorData memory _vData = _getValidatorData(_currentValId);

        // Share-burn boosts do not bring new MON into ShMonad. Only the active-validator portion backed by atomic
        // headroom is booked as global earnedRevenue. Any excess burn value, and all inactive/placeholder share-burn
        // value, increases the share rate immediately and is claimable by the then-current holder set rather than
        // smoothed through _recentRevenueOffset().
        if (!_vData.isPlaceholder && _vData.inActiveSet_Current && _vData.isActive) {
            // CASE: Active, valid validator
            // We must clamp the amount added to revenue and then offset the appropriate buckets due to the
            // atomicUnstakingPool assuming all revenue is collected in MON.
            AtomicCapital memory _atomicCapital = s_atomicAssets;
            uint128 _atomicLiquidityAvailable = _atomicCapital.allocatedAmount > _atomicCapital.distributedAmount
                ? _atomicCapital.allocatedAmount - _atomicCapital.distributedAmount
                : 0;
            if (_atomicLiquidityAvailable < assetValueOfShares) {
                // We must clamp the tracked revenue to prevent the atomic unstaking pool from thinking
                // it has MON available that is still staked shMON.
                assetValueOfShares = _atomicLiquidityAvailable;
            }

            // NOTE: distributedAmount is offset by revenue. First we increase the distributed amount, and then
            // we increase the revenue - this offset is to make sure that we have have MON liquidity for the atomic
            // unstaking pool from these burned shMON shares.

            _atomicCapital.distributedAmount += assetValueOfShares; // +ContraAsset Cr assetValueOfShares
            // Implied: currentAssets += assetValueOfShares // +Asset Dr assetValueOfShares

            // Persist AtomicCapital changes to storage
            s_atomicAssets = _atomicCapital;

            uint120 _amount120 = assetValueOfShares.toUint120();
            validatorRewardsPtr_N(0, _currentValId).earnedRevenue += _amount120;
            globalRevenuePtr_N(0).earnedRevenue += _amount120;
            // This path is still non-staking revenue even though no MON entered the contract, because it comes from
            // burning shares rather than realized staking yield.
            validatorAllocationRevenuePtr_N(0, _currentValId).nonStakingRevenue += _amount120;
            globalAllocationRevenuePtr_N(0).nonStakingRevenue += _amount120;
        } else {
            // CASE: Inactive or placeholder validator
            // Inactive/placeholder share-burn attribution stays in UNKNOWN_VAL_ID only. This preserves active-validator
            // allocation isolation, but intentionally leaves the pooled burn value unsmoothed.

            uint120 _amount120 = assetValueOfShares.toUint120();
            validatorRewardsPtr_N(0, UNKNOWN_VAL_ID).earnedRevenue += _amount120;
            validatorAllocationRevenuePtr_N(0, UNKNOWN_VAL_ID).nonStakingRevenue += _amount120;
        }
    }

    // ================================================== //
    //     Accounting Handlers - Validators / Crank       //
    // ================================================== //

    /// @notice Verifies that expected staking balances match actual staking balances and then handles any discrepancies
    /// @param valId The validator ID in the Monad staking precompile
    /// @param validatorEpochPtrLast Storage pointer to validator's last epoch data
    /// @param monadEpoch Current Monad epoch used to verify source-tracked isolated activation
    /// @return haltedByPrincipalDeficit True when an impossible principal deficit freezes/closes the protocol
    function _handleStakeBalanceVerification(
        uint64 valId,
        Epoch storage validatorEpochPtrLast,
        uint64 monadEpoch
    )
        internal
        returns (bool haltedByPrincipalDeficit)
    {
        // Call the monad staking precompile to get the current balances staked with this validator
        (
            bool _stakeReadSucceeded,
            uint256 _actualActiveStake,
            uint256 _actualPendingDeposits,
            uint64 _deltaEpoch,
            uint64 _nextDeltaEpoch
        ) = _getStakeInfo(valId);

        uint256 _pooledExpectedPendingDeposits;
        uint256 _expectedPendingWithdrawals;
        uint256 _actualPendingWithdrawals;

        // NOTE: Because the shMonad epochs are always at least equal to but could be longer than Monad epochs,
        // we always sum up the pending totals rather than breaking down per epoch and finding a false negative.
        for (int256 i = -4; i < 0; i++) {
            Epoch storage _validatorEpochPtr = validatorEpochPtr_N(i, valId);
            StakingEscrow storage _validatorPendingPtr = validatorPendingPtr_N(i, valId);

            if (_validatorEpochPtr.hasWithdrawal) {
                _expectedPendingWithdrawals += _validatorPendingPtr.pendingUnstaking;
                _actualPendingWithdrawals += _getWithdrawalAmount(valId, _validatorEpochPtr.withdrawalId);
            }

            if (_validatorEpochPtr.hasDeposit) {
                _pooledExpectedPendingDeposits += _validatorPendingPtr.pendingStaking;
            }
        }

        IsolatedValidatorState storage isolatedState = s_isolatedValidatorState[valId];
        if (_stakeReadSucceeded) {
            // Neither source-tracked nor aggregate pending state can be reconciled from the zero values returned by a
            // failed precompile read. Leave local classification unchanged so the later deficit check fails closed.
            _activateProductiveIsolatedPendingStake(valId, monadEpoch, _deltaEpoch, _nextDeltaEpoch);
            _syncIsolatedPendingStake(valId, _actualPendingDeposits);
        }

        if (isolatedState.isolatedWithdrawalPending) {
            _expectedPendingWithdrawals += isolatedState.pendingUnstake;
            _actualPendingWithdrawals += _getWithdrawalAmount(valId, isolatedState.isolatedWithdrawalId);
        }

        // The validator's real precompile position now equals pooled + isolated stake. Surpluses are measured once at
        // that combined level, then split back across the two accounting domains by the same snapshot ratio.
        uint256 _expectedPendingDeposits = _pooledExpectedPendingDeposits + isolatedState.pendingStake;
        uint256 _expectedTotalStake =
            validatorEpochPtrLast.targetStakeAmount + uint256(isolatedState.activeStake) + isolatedState.pendingStake;
        uint256 _actualTotalStake = _actualActiveStake + _actualPendingDeposits;

        // Check the total stake first and emit an event identifying anything unexpected
        if (_actualTotalStake != _expectedTotalStake) {
            emit UnexpectedTotalStakeExpectedIsNotActual(
                valId,
                s_admin.internalEpoch,
                _expectedTotalStake,
                _actualTotalStake,
                _expectedPendingWithdrawals,
                _actualPendingWithdrawals,
                _expectedPendingDeposits,
                _actualPendingDeposits
            );
        }

        // Flag any mismatches between pending withdrawals and actual withdrawals but do not adjust yet - wait until
        // the withdrawal completes.
        if (_expectedPendingWithdrawals != _actualPendingWithdrawals) {
            emit UnexpectedStakeWithdrawalsExpectedIsNotActual(
                valId, s_admin.internalEpoch, _expectedPendingWithdrawals, _actualPendingWithdrawals
            );
        }

        // Track expected deposit mismatches but defer adjustments until the stake is active and finalized.
        if (_expectedPendingDeposits != _actualPendingDeposits) {
            emit UnexpectedPendingStakeExpectedIsNotActual(
                valId, s_admin.internalEpoch, _expectedPendingDeposits, _actualPendingDeposits
            );

            // NOTE: Because multiple Monad epochs can pass during a single ShMonad epoch, it is possible
            // and within expectations for _expectedPendingDeposits to be greater than _pendingDeposits due to
            // the Monad epoch settling what the ShMonad epoch hasn't reached yet. If this is the case, the actual
            // active stake balance should be greater than the expected stake balance by the same amount that the
            // actual pending stake is less than the expected pending stake.
        }

        // If pending deposits alone exceed expected total stake, avoid deriving an invalid active-stake expectation.
        if (_actualPendingDeposits > _expectedTotalStake) {
            emit UnexpectedPendingStakeExceedsExpectedActive(
                valId, s_admin.internalEpoch, _actualPendingDeposits, _expectedTotalStake
            );
            return false;
        }

        // Expected active is calculated with actual pending deposits. Therefore any active mismatch below is already
        // the real total-position mismatch:
        //   actualActive - expectedActive = actualTotal - expectedTotal
        //   expectedActive - actualActive = expectedTotal - actualTotal
        // Do not subtract the pending-deposit mismatch again.
        uint256 _expectedActiveStake = _expectedTotalStake - _actualPendingDeposits;
        if (_expectedActiveStake != _actualActiveStake) {
            emit UnexpectedActiveStakeExpectedIsNotActual(
                valId, s_admin.internalEpoch, _expectedActiveStake, _actualActiveStake
            );

            if (_actualActiveStake > _expectedActiveStake) {
                // Unexpected windfall
                uint256 _delta = _actualActiveStake - _expectedActiveStake;

                (uint256 _pooledDelta, uint256 _isolatedDelta) = _splitIsolatedAndPooledBySnapshot(valId, _delta);

                if (_pooledDelta > 0) {
                    validatorEpochPtrLast.targetStakeAmount += _pooledDelta.toUint128();
                }
                if (_isolatedDelta > 0) {
                    isolatedState.activeStake += _isolatedDelta.toUint120();
                    s_isolatedTotalAssets += _isolatedDelta.toUint128();
                }

                s_globalCapital.stakedAmount += _delta.toUint128(); // +Asset Dr _delta
                // Implied equity += _delta; // +Equity Cr _delta
            } else {
                uint256 _principalDeficit = _expectedTotalStake - _actualTotalStake;
                emit UnexpectedPrincipalStakeDeficit(
                    valId, s_admin.internalEpoch, _expectedTotalStake, _actualTotalStake, _principalDeficit
                );
                // Principal deficits are impossible under current Monad staking assumptions. Freeze/close without
                // writing down stake accounting; the caller stops cranking without reverting this state change.
                globalEpochPtr_N(0).frozen = true;
                globalEpochPtr_N(0).closed = true;
                return true;
            }
        }
        return false;
    }

    /// @notice Handles accounting of the initiation of increased stake allocation with a validator
    /// @param amount The amount to allocate
    function _handleInitiateIncreasedAllocation(uint64 valId, uint120 amount) internal {
        // Method called before calling the validator

        // NOTE: This is called after any handleComplete_Allocation methods
        // Push forward but don't rotate the withdrawal ID

        // Update the target amount and flag as not having a withdrawal
        Epoch storage validatorEpochPtr = validatorEpochPtr_N(0, valId);
        (uint64 monadEpoch, bool inEpochDelayPeriod) = _getEpochInfo();
        validatorEpochPtr.hasDeposit = true;
        validatorEpochPtr.hasWithdrawal = false;
        validatorEpochPtr.crankedInBoundaryPeriod = inEpochDelayPeriod;

        // Initiate ShMonad MON -> Validator
        validatorPendingPtr_N(0, valId).pendingStaking += amount;
        // Delay-period delegations enter the active set one epoch later than ordinary delegations.
        s_pooledDepositActivationEpochs[valId][N(0)] = monadEpoch + (inEpochDelayPeriod ? 2 : 1);
        s_globalPending.pendingStaking += amount;
        s_globalCapital.stakedAmount += amount; // +Asset Dr amount
        // Implied currentAssets -= amount; // -Asset Cr amount
    }

    /// @notice Handles accounting of the completion of increased stake allocation with a validator
    /// @param validatorEpochPtr Storage pointer to validator epoch data
    /// @param validatorPendingPtr Storage pointer to validator pending data
    function _handleCompleteIncreasedAllocation(
        Epoch storage validatorEpochPtr,
        StakingEscrow storage validatorPendingPtr
    )
        internal
    {
        // Complete ShMonad MON -> Validator
        // validatorPendingPtr_N(-2, coinbase).pendingStaking -= amount;
        validatorEpochPtr.hasDeposit = false;
        uint120 _amount = validatorPendingPtr.pendingStaking;
        s_globalPending.pendingStaking -= _amount;
    }

    /// @notice Handles initiation of decreased stake allocation for a validator
    /// @param amount The amount to deallocate
    function _handleInitiateDecreasedAllocation(uint64 valId, uint120 amount) internal {
        // Method called before calling the validator

        // Flag as having a withdrawal
        // NOTE: This is after any handleComplete_Allocation methods
        validatorEpochPtr_N(0, valId).hasWithdrawal = true;
        validatorEpochPtr_N(0, valId).hasDeposit = false;
        validatorEpochPtr_N(0, valId).crankedInBoundaryPeriod = _inEpochDelayPeriod();

        // Initiate Validator MON -> ShMonad
        validatorPendingPtr_N(0, valId).pendingUnstaking += amount;
        s_globalPending.pendingUnstaking += amount;
    }

    /// @notice Handles accounting of the completion of decreased stake allocation with a validator
    /// @param validatorEpochPtr Storage pointer to validator epoch data
    /// @param validatorPendingPtr Storage pointer to validator pending data
    /// @param amount The amount that was deallocated
    function _handleCompleteDecreasedAllocation(
        uint64 valId,
        Epoch storage validatorEpochPtr,
        StakingEscrow storage validatorPendingPtr,
        uint120 amount
    )
        internal
        returns (bool settled)
    {
        // Complete Validator MON -> ShMonad
        // NOTE: Global has been cranked already. Validator is in the process of being cranked
        // but the validator storage has not yet been shifted forwards. Therefore,
        // Global_LastLast corresponds with Validator_Last
        uint120 _expectedAmount = validatorPendingPtr.pendingUnstaking;

        if (amount < _expectedAmount) {
            emit UnexpectedPooledWithdrawalDeficit(valId, s_admin.internalEpoch, _expectedAmount, amount);
            globalEpochPtr_N(0).frozen = true;
            globalEpochPtr_N(0).closed = true;
            return false;
        }

        CurrentLiabilities memory _globalLiabilities = s_globalLiabilities;
        uint256 _reservedAssets = s_globalCapital.reservedAmount;
        uint256 _backedRedemptionsBefore = QueueLib.backedRedemptions(
            _reservedAssets,
            s_globalPending.pendingUnstaking,
            _globalLiabilities.rewardsPayable,
            _globalLiabilities.redemptionsPayable
        );

        // Adjust globals with the expected amount
        s_globalPending.pendingUnstaking -= _expectedAmount;

        // Implied currentAssets += _expectedAmount; // +Asset Dr _expectedAmount
        s_globalCapital.stakedAmount -= _expectedAmount; // -Asset Cr _expectedAmount

        // Mark withdrawal as complete
        validatorEpochPtr.hasWithdrawal = false;

        uint120 _surplus;

        // NOTE: On Monad, a delegator's undelegated balance can continue to accrue rewards during the withdrawal
        // period. This often means `amount` received here exceeds `_expectedAmount`, and we intentionally treat
        // that excess as additional staking yield for the validator below.
        // Reconcile the difference between expected and actual amount received.
        if (amount > _expectedAmount) {
            // CASE: Received more than expected
            _surplus = amount - _expectedAmount;

            // Implied currentAssets += _surplus // +Asset Dr _surplus
            // Implied equity += _surplus // +Equity Cr _surplus

            // Update global target w/ the surplus then correct the unstaking journal entry
            validatorPendingPtr.pendingUnstaking += _surplus;

            // The withdrawal request is pooled, so its surplus must not be split with isolated stake.
            _handlePooledWithdrawalSurplus(valId, _surplus);

            // Global accounting entries:
            // Implied currentAssets += _surplus; // +Asset Dr _expectedAmount
            // Implied equity += _surplus // +Equity Cr _surplus
        }

        // Assign the unstaking funds to the 'reservedAssets' account if it does not
        // currently have enough to cover the liabilities
        uint256 _currentLiabilities = _globalLiabilities.currentLiabilities();

        uint256 _reserveShortfall = _currentLiabilities > _reservedAssets ? _currentLiabilities - _reservedAssets : 0;
        uint120 _reserveIncrease = Math.min(_reserveShortfall, uint256(amount)).toUint120();
        uint120 _principalReserveIncrease = Math.min(_reserveIncrease, _expectedAmount).toUint120();
        uint120 _surplusReserveIncrease = _reserveIncrease - _principalReserveIncrease;

        if (_reserveIncrease > 0) {
            // The full native receipt is available to reserves. Any revenue consumed here must be earmarked so the
            // atomic-liquidity adjustment cannot expose the same MON to a newer exiter.
            _allocateCurrentEpochRevenue(_surplusReserveIncrease);
            s_globalCapital.reservedAmount += _reserveIncrease; // +Asset Dr _reserveIncrease
            // Implied: currentAssets -= _reserveIncrease; // -Asset Cr _reserveIncrease
        }

        uint256 _backedRedemptionsAfter = QueueLib.backedRedemptions(
            _reservedAssets + _reserveIncrease,
            s_globalPending.pendingUnstaking,
            _globalLiabilities.rewardsPayable,
            _globalLiabilities.redemptionsPayable
        );
        if (_backedRedemptionsAfter > _backedRedemptionsBefore) {
            CashFlows storage _cashFlows = globalCashFlowsPtr_N(0);
            uint120 _nonTurnoverQueueForUnstake = _cashFlows.queueForUnstake - turnoverQueuePtr_N(0).queueForUnstake;
            uint120 _queueReduction =
                Math.min(_backedRedemptionsAfter - _backedRedemptionsBefore, _nonTurnoverQueueForUnstake).toUint120();

            // Only live non-turnover demand is replaced by the new redemption backing. The active allocation
            // snapshot and turnover demand remain unchanged.
            if (_queueReduction > 0) _cashFlows.queueForUnstake -= _queueReduction;
        }

        // Preserve the existing atomic refill behavior for returned principal. Surplus remains staking yield: only
        // the gross portion not needed by reserves joins the stake queue.
        uint120 _principalToRoute = _expectedAmount - _principalReserveIncrease;
        uint120 _surplusToStake = _surplus - _surplusReserveIncrease;
        uint120 _principalToStake = _subtractNetToAtomicLiquidity(_principalToRoute).toUint120();
        globalCashFlowsPtr_N(0).queueToStake += _principalToStake + _surplusToStake;
        settled = true;
    }

    /// @notice Directs a portion of net cash inflows to replenish the liquidity in the atomic unstaking pool
    /// @param debitAmount The amount of new MON
    /// @return remainingDebitAmount The net amount of new MON after subtracting the portion allocated to atomic
    /// unstaking
    function _subtractNetToAtomicLiquidity(uint256 debitAmount) internal returns (uint256 remainingDebitAmount) {
        uint256 _distributedAmount = s_atomicAssets.distributedAmount;
        uint256 _netAmountToAtomicLiquidity = debitAmount * _scaledTargetLiquidityPercentage() / SCALE;

        if (_netAmountToAtomicLiquidity > _distributedAmount) _netAmountToAtomicLiquidity = _distributedAmount;

        s_atomicAssets.distributedAmount -= _netAmountToAtomicLiquidity.toUint128(); // -ContraAsset Dr
        // _netAmountToAtomicLiquidity
        // Implied: currentAssets -= _netAmountToAtomicLiquidity // -Asset Cr _netAmountToAtomicLiquidity

        return debitAmount - _netAmountToAtomicLiquidity;
    }

    /// @notice Handles accounting of earned (realized and received) staking yield for a validator
    /// @param valId The validator's ID
    /// @param amount The earned yield amount
    function _handleEarnedStakingYield(uint64 valId, uint120 amount) internal {
        // Implied currentAssets += _surplus; // +Asset Dr amount
        // Implied equity += _surplus // +Equity Cr amount

        uint120 _grossStakingCommission;
        (amount, _grossStakingCommission) = _chargeStakingCommission(amount);
        (uint256 pooledAmount, uint256 isolatedAmount) =
            _splitStakingYieldByProductiveSnapshot(valId, amount, validatorEpochPtr_N(-1, valId).targetStakeAmount);

        // Keep legacy earnedRevenue intact for existing accounting and share math, while the new split buckets carry
        // the weighted signal used by stake allocation.
        // Validator MON -> ShMonad
        validatorRewardsPtr_N(0, valId).earnedRevenue += pooledAmount.toUint120();
        _recordStakingYieldAllocationSignal(valId, _allocationSignalAmount(pooledAmount, isolatedAmount));

        // Validator is being cranked.
        globalRevenuePtr_N(0).earnedRevenue += pooledAmount.toUint120();
        _creditIsolatedRewards(valId, isolatedAmount.toUint120(), isolatedAmount.toUint120(), 0);

        // Queue the rewards to be staked
        // NOTE: We cannot send a portion to the atomic unstaking pool because it would potentially break the invariant
        // "earnedRevenue >= queueToStake"
        globalCashFlowsPtr_N(0).queueToStake += (pooledAmount + _grossStakingCommission).toUint120();
    }

    function _recordStakingYieldAllocationSignal(uint64 valId, uint120 allocationSignalAmount) internal {
        if (allocationSignalAmount == 0) return;

        validatorAllocationRevenuePtr_N(0, valId).stakingYield += allocationSignalAmount;

        // Keep the live global allocation view current between cranks. Adjusted scoring does not trust this
        // accumulator directly: the allocation prepass re-filters both staking-yield windows to the active validator
        // set before validators read them.
        if (s_validatorData[valId].isActive) {
            globalAllocationRevenuePtr_N(0).stakingYield += allocationSignalAmount;
        }
    }

    /// @notice Handles accounting of successful payment / transfer of escrowed MEV rewards to a validator
    /// @param valId The validator's ID
    /// @param amount The amount successfully paid
    function _handleRewardsPaidSuccess(uint64 valId, uint120 amount) internal {
        if (amount == 0) return;

        // ShMonad MON -> Validator
        // Validator cranks can be retried after fail-stop balance checks, so successful settlement must consume
        // the historical local payable bucket as well as the global reserve/liability entries.
        validatorRewardsPtr_N(-1, valId).rewardsPayable -= amount;
        s_globalCapital.reservedAmount -= amount; // -Asset Cr amount
        s_globalLiabilities.rewardsPayable -= amount; // -Liability Dr amount
    }

    /// @notice Handles accounting of failed payment / transfer of escrowed MEV rewards to a validator
    /// @param valId The validator's ID
    /// @param amount The amount that failed to be paid
    function _handleRewardsPaidFail(uint64 valId, uint120 amount) internal {
        // ShMonad MON -> Validator
        // Shift epoch from last to current
        validatorRewardsPtr_N(-1, valId).rewardsPayable -= amount;
        validatorRewardsPtr_N(0, valId).rewardsPayable += amount;
    }

    /// @notice Handles accounting of rewards redirection when validator payment fails due to ineligibility
    /// @param valId The validator's ID
    /// @param amount The amount to redirect
    function _handleRewardsRedirect(uint64 valId, uint120 amount) internal {
        if (amount == 0) return;

        // ShMonad MON -> ShMonad MON
        // Remove it as rewards / reserved amount and queue it to stake
        // Keep validator-local history aligned so retryable validator cranks do not redirect the same rewards again.
        validatorRewardsPtr_N(-1, valId).rewardsPayable -= amount;
        s_globalCapital.reservedAmount -= amount; // -Asset Cr amount
        s_globalLiabilities.rewardsPayable -= amount; // -Liability Dr amount

        // The released escrow is now pooled shMON yield. Record it as current revenue so short-lived exits are
        // smoothed the same way as other newly-realized reward value.
        globalRevenuePtr_N(0).earnedRevenue += amount;
        globalCashFlowsPtr_N(0).queueToStake += amount;
    }

    /// @notice Reconciles atomic pool allocation/utilization with current state during global crank.
    /// @dev Preserves utilization continuity across cranks by proportionally adjusting `distributedAmount`
    /// and `allocatedAmount` to the new target, then books their effects into stake/unstake queues.
    /// Note: When atomic pool rebalancing frees liquidity (allocatedAmount decreases or
    /// distributedAmount increases), this function now first reserves that liquidity for any uncovered
    /// liabilities (rewardsPayable + redemptionsPayable) before routing it to the staking queue.
    /// This prevents the scenario where freed atomic liquidity bypasses liability coverage and gets
    /// routed into staking, potentially leaving redemptions unfulfillable and MON permanently staked.
    function _settleGlobalNetMONAgainstAtomicUnstaking() internal {
        // Called during the Global crank
        // Get the current utilization rate - we want to make sure the utilization doesn't jump due to being cranked
        (uint128 _oldUtilizedAmount, uint128 _oldAllocatedAmount) = _getAdjustedAmountsForAtomicUnstaking();

        // Handle any overflow that may have been created by updating the targetLiquidityPercent to a smaller
        // percentage of total and potentially overflowing the atomic liquidity pool. Get the new allocated and
        // utilized amounts
        (, uint128 _newAllocatedAmount) = _checkSetNewAtomicLiquidityTarget(_oldAllocatedAmount);

        // Calculate the utilized numbers. Avoid div by zero
        // Keep utilization ratio constant relative to allocation size.
        uint256 _utilizedFraction =
            _oldAllocatedAmount > 0 ? _scaledPercentFromAmounts(_oldUtilizedAmount, _oldAllocatedAmount) : 0;
        uint128 _newUtilizedAmount = _amountFromScaledPercent(_newAllocatedAmount, _utilizedFraction).toUint128();

        // Calculate the deltas
        uint120 _allocatedAmountDelta = Math.dist(_oldAllocatedAmount, _newAllocatedAmount).toUint120();
        uint120 _utilizedAmountDelta = Math.dist(_oldUtilizedAmount, _newUtilizedAmount).toUint120();

        // NOTE: This occurs during the global crank right before the shift of globalCashFlowsPtr_N(0) ->
        // globalCashFlowsPtr_N(-1). Track the adjustments we need to make to the amount being staked.
        uint120 _stakeIn;
        uint120 _unstakeOut;

        if (_newAllocatedAmount > _oldAllocatedAmount) {
            // CASE: We are increasing the atomic unstaking pool's liquidity and therefore decreasing the amount
            // that will be staked next epoch.
            _unstakeOut += _allocatedAmountDelta;
            s_atomicAssets.allocatedAmount += _allocatedAmountDelta;
            // Implied: currentAssets -= _allocatedAmountDelta;
        } else {
            // CASE: We are decreasing the atomic unstaking pool's liquidity and therefore increasing the amount
            // that will be staked next epoch.
            _stakeIn += _allocatedAmountDelta;
            s_atomicAssets.allocatedAmount -= _allocatedAmountDelta; // -Asset Cr _allocatedAmountDelta
            // Implied: currentAssets += _allocatedAmountDelta; // +Asset Dr _allocatedAmountDelta
        }

        // Avoid overflow / underflow - we can't assume that allocatedAmountDelta and utilizedAmountDelta
        // are moving in the same direction
        if (_newUtilizedAmount > _oldUtilizedAmount) {
            // CASE: We are decreasing the atomic unstaking pool's liquidity by increasing the amount
            // we treat as having already been distributed
            _stakeIn += _utilizedAmountDelta;
            s_atomicAssets.distributedAmount += _utilizedAmountDelta; // Contra Asset Cr +_utilizedAmountDelta
            // Implied: currentAssets += _utilizedAmountDelta; // +Asset Dr _utilizedAmountDelta
        } else {
            // CASE: We are increasing the atomic unstaking pool's liquidity by decreasing the amount
            // we treat as having already been distributed
            _unstakeOut += _utilizedAmountDelta;
            s_atomicAssets.distributedAmount -= _utilizedAmountDelta; // -Contra_Asset Dr _utilizedAmountDelta
            // Implied: currentAssets -= _utilizedAmountDelta; // -Asset Cr _utilizedAmountDelta
        }

        // Apply the adjustments to the assets that will be staked next epoch
        // NOTE: we try to offset debits against credits and vice versa when possible because
        // this will reduce the net turnover and therefore the amount of 'unproductive' assets
        CashFlows memory _globalCashFlows = globalCashFlowsPtr_N(0);
        uint120 _currentTurnoverQueueForUnstake = turnoverQueuePtr_N(0).queueForUnstake;

        // CASE: stake delta is positive - we need to stake more unstaked assets
        if (_stakeIn > _unstakeOut) {
            uint120 _netStakeIn = _stakeIn - _unstakeOut;

            // Before routing freed liquidity to staking queue, use it to cover liabilities that are not already
            // backed by reserves or in-flight unstaking.
            CurrentLiabilities memory _globalLiabilities = s_globalLiabilities;
            uint256 _currentLiabilities = _globalLiabilities.currentLiabilities();
            uint256 _reservedAssets = s_globalCapital.reservedAmount;
            uint256 _pendingUnstaking = s_globalPending.pendingUnstaking;
            if (_currentLiabilities > _reservedAssets + _pendingUnstaking) {
                uint256 _uncoveredLiabilities = _currentLiabilities - _reservedAssets - _pendingUnstaking;
                uint120 _toReserves = _uncoveredLiabilities > _netStakeIn ? _netStakeIn : uint120(_uncoveredLiabilities);

                uint256 _backedRedemptionsBefore = QueueLib.backedRedemptions(
                    _reservedAssets,
                    _pendingUnstaking,
                    _globalLiabilities.rewardsPayable,
                    _globalLiabilities.redemptionsPayable
                );

                // Freed atomic liquidity is not source-tagged. If current revenue is still unallocated, treat that
                // revenue as consumed first so the carryover step cannot also use it to release atomic liquidity.
                _allocateCurrentEpochRevenue(_toReserves);

                s_globalCapital.reservedAmount += _toReserves;
                // Implied: currentAssets -= _toReserves

                _netStakeIn -= _toReserves;

                // Only the reserve increase that newly backs redemptions has a matching validator unstake queue to
                // cancel. Reserve increases absorbed by rewardsPayable must leave the unstake queue untouched.
                uint256 _backedRedemptionsAfter = QueueLib.backedRedemptions(
                    _reservedAssets + _toReserves,
                    _pendingUnstaking,
                    _globalLiabilities.rewardsPayable,
                    _globalLiabilities.redemptionsPayable
                );
                uint256 _newlyBackedRedemptions = _backedRedemptionsAfter - _backedRedemptionsBefore;
                if (_newlyBackedRedemptions > 0) {
                    uint256 _redemptionQueueReduction =
                        Math.min(_newlyBackedRedemptions, uint256(_globalCashFlows.queueForUnstake));
                    if (_redemptionQueueReduction > 0) {
                        // Redemption coverage consumes the user-facing queue before any turnover budget.
                        (_globalCashFlows.queueForUnstake, _currentTurnoverQueueForUnstake,) =
                            QueueLib.reducePreferNonTurnover(
                                _globalCashFlows.queueForUnstake,
                                _currentTurnoverQueueForUnstake,
                                _redemptionQueueReduction
                            );
                    }
                }
            }

            // Continue with remaining _netStakeIn (may be 0 if all went to reserves)
            if (_netStakeIn > 0) {
                uint120 _currentQueueForUnstake = _globalCashFlows.queueForUnstake;

                // First try to net the net stake in against the queueForUnstake
                if (_netStakeIn > _currentQueueForUnstake) {
                    _globalCashFlows.queueForUnstake = 0;
                    _currentTurnoverQueueForUnstake = 0;
                    _globalCashFlows.queueToStake += (_netStakeIn - _currentQueueForUnstake);
                } else {
                    // Freed atomic liquidity substitutes for ordinary validator withdrawals first. Preserve turnover
                    // where possible so the remaining executable queue keeps its allocation-rebalancing pressure.
                    (_globalCashFlows.queueForUnstake, _currentTurnoverQueueForUnstake,) =
                        QueueLib.reducePreferNonTurnover(
                            _currentQueueForUnstake, _currentTurnoverQueueForUnstake, _netStakeIn
                        );
                }
            }

            // CASE: stake delta is negative - we need to unstake more staked assets.
        } else {
            uint120 _netUnstakeOut = _unstakeOut - _stakeIn;
            uint120 _currentQueueToStake = _globalCashFlows.queueToStake;
            uint256 _queueConsumedByAtomicAllocation = Math.min(_netUnstakeOut, _currentQueueToStake);
            // Target increases consume untagged stake-queue MON. Earmark current-epoch revenue first so the later
            // carryover step cannot use that same MON again by reducing distributedAmount.
            _allocateCurrentEpochRevenue(_queueConsumedByAtomicAllocation);

            // First try to net the net unstake out against the queueToStake
            if (_netUnstakeOut > _currentQueueToStake) {
                uint120 _netUnavailableAssets = _netUnstakeOut - _currentQueueToStake;

                _globalCashFlows.queueToStake -= _currentQueueToStake; // = 0
                _globalCashFlows.queueForUnstake += _netUnavailableAssets;

                emit UnexpectedAtomicSettlementUnavailableAssets(
                    s_admin.internalEpoch,
                    _netUnavailableAssets,
                    _stakeIn,
                    _unstakeOut,
                    _globalCashFlows.queueToStake,
                    _globalCashFlows.queueForUnstake,
                    s_atomicAssets.distributedAmount,
                    s_atomicAssets.allocatedAmount,
                    uint256(s_atomicAssets.allocatedAmount) - uint256(_netUnavailableAssets)
                );

                // The _netUnavailableAssets take time to unstake and are not currently
                // usable for atomic unstaking, so for now we decrease the allocated amount
                // _netUnavailableAssets is bounded by the atomic rebalance deltas calculated above, so this
                // allocation decrease cannot underflow. Raw distributedAmount may temporarily exceed allocatedAmount
                // after atomic fees are booked as smoothed revenue; liquidity views handle that by capping adjusted
                // utilization.
                s_atomicAssets.allocatedAmount -= uint256(_netUnavailableAssets).toUint128();
            } else {
                _globalCashFlows.queueToStake -= _netUnstakeOut;
            }
        }

        _setStakingQueueStorage(globalCashFlowsPtr_N(0), _globalCashFlows);
        _setCurrentTurnoverQueueForUnstake(_currentTurnoverQueueForUnstake, _globalCashFlows.queueForUnstake);
    }

    // ================================================== //
    // Accounting Handlers - User Withdrawals + Deposits  //
    // ================================================== //

    /// @notice Handles accounting for user withdrawals from atomic unstaking pool
    /// @param netAmount The withdrawal amount (net of fee)
    /// @param fee The fee amount
    function _accountForWithdraw(uint256 netAmount, uint256 fee) internal override {
        uint256 _allocatedAmount = s_atomicAssets.allocatedAmount;
        uint256 _distributedAmount = s_atomicAssets.distributedAmount;
        uint256 _availableAtomicLiquidity =
            _allocatedAmount > _distributedAmount ? _allocatedAmount - _distributedAmount : 0;

        // Only the net MON paid out consumes atomic liquidity. The retained fee is booked below as
        // current-epoch revenue, with a matching raw distributedAmount entry so adjusted utilization is unchanged.
        // NOTE: In most cases the slot is already hot because of _getAdjustedAmountsForAtomicUnstaking()
        if (_distributedAmount + netAmount > _allocatedAmount) {
            Revenue storage _globalRevenuePtr = globalRevenuePtr_N(0);
            uint256 _maxEarnedRevenueOffset = _globalRevenuePtr.earnedRevenue - _globalRevenuePtr.allocatedRevenue;

            require(
                _distributedAmount + netAmount <= _allocatedAmount + _maxEarnedRevenueOffset,
                InsufficientBalanceAtomicUnstakingPool(netAmount + fee, _availableAtomicLiquidity)
            );

            // Offset directly with a credit entry, initiating the unstaking process
            uint120 _shortfallAmount = (_distributedAmount + netAmount - _allocatedAmount).toUint120();
            globalCashFlowsPtr_N(0).queueForUnstake += _shortfallAmount;
            _allocateCurrentEpochRevenue(_shortfallAmount);

            // Global Accounting entries
            s_atomicAssets.allocatedAmount += _shortfallAmount; // +Asset Dr _shortfallAmount
            // Implied: currentAssets -= _shortfallAmount -Asset Cr _shortfallAmount
        }

        if (fee > 0) {
            uint120 _fee = fee.toUint120();
            globalRevenuePtr_N(0).earnedRevenue += _fee;

            // Only the portion backed by remaining raw atomic liquidity is liquid MON ready to stake.
            // The rest is still smoothed as revenue, but stays out of cash-flow queues until crank accounting realizes
            // it.
            if (_availableAtomicLiquidity > netAmount) {
                uint256 _liquidFee = Math.min(fee, _availableAtomicLiquidity - netAmount);
                globalCashFlowsPtr_N(0).queueToStake += _liquidFee.toUint120();
            }
        }

        s_atomicAssets.distributedAmount += (netAmount + fee).toUint128();
    }

    /// @notice Handles accounting for user deposits
    /// @param assets The deposit amount
    function _accountForDeposit(uint256 assets) internal virtual override {
        uint256 _currentLiabilities = s_globalLiabilities.currentLiabilities();
        uint256 _reservedAssets = s_globalCapital.reservedAmount;
        uint256 _pendingUnstaking = s_globalPending.pendingUnstaking;

        // NOTE: We include current assets in the calculation of uncovered liabilities because this happens
        // in between cranks and net new deposits accrue to currentAssets prior to being cranked. Because
        // this is a deposit, we must adjust for msg.value
        uint256 _currentAssets = _pooledCurrentAssets(address(this).balance - msg.value);

        // Only send assets in excess of uncovered liabilities to atomic liquidity pool

        // NOTE: We include _currentAssets in this check because those funds will also help cover
        // liabilities during the crank. However, _uncoveredLiabilities below does NOT subtract
        // _currentAssets because those are separate funds that will be applied independently.
        // This means multiple deposits before a crank may collectively over-contribute to liability
        // coverage, but this is conservative/safe behavior - excess just goes to staking.
        if (_currentLiabilities > _reservedAssets + _pendingUnstaking + _currentAssets) {
            // CASE: Some or all of the assets are needed to cover the liabilities
            uint256 _uncoveredLiabilities = _currentLiabilities - (_reservedAssets + _pendingUnstaking);
            if (assets > _uncoveredLiabilities) {
                uint256 _surplus = assets - _uncoveredLiabilities;

                // Send a portion of the surplus to atomic liquidity, then readd the uncovered liabilities
                // to get the assets that need to be queued to stake.
                assets = _uncoveredLiabilities + _subtractNetToAtomicLiquidity(_surplus);
            }
        } else {
            // CASE: None of the assets are needed to cover liabilities
            assets = _subtractNetToAtomicLiquidity(assets);
        }

        // Queue up the necessary staking cranks with the debit entry
        globalCashFlowsPtr_N(0).queueToStake += assets.toUint120();

        // Implied: currentAssets += assets; // +Asset Dr assets
        // Implied: equity += assets; // +Equity Cr assets
    }

    /// @notice Handles accounting after unstake request is made
    /// @param amount The unstake request amount
    function _afterRequestUnstake(uint256 amount) internal virtual override {
        // Queue up the recording unstaking activity, if necessary
        uint120 _amount = amount.toUint120();
        s_globalLiabilities.redemptionsPayable += _amount; // +Liability Cr amount
        // Implied: equity -= amount; // -Equity Dr amount

        // In extreme drawdown scenarios, clamp the allocated amount at remaining equity (excluding recent revenue)
        AtomicCapital memory _atomicAssets = s_atomicAssets;
        uint256 _allocatedAmount = _atomicAssets.allocatedAmount;
        uint256 _remainingEquity =
            s_globalCapital.totalEquity(s_globalLiabilities, s_admin, address(this).balance, s_isolatedTotalAssets);
        uint256 _recentRevenue = _recentRevenueOffset();

        // NOTE: The atomic unstaking pool is vulnerable to "sandwich" attacks if shMonad has a single large depositor
        // who times their unstakes. To counter this, we optimistically reduce utilized and allocated values and at the
        // cost of receiving reduced atomic unstaking fees for that epoch.
        if (_allocatedAmount + _recentRevenue + amount > _remainingEquity) {
            _atomicAssets.allocatedAmount = _atomicAssets.allocatedAmount > _atomicAssets.distributedAmount
                ? _atomicAssets.allocatedAmount - _atomicAssets.distributedAmount
                : 0; // -Asset Cr distributedAmount, capped at available allocation
            _atomicAssets.distributedAmount = 0; // -ContraAsset Dr distributedAmount
            s_atomicAssets = _atomicAssets;
        }

        globalCashFlowsPtr_N(0).queueForUnstake += amount.toUint120();
    }

    /// @notice Handles accounting of completion of unstake request
    /// @param amount The unstake completion amount
    /// @dev The reservedAmount may include funds earmarked for validator rewards (rewardsPayable). We must not let
    /// redemptions drain those funds, otherwise validator reward payments would underflow. We calculate
    /// reservedForRedemptions by excluding rewardsPayable, and only use atomic liquidity to cover any shortfall beyond
    /// that protected amount.
    function _beforeCompleteUnstake(uint128 amount) internal virtual override {
        uint128 rewardsPayable = s_globalLiabilities.rewardsPayable;
        uint128 reservedAmount = s_globalCapital.reservedAmount;

        // Protect validator rewards from being drained by redemptions.
        // The reservedAmount covers both rewardsPayable and redemptionsPayable.
        // Only the portion exceeding rewardsPayable is available for redemptions.
        uint128 reservedForRedemptions = reservedAmount > rewardsPayable ? reservedAmount - rewardsPayable : 0;

        if (reservedForRedemptions < amount) {
            // CASE: Reserved capital available for redemptions is insufficient; pull the shortfall
            // from atomic liquidity. This preserves the validator rewards portion of reserves.
            uint128 _amountNeededFromAtomicLiquidity = amount - reservedForRedemptions;

            AtomicCapital memory _atomicAssets = s_atomicAssets;
            uint128 _atomicAllocatedAmount = _atomicAssets.allocatedAmount;
            uint128 _atomicUtilizedAmount = _atomicAssets.distributedAmount;

            // The unutilized liquidity in the atomic unstaking pool must be enough to cover the required amount
            require(
                _atomicAllocatedAmount - Math.min(_atomicUtilizedAmount, _atomicAllocatedAmount)
                    >= _amountNeededFromAtomicLiquidity,
                InsufficientReservedLiquidity(amount, reservedForRedemptions)
            );

            // Take the shortfall from the atomic liquidity pool by crediting the allocated asset,
            // offset by debiting the reserved amount.
            s_atomicAssets.allocatedAmount -= _amountNeededFromAtomicLiquidity; // -Asset Cr
            // _amountNeededFromAtomicLiquidity
            s_globalCapital.reservedAmount += _amountNeededFromAtomicLiquidity; // +Asset Dr
            // _amountNeededFromAtomicLiquidity;
        }

        // Reduce the reserved amount and the liability by the amount withdrawn
        s_globalCapital.reservedAmount -= amount; // -Asset Cr amount
        s_globalLiabilities.redemptionsPayable -= amount; // -Liability Dr amount
    }

    function _depositIsolated(
        address caller,
        uint64 validatorId,
        uint256 assets,
        address receiver
    )
        internal
        returns (uint256 vShares)
    {
        require(receiver != address(0), ZeroAddress());
        require(msg.value == assets, IncorrectNativeTokenAmountSent());
        require(assets >= MIN_VALIDATOR_DEPOSIT, IsolatedDepositBelowMinimum(assets, MIN_VALIDATOR_DEPOSIT));
        require(
            s_validatorIsActive[validatorId] && s_validatorData[validatorId].isActive,
            IsolatedValidatorNotActive(validatorId)
        );
        IsolatedValidatorState storage state = s_isolatedValidatorState[validatorId];
        // Newly added validators skip their first historical crank. Wait for the first completed snapshot roll so a
        // legitimate zero snapshot cannot be confused with missing state after this deposit changes live balances.
        require(state.snapshotsInitialized, IsolatedValidatorSnapshotNotReady(validatorId));

        _sweepOrphanedIsolatedIdleAssets(validatorId, state);

        if (s_isolatedVTotalShares[validatorId] == 0) {
            // A burned share supply can still have principal in native settlement. Keep the next owner cohort out until
            // every validator-local asset and liability from the previous cohort has cleared.
            require(!_hasResidualIsolatedState(validatorId), IsolatedSettlementInProgress(validatorId));
        }

        vShares = _convertToIsolatedShares(validatorId, assets);
        // Extreme equity-to-share ratios can floor a live owner's deposit quote to zero. Do not accept new MON unless
        // the receiver gets an enforceable validator-specific claim.
        require(vShares != 0, IsolatedDepositWouldMintZeroShares(validatorId, assets));

        (uint64 monadEpoch, bool inEpochDelayPeriod) = _getEpochInfo();
        _refreshProductiveIsolatedPendingStake(validatorId, monadEpoch);

        (bool success, uint128 actualAmount) = _initiateStaking(validatorId, assets.toUint128());
        require(success && actualAmount == assets, IsolatedStakeInitiationFailed(validatorId, assets, actualAmount));

        s_isolatedVShareBalances[receiver][validatorId] += vShares;
        s_isolatedVTotalShares[validatorId] += vShares;

        _recordIsolatedPendingStake(validatorId, assets.toUint120(), monadEpoch, inEpochDelayPeriod);
        s_isolatedTotalAssets += assets.toUint128();
        s_globalCapital.stakedAmount += assets.toUint128();

        emit DepositIsolated(validatorId, caller, receiver, assets, vShares);
    }

    function _calcIsolatedUnstakeRequestCompletionEpoch(uint64 validatorId)
        internal
        view
        returns (uint64 completionEpoch)
    {
        IsolatedValidatorState memory state = s_isolatedValidatorState[validatorId];
        uint64 currentInternalEpoch = s_admin.internalEpoch;

        if (state.redemptionsPayable <= state.idleAssets) {
            return currentInternalEpoch;
        }

        completionEpoch = currentInternalEpoch + STAKING_WITHDRAWAL_DELAY + 4;
        // queuedUnstake only schedules withdrawal work against active or pending stake; it is not additional coverage.
        uint256 baseWindowCoverage = uint256(state.idleAssets) + state.pendingUnstake + state.activeStake;
        if (state.redemptionsPayable > baseWindowCoverage) {
            completionEpoch += 2;
        }
    }

    function _requestUnstakeIsolated(
        address account,
        uint64 validatorId,
        uint256 vShares
    )
        internal
        returns (uint64 completionEpoch)
    {
        require(vShares != 0, CannotUnstakeZeroShares());

        uint256 availableShares = s_isolatedVShareBalances[account][validatorId];
        require(vShares <= availableShares, InsufficientIsolatedShares(validatorId, account, availableShares, vShares));

        uint256 amountMon = _convertToIsolatedAssets(validatorId, vShares);
        require(amountMon != 0, InsufficientIsolatedShares(validatorId, account, availableShares, vShares));

        uint256 remainingShares = availableShares - vShares;
        s_isolatedVShareBalances[account][validatorId] = remainingShares;
        s_isolatedVTotalShares[validatorId] -= vShares;

        IsolatedValidatorState storage state = s_isolatedValidatorState[validatorId];
        uint120 amountMon120 = amountMon.toUint120();
        state.redemptionsPayable += amountMon120;

        // Sub-minimum leftovers can become native staking dust during validator withdrawals.
        // Require users to exit fully instead of preserving a residual isolated position.
        if (remainingShares != 0) {
            uint256 remainingAssets = _convertToIsolatedAssets(validatorId, remainingShares);
            require(
                remainingAssets >= MIN_VALIDATOR_DEPOSIT,
                IsolatedRemainderBelowMinimum(validatorId, account, remainingAssets, MIN_VALIDATOR_DEPOSIT)
            );
        }

        _reserveQueuedIsolatedLiquidityForRedemptions(validatorId);
        // Quote against actual validator assets before adding any scheduling-only queued unstake amount.
        completionEpoch = _calcIsolatedUnstakeRequestCompletionEpoch(validatorId);

        uint256 coveredAmount = uint256(state.idleAssets) + state.pendingUnstake + state.queuedUnstake;
        if (coveredAmount < state.redemptionsPayable) {
            state.queuedUnstake += (state.redemptionsPayable - coveredAmount).toUint120();
        }

        IsolatedUnstakeRequest storage request = s_isolatedUnstakeRequests[account][validatorId];
        uint64 previousCompletionEpoch = request.completionEpoch;
        if (request.amountMon == 0) ++s_isolatedUnstakeRequestCount[validatorId];
        if (completionEpoch < previousCompletionEpoch) completionEpoch = previousCompletionEpoch;

        // Multiple requests from the same account and validator collapse into one fixed-principal entry.
        request.amountMon = (uint256(request.amountMon) + amountMon).toUint128();
        request.completionEpoch = completionEpoch;

        emit RequestUnstakeIsolated(validatorId, account, vShares, amountMon, completionEpoch);
    }

    function _hasTerminalIsolatedRedemptionDust(
        uint64 validatorId,
        uint256 requestAmount,
        IsolatedValidatorState storage state
    )
        internal
        view
        returns (bool)
    {
        // A swept native remainder cannot be undelegated once the validator has no isolated stake left. Reconcile only
        // that terminal scheduling residue so ordinary liquidity delays and recoverable stake remain exact-pay claims.
        if (state.queuedUnstake == 0 || state.queuedUnstake >= DUST_THRESHOLD) return false;
        // An active validator can still be fully unwound. Preserve exact redemption payments while isolated shares or
        // recoverable stake remain.
        if (s_isolatedVTotalShares[validatorId] != 0) return false;
        if (s_isolatedUnstakeRequestCount[validatorId] != 1 || requestAmount != state.redemptionsPayable) return false;
        if (state.isolatedWithdrawalPending) return false;

        return
            state.activeStake == 0 && state.pendingStake == 0 && state.pendingUnstake == 0 && state.queuedRestake == 0;
    }

    function _completeUnstakeIsolated(address account, uint64 validatorId) internal returns (uint256 amountMon) {
        return _completeUnstakeIsolated(account, validatorId, account, false);
    }

    function _completeUnstakeIsolated(
        address account,
        uint64 validatorId,
        address receiver,
        bool forceIfTransferFails
    )
        internal
        returns (uint256 amountMon)
    {
        require(receiver != address(0), ZeroAddress());
        uint64 currentInternalEpoch = s_admin.internalEpoch;
        IsolatedUnstakeRequest memory request = s_isolatedUnstakeRequests[account][validatorId];
        require(request.amountMon != 0, NoIsolatedUnstakeRequestFound(account, validatorId));
        require(
            currentInternalEpoch >= request.completionEpoch,
            IsolatedCompletionEpochNotReached(validatorId, currentInternalEpoch, request.completionEpoch)
        );

        IsolatedValidatorState storage state = s_isolatedValidatorState[validatorId];
        amountMon = request.amountMon;
        uint256 writtenOffAmountMon;
        bool reconcileTerminalDust = _hasTerminalIsolatedRedemptionDust(validatorId, amountMon, state);

        if (state.idleAssets < amountMon) {
            writtenOffAmountMon = amountMon - state.idleAssets;
            require(
                reconcileTerminalDust && writtenOffAmountMon <= state.queuedUnstake,
                InsufficientIsolatedIdleAssets(validatorId, amountMon, state.idleAssets)
            );
            amountMon = state.idleAssets;
        }

        if (reconcileTerminalDust) {
            // Later isolated credits can reduce or eliminate the redemption shortfall without changing this
            // unfulfillable scheduling residue. Clear it whenever the final terminal request successfully settles.
            state.queuedUnstake = 0;
        }

        delete s_isolatedUnstakeRequests[account][validatorId];
        --s_isolatedUnstakeRequestCount[validatorId];

        state.idleAssets -= amountMon.toUint120();
        state.redemptionsPayable -= request.amountMon.toUint120();
        s_isolatedIdleAssets -= amountMon.toUint128();
        s_isolatedLiquidAssets -= amountMon.toUint128();
        s_isolatedTotalAssets -= amountMon.toUint128();
        _sweepOrphanedIsolatedIdleAssets(validatorId, state);

        _sendIsolatedSettlement(receiver, amountMon, forceIfTransferFails);

        if (writtenOffAmountMon != 0) {
            emit IsolatedRedemptionDustWrittenOff(
                validatorId, account, request.amountMon, amountMon, writtenOffAmountMon
            );
        }
        emit CompleteUnstakeIsolated(validatorId, account, amountMon);
    }

    function _claimDeactivatedIsolated(
        address account,
        uint64 validatorId,
        uint256 vShares,
        address receiver
    )
        internal
        returns (uint256 amountMon)
    {
        return _claimDeactivatedIsolated(account, validatorId, vShares, receiver, false);
    }

    function _claimDeactivatedIsolated(
        address account,
        uint64 validatorId,
        uint256 vShares,
        address receiver,
        bool forceIfTransferFails
    )
        internal
        returns (uint256 amountMon)
    {
        require(receiver != address(0), ZeroAddress());
        require(!s_validatorData[validatorId].isActive, IsolatedDirectClaimUnavailable(validatorId));
        require(_isIsolatedValidatorFullyIdle(validatorId), IsolatedValidatorNotFullyIdle(validatorId));

        IsolatedValidatorState storage state = s_isolatedValidatorState[validatorId];
        require(state.redemptionsPayable == 0, IsolatedDirectClaimUnavailable(validatorId));

        uint256 availableShares = s_isolatedVShareBalances[account][validatorId];
        require(
            vShares != 0 && vShares <= availableShares,
            InsufficientIsolatedShares(validatorId, account, availableShares, vShares)
        );

        amountMon = _convertToIsolatedAssets(validatorId, vShares);
        require(state.idleAssets >= amountMon, InsufficientIsolatedIdleAssets(validatorId, amountMon, state.idleAssets));

        s_isolatedVShareBalances[account][validatorId] = availableShares - vShares;
        s_isolatedVTotalShares[validatorId] -= vShares;

        state.idleAssets -= amountMon.toUint120();
        s_isolatedIdleAssets -= amountMon.toUint128();
        s_isolatedLiquidAssets -= amountMon.toUint128();
        s_isolatedTotalAssets -= amountMon.toUint128();
        _sweepOrphanedIsolatedIdleAssets(validatorId, state);

        _sendIsolatedSettlement(receiver, amountMon, forceIfTransferFails);

        emit ClaimDeactivatedIsolated(validatorId, account, receiver, vShares, amountMon);
    }

    function _sendIsolatedSettlement(address receiver, uint256 amountMon, bool forceIfTransferFails) internal {
        if (!forceIfTransferFails) {
            receiver.safeTransferETH(amountMon);
            return;
        }

        // Permissionless finalizers need the force-send fallback for abandoned non-payable receivers, but the
        // receiver callback must stay bounded so post-transfer checks cannot be gas-starved. Force-send guarantees
        // delivery to the address balance, not that a recipient contract can later move the MON; contract owners of
        // isolated positions must provide their own native-MON recovery path.
        receiver.forceSafeTransferETH(amountMon);
    }

    // ================================================== //
    //                        Math                        //
    // ================================================== //

    /// @notice Returns atomic pool utilization/allocation adjusted for pending revenue settlement.
    /// @dev Offsets `distributedAmount` by min(currentRevenue, distributed) so fee math doesn't jump at crank.
    /// @return utilizedAmount Adjusted utilized (distributed) amount.
    /// @return allocatedAmount Current allocated amount (unchanged).
    function _getAdjustedAmountsForAtomicUnstaking()
        internal
        view
        returns (uint128 utilizedAmount, uint128 allocatedAmount)
    {
        // Get the initial total amount
        AtomicCapital memory _atomicAssets = s_atomicAssets;
        allocatedAmount = _atomicAssets.allocatedAmount;
        utilizedAmount = _atomicAssets.distributedAmount;

        // If this occurs during the global crank, globalRevenuePtr_N(0) is the epoch that just ended.
        // Otherwise, globalRevenuePtr_N(0) is the ongoing epoch.
        Revenue memory _globalRevenue = globalRevenuePtr_N(0);
        // We must subtracted any already-allocated revenue from the earned revenue to get the amount still
        // available for use by the atomic unstaking pool.
        uint256 _availableRevenue = uint256(_globalRevenue.earnedRevenue - _globalRevenue.allocatedRevenue);

        // The _carryOverAtomicUnstakeIntoQueue() method settles a max amount of _availableRevenue
        // (earnedRevenue - allocatedRevenue) during the global crank. This offset ensures fee math
        // remains consistent before and after cranking.
        utilizedAmount -= Math.min(_availableRevenue, utilizedAmount).toUint128();
        if (utilizedAmount > allocatedAmount) utilizedAmount = allocatedAmount;

        return (utilizedAmount, allocatedAmount);
    }

    /// @notice Returns available liquidity and total allocation for atomic unstaking pool.
    /// @dev Mirrors `_getAdjustedAmountsForAtomicUnstaking` adjustment to avoid fee discontinuity in previews.
    /// @return currentAvailableAmount Currently withdrawable amount (allocated - adjusted utilized).
    /// @return totalAllocatedAmount Total allocated (float target) for atomic pool.
    function _getLiquidityForAtomicUnstaking()
        internal
        view
        returns (uint256 currentAvailableAmount, uint256 totalAllocatedAmount)
    {
        // Get the initial total amount
        AtomicCapital memory _atomicAssets = s_atomicAssets;
        totalAllocatedAmount = uint256(_atomicAssets.allocatedAmount);
        uint256 _utilizedAmount = uint256(_atomicAssets.distributedAmount);

        Revenue memory _globalRevenue = globalRevenuePtr_N(0);
        // We must subtracted any already-allocated revenue from the earned revenue to get the amount still
        // available for use by the atomic unstaking pool.
        uint256 _availableRevenue = uint256(_globalRevenue.earnedRevenue - _globalRevenue.allocatedRevenue);

        // The _carryOverAtomicUnstakeIntoQueue() method settles a max amount of _availableRevenue
        // (earnedRevenue - allocatedRevenue) during the global crank. This offset ensures fee math
        // and liquidity previews remain consistent before and after cranking.
        _utilizedAmount -= Math.min(_availableRevenue, _utilizedAmount).toUint128();
        if (_utilizedAmount >= totalAllocatedAmount) return (0, totalAllocatedAmount);

        currentAvailableAmount = totalAllocatedAmount - _utilizedAmount;

        return (currentAvailableAmount, totalAllocatedAmount);
    }

    // ================================================== //
    //                    Percent Math                   //
    // ================================================== //

    /// @notice Gets target liquidity percentage scaled to `SCALE` (1e18).
    /// @dev Converts `s_admin.targetLiquidityPercentage` (BPS) → scaled (1e18).
    /// @return Scaled target percentage in 1e18 units.
    function _scaledTargetLiquidityPercentage() internal view returns (uint256) {
        return s_admin.targetLiquidityPercentage * SCALE / BPS_SCALE;
    }

    /// @notice Converts scaled (1e18) target liquidity percentage to unscaled BPS.
    /// @param scaledTargetLiquidityPercentage Target liquidity percentage in 1e18 units.
    /// @return Unscaled percentage in BPS.
    function _unscaledTargetLiquidityPercentage(uint256 scaledTargetLiquidityPercentage)
        internal
        pure
        returns (uint16)
    {
        return (scaledTargetLiquidityPercentage * BPS_SCALE / SCALE).toUint16();
    }

    /// @notice Computes a scaled percentage from two unscaled amounts.
    /// @dev Returns `numerator * SCALE / denominator`. Caller must ensure `denominator > 0`.
    /// @param unscaledNumeratorAmount Numerator amount (unscaled).
    /// @param unscaledDenominatorAmount Denominator amount (unscaled, must be > 0).
    /// @return Scaled percentage in 1e18 units.
    function _scaledPercentFromAmounts(
        uint256 unscaledNumeratorAmount,
        uint256 unscaledDenominatorAmount
    )
        internal
        pure
        returns (uint256)
    {
        return unscaledNumeratorAmount * SCALE / unscaledDenominatorAmount;
    }

    /// @notice Applies a scaled percentage to a gross amount.
    /// @dev Returns `grossAmount * scaledPercent / SCALE`.
    /// @param grossAmount Gross (unscaled) amount.
    /// @param scaledPercent Percentage in 1e18 units.
    /// @return Resulting unscaled amount after applying percentage.
    function _amountFromScaledPercent(uint256 grossAmount, uint256 scaledPercent) internal pure returns (uint256) {
        return grossAmount * scaledPercent / SCALE;
    }

    // --------------------------------------------- //
    //                  View Functions               //
    // --------------------------------------------- //

    /// @notice Returns true if global crank can run based on basic readiness checks.
    /// @dev Ready when: contract not frozen, all validators cranked, and new epoch available. This is essentially a
    /// view function but cannot be declared as such because the Monad staking precompile absolutely hates when we call
    /// its function calls view or staticcall.
    /// @custom:selector 0x9a292225
    function isGlobalCrankAvailable() external returns (bool) {
        return _isGlobalCrankAvailable();
    }

    function _isGlobalCrankAvailable() internal returns (bool) {
        if (globalEpochPtr_N(0).frozen) return false;
        if (s_nextValidatorToCrank != LAST_VAL_ID) return false;

        (uint64 _monadEpoch, bool _inEpochDelayPeriod) = _getEpochInfo();
        return !_inEpochDelayPeriod && globalEpochPtr_N(0).epoch < _monadEpoch;
    }

    /// @notice Returns true if a specific validator can be cranked based on basic checks.
    /// @dev Ready when: contract not frozen, validatorId is valid and last epoch not cranked.
    /// @custom:selector 0xf062f386
    function isValidatorCrankAvailable(uint64 validatorId) external view returns (bool) {
        if (globalEpochPtr_N(0).frozen) return false;
        if (validatorId == 0 || validatorId == UNKNOWN_VAL_ID) return false;
        address _coinbase = _validatorCoinbase(validatorId);
        if (_coinbase == address(0)) return false;
        return !validatorEpochPtr_N(-1, validatorId).wasCranked;
    }

    /// @notice Returns current working capital snapshot (no structs).
    /// @return stakedAmount Total staked amount
    /// @return reservedAmount Total reserved amount
    /// @custom:selector 0x934c85d7
    function getWorkingCapital() external view returns (uint128 stakedAmount, uint128 reservedAmount) {
        WorkingCapital memory _workingCapital = s_globalCapital;
        return (_workingCapital.stakedAmount, _workingCapital.reservedAmount);
    }

    /// @notice Returns atomic capital snapshot (no structs).
    /// @return allocatedAmount Total allocated amount for atomic pool
    /// @return distributedAmount Amount already distributed to atomic unstakers
    /// @custom:selector 0x0fb6215a
    function getAtomicCapital() external view returns (uint128 allocatedAmount, uint128 distributedAmount) {
        AtomicCapital memory _atomicCapital = s_atomicAssets;
        return (_atomicCapital.allocatedAmount, _atomicCapital.distributedAmount);
    }

    /// @notice Returns global pending escrow snapshot (no structs).
    /// @return pendingStaking Pending staking amount
    /// @return pendingUnstaking Pending unstaking amount
    /// @custom:selector 0xba749daf
    function getGlobalPending() external view returns (uint120 pendingStaking, uint120 pendingUnstaking) {
        StakingEscrow memory _stakingEscrow = s_globalPending;
        return (_stakingEscrow.pendingStaking, _stakingEscrow.pendingUnstaking);
    }

    /// @notice Returns global escrow snapshot for the last epoch (no structs).
    /// @return pendingStaking Pending staking amount at the end of last epoch
    /// @return pendingUnstaking Pending unstaking amount at the end of last epoch
    /// @custom:selector 0x4c9dd95d
    function getGlobalPendingLast() external view returns (uint120 pendingStaking, uint120 pendingUnstaking) {
        StakingEscrow memory _stakingEscrow = s_globalPendingLast;
        return (_stakingEscrow.pendingStaking, _stakingEscrow.pendingUnstaking);
    }

    /// @notice Returns selected epoch global cash flows (no structs).
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking)
    /// @return queueToStake Queue to stake for selected epoch
    /// @return queueForUnstake Queue for unstake for selected epoch
    /// @custom:selector 0x1884fbda
    function getGlobalCashFlows(int256 epochPointer)
        external
        view
        returns (uint120 queueToStake, uint120 queueForUnstake)
    {
        CashFlows memory _cashFlows = globalCashFlowsPtr_N(epochPointer);
        return (_cashFlows.queueToStake, _cashFlows.queueForUnstake);
    }

    /// @notice Returns selected epoch global rewards (no structs).
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking)
    /// @return allocatedRevenue Earned revenue consumed or reserved by prior same-epoch accounting sinks
    /// @return earnedRevenue Earned revenue for selected epoch
    /// @custom:selector 0x08cd7fad
    function getGlobalRevenue(int256 epochPointer)
        external
        view
        returns (uint120 allocatedRevenue, uint120 earnedRevenue)
    {
        Revenue memory _revenue = globalRevenuePtr_N(epochPointer);
        return (_revenue.allocatedRevenue, _revenue.earnedRevenue);
    }

    /// @notice Returns the turnover-only slice of the unstake queue for an epoch pointer.
    /// @dev Subtract this value from `getGlobalCashFlows(epochPointer).queueForUnstake` to derive the non-turnover
    /// component that follows stake-proportional withdrawal routing.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return queueForUnstake Aggregate unstake amount tagged as turnover / incentive-alignment flow.
    /// @custom:selector 0x79b7c5b0
    function getTurnoverQueueForUnstake(int256 epochPointer) external view returns (uint120 queueForUnstake) {
        return turnoverQueuePtr_N(epochPointer).queueForUnstake;
    }

    /// @notice Returns the split global allocation revenue used by weighted stake allocation.
    /// @dev These values partition the allocation signal only. `getGlobalRevenue(epochPointer).earnedRevenue` remains
    /// the legacy aggregate revenue bucket used by existing accounting. When
    /// `getIncludeIsolatedRewardsInStakeAllocation()` is enabled, validator-attributed isolated rewards are included
    /// in this signal even though pooled and isolated economics remain accounted separately elsewhere.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return stakingYield Global stake-allocation staking-yield bucket for the selected epoch.
    /// @return nonStakingRevenue Global stake-allocation MEV / boost / donation bucket for the selected epoch.
    /// @custom:selector 0xf760b95b
    function getGlobalAllocationRevenue(int256 epochPointer)
        external
        view
        returns (uint120 stakingYield, uint120 nonStakingRevenue)
    {
        AllocationRevenue memory _revenue = globalAllocationRevenuePtr_N(epochPointer);
        return (_revenue.stakingYield, _revenue.nonStakingRevenue);
    }

    /// @notice Returns the cached active-set totals used by turnover routing for an epoch pointer.
    /// @dev These totals are computed once during the global crank so every validator uses the same denominator.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return totalPooledTargetStake Sum of pooled target stake across active validators.
    /// @return totalOverallocatedStake Sum of max(0, stake - idealWeightedStake) across active validators.
    /// @return totalAllocationSignalStake Sum of stake used to calculate expected staking-yield baselines.
    /// @return totalAdjustedWeightedRevenue Sum of weighted revenue across active validators.
    /// @custom:selector 0xf7ee148c
    function getAllocationTotals(int256 epochPointer)
        external
        view
        returns (
            uint128 totalPooledTargetStake,
            uint128 totalOverallocatedStake,
            uint128 totalAllocationSignalStake,
            uint128 totalAdjustedWeightedRevenue
        )
    {
        AllocationTotals memory _totals = allocationTotalsPtr_N(epochPointer);
        return (
            _totals.totalPooledTargetStake,
            _totals.totalOverallocatedStake,
            _totals.totalAllocationSignalStake,
            _totals.totalAdjustedWeightedRevenue
        );
    }

    /// @notice Returns the allocation multiplier snapshot for an epoch pointer.
    /// @dev A zero stored snapshot defaults to `RAY`, matching stake-allocation math.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return multiplierRay Non-staking revenue multiplier snapshot in ray precision.
    /// @custom:selector 0x17f9ae34
    function getAllocationMultiplierSnapshotRay(int256 epochPointer) external view returns (uint256 multiplierRay) {
        return _allocationMultiplierSnapshotRay(epochPointer);
    }

    /// @notice Returns the staking-yield deadband snapshot for an epoch pointer.
    /// @dev Stored snapshots are used by validator cranks so live config updates cannot change an in-flight round.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return deadbandBps Staking-yield deadband snapshot in basis points.
    /// @custom:selector 0x675de442
    function getStakingYieldDeadbandSnapshotBps(int256 epochPointer) external view returns (uint16 deadbandBps) {
        return _stakingYieldDeadbandSnapshotBps(epochPointer);
    }

    /// @notice Returns whether the current allocation round still reads legacy earned-revenue weighting.
    /// @custom:selector 0x2fe64a0a
    function isUsingLegacyAllocationWeightingForCurrentRound() external view returns (bool) {
        return _useLegacyAllocationWeightingForCurrentRound();
    }

    /// @notice Returns whether the pending allocation round will read legacy earned-revenue weighting.
    /// @custom:selector 0x088deec5
    function isUsingLegacyAllocationWeightingForPendingRound() external view returns (bool) {
        return _useLegacyAllocationWeightingForPendingRound();
    }

    /// @notice Returns selected global epoch data (no structs).
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking)
    /// @custom:selector 0x2d6d6b97
    function getGlobalEpoch(int256 epochPointer)
        external
        view
        returns (
            uint64 epoch,
            uint8 withdrawalId,
            bool hasWithdrawal,
            bool hasDeposit,
            bool crankedInBoundaryPeriod,
            bool wasCranked,
            bool frozen,
            bool closed,
            uint128 targetStakeAmount
        )
    {
        Epoch memory _epoch = globalEpochPtr_N(epochPointer);
        return (
            _epoch.epoch,
            _epoch.withdrawalId,
            _epoch.hasWithdrawal,
            _epoch.hasDeposit,
            _epoch.crankedInBoundaryPeriod,
            _epoch.wasCranked,
            _epoch.frozen,
            _epoch.closed,
            _epoch.targetStakeAmount
        );
    }

    /// @notice Returns internal epoch counter used by StakeTracker.
    /// @custom:selector 0x29bb317c
    function getInternalEpoch() external view returns (uint64) {
        return s_admin.internalEpoch;
    }

    /// @notice Returns selected epoch frozen/closed status convenience flags.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking)
    /// @custom:selector 0x424567eb
    function getGlobalStatus(int256 epochPointer) external view returns (bool frozen, bool closed) {
        Epoch memory _epoch = globalEpochPtr_N(epochPointer);
        return (_epoch.frozen, _epoch.closed);
    }

    /// @notice Returns the current target liquidity percentage scaled to 1e18.
    /// @custom:selector 0x6ec52fed
    function getScaledTargetLiquidityPercentage() external view returns (uint256) {
        return _scaledTargetLiquidityPercentage();
    }

    /// @notice Returns the global amount currently eligible to be unstaked.
    /// @custom:selector 0x365520db
    function getGlobalAmountAvailableToUnstake() external view returns (uint256 amount) {
        amount = StakeAllocationLib.getGlobalAmountAvailableToUnstake(s_globalCapital, s_globalPending);
        uint256 _isolatedIlliquidAmount =
            s_isolatedTotalAssets > s_isolatedLiquidAssets ? s_isolatedTotalAssets - s_isolatedLiquidAssets : 0;
        return amount > _isolatedIlliquidAmount ? amount - _isolatedIlliquidAmount : 0;
    }

    /// @custom:selector 0xdca8b9fb
    function previewDepositIsolated(uint64 validatorId, uint256 assets) external view returns (uint256) {
        return _convertToIsolatedShares(validatorId, assets);
    }

    /// @custom:selector 0x5e309bea
    function previewRedeemIsolated(uint64 validatorId, uint256 vShares) external view returns (uint256) {
        return _convertToIsolatedAssets(validatorId, vShares);
    }

    /// @notice Returns current-assets per AccountingLib.
    /// @custom:selector 0xa250f825
    function getCurrentAssets() external view returns (uint256) {
        return _pooledCurrentAssets(address(this).balance);
    }

    function _completeDeactivatingValidator(uint64 validatorId) internal virtual override {
        if (_hasPendingIsolatedCrankWork(validatorId)) return;
        if (_hasResidualPooledState(validatorId)) return;
        super._completeDeactivatingValidator(validatorId);
        delete s_pooledDepositActivationEpochs[validatorId];
    }

    function _assertValidatorCanBeAdded(uint64 validatorId) internal view override {
        uint256 requestedActiveValidators = s_activeValidatorCount + 1;
        require(
            requestedActiveValidators <= MAX_ACTIVE_VALIDATORS_FOR_ALLOCATION,
            ActiveValidatorLimitExceeded(requestedActiveValidators, MAX_ACTIVE_VALIDATORS_FOR_ALLOCATION)
        );

        // Once a validator's isolated position is fully unstaked and idle, it may leave the crank sequence even if
        // users have not yet withdrawn those idle funds. Re-adding the same validator id is what gets blocked until
        // that residual isolated state is gone, so new stake cannot inherit stale claims or balances.
        require(!_hasResidualIsolatedState(validatorId), ValidatorHasOutstandingIsolatedState(validatorId));
    }

    function _prepareValidatorForReuse(uint64 validatorId) internal override {
        delete s_isolatedValidatorState[validatorId];
        delete s_isolatedPendingStakeState[validatorId];
        delete s_pooledDepositActivationEpochs[validatorId];
        delete s_isolatedVTotalShares[validatorId];
        delete s_isolatedUnstakeRequestCount[validatorId];
        for (uint256 i; i < EPOCHS_TRACKED; i++) {
            delete s_validatorAllocationRevenue[validatorId][i];
        }
    }

    // ================================================== //
    //                 Overriding Methods                 //
    // ================================================== //
    /// @notice Returns the Monad staking precompile interface
    /// @return IMonadStaking The staking precompile interface
    /// @custom:selector 0x0cb9f3ad
    function STAKING_PRECOMPILE() public pure override(ValidatorRegistry) returns (IMonadStaking) {
        return STAKING;
    }

    /// @notice Modifier that sets up transient capital for rewards delivered via receive()
    modifier expectsRewards() override {
        _setTransientCapital(CashFlowType.Revenue, 0);
        _;
        _clearTransientCapital();
    }

    /// @notice Sets up transient revenue accounting for native MON sent by one expected contract.
    modifier expectsRewardsFrom(address expectedSender) {
        _setTransientCapital(CashFlowType.Revenue, 0, expectedSender);
        _;
        _clearTransientCapital();
    }
}
