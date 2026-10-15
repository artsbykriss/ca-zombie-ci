#!/usr/bin/env bash
# Heavy verification job for blocto-staking (runs on CI runner, read-only, public endpoints only).
# Writes everything to ci-out/. No secrets, no transactions to any real network.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p ci-out/live

echo "=== [1/4] live-state Cadence scripts (public Flow Access API) ==="
for s in global_state cap_probe pass_state; do
  echo "--- $s"
  python3 analysis/flowscript.py "analysis/scripts/$s.cdc" > "ci-out/live/$s.txt" 2>&1 || echo "script $s failed"
  head -c 2000 "ci-out/live/$s.txt"; echo
done

echo "=== [2/4] full staker-record enumeration (29,762 records) ==="
python3 analysis/enumerate_stakers.py 29762 2000 > ci-out/live/staker_enum.log 2>&1 || echo "enumeration failed"
tail -20 ci-out/live/staker_enum.log
cp analysis/staker_enum.json ci-out/live/staker_enum.json 2>/dev/null || true

echo "=== [3/4] top-holder concentration + event scans (dates the freeze) ==="
python3 analysis/top_holders.py > ci-out/live/top_holders.txt 2>&1 || echo "top_holders failed"
cp analysis/top_holders.json ci-out/live/top_holders.json 2>/dev/null || true
HEAD=$(python3 - <<'EOF'
import json, urllib.request
req = urllib.request.Request("https://rest-mainnet.onflow.org/v1/blocks?height=sealed", headers={"User-Agent":"Mozilla/5.0"})
print(int(json.loads(urllib.request.urlopen(req, timeout=60).read())[0]["header"]["height"]))
EOF
)
echo "head=$HEAD"
for ev in NewEpoch MoveToken RewardsPaid TokensUnstaked; do
  echo "--- scanning last 500,000 blocks for $ev"
  python3 analysis/scan_events_parallel.py "A.0f9df91c9121c460.BloctoTokenStaking.$ev" "$HEAD" 500000 "ci-out/live/scan_$ev.json" > "ci-out/live/scan_$ev.log" 2>&1 || echo "scan $ev failed"
  tail -5 "ci-out/live/scan_$ev.log"
done

echo "=== [4/4] Cadence emulator PoC (local only) ==="
if [ -f poc-cadence/run.sh ]; then
  POC_OUT_DIR="$ROOT/ci-out/cadence-poc" POC_DEADLINE=900 bash poc-cadence/run.sh > ci-out/live/cadence_poc.log 2>&1
  echo "poc-cadence exit=$?"
  tail -30 ci-out/live/cadence_poc.log
else
  echo "no poc-cadence/run.sh"
fi

echo "=== DONE ==="
ls -la ci-out/live/ | head -30
