#!/usr/bin/env bash
# Read-only live-state reader for Ledgity Yield vaults. Public keyless RPCs only.
# Usage: bash read_state.sh   -> writes analysis/live_state.json
set -uo pipefail
cd "$(dirname "$0")/.."

declare -A R=(
 [ethereum]="https://ethereum-rpc.publicnode.com"
 [base]="https://mainnet.base.org"
 [arbitrum]="https://arbitrum-one-rpc.publicnode.com"
 [linea]="https://rpc.linea.build"
 [sonic]="https://rpc.soniclabs.com"
)
declare -A P=(
 [ethereum_lyUSD]=0x3C769d0e8D21d380228dFB7918c6933bb6ecB6D4
 [ethereum_lyEUR]=0x20968165B7d2cDF33aF632aAB3e0539848d44BC8
 [base_lyUSD]=0x916f179D5D9B7d8Ad815AC2f8570aabF0C6a6e38
 [base_lyEUR]=0xFaA1e3720e6Ef8cC76A800DB7B3dF8944833b134
 [arbitrum_lyUSD]=0x283F35b6406a0e19a786ed119869eF2c0fE157Ee
 [linea_lyUSD]=0x43b3c64dbc95F9eD83795E051fc00014059e698F
 [sonic_lyUSD]=0x65f75c675Cc76474662DfBF7B6e8683764223001
)
FNS=(
 "asset()(address)" "decimals()(uint8)" "totalAssets()(uint256)" "totalSupply()(uint256)"
 "managementFeeRate()(uint256)" "performanceFeeRate()(uint256)" "withdrawalFeeRate()(uint256)"
 "yieldAPR()(uint256)" "lastFeeTime()(uint256)" "lastCompoundTime()(uint256)" "highWaterMark()(uint256)"
 "paused()(bool)" "owner()(address)" "liquidityManager()(address)" "feeRecipient()(address)"
 "hasBufferStrategy()(bool)" "aToken()(address)" "liquidityBufferRate()(uint256)"
 "stakeForInstantWithdrawal()(uint256)" "getWithdrawalRequestCount()(uint256)"
)
OUT="analysis/live_state.json"
DIR="analysis/live_state.d"
rm -rf "$DIR"; mkdir -p "$DIR"

one() {
  local key="$1" addr="$2" rpc="$3"
  local json="{\"chain\":\"${key%%_*}\",\"address\":\"$addr\",\"rpc_host\":\"${rpc#*//}\""
  json="$json,\"block\":$(cast block-number --rpc-url "$rpc" 2>/dev/null || echo null)"
  for fn in "${FNS[@]}"; do
    local name="${fn%%(*}"
    local v; v=$(cast call --rpc-url "$rpc" "$addr" "$fn" 2>&1 | head -1 | sed 's/ \[.*//' )
    json="$json,\"$name\":\"$v\""
  done
  local fd; fd=$(cast call --rpc-url "$rpc" "$addr" "getFeeData()(uint256,uint256)" 2>&1 | tr '\n' '|' | head -c 300)
  json="$json,\"getFeeData\":\"$fd\"}"
  echo "$json" > "$DIR/$key.json"
  echo "DONE $key"
}

for k in "${!P[@]}"; do
  chain="${k%%_*}"; one "$k" "${P[$k]}" "${R[$chain]}" &
done
wait
jq -n --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --slurpfile v <(cat "$DIR"/*.json | jq -s .) '{generated:$ts, vaults:($v[0])}' > "$OUT" 2>/dev/null \
  || jq -s --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{generated:$ts, vaults:(map({(.address): .}) | add)}' "$DIR"/*.json > "$OUT"
echo "wrote $OUT"
