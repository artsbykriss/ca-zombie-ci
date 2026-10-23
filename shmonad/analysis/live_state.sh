#!/usr/bin/env bash
# Read-only live-state dump for shMonad (Monad 143). Public RPC only. No keys, no txs.
set -uo pipefail
RPC="${MONAD_RPC:-https://rpc.monad.xyz}"
P=0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c
BLK=$(cast block-number --rpc-url "$RPC")
echo "RPC=$RPC  BLOCK=$BLK"
c() { # c <sig> [args...]
  local sig="$1"; shift
  printf '%-46s' "$sig"
  cast call "$P" "$sig" "$@" --rpc-url "$RPC" --block "$BLK" 2>&1 | head -1
}
c "totalAssets()(uint256)"
c "totalSupply()(uint256)"
c "realTotalSupply()(uint256)"
c "committedTotalSupply()(uint256)"
c "owner()(address)"
c "getCodeUpgradeAuthority()(address)"
c "getInternalEpoch()(uint64)"
c "getGlobalEpoch(int256)(uint64,uint8,bool,bool,bool,bool,bool,bool,uint128)" 0
c "getGlobalStatus(int256)(bool,bool)" 0
c "getAdminValues()(uint64,uint16,uint16,uint16,uint16,uint128)"
c "globalLiabilities()(uint128,uint128,uint128)"
c "getWorkingCapital()(uint128,uint128)"
c "getAtomicCapital()(uint128,uint128)"
c "getAtomicPoolUtilization()(uint256,uint256,uint256,uint256)"
c "getAtomicUtilizationWad()(uint256)"
c "getCurrentUnstakeFeeRateRay()(uint256)"
c "getFeeCurveParams()(uint256,uint256)"
c "getCurrentLiquidity()(uint256)"
c "getTargetLiquidity()(uint256)"
c "getPendingTargetLiquidity()(uint256)"
c "getScaledTargetLiquidityPercentage()(uint256)"
c "getGlobalPending()(uint120,uint120)"
c "getIsolatedTotals()(uint128,uint128,uint128,uint128,uint128)"
c "getGlobalAmountAvailableToUnstake()(uint256)"
c "getMaxUnstakeRequestAmountWithoutDelay()(uint256)"
c "getZeroYieldToken()(address)"
c "unclaimedOwnerCommission()(uint256)"
c "getActiveValidatorCount()(uint256)"
c "isGlobalCrankAvailable()(bool)"
c "getIncludeIsolatedRewardsInStakeAllocation()(bool)"
c "getStakingYieldDeadbandBps()(uint16)"
c "getNonStakingRevenueMultiplierRay()(uint256)"
c "yInterceptRay()(uint256)"
c "slopeRateRay()(uint256)"
c "policyCount()(uint64)"
c "previewDeposit(uint256)(uint256)" 1000000000000000000
c "previewRedeem(uint256)(uint256)" 1000000000000000000
c "convertToShares(uint256)(uint256)" 1000000000000000000
c "convertToAssets(uint256)(uint256)" 1000000000000000000
c "maxRedeem(address)(uint256)" 0x000000000000000000000000000000000000dEaD
echo "--- native balance (wei) ---"
cast balance "$P" --rpc-url "$RPC" --block "$BLK"
echo "--- code sizes ---"
cast codesize "$P" --rpc-url "$RPC"
cast codesize 0x8ee4ff5ff50198dcbb7b882a0781f42724dd095f --rpc-url "$RPC"
