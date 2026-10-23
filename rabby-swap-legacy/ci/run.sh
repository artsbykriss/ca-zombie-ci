#!/usr/bin/env bash
# Custom heavy job for the Rabby Swap legacy deep-dive.
# Runs the 19-chain allowance census + per-chain live-state probe + USD valuation.
# Read-only. Never prints secrets. RPC URLs are built from env vars only.
set -uo pipefail

export RABBY_MAX_REQS="${RABBY_MAX_REQS:-1500}"
export RABBY_MAX_SECS="${RABBY_MAX_SECS:-420}"

mkdir -p ci-out/raw

# --- build per-chain Ankr RPC env vars (key stays in the environment) ---
if [ -n "${ANKR_API_KEY:-}" ]; then
  for c in ETH BSC POLYGON AVALANCHE FANTOM OPTIMISM ARBITRUM GNOSIS CRONOS AURORA HARMONY METIS MOONBEAM KLAYTN ASTAR BOBA HECO CELO; do
    slug=$(echo "$c" | tr 'A-Z' 'a-z')
    export "ANKR_$c=https://rpc.ankr.com/$slug/$ANKR_API_KEY"
  done
  echo "[ci] ankr RPCs configured for census"
fi

echo "=================== live-state probe ==================="
python3 analysis/live_state.py analysis/chains.json ci-out/raw 2>&1 | tee ci-out/live_state.log

echo "=================== allowance census ==================="
python3 analysis/census.py analysis/chains.json ci-out/raw 2>&1 | tee ci-out/census.log

echo "=================== NFT operator approvals ==================="
python3 analysis/nft_approvals.py analysis/chains.json ci-out/raw 2>&1 | tee ci-out/nft_approvals.log

echo "=================== valuation ==================="
python3 analysis/valuation.py ci-out/raw ci-out/live_allowance_valuation.json 2>&1 | tee ci-out/valuation.log

echo "=================== aggregate summary ==================="
python3 - <<'PY'
import json, glob, os
recs = []
for p in sorted(glob.glob("ci-out/raw/census_*.json")):
    recs.append(json.load(open(p)))
ls = json.load(open("ci-out/raw/live_state_all.json")) if os.path.exists("ci-out/raw/live_state_all.json") else []
val = json.load(open("ci-out/live_allowance_valuation.json")) if os.path.exists("ci-out/live_allowance_valuation.json") else {}
summary = {
    "chains_probed": len(recs),
    "chains_with_live_router_code": sum(1 for r in ls if r.get("has_code")),
    "chains_unpaused": sum(1 for r in ls if r.get("paused") == "0x" + "0"*64),
    "total_approval_logs": sum(r.get("approval_logs", 0) for r in recs),
    "total_unique_pairs": sum(r.get("unique_pairs", 0) for r in recs),
    "total_unread_pairs": sum(len(r.get("unread_pairs", [])) for r in recs),
    "live_positions": sum(len(r.get("live_positions", [])) for r in recs),
    "total_live_allowance_usd": val.get("total_live_allowance_usd", 0),
    "per_chain": {r["chain"]: {"block": r.get("latest_block"), "source": r.get("source"),
                                "logs": r.get("approval_logs"), "pairs": r.get("unique_pairs"),
                                "unread": len(r.get("unread_pairs", [])),
                                "live": len(r.get("live_positions", [])),
                                "partial": r.get("partial_coverage"),
                                "error": r.get("error")} for r in recs},
}
json.dump(summary, open("ci-out/census_summary.json", "w"), indent=1)
print(json.dumps(summary, indent=1))
PY

echo "[ci] done"
