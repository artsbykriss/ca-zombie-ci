#!/usr/bin/env bash
# iota-residual / ci/run.sh — heavy-ish CI job: live-state verification for both targets.
# Read-only: public keyless RPCs only. No secrets. Writes JSON into ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
export PYTHONUNBUFFERED=1
python3 ci/verify_live.py 2>&1 | tee ci-out/verify_live.log
echo "=== ci/run.sh done ==="
ls -la ci-out/
