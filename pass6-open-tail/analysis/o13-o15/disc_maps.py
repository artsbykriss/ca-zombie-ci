#!/usr/bin/env python3
"""Build discriminator maps for the three programs from their known instruction names."""
import hashlib, json, re

def camel_to_snake(n):
    s = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', n)
    s = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s)
    return s.lower()

def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8].hex()

# ---- O13 SolutioFi/DiversiFi (from ELF strings) ----
O13 = ["Initialize","InitializeDeposit","RefundDeposit","Deposit","InitializeWithdrawal",
       "RefundWithdrawal","Withdraw","Rebalance","UpdateOracle","UpdateWeights","UpdateFee",
       "UpdateManager","GetVaultBalances"]

# ---- O14 Overpass ----
O14 = ["InitGlobalConfig","UpdateGlobalConfig","DepositKvault","WithdrawKvault","CreateKlendWrapper",
       "DepositKlend","WithdrawKlend","CreateSaveWrapper","DepositSave","WithdrawSave",
       "CreateLuloProtectedWrapper","DepositLuloProtected","WithdrawLuloProtected",
       "CreateMarginfiWrapper","DepositMarginfi","WithdrawMarginfi","ClaimCreatorFees",
       "UpdateCreatorFee","ClaimProtocolFees"]

# ---- O15 Zodial (marginfi fork) ----
O15 = ["MarginfiGroupInitialize","MarginfiGroupConfigure","ProposeGroupAdminTransfer",
 "AcceptGroupAdminTransfer","CancelGroupAdminTransfer","LendingPoolAddBank",
 "LendingPoolAddBankWithSeed","LendingPoolCloneBank","LendingPoolAddBankPermissionless",
 "LendingPoolConfigureBank","LendingPoolConfigureBankInterestOnly","LendingPoolConfigureBankLimitsOnly",
 "LendingPoolForceTokenlessRepayComplete","LendingPoolConfigureBankOracle","LendingPoolConfigureScopeOracle",
 "LendingPoolApproveScopeRelink","LendingPoolAttestScopeRelink","LendingPoolFinalizeScopeRelink",
 "LendingPoolTripScopeBinding","LendingPoolSetScopeTripEnabled","LendingPoolSetScopeReferenceMaxAge",
 "LendingPoolConfigureBankConfigFlags","LendingPoolSetRwaEquityImmediateTransitionMaxBps",
 "LendingPoolRefreshRwaMultiplierCache","LendingPoolSetFixedOraclePrice","LendingPoolConfigureBankEmode",
 "LendingPoolCloneEmode","LendingPoolReclaimEmissionsVault","LendingPoolHandleBankruptcy",
 "MarginfiAccountInitialize","MarginfiAccountInitLiqRecord","MarginfiAccountCloseLiqRecord",
 "MarginfiAccountInitializePda","MarginfiAccountPlaceOrder","MarginfiAccountCloseOrder",
 "MarginfiAccountKeeperCloseOrder","MarginfiAccountSetKeeperCloseFlags","MarginfiAccountStartExecuteOrder",
 "MarginfiAccountEndExecuteOrder","LendingAccountDeposit","LendingAccountWithdraw",
 "LendingAccountBorrow","LendingAccountCloseBalance","LendingAccountLiquidate",
 "LendingAccountStartFlashloan","LendingAccountEndFlashloan",
 "MarginfiAccountUpdateEmissionsDestinationAccount","LendingPoolAccrueBankInterest",
 "LendingPoolCollectBankFees","LendingPoolWithdrawFees","LendingPoolWithdrawFeesPermissionless",
 "LendingPoolUpdateFeesDestinationAccount","LendingPoolWithdrawInsurance","LendingPoolCloseBank",
 "TransferToNewAccount","TransferToNewAccountPda","MarginfiAccountSetFreeze","MarginfiAccountClose",
 "LendingAccountPulseHealth","LendingPoolPulseBankPriceCache","InitGlobalFeeState","EditGlobalFeeState",
 "ProposeGlobalFeeAdminTransfer","AcceptGlobalFeeAdminTransfer","CancelGlobalFeeAdminTransfer",
 "ProposeGlobalFeeWalletTransfer","ConfirmGlobalFeeWalletTransfer","CancelGlobalFeeWalletTransfer",
 "SetPauseDelegateAdmin","SetGlobalFeatureFlags","PropagateFeeState","ConfigGroupFee",
 "InitStakedSettings","InitPairwiseRiskRegistry","SetPairwiseRiskPairsBatch","DeletePairwiseRiskPair",
 "DeletePairwiseRiskPairsBatch","SyncPairwiseBankRows","RetirePairwiseBankSlot","EditStakedSettings",
 "PropagateStakedSettings","StartLiquidation","EndLiquidation","StartDeleverage","EndDeleverage",
 "InitLpWitnessCache","InitLpWitnessStaging","AppendLpWitnessStagingChunk","FinalizeLpWitnessStaging",
 "CloseLpWitnessStaging","UpsertLpWitnessCacheEntry","PruneLpWitnessCacheEntries",
 "InitLpWitnessScratchCache","CloseLpWitnessScratchCache","UpsertLpWitnessScratchCacheEntry",
 "InitLpWitnessScratchStaging","AppendLpWitnessScratchStagingChunk","FinalizeLpWitnessScratchStaging",
 "CloseLpWitnessScratchStaging","PanicPause","PanicUnpause","PanicUnpausePermissionless",
 "InitBankMetadata","WriteBankMetadata","ConfigureDeleverageWithdrawalLimit","UpdateDeleverageWithdrawals",
 "ConfigureBankRateLimits","ConfigureGroupRateLimits","UpdateGroupRateLimiter","PurgeDeleverageBalance",
 "KaminoInitObligation","KaminoDeposit","KaminoWithdraw","LendingPoolAddBankKamino",
 "LendingPoolAddBankDrift","DriftInitUser","DriftDeposit","DriftWithdraw","DriftHarvestReward",
 "LendingPoolAddBankSolend","SolendInitObligation","SolendDeposit","SolendWithdraw",
 "LendingPoolAddBankJuplend","JuplendDeposit","JuplendWithdraw"]

def build(names):
    m = {}
    for n in names:
        m[disc(camel_to_snake(n))] = camel_to_snake(n)
    return m

all_maps = {"O13": build(O13), "O14": build(O14), "O15": build(O15)}
json.dump(all_maps, open("disc_maps.json","w"), indent=1)
print("O13 deposit =", disc("deposit"))
print("O15 c013c98769cb20de ->", {v:k for k,v in all_maps['O15'].items()}.get('c013c98769cb20de'))
# print all O15 disc -> name
for d,n in sorted(all_maps['O15'].items()):
    print(d, n)
