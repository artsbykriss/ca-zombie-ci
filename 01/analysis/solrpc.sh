#!/usr/bin/env bash
# Solana JSON-RPC helper (read-only). Endpoint chosen from env; never prints keys.
# Usage: solrpc.sh <method> '<json-params-array>'
set -euo pipefail
METHOD="$1"; PARAMS="$2"
if [ -n "${ALCHEMY_API_KEY:-}" ]; then
  URL="https://solana-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}"
else
  URL="https://api.mainnet-beta.solana.com"
fi
curl -s --max-time 60 "$URL" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$METHOD\",\"params\":$PARAMS}"
