#!/usr/bin/env bash
# Heavy/CI job for the SunSwap V4 PoolManager target. Public data only, no keys.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out

echo "== environment =="
date -u
python3 --version
curl -s -m 10 -X POST https://api.trongrid.io/wallet/getnowblock -H 'Content-Type: application/json' -d '{}' | head -c 120 || true
echo

echo "== heimdall (decompiler) =="
if ! command -v heimdall >/dev/null 2>&1; then
  curl -sL --retry 3 -m 120 \
    https://github.com/Jon-Becker/heimdall-rs/releases/download/0.9.2/heimdall-linux-amd64 \
    -o /tmp/heimdall || true
  chmod +x /tmp/heimdall 2>/dev/null || true
  export PATH="/tmp:$PATH"
fi
heimdall --version > ci-out/heimdall-version.txt 2>&1 || echo "heimdall unavailable" >> ci-out/heimdall-version.txt
if command -v heimdall >/dev/null 2>&1; then
  heimdall decompile analysis/poolmanager_runtime_only.hex --skip-resolving --include-sol \
    -o ci-out/heimdall -n PoolManager > ci-out/heimdall.log 2>&1 || true
  ls -la ci-out/heimdall >> ci-out/heimdall.log 2>&1 || true
else
  echo "heimdall not available; decompile skipped" > ci-out/heimdall.log
fi

echo "== static guard map =="
python3 analysis/static_checks.py > ci-out/static-checks.txt 2>&1 || true
cp analysis/static_guards.json ci-out/ 2>/dev/null || true

echo "== live read-only snapshot (public TronGrid) =="
python3 analysis/live_sunswap.py > ci-out/live-sunswap.txt 2>&1 || true
cp analysis/live_sunswap.json ci-out/ 2>/dev/null || true

echo "== summary =="
python3 - <<'PY' | tee ci-out/ci-summary.txt
import json, os
for f in ("ci-out/static_guards.json", "ci-out/live_sunswap.json"):
    if os.path.exists(f):
        d = json.load(open(f))
        if "runtime_bytes" in d:
            print("runtime_bytes", d["runtime_bytes"], "selectors", d["selector_count"],
                  "delegatecall", d["opcode_counts"]["DELEGATECALL"],
                  "selfdestruct", d["opcode_counts"]["SELFDESTRUCT"])
        if "pool_manager" in d:
            print("block", d.get("block"), "native_trx", d.get("native_balance_trx"),
                  "paused", d.get("paused"), "pool_count", d.get("pool_count"))
PY

echo "done"
