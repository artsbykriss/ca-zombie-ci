#!/usr/bin/env bash
# Heavy job for ca3-gdc: verify the live residual and run the fork suite.
# Secrets are only used via env vars; nothing keyed is echoed or written.
set -uo pipefail
mkdir -p ci-out

RPC="${BSC_RPC_URL:-https://bsc-dataseed.binance.org}"
LATEST_BLOCK_HEX=$(curl -s -m 20 -X POST -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$RPC" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"])')
echo "[ci] latest block: $LATEST_BLOCK_HEX"

# Archive probe: the pinned/historical blocks need archive state. Prefer a keyed
# archive endpoint from the CI env (built here, never written to disk or echoed).
HIST_BLOCK=$(python3 -c 'print(hex(132546182))')
probe() {
  curl -s -m 25 -X POST -H 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":[{\"to\":\"0xe3349Ca6AC1656e02B20b8d5a4C095e28255eb0A\",\"data\":\"0x0902f1ac\"},
      \"$HIST_BLOCK\"]}" "$1" | grep -q '"result"'
}
ARCHIVE=""
if [ -n "${ANKR_API_KEY:-}" ] && probe "https://rpc.ankr.com/bsc/$ANKR_API_KEY"; then
  ARCHIVE="https://rpc.ankr.com/bsc/$ANKR_API_KEY"
elif [ -n "${NODEREAL_API_KEY:-}" ] && probe "https://bsc-mainnet.nodereal.io/v1/$NODEREAL_API_KEY"; then
  ARCHIVE="https://bsc-mainnet.nodereal.io/v1/$NODEREAL_API_KEY"
elif probe "$RPC"; then
  ARCHIVE="$RPC"
fi
if [ -n "$ARCHIVE" ]; then
  echo "archive support: yes -> RUN_HISTORICAL=1"
  export RUN_HISTORICAL=1
  export BSC_ARCHIVE_RPC_URL="$ARCHIVE"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "RUN_HISTORICAL=1" >> "$GITHUB_ENV"
    echo "BSC_ARCHIVE_RPC_URL=$ARCHIVE" >> "$GITHUB_ENV"
  fi
else
  echo "archive support: no -> historical tests will skip"
fi

# Snapshot of the live state (public, no secrets).
python3 analysis/dump_live_state.py "$RPC" > ci-out/live-state.json || echo "[ci] live-state dump failed"

# Run the full suite; keep a machine-readable copy.
cd poc || exit 1
forge test -vv --json > ../ci-out/forge-test.json 2>../ci-out/forge-test.err
TEST_RC=$?
cd .. || exit 1

python3 - <<'PY' > ci-out/test-summary.json
import json
try:
    d = json.load(open("ci-out/forge-test.json"))
except Exception as e:
    print(json.dumps({"error": str(e)})); raise SystemExit
passed = failed = skipped = 0
results = {}
for suite, s in d.items():
    for name, t in s.get("test_results", {}).items():
        st = t.get("status")
        results[name] = {"status": st, "reason": t.get("reason")}
        if st == "Success": passed += 1
        elif st == "Skipped": skipped += 1
        else: failed += 1
print(json.dumps({"passed": passed, "failed": failed, "skipped": skipped,
                  "total": passed+failed+skipped, "results": results}, indent=2))
PY

echo "[ci] forge exit=$TEST_RC"
cat ci-out/test-summary.json
exit "$TEST_RC"
