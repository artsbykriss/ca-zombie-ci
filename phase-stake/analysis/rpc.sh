#!/usr/bin/env bash
# Read-only Solana RPC helper (keyless public endpoints only; no secrets in file).
# Usage: ./rpc.sh <method> '<params-json-array>'
RPC_LIST=(
  "https://solana-rpc.publicnode.com"
  "https://api.mainnet-beta.solana.com"
)
METHOD="$1"
PARAMS="${2:-[]}"
for u in "${RPC_LIST[@]}"; do
  out=$(curl -s -m 30 -X POST "$u" -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$METHOD\",\"params\":$PARAMS}")
  if echo "$out" | grep -q '"result"'; then
    echo "$out"
    exit 0
  fi
done
echo "$out"
exit 1
