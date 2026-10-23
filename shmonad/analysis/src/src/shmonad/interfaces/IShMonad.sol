//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { IERC4626Custom } from "./IERC4626Custom.sol";
import { IERC20Full } from "./IERC20Full.sol";
import { IMonadStaking } from "./IMonadStaking.sol";
import { Policy, UncommitApproval, UserUnstakeRequest, ValidatorStats } from "../Types.sol";

/**
 * @title IShMonad - Interface for the ShMonad Liquid Staking Token contract
 * @notice Canonical NatSpec lives on the concrete mixins; this interface captures ShMonad user/admin entrypoints.
 * @dev Token-controller entrypoints used only by HolisticMON live in `IHolisticMONController`.
 */
interface IShMonad is IERC4626Custom, IERC20Full {
    // --------------------------------------------- //
    //          Initialization & Supply Views        //
    // --------------------------------------------- //

    function initialize(address owner_, address codeUpgradeAuthority_) external;

    function realTotalSupply() external view returns (uint256);

    function committedTotalSupply() external view returns (uint256);

    // --------------------------------------------- //
    //         Yield & Detailed ERC4626 Previews     //
    // --------------------------------------------- //

    function boostYield(address yieldOriginator) external payable;

    function boostYield(uint256 shares, address from, address yieldOriginator) external;

    function sendValidatorRewards(uint64 validatorId, uint256 feeRate) external payable;

    function donateRecoveredCoinbaseRewards(uint64 validatorId) external payable;

    function previewRedeemDetailed(uint256 shares)
        external
        view
        returns (uint256 grossAssets, uint256 feeAssets, uint256 netAssets);

    function previewWithdrawDetailed(uint256 netAssets)
        external
        view
        returns (uint256 shares, uint256 grossAssets, uint256 feeAssets);

    /// @notice Previews the MON amount currently quoted for a traditional unstake request.
    /// @dev Uses ShMonad's smoothed exit basis. Around epoch boundaries, callers that require freshness-correct quotes
    /// should ensure pending global rolls have been processed by calling `crank()` until it returns true.
    function previewUnstake(uint256 shares) external view returns (uint256 assets);

    function previewRequestUnstake(uint256 shares) external view returns (uint64 completionEpoch);

    function getMaxUnstakeRequestAmountWithoutDelay() external view returns (uint256 amount);

    // --------------------------------------------- //
    //             Zero-Yield Tranche                //
    // --------------------------------------------- //

    function depositToZeroYieldTranche(uint256 assets, address receiver) external payable;

    function convertZeroYieldTrancheToShares(uint256 assets, address receiver) external returns (uint256 sharesMinted);

    function balanceOfZeroYieldTranche(address account) external view returns (uint256);

    function unclaimedOwnerCommission() external view returns (uint256);

    // --------------------------------------------- //
    //            Account & Commitment Flow          //
    // --------------------------------------------- //

    function commit(uint64 policyID, address commitRecipient, uint256 shares) external;

    function depositAndCommit(
        uint64 policyID,
        address commitRecipient,
        uint256 shMonToCommit
    )
        external
        payable
        returns (uint256 sharesMinted);

    function requestUncommit(
        uint64 policyID,
        uint256 shares,
        uint256 newMinBalance
    )
        external
        returns (uint256 uncommitCompleteBlock);

    function requestUncommitWithApprovedCompletor(
        uint64 policyID,
        uint256 shares,
        uint256 newMinBalance,
        address completor
    )
        external
        returns (uint256 uncommitCompleteBlock);

    function completeUncommit(uint64 policyID, uint256 shares) external;

    function completeUncommitAndRedeem(uint64 policyID, uint256 shares) external returns (uint256 assets);

    function completeUncommitAndRecommit(
        uint64 fromPolicyID,
        uint64 toPolicyID,
        address commitRecipient,
        uint256 shares
    )
        external;

    function completeUncommitWithApproval(uint64 policyID, uint256 shares, address account) external;

    function setUncommitApproval(uint64 policyID, address completor, uint256 shares) external;

