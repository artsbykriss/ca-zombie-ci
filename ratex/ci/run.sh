#!/usr/bin/env bash
# RateX (Solana) heavy job: live-state read + attacker simulation matrix + TVL.
# Runs on GitHub Actions. Read-only; no secrets. Outputs -> ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== RateX probe: live state + simulateTransaction matrix ==="
OUT=ci-out/ratex_results.json python3 analysis/ratex_probe.py 2>&1 | tee ci-out/ratex_probe_stdout.txt
echo "=== RateX TVL (ALT-listed vault token accounts) ==="
python3 analysis/ratex_tvl_probe.py 2>&1 | tee ci-out/ratex_tvl_stdout.txt
cp ratex_tvl.json ci-out/ratex_tvl.json 2>/dev/null || true
echo "=== results ==="
ls -la ci-out
