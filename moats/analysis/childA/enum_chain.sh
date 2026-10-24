#!/usr/bin/env bash
# Read-only enumeration for one chain via cast. Usage: enum_chain.sh <rpc> <moat1> <moat2> ...
set -u
R="$1"; shift
BLK=$(cast block-number --rpc-url "$R")
echo "chain_block: $BLK"
for M in "$@"; do
  echo "### $M"
  for sig in "owner()(address)" "moatManager()(address)" "stakingToken()(address)" "tokenDecimals()(uint8)" \
      "POINTS_SCALING_FACTOR()(uint256)" "MIN_STAKE_AMOUNT()(uint256)" "totalPoints()(uint256)" \
      "totalStaked()(uint256)" "totalLocked()(uint256)" "totalBurned()(uint256)" "paused()(bool)" \
      "stakingEnabled()(bool)" "lockingEnabled()(bool)" "burningEnabled()(bool)" "earlyExitEnabled()(bool)" \
      "emergencyUnlockEnabled()(bool)" "unstakeFee()(uint256)" "feeCollector()(address)" \
      "getActiveUserCount()(uint256)" "getTotalAmounts()(uint256,uint256,uint256,uint256)" \
      "getRewardTokens()(address[],uint256[],uint256[],uint256[])"; do
    printf '%s = ' "$sig"
    cast call "$M" "$sig" --rpc-url "$R" --block "$BLK" 2>&1 | tr '\n' ' '
    echo
  done
  ST=$(cast call "$M" "stakingToken()(address)" --rpc-url "$R" --block "$BLK")
  printf 'st_decimals = '; cast call "$ST" "decimals()(uint8)" --rpc-url "$R" --block "$BLK" 2>&1
  printf 'st_totalSupply = '; cast call "$ST" "totalSupply()(uint256)" --rpc-url "$R" --block "$BLK" 2>&1
  printf 'moat_st_balance = '; cast call "$ST" "balanceOf(address)(uint256)" "$M" --rpc-url "$R" --block "$BLK" 2>&1
done
