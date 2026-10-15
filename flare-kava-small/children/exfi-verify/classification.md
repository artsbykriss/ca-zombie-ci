# Stake manager — every recovered-ABI function classified (independent)

`fresh-caller` column = live `eth_call` from a keyless fresh EOA (0x4444…4444).

| function | mutability | class | to-self | claim+ | others | note | fresh-caller live |
|---|---|---|---|---|---|---|---|
| `addVoting(uint256,uint256)` | nonpayable | ADMIN | no | no | no | governor-only | execution reverted: EnosysGovernanceStakeManager: Not a governor |
| `renounceOwnership()` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `transferOwnership(address)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateApyCloudVault(address)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateGovernor(address,bool)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateRewardAmountByToken(address,uint256)` | nonpayable | ADMIN | no | no | no | notifier-only (apyCloud 0xb8d1c66a) | execution reverted: EnosysGovernanceStakeManager: Not allowed reward notifier |
| `updateRewardTokensAdd(address)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateRewardTokensRemove(uint256)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateTotalSupplyAggregationRange(uint256)` | nonpayable | ADMIN | no | no | no | Ownable | execution reverted: Ownable: caller is not the owner |
| `updateVoting(uint256,bool)` | nonpayable | ADMIN | no | no | no | governor-only | execution reverted: EnosysGovernanceStakeManager: Not a governor |
| `acceptOwnership()` | nonpayable | INIT | no | no | no | requires being pendingOwner (0x0 live) | execution reverted: Ownable2Step: caller is not the new owner |
| `initialize(address,uint256,address[],address)` | nonpayable | INIT | no | no | no | already initialized (live revert) | execution reverted: Initializable: contract is already initialized |
| `stake(uint256)` | nonpayable | VALUE-IN | no | no | no | pulls stakingToken from msg.sender; credits msg.sender | execution reverted: EXFI: Transfer exceeds balance |
| `stakeToWithHint(uint256,address,uint256)` | nonpayable | VALUE-IN | no | no | donation only | credits arbitrary recipient with caller's tokens; no past-epoch balance | execution reverted: EXFI: Transfer exceeds balance |
| `stakeToWithPermit(uint256,address,uint256,uint256,uint8,bytes32,bytes32)` | nonpayable | VALUE-IN | no | no | donation only | same + valid permit required | execution reverted: EXFI: invalid signature |
| `stakeWithHint(uint256,uint256)` | nonpayable | VALUE-IN | no | no | no | hint validated; oversized reverts (live) | execution reverted: EXFI: Transfer exceeds balance |
| `stakeWithPermit(uint256,uint256,uint256,uint8,bytes32,bytes32)` | nonpayable | VALUE-IN | no | no | no | valid permit required | execution reverted: EXFI: invalid signature |
| `claimRewards()` | nonpayable | VALUE-OUT | no | no | no | pays only msg.sender's own sum(balanceOfEpoch*rate); advances claim epoch | execution reverted: EnosysGovernanceStakeManager: No any rewards |
| `exit()` | nonpayable | VALUE-OUT | no | no | no | msg.sender only | execution reverted: EnosysGovernanceStakeManager: Amount is zero |
| `exitWithHint(uint256)` | nonpayable | VALUE-OUT | no | no | no | msg.sender only | execution reverted: EnosysGovernanceStakeManager: Amount is zero |
| `withdraw(uint256)` | nonpayable | VALUE-OUT | no | no | no | amount <= balanceOf(msg.sender) | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawAndGetReward(uint256)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawAndGetRewardWithHint(uint256,uint256)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawReturnedFees(bool)` | nonpayable | VALUE-OUT | no | no | no | own returned fees; live no-op with false | execution reverted: EnosysGovernanceStakeManager: No pending fees |
| `withdrawReturnedFeesTo(address,bool)` | nonpayable | VALUE-OUT | no | no | no | recipient param; record keyed by msg.sender | execution reverted: EnosysGovernanceStakeManager: No pending fees |
| `withdrawTo(uint256,address)` | nonpayable | VALUE-OUT | no | no | no | recipient param; live-tested | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawToAndGetReward(uint256,address)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawToAndGetRewardWithHint(uint256,address,uint256)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawToWithHint(uint256,address,uint256)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `withdrawWithHint(uint256,uint256)` | nonpayable | VALUE-OUT | no | no | no |  | execution reverted: EnosysGovernanceStakeManager: Cannot withdraw, exceed the balance |
| `DECIMAL_PRECISION()` | view | VIEW | no | no | no | constant 1e18 |  |
| `DURATION()` | view | VIEW | no | no | no | 86400 |  |
| `ZERO_EPOCH_START()` | view | VIEW | no | no | no | epoch origin 1759406400 |  |
| `_1pct()` | view | VIEW | no | no | no | constant helper |  |
| `_totalSupply()` | view | VIEW | no | no | no | same storage as totalSupply |  |
| `apyCloud()` | view | VIEW | no | no | no | notifier address |  |
| `apyCloudVault()` | view | VIEW | no | no | no | vault address |  |
| `balanceOf(address)` | view | VIEW | no | no | no | stake balance |  |
| `balanceOfEpoch(address,uint256)` | view | VIEW | no | no | no | checkpoint balance at epoch snapshot |  |
| `canClaimRewards(address)` | view | VIEW | no | no | no |  |  |
| `checkpoints(address,uint256)` | view | VIEW | no | no | no | user checkpoint array |  |
| `epochInterval(uint256)` | view | VIEW | no | no | no |  |  |
| `epochRewardRate(uint256,address)` | view | VIEW | no | no | no |  |  |
| `epochSnapshotBlock(uint256)` | view | VIEW | no | no | no |  |  |
| `getAllUnclaimedRewards(address)` | view | VIEW | no | no | no |  |  |
| `getBalanceAt(address,uint256)` | view | VIEW | no | no | no | checkpoint binary search |  |
| `getBalanceHint(address)` | view | VIEW | no | no | no | 3 for accounts with checkpoints, 0 otherwise (live) |  |
| `getCurrentEpoch()` | view | VIEW | no | no | no |  |  |
| `getLatestEpochForRewards()` | view | VIEW | no | no | no |  |  |
| `getNextEpoch()` | view | VIEW | no | no | no |  |  |
| `getPreviousEpoch()` | view | VIEW | no | no | no |  |  |
| `getRewardTokens()` | view | VIEW | no | no | no | 8 tokens |  |
| `getTotalSupplyEpochAggregationCheckpoints(uint256)` | view | VIEW | no | no | no |  |  |
| `getUserLastVotingBlock(address)` | view | VIEW | no | no | no |  |  |
| `getUserPendingFeesCheckpoints(address)` | view | VIEW | no | no | no |  |  |
| `getUserUnprocessedFees(address)` | view | VIEW | no | no | no |  |  |
| `getVotingCheckpoints()` | view | VIEW | no | no | no | 3 historical votings |  |
| `governors(address)` | view | VIEW | no | no | no |  |  |
| `isStakeOrWithdrawInEpoch(uint256)` | view | VIEW | no | no | no |  |  |
| `lockedFeesByEpoch(uint256)` | view | VIEW | no | no | no | 0 for recent epochs |  |
| `owner()` | view | VIEW | no | no | no | EOA 0x28591a8d |  |
| `pendingOwner()` | view | VIEW | no | no | no | 0x0 live |  |
| `rewardTokens(uint256)` | view | VIEW | no | no | no |  |  |
| `stakingToken()` | view | VIEW | no | no | no | EXFI |  |
| `totalBurnedFees()` | view | VIEW | no | no | no | 0 |  |
| `totalLockedFees()` | view | VIEW | no | no | no | 0.022 EXFI historical |  |
| `totalSupply()` | view | VIEW | no | no | no |  |  |
| `totalSupplyAggregatedByCheckpoint(uint256)` | view | VIEW | no | no | no |  |  |
| `totalSupplyAggregationRange()` | view | VIEW | no | no | no | 1000 |  |
| `totalSupplyByEpoch(uint256)` | view | VIEW | no | no | no |  |  |
| `totalSupplyEpochAggregationCheckpoints(uint256,uint256)` | view | VIEW | no | no | no |  |  |
| `userLastCheckedVotingBlock(address)` | view | VIEW | no | no | no |  |  |
| `userLastRewardClaimEpoch(address)` | view | VIEW | no | no | no |  |  |
| `userPaidFees(address)` | view | VIEW | no | no | no |  |  |
| `userPendingFeesCheckpoints(address,uint256)` | view | VIEW | no | no | no |  |  |
| `userPendingVotingFees(address,uint256)` | view | VIEW | no | no | no |  |  |
| `usersCheckpointsCount(address)` | view | VIEW | no | no | no |  |  |
| `votingCheckpoints(uint256)` | view | VIEW | no | no | no |  |  |
| `votingsByCheckpoint(uint256)` | view | VIEW | no | no | no |  |  |
| `votingsByGovernors(address,uint256)` | view | VIEW | no | no | no |  |  |

## Bytecode-only extras (4 selectors not in the frontend ABI)

| function | class | to-self | claim+ | others | note |
|---|---|---|---|---|---|
| `updateTotalSupplyByEpochIfNeeded(uint256) [0xa63d3646]` | ADMIN/permissionless | no | no | no | settled-epoch finaliser; idempotent live (S4) |
| `apyCloud() raw getter [0xa5032f3c]` | VIEW | no | no | no | returns notifier 0xb8d1c66a |
| `withdrawReturnedFeesTo(address,bool) [0x1ae78c48]` | VALUE-OUT | no | no | no | same as withdrawReturnedFees with recipient |
| `getBalanceHint(address) [0x0a55048a]` | VIEW | no | no | no | search hint only |