    // --------------------------------------------- //
    //               Unstake Lifecycle               //
    // --------------------------------------------- //

    function requestUnstake(uint256 shares) external returns (uint64 completionEpoch);

    function completeUnstake() external;

    function getUnstakeRequest(address account) external view returns (uint128 amountMon, uint64 completionEpoch);

    function getUnstakeRequests(address account) external view returns (UserUnstakeRequest[] memory requests);

    function depositIsolated(uint64 validatorId, uint256 assets, address receiver) external payable returns (uint256);

    function previewDepositIsolated(uint64 validatorId, uint256 assets) external view returns (uint256);

    function previewRedeemIsolated(uint64 validatorId, uint256 vShares) external view returns (uint256);

    function balanceOfIsolated(uint64 validatorId, address account) external view returns (uint256);

    function totalSupplyIsolated(uint64 validatorId) external view returns (uint256 totalVShares);

    function getIsolatedTotals()
        external
        view
        returns (
            uint128 totalAssets,
            uint128 liquidAssets,
            uint128 idleAssets,
            uint128 totalAssetsLast,
            uint128 liquidAssetsLast
        );

    function getIsolatedUnstakeRequestCount(uint64 validatorId) external view returns (uint32 requestCount);

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
        );

    function getIsolatedUnstakeRequest(
        address account,
        uint64 validatorId
    )
        external
        view
        returns (uint128 amountMon, uint64 completionEpoch);

    function requestUnstakeIsolated(uint64 validatorId, uint256 vShares) external returns (uint64 completionEpoch);

    function completeUnstakeIsolated(uint64 validatorId) external;

    function completeUnstakeIsolatedFor(uint64 validatorId, address account) external returns (uint256 amountMon);

    function claimDeactivatedIsolated(uint64 validatorId, uint256 vShares, address receiver) external returns (uint256);

    function claimDeactivatedIsolatedFor(
        uint64 validatorId,
        uint256 vShares,
        address account
    )
        external
        returns (uint256 amountMon);

    // --------------------------------------------- //
    //             Agent & Hold Operations           //
    // --------------------------------------------- //

    function hold(uint64 policyID, address account, uint256 shares) external;

    function release(uint64 policyID, address account, uint256 shares) external;

    function batchHold(uint64 policyID, address[] calldata accounts, uint256[] memory amounts) external;

    function batchRelease(uint64 policyID, address[] calldata accounts, uint256[] calldata amounts) external;

    function agentTransferFromCommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool inUnderlying
    )
        external;

    function agentTransferToUncommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool inUnderlying
    )
        external;

    function agentWithdrawFromCommitted(
        uint64 policyID,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool amountSpecifiedInUnderlying
    )
        external;

    function getHoldAmount(uint64 policyID, address account) external view returns (uint256);

    // --------------------------------------------- //
    //         Top-Up Settings & Balance Views       //
    // --------------------------------------------- //

    function setMinCommittedBalance(
        uint64 policyID,
        uint128 minCommitted,
        uint128 maxTopUpPerPeriod,
        uint32 topUpPeriodDuration
    )
        external;

    function getTopUpSettings(
        uint64 policyID,
        address account
    )
        external
        view
        returns (uint128 maxTopUpPerPeriod, uint32 topUpPeriodDuration);

    function getCommittedData(
        uint64 policyID,
        address account
    )
        external
        view
        returns (uint128 committed, uint128 minCommitted);

    function getUncommittingData(
        uint64 policyID,
        address account
    )
        external
        view
        returns (uint128 uncommitting, uint48 uncommitStartBlock);

    function policyBalanceAvailable(
        uint64 policyID,
        address account,
        bool inUnderlying
    )
        external
        view
        returns (uint256 balanceAvailable);

    function topUpAvailable(
        uint64 policyID,
        address account,
        bool inUnderlying
    )
        external
        view
        returns (uint256 amountAvailable);

    function getUncommitApproval(
        uint64 policyID,
        address account
    )
        external
        view
        returns (UncommitApproval memory approval);

    function uncommittingCompleteBlock(uint64 policyID, address account) external view returns (uint256);

    function balanceOfCommitted(address account) external view returns (uint256);

    function balanceOfCommitted(uint64 policyID, address account) external view returns (uint256);

    function balanceOfUncommitting(uint64 policyID, address account) external view returns (uint256);

    // --------------------------------------------- //
    //               Policy Management               //
    // --------------------------------------------- //

    function createPolicy(uint48 escrowDuration) external returns (uint64 policyID);

    function addPolicyAgent(uint64 policyID, address agent) external;

    function removePolicyAgent(uint64 policyID, address agent) external;

    function disablePolicy(uint64 policyID) external;

    function policyCount() external view returns (uint64);

    function getPolicy(uint64 policyID) external view returns (Policy memory);

    function isPolicyAgent(uint64 policyID, address agent) external view returns (bool);

    function getPolicyAgents(uint64 policyID) external view returns (address[] memory);

    // --------------------------------------------- //
    //          Atomic Unstake Pool Management       //
    // --------------------------------------------- //

    function setPoolTargetLiquidityPercentage(uint256 newPercentageScaled) external;

    function setUnstakeFeeCurve(uint256 newSlopeRateRay, uint256 newYInterceptRay) external;

    function yInterceptRay() external view returns (uint256);

    function slopeRateRay() external view returns (uint256);

    function getCurrentLiquidity() external view returns (uint256);

    function getTargetLiquidity() external view returns (uint256);

    function getPendingTargetLiquidity() external view returns (uint256);

    function getAtomicPoolUtilization()
        external
        view
        returns (uint256 utilized, uint256 allocated, uint256 available, uint256 utilizationWad);

    function getFeeCurveParams() external view returns (uint256 slopeRateRayOut, uint256 yInterceptRayOut);

    function getAtomicUtilizationWad() external view returns (uint256 utilizationWad);

    function getCurrentUnstakeFeeRateRay() external view returns (uint256 feeRateRay);

    // --------------------------------------------- //
    //           Global Accounting & Cranking        //
    // --------------------------------------------- //

    /// @notice Advances global and validator accounting.
    /// @dev Call until it returns true before treating currently executable crank work, including exit-quote freshness,
    /// as complete.
    function crank() external returns (bool complete);

    /// @notice Returns true when a global roll can execute immediately.
    /// @dev If true, ERC4626 exit quotes may still be freshness-stale until `crank()` processes the roll. A false
    /// result during pending validator work is not by itself a full exit-quote freshness proof.
    function isGlobalCrankAvailable() external returns (bool);

    function isValidatorCrankAvailable(uint64 validatorId) external view returns (bool);

    function getWorkingCapital() external view returns (uint128 stakedAmount, uint128 reservedAmount);

    function getAtomicCapital() external view returns (uint128 allocatedAmount, uint128 distributedAmount);

    function getGlobalPending() external view returns (uint120 pendingStaking, uint120 pendingUnstaking);

    function getGlobalPendingLast() external view returns (uint120 pendingStaking, uint120 pendingUnstaking);

    function getGlobalCashFlows(int256 epochPointer)
        external
        view
        returns (uint120 queueToStake, uint120 queueForUnstake);

    /// @notice Returns the turnover-only slice of the unstake queue for an epoch pointer.
    /// @dev Subtract this value from `getGlobalCashFlows(epochPointer).queueForUnstake` to derive the non-turnover
    /// component that follows stake-proportional withdrawal routing.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return turnoverQueueForUnstake Aggregate unstake amount tagged as turnover / incentive-alignment flow.
    function getTurnoverQueueForUnstake(int256 epochPointer) external view returns (uint120 turnoverQueueForUnstake);

    function getGlobalRevenue(int256 epochPointer)
        external
        view
        returns (uint120 allocatedRevenue, uint120 earnedRevenue);

    /// @notice Returns the split global allocation revenue used by weighted stake allocation.
    /// @dev These values partition the allocation signal only. `getGlobalRevenue(epochPointer).earnedRevenue` remains
    /// the legacy aggregate revenue bucket used by existing accounting. When
    /// `getIncludeIsolatedRewardsInStakeAllocation()` is enabled, validator-attributed isolated rewards are included
    /// in this signal even though pooled and isolated economics remain accounted separately elsewhere. Staking-yield
    /// windows are filtered to the allocation-eligible active set before adjusted deadband scoring consumes them.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return stakingYield Global stake-allocation staking-yield bucket for the selected epoch.
    /// @return nonStakingRevenue Global stake-allocation MEV / boost / donation bucket for the selected epoch.
    function getGlobalAllocationRevenue(int256 epochPointer)
        external
        view
        returns (uint120 stakingYield, uint120 nonStakingRevenue);

    /// @notice Returns the cached active-set totals used by turnover routing for an epoch pointer.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return totalPooledTargetStake Sum of pooled target stake across active validators.
    /// @return totalOverallocatedStake Sum of max(0, stake - idealWeightedStake) across active validators.
    /// @return totalAllocationSignalStake Sum of stake used to calculate expected staking-yield baselines.
    /// @return totalAdjustedWeightedRevenue Sum of weighted revenue across active validators.
    function getAllocationTotals(int256 epochPointer)
        external
        view
        returns (
            uint128 totalPooledTargetStake,
            uint128 totalOverallocatedStake,
            uint128 totalAllocationSignalStake,
            uint128 totalAdjustedWeightedRevenue
        );

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
        );

    function getInternalEpoch() external view returns (uint64);

    function getGlobalStatus(int256 epochPointer) external view returns (bool frozen, bool closed);

    function getScaledTargetLiquidityPercentage() external view returns (uint256);

    function getGlobalAmountAvailableToUnstake() external view returns (uint256 amount);

    function getCurrentAssets() external view returns (uint256);

    function globalLiabilities()
        external
        view
        returns (uint128 rewardsPayable, uint128 redemptionsPayable, uint128 totalZeroYieldPayable);

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
        );

    /// @notice Returns the first internal allocation round that reads split allocation buckets.
    /// @dev A zero value means split allocation weighting is active immediately.
    function getAllocationSplitStartEpoch() external view returns (uint64 splitStartEpoch);

    /// @notice Returns the configured multiplier for non-staking revenue.
    /// @return multiplierRay Non-staking revenue multiplier in ray precision.
    function getNonStakingRevenueMultiplierRay() external view returns (uint256 multiplierRay);

    function getAllocationMultiplierSnapshotRay(int256 epochPointer) external view returns (uint256 multiplierRay);

    /// @notice Returns the configured staking-yield deadband for allocation scoring.
    /// @return deadbandBps Basis points of expected staking yield filtered from the staking-yield signal.
    function getStakingYieldDeadbandBps() external view returns (uint16 deadbandBps);

    /// @notice Returns the staking-yield deadband snapshot for an epoch pointer.
    /// @return deadbandBps Staking-yield deadband snapshot in basis points.
    function getStakingYieldDeadbandSnapshotBps(int256 epochPointer) external view returns (uint16 deadbandBps);

    function isUsingLegacyAllocationWeightingForCurrentRound() external view returns (bool);

    function isUsingLegacyAllocationWeightingForPendingRound() external view returns (bool);

    /// @notice Returns whether validator-attributed isolated rewards are included in stake-allocation signal buckets.
    /// @return include Whether the weighted allocation signal uses pooled-only rewards (`false`) or pooled+isolated
    /// validator-attributed rewards (`true`).
    function getIncludeIsolatedRewardsInStakeAllocation() external view returns (bool include);

    function getCodeUpgradeAuthority() external view returns (address authority);

    function STAKING_PRECOMPILE() external pure returns (IMonadStaking);

    // --------------------------------------------- //
    //             Validator Administration          //
    // --------------------------------------------- //

    function deactivateValidator(uint64 validatorId) external;

    function addValidator(uint64 validatorId, address coinbase) external;

    function addValidator(uint64 validatorId) external returns (address coinbase);

    function updateStakingCommission(uint16 feeInBps) external;

    function updateBoostCommission(uint16 feeInBps) external;

    function updateIncentiveAlignmentPercentage(uint16 percentageInBps) external;

    /// @notice Updates the multiplier applied to non-staking revenue during stake allocation.
    /// @param multiplierRay New non-staking revenue multiplier in ray precision.
    function updateNonStakingRevenueMultiplierRay(uint256 multiplierRay) external;

    /// @notice Updates the staking-yield deadband used during stake allocation.
    /// @param deadbandBps New deadband in basis points of expected staking yield.
    function updateStakingYieldDeadbandBps(uint16 deadbandBps) external;

    /// @notice Updates whether validator-attributed isolated rewards are included in the stake-allocation signal.
    /// @param include Whether to include isolated rewards in the signal used for pooled stake allocation.
    function updateIncludeIsolatedRewardsInStakeAllocation(bool include) external;

    function setFrozenStatus(bool isFrozen) external;

    function setClosedStatus(bool isClosed) external;

    function upgradeCoinbaseBeaconImplementation(address newImplementation) external;

    function updateCodeUpgradeAuthority(address newAuthority) external;

    function updateCoinbaseForExistingValidator(uint64 validatorId) external returns (address newCoinbase);

    function processCoinbaseByAuth(uint64 validatorId) external;
    function processCoinbaseByAuth(address coinbase) external;

    function claimOwnerCommissionAsShares(uint256 assets, address receiver) external returns (uint256 sharesMinted);

    function getZeroYieldToken() external view returns (address token);

    // --------------------------------------------- //
    //                 Validator Views               //
    // --------------------------------------------- //

    function previewCoinbaseAddress(uint64 validatorId) external view returns (address predicted);

    function getValidatorStats(uint64 validatorId) external view returns (ValidatorStats memory stats);

    function isValidatorActive(uint64 validatorId) external view returns (bool);

    function getEpochInfo() external returns (uint256 epochNumber, uint256 epochStartBlock);

    function getValidatorCoinbase(uint256 validatorId) external view returns (address);

    function getValidatorIdForCoinbase(address coinbase) external view returns (uint256);

    function getCoinbaseBeacon() external view returns (address);

    function getCoinbaseBeaconImplementation() external view returns (address);

    function getValidatorData(uint64 validatorId)
        external
        view
        returns (
            uint64 epoch,
            uint64 id,
            bool isPlaceholder,
            bool isActive,
            bool inActiveSet_Current,
            bool inActiveSet_Last,
            address coinbase
        );

    function listActiveValidators() external view returns (uint64[] memory validatorIds, address[] memory coinbases);

    function getValidatorEpochs(uint64 validatorId)
        external
        view
        returns (uint64 lastEpoch, uint128 lastTargetStakeAmount, uint64 currentEpoch, uint128 currentTargetStakeAmount);

    function getValidatorPendingEscrow(uint64 validatorId)
        external
        view
        returns (
            uint120 lastPendingStaking,
            uint120 lastPendingUnstaking,
            uint120 currentPendingStaking,
            uint120 currentPendingUnstaking
        );

    function getValidatorRewards(uint64 validatorId)
        external
        view
        returns (
            uint120 lastRewardsPayable,
            uint120 lastEarnedRevenue,
            uint120 currentRewardsPayable,
            uint120 currentEarnedRevenue
        );

    /// @notice Returns the split allocation signal for a validator and epoch pointer.
    /// @dev When `getIncludeIsolatedRewardsInStakeAllocation()` is enabled, these values include the validator's
    /// isolated-attributed rewards for signal purposes even though pooled and isolated accounting remain separated.
    /// @param validatorId Validator to inspect.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return stakingYield Stake-allocation staking-yield signal attributed to the validator for the selected epoch.
    /// @return nonStakingRevenue Stake-allocation MEV / boost / donation signal attributed to the validator.
    function getValidatorAllocationRevenue(
        uint64 validatorId,
        int256 epochPointer
    )
        external
        view
        returns (uint120 stakingYield, uint120 nonStakingRevenue);

    function getValidatorNeighbors(uint64 validatorId) external view returns (address previous, address next);

    function getActiveValidatorCount() external view returns (uint256);

    function getNextValidatorToCrank() external view returns (address);
}
