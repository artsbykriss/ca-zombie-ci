#!/usr/bin/env bash
# Unichain PoC CI helper — pick a working public Unichain RPC for the fork test.
# Read-only; no secrets. Exposes UNICHAIN_RPC_URL to subsequent workflow steps.
set -uo pipefail

pick() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
    case "$r" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}

PICK=$(pick "${UNICHAIN_RPC_URL:-}" \
             "https://mainnet.unichain.org" \
             "https://unichain-rpc.publicnode.com" \
             "https://unichain.drpc.org" || true)

if [ -z "$PICK" ]; then
  echo "WARNING: no working Unichain RPC found"
else
  echo "Unichain fork RPC selected: $PICK"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UNICHAIN_RPC_URL=$PICK" >> "$GITHUB_ENV"
  else
    export UNICHAIN_RPC_URL="$PICK"
  fi
fi

mkdir -p ci-out
echo "{\"unichain_rpc_selected\": \"${PICK:+yes}\"}" > ci-out/unichain_rpc.json

# Live clone scan (read-only RPC). Writes ci-out/immutableproxy_scan.json
if [ -n "$PICK" ]; then
  export UNICHAIN_RPC_URL="$PICK"
fi
python3 "$(dirname "$0")/scan_clones.py" || echo "WARNING: clone scan failed"
exit 0
