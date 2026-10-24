#!/usr/bin/env bash
# Light live-state capture for the INFER/imdUSD report (runs in CI; no secrets printed).
set -uo pipefail
mkdir -p ci-out
R="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
B=$(cast block-number --rpc-url "$R" 2>/dev/null || echo latest)
V=0x0b69F8DA8D8cE521d74Ea69a7A3475B77302EF82
PF=0x070e0603737242B01aBC1D223f7C92D63E86EC97
SF=0x77E1684402869Bf2B7c70B8bf21E1C7Ca7104951
NF=0x014DabF6F940c9C383D9ef48636F70D842F65D7A
RELAY=0x9AEb55c7A16C11B37DC96BD22a33906D1668e20B
ATT=0x5598Aa9146215Bc13eb26f2c692Ad1461Fd32982
SIMD=0x9Efa934D9fAd4AE28c998a40195646b965a97247
USD=0x61aAF8a992A3143e2B0C9cB0030b9fE702854a25
out=ci-out/live-state.txt
{
  echo "fork_block=$B"
  echo "block_ts=$(cast block "$B" --rpc-url "$R" --field timestamp 2>/dev/null)"
  echo "vault_line=$(cast call $V 'line()(uint256)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "vault_totalDebt=$(cast call $V 'totalDebt()(uint256)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "vault_mat=$(cast call $V 'mat()(uint256)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "vault_sIMD_collateral=$(cast call $SIMD 'balanceOf(address)(uint256)' $V --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "imdUSD_supply=$(cast call $USD 'totalSupply()(uint256)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "price_attester=$(cast call $PF 'attester()(address)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "spot_attester=$(cast call $SF 'attester()(address)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "nhi_attester=$(cast call $NF 'attester()(address)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "price_relayer=$(cast call $PF 'relayer()(address)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "price_maxDeviationBps=$(cast call $PF 'maxDeviationBps()(uint256)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "price_latestValue=$(cast call $PF 'latestValue()(uint256,uint64)' --block "$B" --rpc-url "$R" 2>/dev/null | tr '\n' ' ')"
  echo "price_isStale=$(cast call $PF 'isStale()(bool)' --block "$B" --rpc-url "$R" 2>/dev/null)"
  echo "attester_code_len=$(cast code $ATT --rpc-url "$R" 2>/dev/null | wc -c)"
  echo "relay_code_len=$(cast code $RELAY --rpc-url "$R" 2>/dev/null | wc -c)"
} > "$out" 2>/dev/null
echo "wrote $out"; cat "$out"
