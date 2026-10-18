#!/usr/bin/env bash
# ZH4-02 Startale Earn — CI heavy job: live-state dump, recent-epoch census, fork PoC.
# Read-only. Public keyless Soneium RPC only; no secrets are read or written.
set -euo pipefail
cd "$(dirname "$0")/.."

RPC="${SONEIUM_RPC_URL:-https://rpc.soneium.org}"
export SONEIUM_RPC_URL="$RPC"
mkdir -p ci-out

echo "=== live state (latest) ==="
python3 analysis/live_state.py ci-out/live_state.json 30000 | tee ci-out/live_state_summary.txt

echo "=== recent epoch + JIT deposit census (last 30k blocks ~17h) ==="
python3 analysis/scan_epochs.py 30000 ci-out/recent_epochs.json | tee ci-out/scan_summary.txt \
  || echo "WARN: epoch scan failed (public RPC rate limit); PoC still runs below"

echo "=== closing-condition / competitor-bot monitor ==="
python3 analysis/monitor.py 12000 ci-out/monitor.json || true

echo "=== fork PoC (7 tests: control, Play-P 1M/3.5M on small+large epoch, no-lock, daily avg) ==="
( cd poc && forge test -vv --fork-url "$RPC" ) | tee ci-out/forge-test.log
grep -E "RESULT_|\[PASS\]|\[FAIL\]|Suite result" ci-out/forge-test.log > ci-out/poc-results.txt || true

echo "=== done ==="
cat ci-out/poc-results.txt
