#!/usr/bin/env bash
# ZH4 Wave-B0 residual reconciliation — CI job.
# Read-only validation + public-RPC live-funds re-reads. No secrets used.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/check.py
rc=$?
echo "[residual-recon] validation exit=$rc"
exit $rc
