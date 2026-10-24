#!/usr/bin/env bash
# Robinhood Chain (4663) — light pre-job for the Morpho equity-oracle staleness finding.
# Picks a working keyless Robinhood RPC, exports RH_RPC_URL for the forge step, and writes a
# live-state snapshot to ci-out/live-state.json. No secrets, no transactions.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

pick() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
    case "$r" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}

RH=$(pick "https://robinhood.drpc.org" "https://4663.rpc.thirdweb.com" || true)
if [ -z "$RH" ]; then echo "WARNING: no Robinhood RPC reachable; skipping snapshot"; exit 0; fi
echo "RH_RPC_URL=$RH" >> "${GITHUB_ENV:-/dev/null}"
echo "using keyless RPC: $(echo "$RH" | sed -E 's#(https://[^/]+).*#\1#')"

RH_RPC_URL="$RH" python3 analysis/snapshot.py > ci-out/live-state.json
echo "wrote ci-out/live-state.json:"
cat ci-out/live-state.json
