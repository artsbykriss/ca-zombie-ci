#!/usr/bin/env bash
# ci/run.sh — heavy job for the Kolan launch-hook deep dive.
# Runs on GitHub Actions (public repo). No secrets written to disk.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

echo "== Kolan bytecode identity proof (recompile Sourcify source, compare to chain) =="
python3 ci/bytecode_identity.py 2>&1 | tee ci-out/bytecode_identity.log || echo "bytecode_identity failed (see log)"

echo "== copying evidence into ci-out =="
cp -f analysis/live_state.json ci-out/ 2>/dev/null || true
cp -f analysis/bytecode_compare.json ci-out/ 2>/dev/null || true
ls -la ci-out
echo "== done =="
