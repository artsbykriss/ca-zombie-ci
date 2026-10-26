#!/usr/bin/env bash
# ci/run.sh — heavy/networked job for the Hylo-router finding.
# Runs the read-only Solana substitution battery against keyless public RPC.
# No secrets, no keys, no transactions: simulateTransaction only.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

echo "== python =="; python3 -V
python3 -m pip install --quiet --disable-pip-version-check solders 2>&1 | tail -2 || true

echo "== hylo router battery =="
python3 poc/hylo_router_poc.py 2>&1 | tee ci-out/hylo_router_stdout.txt
rc=${PIPESTATUS[0]}

echo "== summary =="
python3 - <<'PY' || true
import json
d = json.load(open("ci-out/hylo_router_results.json"))
print("slot", d["slot"], "| live ix is", d["discriminators"]["live_ix_is"])
for r in d["substitutions"]:
    print(f'  {r["label"]:42s} {r["result"]}')
PY
exit $rc
