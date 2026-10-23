//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { ShMonadErrors } from "./Errors.sol";
import { ShMonadEvents } from "./Events.sol";
import {
    Balance,
    Policy,
    CommittedData,
    UncommittingData,
    TopUpData,
    TopUpSettings,
    Supply,
    UserUnstakeRequest,
    UserUnstakesState,
    UncommitApproval,
    Epoch,
    PendingBoost,
    CashFlows,
    StakingEscrow,
    AtomicCapital,
    AdminValues,
    ValidatorDataStorage,
    FeeParams,
    WorkingCapital,
    CurrentLiabilities,
    RevenueSmoother,
    Revenue,
    AllocationRevenue,
    TurnoverQueue,
    StakeAllocationConfig,
    AllocationTotals,
    IsolatedValidatorState,
    IsolatedPendingStakeState,
    IsolatedUnstakeRequest
} from "./Types.sol";
import { IShMonad } from "./interfaces/IShMonad.sol";
import { TradUnstakeLib } from "./libraries/TradUnstakeLib.sol";
import { EPOCHS_TRACKED, WITHDRAWAL_DELAY } from "./Constants.sol";

abstract contract ShMonadStorage is ShMonadErrors, ShMonadEvents, IShMonad {
    uint40 internal immutable STAKING_WITHDRAWAL_DELAY; // Measured in Monad staking epochs
    address internal immutable HMON_TOKEN_ADDRESS; // HolisticMON token contract address, wraps zero-yield deposits

    uint64 internal s_policyCount = 0; // Incremented to create ID for each new policy.

    // ERC20 data
    /// @dev Legacy storage slots retained for upgrade layout compatibility. `s_supply` is authoritative.
    uint256 internal s_totalSupply;
    uint256 internal s_committedTotalSupply;
    mapping(address account => Balance balance) internal s_balances; // Tracks all types and committed balances
    mapping(address account => mapping(address spender => uint256)) internal s_allowances;

    // Policy-Account Committed, Uncommitting, and Top-Up data
    mapping(uint64 policyID => mapping(address account => CommittedData committedData)) internal s_committedData;
    mapping(uint64 policyID => mapping(address account => UncommittingData uncommittingData)) internal
        s_uncommittingData;
    mapping(uint64 policyID => mapping(address account => TopUpData topUpData)) internal s_topUpData;
    mapping(uint64 policyID => mapping(address account => TopUpSettings topUpSettings)) internal s_topUpSettings;

    // Policy data
    mapping(uint64 policyID => Policy policy) internal s_policies;
    mapping(uint64 policyID => mapping(address agent => bool)) internal s_isPolicyAgent;
    mapping(uint64 policyID => address[] policyAgents) internal s_policyAgents;

    /// @dev Legacy storage slot retained for upgrade layout compatibility. Replaced by `s_uncommitApprovals`.
    mapping(address task => bytes32 policyIdUserHash) internal s_userTaskUncommits;

    // NOTE: Move this to replace s_totalSupply / committed in prod, but keep as separate storage
    // on testnet to prevent disrupting balances.
    Supply internal s_supply;

    // Pending validator unstake requests
    mapping(address requestor => UserUnstakeRequest) internal s_unstakeRequests;

    // Validator Management
    mapping(uint64 validatorId => bool) internal s_validatorIsActive;

    // Policies
    mapping(uint64 policyID => mapping(address account => UncommitApproval uncommitApproval)) internal
        s_uncommitApprovals;

    // StakeTracker State
    FeeParams internal s_feeParams;
    AdminValues internal s_admin;

    WorkingCapital internal s_globalCapital;
    StakingEscrow internal s_globalPending;
    CurrentLiabilities internal s_globalLiabilities;
    AtomicCapital internal s_atomicAssets;
    RevenueSmoother internal s_revenueSmoother;

    CashFlows[EPOCHS_TRACKED] internal s_globalCashFlows;
    Epoch[EPOCHS_TRACKED] internal s_globalEpoch;
    Revenue[EPOCHS_TRACKED] internal s_globalRevenue;

    mapping(uint64 valId => Epoch[EPOCHS_TRACKED]) internal s_validatorEpoch;
    mapping(uint64 valId => PendingBoost[EPOCHS_TRACKED]) internal s_validatorRewards;
    mapping(uint64 valId => StakingEscrow[EPOCHS_TRACKED]) internal s_validatorPending;

    mapping(uint64 valId => ValidatorDataStorage validatorData) internal s_validatorData;
    mapping(uint64 valId => address coinbase) internal s_valCoinbases;
    mapping(address coinbase => uint64 valId) internal s_valIdByCoinbase;
    // List-based ordering for cranking validator IDs
    mapping(uint64 thisValId => uint64 nextValId) internal s_valLinkNext;
    mapping(uint64 thisValId => uint64 prevValId) internal s_valLinkPrevious;

    mapping(address account => uint256 balance) internal s_zeroYieldBalances;

    uint256 internal s_activeValidatorCount;
    uint256 internal s_pendingTargetAtomicLiquidityPercent;
    uint64 internal s_nextValidatorToCrank;
    uint256 internal transient t_cashFlowClassifier;
    address internal transient t_cashFlowExpectedSender;
    uint64 internal transient t_validatorActiveSetCheckValId;
    bool internal transient t_validatorActiveSetCheckValIdState;

    // Added in v1.1
    StakingEscrow internal s_globalPendingLast;
    WorkingCapital internal s_globalCapitalLast;

    // Added in v1.2
    // Beacon used for per-validator Coinbase beacon-proxy deployments.
    address internal s_coinbaseBeacon;

    // Authority that can rotate implementation pointers (proxy upgrades and beacon upgrades) without taking over
    // immediate owner-only operational controls such as freeze/close or validator administration.
    address internal s_codeUpgradeAuthority;

    // v1.2 isolated stake state.
    uint128 internal s_isolatedTotalAssets;
    uint128 internal s_isolatedLiquidAssets;
    uint128 internal s_isolatedIdleAssets;
    uint128 internal s_isolatedTotalAssetsLast;
    uint128 internal s_isolatedLiquidAssetsLast;

    mapping(uint64 valId => IsolatedValidatorState isolatedState) internal s_isolatedValidatorState;
    mapping(address account => mapping(uint64 valId => uint256 vShares)) internal s_isolatedVShareBalances;
    mapping(uint64 valId => uint256 totalVShares) internal s_isolatedVTotalShares;
    mapping(address account => mapping(uint64 valId => IsolatedUnstakeRequest request)) internal
        s_isolatedUnstakeRequests;
    mapping(uint64 valId => uint32 requestCount) internal s_isolatedUnstakeRequestCount;

    // v1.2 stake allocation state. These buckets are parallel to the legacy aggregate queue/revenue fields above:
    // aggregate accounting still reads the legacy fields, while stake-allocation math reads this split state.
    StakeAllocationConfig internal s_stakeAllocationConfig;
    TurnoverQueue[EPOCHS_TRACKED] internal s_turnoverQueueForUnstake;
    AllocationRevenue[EPOCHS_TRACKED] internal s_globalAllocationRevenue;
    AllocationTotals[EPOCHS_TRACKED] internal s_allocationTotals;
    uint128[EPOCHS_TRACKED] internal s_allocationMultiplierSnapshots;
    uint16[EPOCHS_TRACKED] internal s_stakingYieldDeadbandBpsSnapshots;
    mapping(uint64 valId => AllocationRevenue[EPOCHS_TRACKED]) internal s_validatorAllocationRevenue;

    // `s_unstakeRequests` remains as the legacy single-request slot and is lazily migrated into this state.
    mapping(address account => UserUnstakesState state) internal s_userUnstakesState;

    // Appended pending-isolated activation metadata. It is separate from the public validator state so existing
    // state reads stay compact and principal accounting remains authoritative in `s_isolatedValidatorState`.
    mapping(uint64 valId => IsolatedPendingStakeState pendingState) internal s_isolatedPendingStakeState;

    // Native activation epochs for pooled deposits in each validator epoch ring.
    mapping(uint64 valId => uint64[EPOCHS_TRACKED] activationEpochs) internal s_pooledDepositActivationEpochs;

    constructor(address zeroYieldToken) {
        require(zeroYieldToken != address(0), InvalidZeroYieldToken(zeroYieldToken));
        STAKING_WITHDRAWAL_DELAY = uint40(WITHDRAWAL_DELAY);
        HMON_TOKEN_ADDRESS = zeroYieldToken;
    }

    // --------------------------------------------- //
    //                  View Functions               //
    // --------------------------------------------- //

    /// @notice Gets the total number of policies that have been created.
    /// @return The current policy count.
    /// @custom:selector 0xde54d429
    function policyCount() external view returns (uint64) {
        return s_policyCount;
    }

    /// @notice Gets information about a specific policy.
    /// @param policyID The ID of the policy to query.
    /// @return The policy information (escrow duration, active flag, and primary agent).
    /// @custom:selector 0x6d738773
    function getPolicy(uint64 policyID) external view returns (Policy memory) {
        return s_policies[policyID];
    }

    /// @notice Checks if an address is an agent for a specific policy.
    /// @param policyID The ID of the policy.
    /// @param agent The address to check.
    /// @return Whether the address is a policy agent.
    /// @custom:selector 0x6d20d833
    function isPolicyAgent(uint64 policyID, address agent) external view returns (bool) {
        return _isPolicyAgent(policyID, agent);
    }

    /// @notice Gets all agent addresses for a specific policy.
    /// @param policyID The ID of the policy.
    /// @return Array of agent addresses.
    /// @custom:selector 0x6653bd41
    function getPolicyAgents(uint64 policyID) external view returns (address[] memory) {
        return s_policyAgents[policyID];
    }

    /// @notice Retrieves the rolling global liabilities tracked by StakeTracker.
    /// @return rewardsPayable The MON amount reserved for rewards payouts.
    /// @return redemptionsPayable The MON amount pending redemption settlement.
    /// @return totalZeroYieldPayable The MON amount earmarked for zero-yield obligations (e.g., commission accruals).
    /// @custom:selector 0x79251e7e
    function globalLiabilities()
        external
        view
        returns (uint128 rewardsPayable, uint128 redemptionsPayable, uint128 totalZeroYieldPayable)
    {
        CurrentLiabilities memory _liabilities = s_globalLiabilities;
        AdminValues memory _admin = s_admin;
        rewardsPayable = _liabilities.rewardsPayable;
        redemptionsPayable = _liabilities.redemptionsPayable;
        totalZeroYieldPayable = _admin.totalZeroYieldPayable;
    }

    // --------------------------------------------- //
    //            Traditional Unstake Views          //
    // --------------------------------------------- //

    /// @notice Returns a compatibility summary of an account's traditional unstake queue after the v1.2 upgrade.
    /// @dev This view preserves the pre-upgrade ABI by returning:
    /// - `amountMon`: the total MON across every active traditional unstake request for `account`
    /// - `completionEpoch`: the maximum completion epoch across the active request set
    /// @dev Existing integrations can keep polling this getter, but multi-request-aware integrations should prefer
    /// `getUnstakeRequests(address)` to inspect each active request directly.
    /// @param account The account whose unstake request is being queried.
    /// @return amountMon The total MON pending unstake for the account across all active requests.
    /// @return completionEpoch The latest completion epoch across the account's active request set.
    /// @custom:selector 0x64a6c194
    function getUnstakeRequest(address account) external view returns (uint128 amountMon, uint64 completionEpoch) {
        return TradUnstakeLib.summary(s_unstakeRequests, s_userUnstakesState, account);
    }

    /// @notice Returns every active traditional unstake request for `account` as a compact array.
    /// @dev The returned array is sorted by ascending completion epoch.
    /// @dev After the v1.2 upgrade, already-matured requests may be compacted into a single withdrawable entry to keep
    /// the bounded slot set available for pending requests. When that compaction happens, the returned entry's
    /// `completionEpoch` is the latest completion epoch among the matured requests merged into it.
    /// @param account The account whose traditional unstake queue is being queried.
    /// @return requests Compact array containing every active traditional unstake request, matured and pending.
    /// @custom:selector 0x91174e41
    function getUnstakeRequests(address account) external view returns (UserUnstakeRequest[] memory requests) {
        return TradUnstakeLib.activeRequests(s_unstakeRequests, s_userUnstakesState, account);
    }

    /// @notice Returns admin values (no structs).
    /// @return internalEpoch The current internal accounting epoch.
    /// @return targetLiquidityPercentage The target atomic liquidity percentage.
    /// @return incentiveAlignmentPercentage The incentive alignment percentage applied to user rewards.
    /// @return stakingCommission The protocol staking commission in basis points.
    /// @return boostCommissionRate The commission rate charged on boosted yield.
    /// @return totalZeroYieldPayable The total zero-yield tranche liabilities owed by ShMonad.
    /// @custom:selector 0x2c45d5dc
    function getAdminValues()
        external
        view
        returns (
            uint64 internalEpoch,
            uint16 targetLiquidityPercentage,
            uint16 incentiveAlignmentPercentage,
            uint16 stakingCommission,
            uint16 boostCommissionRate,
            uint128 totalZeroYieldPayable
        )
    {
        AdminValues memory _admin = s_admin;
        return (
            _admin.internalEpoch,
            _admin.targetLiquidityPercentage,
            _admin.incentiveAlignmentPercentage,
            _admin.stakingCommission,
            _admin.boostCommissionRate,
            _admin.totalZeroYieldPayable
        );
    }

    /// @notice Returns the Holistic MON token address associated with ShMonad.
    /// @return token The zero-yield token address used by the system.
    /// @custom:selector 0x18b64497
    function getZeroYieldToken() external view returns (address token) {
        return HMON_TOKEN_ADDRESS;
    }

    /// @notice Returns the authority that can execute delayed code upgrades.
    /// @custom:selector 0xea5364b5
    function getCodeUpgradeAuthority() external view returns (address authority) {
        authority = s_codeUpgradeAuthority;
    }

    /// @notice Returns the aggregate isolated-stake asset trackers.
    /// @dev `totalAssets` includes all isolated stake, liquid and illiquid. `liquidAssets` is the portion already
    /// available or queued for isolated settlement. `idleAssets` is immediately payable from validator-local idle MON.
    /// The `last` fields are the snapshot used during the current validator crank round.
    /// @return totalAssets Total isolated MON assets tracked by ShMonad.
    /// @return liquidAssets Isolated MON considered liquid for settlement/routing.
    /// @return idleAssets Isolated MON already idle at validators.
    /// @return totalAssetsLast Snapshot of total isolated assets from the previous validator round.
    /// @return liquidAssetsLast Snapshot of liquid isolated assets from the previous validator round.
    /// @custom:selector 0xfe06849b
    function getIsolatedTotals()
        external
        view
        returns (
            uint128 totalAssets,
            uint128 liquidAssets,
            uint128 idleAssets,
            uint128 totalAssetsLast,
            uint128 liquidAssetsLast
        )
    {
        return (
            s_isolatedTotalAssets,
            s_isolatedLiquidAssets,
            s_isolatedIdleAssets,
            s_isolatedTotalAssetsLast,
            s_isolatedLiquidAssetsLast
        );
    }

    /// @notice Returns the total isolated vShares issued for a validator.
    /// @param validatorId The validator whose isolated vShare supply is being queried.
    /// @return totalVShares Total isolated vShares issued against `validatorId`.
    /// @custom:selector 0x390a2396
    function totalSupplyIsolated(uint64 validatorId) external view returns (uint256 totalVShares) {
        return s_isolatedVTotalShares[validatorId];
    }

    /// @notice Returns the number of outstanding isolated unstake requests for a validator.
    /// @param validatorId The validator whose isolated request count is being queried.
    /// @return requestCount Number of accounts with an outstanding isolated redemption request.
    /// @custom:selector 0x03e95bd8
    function getIsolatedUnstakeRequestCount(uint64 validatorId) external view returns (uint32 requestCount) {
        return s_isolatedUnstakeRequestCount[validatorId];
    }

    /// @notice Returns the first internal allocation round that reads split allocation buckets.
    /// @dev This is not the first epoch that records split revenue. For non-zero values, the historical smoothing
    /// window read by that round (`splitStartEpoch - 2` and `splitStartEpoch - 1`) must already be populated under
    /// split accounting. A zero value means the split allocation path is active immediately.
    /// @custom:selector 0x97e09c53
    function getAllocationSplitStartEpoch() external view returns (uint64 splitStartEpoch) {
        return s_stakeAllocationConfig.splitStartEpoch;
    }

    /// @notice Returns the isolated vShare balance for an account and validator.
    /// @param validatorId The validator whose isolated balance is being queried.
    /// @param account The account whose isolated balance is being queried.
    /// @return balance Isolated vShares owned by `account` for `validatorId`.
    /// @custom:selector 0xc4e98c38
    function balanceOfIsolated(uint64 validatorId, address account) external view returns (uint256) {
        return s_isolatedVShareBalances[account][validatorId];
    }

    /// @notice Returns isolated stake accounting for a validator.
    /// @param validatorId The validator whose isolated accounting state is being queried.
    /// @return activeStake Isolated MON active in the staking precompile.
    /// @return pendingStake Isolated MON delegated but not yet active.
    /// @return pendingUnstake Isolated MON undelegated but not yet withdrawn.
    /// @return queuedRestake Idle isolated MON queued to restake.
    /// @return queuedUnstake Isolated MON queued to unstake.
    /// @return idleAssets Isolated MON idle at the validator and available for isolated settlement.
    /// @return redemptionsPayable Isolated MON owed to outstanding redemption requests.
    /// @return snapshotPooledStake Pooled stake snapshot for reward splits.
    /// @return snapshotIsolatedStake Isolated stake snapshot for reward splits and allocation signal stake.
    /// @return pooledWithdrawalCursor Current pooled withdrawal ID cursor in the pooled range [1, 128].
    /// @return isolatedWithdrawalCursor Current isolated withdrawal ID cursor in the isolated range [129, 255].
    /// @return isolatedWithdrawalId Active isolated withdrawal ID, if any.
    /// @return isolatedWithdrawalPending Whether an isolated withdrawal is currently pending completion.
    /// @custom:selector 0xd10c1089
    function getIsolatedValidatorState(uint64 validatorId)
        external
        view
        returns (
            uint120 activeStake,
            uint120 pendingStake,
            uint120 pendingUnstake,
            uint120 queuedRestake,
            uint120 queuedUnstake,
            uint120 idleAssets,
            uint120 redemptionsPayable,
            uint120 snapshotPooledStake,
            uint120 snapshotIsolatedStake,
            uint8 pooledWithdrawalCursor,
            uint8 isolatedWithdrawalCursor,
            uint8 isolatedWithdrawalId,
            bool isolatedWithdrawalPending
        )
    {
        IsolatedValidatorState memory _state = s_isolatedValidatorState[validatorId];
        return (
            _state.activeStake,
            _state.pendingStake,
            _state.pendingUnstake,
            _state.queuedRestake,
            _state.queuedUnstake,
            _state.idleAssets,
            _state.redemptionsPayable,
            _state.snapshotPooledStake,
            _state.snapshotIsolatedStake,
            _state.pooledWithdrawalCursor,
            _state.isolatedWithdrawalCursor,
            _state.isolatedWithdrawalId,
            _state.isolatedWithdrawalPending
        );
    }

    /// @notice Returns the externally payable amount and completion epoch for an isolated unstake request.
    /// @dev Isolated requests are fixed-principal. The final request against a validator with no remaining isolated
    /// shares or stake may receive less only when its remaining shortfall is below the native staking dust threshold.
    /// @param account The account whose isolated unstake request is being queried.
    /// @param validatorId The validator associated with the isolated unstake request.
    /// @return amountMon Stored MON amount requested for settlement.
    /// @return completionEpoch Internal epoch when the request can be completed.
    /// @custom:selector 0x8c1a6a03
    function getIsolatedUnstakeRequest(
        address account,
        uint64 validatorId
    )
        external
        view
        returns (uint128 amountMon, uint64 completionEpoch)
    {
        IsolatedUnstakeRequest storage _request = s_isolatedUnstakeRequests[account][validatorId];
        return (_request.amountMon, _request.completionEpoch);
    }

    // ================================================== //
    //                 Epoch Alignment                    //
    // ================================================== //

    function N(int256 nDelta) internal view returns (uint256 index) {
        int256 _internalEpoch = int256(uint256(s_admin.internalEpoch));
        unchecked {
            // Allow underflow
            index = uint256(_internalEpoch + nDelta) % EPOCHS_TRACKED;
        }
    }

    function globalCashFlowsPtr_N(int256 nDelta) internal view returns (CashFlows storage ptr) {
        ptr = s_globalCashFlows[N(nDelta)];
    }

    function globalEpochPtr_N(int256 nDelta) internal view returns (Epoch storage ptr) {
        ptr = s_globalEpoch[N(nDelta)];
    }

    function globalRevenuePtr_N(int256 nDelta) internal view returns (Revenue storage ptr) {
        ptr = s_globalRevenue[N(nDelta)];
    }

    function turnoverQueuePtr_N(int256 nDelta) internal view returns (TurnoverQueue storage ptr) {
        ptr = s_turnoverQueueForUnstake[N(nDelta)];
    }

    function globalAllocationRevenuePtr_N(int256 nDelta) internal view returns (AllocationRevenue storage ptr) {
        ptr = s_globalAllocationRevenue[N(nDelta)];
    }

    function allocationTotalsPtr_N(int256 nDelta) internal view returns (AllocationTotals storage ptr) {
        ptr = s_allocationTotals[N(nDelta)];
    }

    function validatorAllocationRevenuePtr_N(
        int256 nDelta,
        uint64 valId
    )
        internal
        view
        returns (AllocationRevenue storage ptr)
    {
        ptr = s_validatorAllocationRevenue[valId][N(nDelta)];
    }

    function validatorEpochPtr_N(int256 nDelta, uint64 valId) internal view returns (Epoch storage ptr) {
        ptr = s_validatorEpoch[valId][N(nDelta)];
    }

    function validatorRewardsPtr_N(int256 nDelta, uint64 valId) internal view returns (PendingBoost storage ptr) {
        ptr = s_validatorRewards[valId][N(nDelta)];
    }

    function validatorPendingPtr_N(int256 nDelta, uint64 valId) internal view returns (StakingEscrow storage ptr) {
        ptr = s_validatorPending[valId][N(nDelta)];
    }

    // ================================================== //
    //       Avoiding SSTORE over Null Values             //
    // ================================================== //

    function _setEpochStorage(Epoch storage ptr, Epoch memory values) internal {
        ptr.epoch = values.epoch;
        ptr.withdrawalId = values.withdrawalId;
        ptr.hasWithdrawal = values.hasWithdrawal;
        ptr.hasDeposit = values.hasDeposit;
        ptr.crankedInBoundaryPeriod = values.crankedInBoundaryPeriod;
        ptr.wasCranked = values.wasCranked;
        ptr.frozen = values.frozen;
        ptr.closed = values.closed;
        ptr.targetStakeAmount = values.targetStakeAmount;
    }

    function _setStakingQueueStorage(CashFlows storage ptr, CashFlows memory values) internal {
        ptr.queueForUnstake = values.queueForUnstake;
        ptr.queueToStake = values.queueToStake;
    }

    // --------------------------------------------- //
    //                Internal Functions             //
    // --------------------------------------------- //

    function _isPolicyAgent(uint64 policyID, address agent) internal view returns (bool) {
        return s_isPolicyAgent[policyID][agent];
    }

    // --------------------------------------------- //
    //                    Modifiers                  //
    // --------------------------------------------- //
    modifier notWhenFrozen() {
        require(!globalEpochPtr_N(0).frozen, NotWhenFrozen());
        _;
    }

    modifier notWhenClosed() {
        require(!globalEpochPtr_N(0).closed, NotWhenClosed());
        _;
    }

    modifier onlyCodeUpgradeAuthority() {
        require(msg.sender == s_codeUpgradeAuthority, NotCodeUpgradeAuthority(msg.sender));
        _;
    }
}
