#!/usr/bin/env bash
# Loopscale Curation (Solana) heavy job: live-state read + gating simulation matrix + vault value.
# Runs on GitHub Actions. Read-only; no secrets. Outputs -> ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== Loopscale Curation probe: Exponent strategy vaults + gating sims ==="
OUT=ci-out/loopscale_results.json python3 analysis/loopscale_probe.py 2>&1 | tee ci-out/loopscale_probe_stdout.txt
echo "=== recent instruction-tag scan (informational) ==="
python3 analysis/exponent_ixscan.py 2>&1 | tee ci-out/exponent_ixscan_stdout.txt || true
echo "=== results ==="
ls -la ci-out
