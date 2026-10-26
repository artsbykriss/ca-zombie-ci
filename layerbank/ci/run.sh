#!/usr/bin/env bash
# LayerBank (Robinhood Chain 4663) — light pre-job.
# Picks a working keyless Robinhood RPC, exports RH_RPC_URL for the forge step,
# and writes a live-state snapshot to ci-out/live-state.json. No secrets, no transactions.
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

RH=$(pick "https://4663.rpc.thirdweb.com" "https://robinhood.drpc.org" || true)
if [ -z "$RH" ]; then echo "WARNING: no Robinhood RPC reachable; skipping snapshot"; exit 0; fi
echo "RH_RPC_URL=$RH" >> "${GITHUB_ENV:-/dev/null}"
echo "using keyless RPC: $(echo "$RH" | sed -E 's#(https://[^/]+).*#\1#')"

# a second provider for the pinned historical-block fork test (avoids one endpoint's rate limit)
RH2=$(pick "https://robinhood.drpc.org" "https://4663.rpc.thirdweb.com" || true)
[ -n "$RH2" ] && echo "RH_RPC_URL2=$RH2" >> "${GITHUB_ENV:-/dev/null}" && echo "RH_RPC_URL2 -> $(echo "$RH2" | sed -E 's#(https://[^/]+).*#\1#')"

if RH_RPC_URL="$RH" python3 analysis/snapshot.py > ci-out/live-state.json 2>ci-out/snapshot.err; then
  echo "wrote ci-out/live-state.json"
  python3 - <<'PY'
import json
d=json.load(open("ci-out/live-state.json"))
print("block", d["block"], "ts", d["block_timestamp"])
for k,v in d["reserves"].items():
    f=d["feeds"][k]
    dl=d.get("defillama",{}).get(k,{})
    print(f"  {k:5} ltv={v['ltv_bps']/100:5.2f}% borrow={str(v['borrowingEnabled']):5} "
          f"oracle=${v['price_1e8']/1e8:>12,.4f} age={f['age_seconds']}s "
          f"free={v['free_liquidity_human']:>14,.2f} real={dl.get('real')} gap={dl.get('gap_pct')}")
PY
else
  echo "snapshot failed:"; cat ci-out/snapshot.err | tail -20
fi
