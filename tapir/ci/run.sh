#!/usr/bin/env bash
# Tapir PoC CI helper — pick a working public Base RPC for the fork test.
# Read-only; no secrets. Exposes BASE_RPC_URL to subsequent workflow steps.
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

# Prefer an injected BASE_RPC_URL if it is actually set and reachable.
PICK=$(pick "${BASE_RPC_URL:-}" \
             "https://base-rpc.publicnode.com" \
             "https://base.drpc.org" \
             "https://mainnet.base.org" || true)

if [ -z "$PICK" ]; then
  echo "WARNING: no working Base RPC found"
else
  echo "Base fork RPC selected: $PICK"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "BASE_RPC_URL=$PICK" >> "$GITHUB_ENV"
  else
    export BASE_RPC_URL="$PICK"
  fi
fi

mkdir -p ci-out
echo "{\"base_rpc_selected\": \"${PICK:+yes}\"}" > ci-out/base_rpc.json
exit 0
