#!/usr/bin/env bash
# rpc.sh — keyless Filecoin FEVM JSON-RPC helper with endpoint rotation.
# Usage: rpc.sh <method> '<params-json>'   e.g. rpc.sh eth_blockNumber '[]'
# No secrets: public endpoints only.
set -uo pipefail
METHOD="${1:?usage: rpc.sh method params}"
PARAMS="${2:-[]}"
ENDPOINTS=(
  "https://api.node.glif.io/rpc/v1"
  "https://filecoin.drpc.org"
  "https://rpc.ankr.com/filecoin"
)
BODY="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$METHOD\",\"params\":$PARAMS}"
for ep in "${ENDPOINTS[@]}"; do
  for try in 1 2 3; do
    out=$(curl -s -m 30 -X POST -H 'Content-Type: application/json' -A 'Mozilla/5.0' --data "$BODY" "$ep")
    if [ -n "$out" ] && ! echo "$out" | grep -q '"error"'; then
      echo "$out"; exit 0
    fi
    sleep 2
  done
done
echo "{\"error\":\"all endpoints failed\",\"method\":\"$METHOD\"}"
exit 1
