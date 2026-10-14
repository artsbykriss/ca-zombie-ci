#!/usr/bin/env bash
# MinMax Finance (IoTeX) — CI heavy job.
# Runs the live-state dump, the extraction simulation, the swap-call-path verification and the
# event liveness scan against the keyless public IoTeX RPC. All results land in ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

RPC_FALLBACK="${IOTEX_RPC:-https://babel-api.mainnet.iotex.io}"
echo "RPC: $RPC_FALLBACK" > ci-out/run_meta.txt
date -u >> ci-out/run_meta.txt

echo "=== 1) state dump ==="
python3 analysis/state_dump.py ci-out/state_dump.json 2>&1 | tee ci-out/state_dump.log | tail -25

echo "=== 2) extraction simulation (best closed cycles) ==="
python3 analysis/extract_sim.py ci-out/extract_sim_out.json 2>&1 | tee ci-out/extract_sim.log | tail -40

echo "=== 3) swap() call-path verification (eth_call) ==="
python3 analysis/verify_swaps.py ci-out/verify_swaps.json 2>&1 | tee ci-out/verify_swaps.log | tail -15 || true

echo "=== 4) event liveness scan (last 30k blocks) ==="
python3 analysis/scan_events.py ci-out/events_scan.json 2>&1 | tee ci-out/events_scan.log | tail -25 || true

echo "=== 5) LP data ==="
python3 analysis/lp_data.py 2>&1 | tee ci-out/lp_data.log | tail -15 || true
[ -f pool_lp_data.json ] && cp pool_lp_data.json ci-out/ || true

echo "=== ci-out contents ==="
ls -la ci-out/
echo "=== done ==="
