#!/usr/bin/env bash
# Z3-C5 · EtherVista deep-dive — heavy CI job (READ-ONLY; no mainnet transactions).
# Runs from the finding folder (workflow: working-directory = <finding>).
# Writes results to ci-out/ (uploaded as artifact). Never prints secrets.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out
export OUTDIR="$PWD/ci-out"

rc=0

echo "=== [1/3] fleet scan: all pairs, code identity, skim excess, K-overflow, USD values ==="
python3 analysis/fleet_scan.py || { echo "FLEET_SCAN_FAILED"; rc=1; }

echo "=== [2/3] bytecode vs verified source (pair / router / factory) ==="
python3 analysis/bytecode_diff.py || { echo "BYTECODE_DIFF_FAILED"; rc=1; }

echo "=== [3/3] extra live-state checks (roles, bindings, balances, LP split) ==="
python3 analysis/extra_checks.py || { echo "EXTRA_CHECKS_FAILED"; rc=1; }

echo "=== ci-out contents ==="
ls -la ci-out || true

exit $rc
