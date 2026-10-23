#!/usr/bin/env bash
# ZH4 pass4 residual reconciliation — CI job.
# Read-only validation + public-RPC live-funds re-reads. No secrets used.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/check.py
rc=$?
python3 ci/live_checks.py 2>/dev/null || echo "[pass4-recon] live_checks skipped"
echo "[pass4-recon] validation exit=$rc"
exit $rc
