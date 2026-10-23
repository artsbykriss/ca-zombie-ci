#!/usr/bin/env bash
# pass3-recon — light read-only re-verification of the OPEN list.
# No secrets. Public/keyless RPCs only. Writes ci-out/open-list-check.json
set -uo pipefail
OUT="$(cd "$(dirname "$0")/.." && pwd)/ci-out"
mkdir -p "$OUT"
JSON="$OUT/open-list-check.json"
echo "{" > "$JSON"
echo "  \"generated_utc\": \"$(date -u +%FT%TZ)\"," >> "$JSON"
echo "  \"mode\": \"read-only eth_getCode / eth_call (no tx)\"," >> "$JSON"
echo "  \"targets\": [" >> "$JSON"

q(){ curl -s -m 25 -X POST "$1" -H 'Content-Type: application/json' -d "$2"; }
first=1
# helper: emit one target row.  args: name chain rpc method params
row(){
  local name="$1" chain="$2" rpc="$3" method="$4" params="$5"
  local res
  res=$(q "$rpc" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}")
  local r
  r=$(printf '%s' "$res" | sed -n 's/.*"result":"\([^"]*\)".*/\1/p')
  [ -z "$r" ] && r=$(printf '%s' "$res" | sed -n 's/.*"result":\([0-9a-fx]*\).*/\1/p')
  local codesz
  codesz=$(( (${#r} - 2) / 2 ))
  [ "$first" = 1 ] || echo "," >> "$JSON"
  first=0
  printf '    {"name":"%s","chain":"%s","method":"%s","code_bytes":%s,"result_prefix":"%s"}' \
    "$name" "$chain" "$method" "$codesz" "$(printf '%s' "$r" | cut -c1-20)" >> "$JSON"
}
ARB=https://arb1.arbitrum.io/rpc
AVAX=https://api.avax.network/ext/bc/C/rpc
ETH=https://ethereum-rpc.publicnode.com
BSC=https://bsc-dataseed.bnbchain.org

# MUX Perps (Arbitrum) — reader + MUX3 diamond
row "MUX Perps reader"   arbitrum "$ARB" eth_getCode '["0x437CEa956B415e97517020490205c07f4a845168","latest"]'
row "MUX3 core diamond"  arbitrum "$ARB" eth_getCode '["0x85c8F4a67F4f9AD7b38e875c8FeDE7F4c878bFAc","latest"]'
# HiYield (Avalanche) — T-bill proxy + USDC custody
row "HiYield Tbill proxy" avalanche "$AVAX" eth_getCode '["0x8475509d391e6ee5A8b7133221CE17019D307B3E","latest"]'
row "HiYield Tbill USDC bal" avalanche "$AVAX" eth_call '[{"to":"0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E","data":"0x70a082310000000000000000000000008475509d391e6ee5A8b7133221CE17019D307B3E"},"latest"]'
# SMARDEX USDN (Ethereum) — protocol proxy
row "SMARDEX USDN protocol" ethereum "$ETH" eth_getCode '["0x656cB8C6d154Aad29d8771384089be5B5141f01a","latest"]'
# Venus Flux (BSC) — Fluid Liquidity proxy
row "Venus Flux Fluid Liq" bsc "$BSC" eth_getCode '["0x52Aa899454998Be5b000Ad077a46Bbe360F4e497","latest"]'
# Premia V3 (Arbitrum) — diamond factory
row "Premia V3 factory" arbitrum "$ARB" eth_getCode '["0x89b36ce3491f2258793c7408bd46aac725973ba2","latest"]'

echo "" >> "$JSON"
echo "  ]" >> "$JSON"
echo "}" >> "$JSON"
echo "[ci] wrote $JSON"
cat "$JSON"
