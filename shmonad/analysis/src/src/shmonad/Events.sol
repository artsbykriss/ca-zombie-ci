//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

abstract contract ShMonadEvents {
    // --------------------------------------------- //
    //                   Policies                    //
    // --------------------------------------------- //
    /// @custom:selector 0x45d67bb4
    event Commit(uint64 indexed policyID, address indexed account, uint256 amount);
    /// @custom:selector 0xc2004f6d
    event RequestUncommit(
        uint64 indexed policyID, address indexed account, uint256 amount, uint256 expectedUncommitCompleteBlock
    );
    /// @custom:selector 0x14ee26c6
    event CompleteUncommit(uint64 indexed policyID, address indexed account, uint256 amount);
    /// @custom:selector 0x44483dcf
    event UncommittingRecommitted(uint64 indexed policyID, address indexed account, uint256 amount);
    /// @custom:selector 0xb1832e21
    event CommittedSharesSpentAsUnderlying(uint64 indexed policyID, address indexed account, uint256 shares);
    /// @custom:selector 0x89114bbe
    event UncommitApprovalUpdated(
        uint64 indexed policyID, address indexed account, address indexed completor, uint96 shares
    );
    /// @custom:selector 0xcbb33209
    event SetTopUp(
        uint64 indexed policyID,
        address indexed account,
        uint128 minCommitted,
        uint128 maxTopUpPerPeriod,
        uint32 topUpPeriodDuration
    );
    /// @custom:selector 0x369b9ef7
    event CreatePolicy(uint64 indexed policyID, address indexed creator, uint48 escrowDuration);
    /// @custom:selector 0x536699e7
    event AddPolicyAgent(uint64 indexed policyID, address indexed agent);
    /// @custom:selector 0xd1dd9f27
    event RemovePolicyAgent(uint64 indexed policyID, address indexed agent);
    /// @custom:selector 0x724f90fb
    event DisablePolicy(uint64 indexed policyID);

    // --------------------------------------------- //
    //               Agent Functions                 //
    // --------------------------------------------- //
    /// @custom:selector 0x1fdbc0b3
    event AgentTransferFromCommitted(uint64 indexed policyID, address indexed from, address indexed to, uint256 amount);
    /// @custom:selector 0xa7c991dc
    event AgentTransferToUncommitted(uint64 indexed policyID, address indexed from, address indexed to, uint256 amount);
    /// @custom:selector 0x63bd79ea
    event AgentWithdrawFromCommitted(uint64 indexed policyID, address indexed from, address indexed to, uint256 amount);

    // --------------------------------------------- //
    //                    Yield                      //
    // --------------------------------------------- //
    /// @custom:selector 0x6c93063a
    event BoostYield(
        address indexed sender,
        address indexed yieldOriginator,
        uint256 indexed validatorId,
        uint256 amount,
        bool sharesBurned
    );

    // --------------------------------------------- //
    //           Capital Allocator events            //
    // --------------------------------------------- //
    /// @custom:selector 0xe8f686fe
    event RequestUnstake(address indexed owner, uint256 shares, uint256 amountMon, uint256 completionEpoch);
    /// @custom:selector 0xba4e3b2e
    event CompleteUnstake(address indexed owner, uint256 amountMon);
    /// @custom:selector 0x7429a06e
    event ValidatorAdded(uint256 validatorId, address coinbase);
    /// @custom:selector 0xc62b7381
    event ValidatorNotFoundInActiveSet(
        uint64 validatorId, address coinbase, uint64 internalEpoch, uint256 detectionIndex
    );
    /// @custom:selector 0xddb6b82e
    event ValidatorMarkedInactive(uint64 validatorId, address coinbase, uint64 internalEpoch);
    /// @custom:selector 0x69bbed99
    event InactiveValidatorRewardsRedirected(uint64 indexed validatorId, uint256 amount);
    /// @custom:selector 0x12048e17
    event ValidatorDeactivated(uint256 validatorId);
    /// @custom:selector 0x831bd670
    event ValidatorUnstakeCompleted(uint256 indexed validatorId, uint256 amount, uint256 withdrawId);
    /// @custom:selector 0xd1f415bb
    event LowValidatorStakeDeltaOnDecrease(
        address coinbase,
        uint64 validatorId,
        uint64 globalEpoch,
        uint128 targetStakeAmount,
        uint128 netAmount,
        bool inActiveSetCurrent,
        bool inActiveSetLast
    );
    /// @custom:selector 0xe2aa2cd3
    event LowValidatorStakeDeltaOnIncrease(
        address coinbase,
        uint64 validatorId,
        uint64 globalEpoch,
        uint128 targetStakeAmount,
        uint128 netAmount,
        bool inActiveSetCurrent,
        bool inActiveSetLast
    );
    /// @custom:selector 0x7a444ffd
    event LowValidatorStakeDeltaNetZero(
        address coinbase,
        uint64 validatorId,
        uint64 globalEpoch,
        uint128 targetStakeAmount,
        uint128 netAmount,
        bool inActiveSetCurrent,
        bool inActiveSetLast
    );
    /// @custom:selector 0x2ca8882a
    event InsufficientLocalBalance(
        uint256 expectedAmount, uint256 actualAmount, uint256 balance, uint256 totalSupply, uint256 actionIndex
    );

    /// @custom:selector 0xd83c6078
    event PartialValidatorRewardsPayment(
        uint64 validatorId, uint120 amountSent, uint120 amountRequested, uint256 balance
    );
    /// @custom:selector 0xb14d34e3
    event WithdrawSettlementDelayed(
        address coinbase,
        uint64 validatorId,
        uint64 globalEpoch,
        uint256 expectedWithdrawAmount,
        uint256 availableWithdrawAmount,
        uint8 withdrawalId
    );
    /// @custom:selector 0xec028431
    event QueuesOffsetViaNet(
        uint256 offsetAmount,
        uint256 globalUnstakableAmount,
        uint256 queueForUnstake,
        uint256 globalStakableAmount,
        uint256 queueToStake
    );
    /// @custom:selector 0xd9da440b
    event ReservesIncreasedBySurplusDeposits(uint256 netToReserves);
    /// @custom:selector 0x1f7b809c
    event ReservesIncreasedByExcessQueueCapacity(uint256 netToReserves);
    /// @custom:selector 0x46360e9d
    event UnstakingQueueExceedsUnstakableAmount(uint256 queueForUnstake, uint256 unstakableAmount);
    /// @custom:selector 0x489f5f74
    event UnstakingDustQueueRolledForward(
        uint64 epoch, uint256 amountRolled, uint256 remainingQueueForUnstake, uint256 nextQueueForUnstake
    );
    /// @custom:selector 0x775610ca
    event StakeUnassignableNoGlobalRevenue(uint256 queueToStake);
    /// @custom:selector 0x6b2dd4fd
    event StakingQueueExceedsStakableAmount(uint256 queueToStake, uint256 stakableAmount);
    /// @custom:selector 0x41c24504
    event UnregisteredValidatorRevenue(uint64 epoch, uint256 rewardsSentToValidator, uint256 revenueToShMonad);
    /// @custom:selector 0xa6189399
    event CrankSkippedOnValidatorIdZero(address coinbase);

    /// @custom:selector 0x45ef01ba
    event UnexpectedNoValidators(uint64 epoch, uint256 queueToStakeRolled, uint256 queueForUnstakeRolled);
    /// @custom:selector 0x8bd0ad85
    event UnexpectedGoodwill(uint64 epoch, uint256 goodwillAmount);
    /// @custom:selector 0xc1c30cfc
    event UnexpectedPooledWithdrawalDeficit(
        uint64 valId, uint64 shMonEpoch, uint256 expectedAmount, uint256 actualAmount
    );
    /// @custom:selector 0x5dc5856f
    event UnexpectedFailureInitiateStake(
        address coinbase, uint64 valId, uint128 nextTargetStakeAmount, uint128 netAmount
    );
    /// @custom:selector 0x3f91c9d6
    event UnexpectedFailureInitiateUnstake(
        address coinbase, uint64 valId, uint128 nextTargetStakeAmount, uint128 netAmount
    );
    /// @custom:selector 0x6a4eb97f
    event UnexpectedValidatorRewardsPayError(
        address coinbase, uint64 valId, uint128 validatorRewardsPayable, uint256 addressThisBalance, uint256 actionIndex
    );
    /// @custom:selector 0x59fb2c26
    event UnexpectedYieldSettlementError(
        address coinbase, uint64 valId, uint128 amountRewarded, uint256 addressThisBalance, uint256 actionIndex
    );
    /// @custom:selector 0x138acd4a
    event UnexpectedStakeSettlementError(address coinbase, uint64 valId, uint128 amountReceived, uint256 actionIndex);
    /// @custom:selector 0xf8d9ad0c
    event UnexpectedPendingStakeExceedsExpectedActive(
        uint64 valId, uint64 shMonEpoch, uint256 pendingStake, uint256 expectedTotalStake
    );
    /// @custom:selector 0x58ae497b
    event UnexpectedPendingStakeExpectedIsNotActual(
        uint64 valId, uint64 shMonEpoch, uint256 pendingExpected, uint256 pendingActual
    );
    /// @custom:selector 0x2471537e
    event UnexpectedActiveStakeExpectedIsNotActual(
        uint64 valId, uint64 shMonEpoch, uint256 activeExpected, uint256 activeActual
    );
    /// @custom:selector 0x42dcd2f1
    event UnexpectedTotalStakeExpectedIsNotActual(
        uint64 valId,
        uint64 shMonEpoch,
        uint256 totalExpected,
        uint256 totalActual,
        uint256 withdrawalsExpected,
        uint256 withdrawalsActual,
        uint256 depositsExpected,
        uint256 depositsActual
    );
    /// @custom:selector 0xa17e0e2a
    event UnexpectedPrincipalStakeDeficit(
        uint64 valId, uint64 shMonEpoch, uint256 totalExpected, uint256 totalActual, uint256 principalDeficit
    );
    /// @custom:selector 0x7b176f9f
    event UnexpectedStakeWithdrawalsExpectedIsNotActual(
        uint64 valId, uint64 shMonEpoch, uint256 withdrawalsExpected, uint256 withdrawalsActual
    );
    /// @custom:selector 0xb5ca5bab
    event UnexpectedAtomicSettlementUnavailableAssets(
        uint64 shMonEpoch,
        uint256 netUnavailable,
        uint256 stakeIn,
        uint256 unstakeOut,
        uint256 queueToStake,
        uint256 queueForUnstake,
        uint256 distributedAmount,
        uint256 oldAllocatedAmount,
        uint256 newAllocatedAmount
    );

    // --------------------------------------------- //
    //           DirectDelegation events             //
    // --------------------------------------------- //
    /// @custom:selector 0x769214df
    event ZeroYieldTokenConfigured(address indexed token);
    /// @custom:selector 0x71342ff6
    event Delegate(uint256 indexed validatorId, address indexed account, uint256 assets, uint256 vShares);
    /// @custom:selector 0x837cc87f
    event Undelegate(
        uint256 indexed validatorId, address indexed account, uint256 vShares, uint256 assets, uint256 shares
    );
    /// @custom:selector 0xe4cae5f8
    event DepositIsolated(
        uint64 indexed validatorId, address indexed caller, address indexed receiver, uint256 assets, uint256 vShares
    );
    /// @custom:selector 0x487e3c98
    event RequestUnstakeIsolated(
        uint64 indexed validatorId, address indexed owner, uint256 vShares, uint256 amountMon, uint64 completionEpoch
    );
    /// @custom:selector 0xd0e69807
    event CompleteUnstakeIsolated(uint64 indexed validatorId, address indexed owner, uint256 amountMon);
    /// @custom:selector 0xa341aecb
    event IsolatedRedemptionDustWrittenOff(
        uint64 indexed validatorId,
        address indexed owner,
        uint256 requestedAmountMon,
        uint256 paidAmountMon,
        uint256 writtenOffAmountMon
    );
    /// @custom:selector 0x1d00b4ae
    event ClaimDeactivatedIsolated(
        uint64 indexed validatorId, address indexed owner, address indexed receiver, uint256 vShares, uint256 amountMon
    );
    /// @custom:selector 0x0ebbe6b2
    event ValidatorIsolatedWithdrawalRequested(uint64 indexed validatorId, uint8 withdrawalId, uint256 amountMon);
    /// @custom:selector 0x67bcedbb
    event ValidatorIsolatedWithdrawalCompleted(uint64 indexed validatorId, uint8 withdrawalId, uint256 amountMon);
    /// @custom:selector 0xf93ee8b0
    event IsolatedRewardsQueued(
        uint64 indexed validatorId, uint256 grossAmount, uint256 netAmount, uint256 commissionAmount
    );

    /// @custom:selector 0xa00ba9b9
    event SendValidatorRewards(address sender, uint64 valId, uint256 validatorPayout, uint256 feeTaken);

    // --------------------------------------------- //
    //           AtomicUnstakePool events            //
    // --------------------------------------------- //
    /// @custom:selector 0x17295cc5
    event FeeCurveUpdated(
        uint256 oldSlopeRateRay, uint256 oldYInterceptRay, uint256 newSlopeRateRay, uint256 newYInterceptRay
    );

    // --------------------------------------------- //
    //           ValidatorRegistry events            //
    // --------------------------------------------- //
    /// @custom:selector 0xc5fe86e4
    event AdminCommissionClaimedAsShares(address indexed recipient, uint256 assets, uint256 shares);
    /// @custom:selector 0x661833a2
    event CoinbaseContractUpdated(uint64 valId, address oldCoinbase, address newCoinbase);
    /// @custom:selector 0x41dd65f9
    event CoinbaseBeaconInitialized(address beacon, address implementation);
    /// @custom:selector 0xc3754e1c
    event CoinbaseBeaconImplementationUpgraded(address beacon, address oldImplementation, address newImplementation);
    /// @custom:selector 0x64e639eb
    event CodeUpgradeAuthorityUpdated(address indexed oldAuthority, address indexed newAuthority);
    /// @custom:selector 0x451589bc
    event CoinbaseMigrationConfigImported(uint64 valId, address oldCoinbase, address newCoinbase);
    /// @custom:selector 0xf77b90a2
    event CoinbaseMigrationConfigImportFailed(uint64 valId, address oldCoinbase, address newCoinbase);
    /// @custom:selector 0x97dd3144
    event CoinbaseMigrationResidualBalance(uint64 valId, address oldCoinbase, uint256 residualBalance);
    /// @custom:selector 0x70a7de34
    event NonStakingRevenueMultiplierUpdated(uint256 oldMultiplierRay, uint256 newMultiplierRay);
    /// @custom:selector 0xa4f9a5e1
    event StakingYieldDeadbandUpdated(uint16 oldDeadbandBps, uint16 newDeadbandBps);
    /// @custom:selector 0x619d58a9
    event IncludeIsolatedRewardsInStakeAllocationUpdated(bool oldInclude, bool newInclude);
    /// @custom:selector 0x474ac3b3
    event TurnoverQueueUpdated(
        uint64 indexed internalEpoch,
        uint256 previousTurnoverQueueForUnstake,
        uint256 newTurnoverQueueForUnstake,
        uint256 queueForUnstake
    );

    // --------------------------------------------- //
    //           Zero-Yield Tranche events           //
    // --------------------------------------------- //
    /// @custom:selector 0x74fa4be6
    event DepositToZeroYieldTranche(address indexed sender, address indexed receiver, uint256 assets);
    /// @custom:selector 0x2189dd61
    event ZeroYieldBalanceConvertedToShares(address indexed from, address indexed to, uint256 assets, uint256 shares);
}
