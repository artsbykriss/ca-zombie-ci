#!/usr/bin/env bash
# Sturdy V2 (Ethereum) — light pre-job for the oracle-manipulation / stale-mark residual.
# Picks a working keyless Ethereum RPC, snapshots the 23 strategies + their oracles to
# ci-out/live-state.json, and rebuilds the free-liquidity table. No secrets, no transactions.
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

RPC=$(pick "${FORK_RPC_URL:-}" "https://ethereum-rpc.publicnode.com" "https://1rpc.io/eth" "https://eth.drpc.org" || true)
if [ -z "$RPC" ]; then echo "WARNING: no Ethereum RPC reachable; skipping snapshot"; exit 0; fi
# record only the host — never a full (possibly keyed) URL
echo "using RPC host: $(echo "$RPC" | sed -E 's#(https://[^/]+).*#\1#')"
# make the picked RPC the fork source for the subsequent `forge test` step
echo "FORK_RPC_URL=$RPC" >> "${GITHUB_ENV:-/dev/null}"

FORK_RPC_URL="$RPC" python3 analysis/snapshot.py > ci-out/live-state.json || echo "snapshot failed"
LIVE_STATE=ci-out/live-state.json STRATEGY_TABLE_OUT=ci-out/strategy-table.json \
  python3 analysis/strategy_table.py || echo "table failed"

echo "=== ci-out/live-state.json (head) ==="
head -c 700 ci-out/live-state.json
echo
echo "=== ci-out/strategy-table.json (total) ==="
python3 - <<'PY' 2>/dev/null || true
import json
d = json.load(open("ci-out/strategy-table.json"))
print("block", d["block"], "total_free_usd", d["total_free_usd"])
for r in d["strategies"]:
    print(f'{r["idx"]:>2} {r["assetSymbol"]:<7} {str(r["oracle_name"])[:34]:<34} freeUSD={r["freeUsd"]:>9.2f} maxDev={r["maxOracleDeviation"]} reverts={r["oracle_reverts"]}')
PY
