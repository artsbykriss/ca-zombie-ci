#!/usr/bin/env bash
# CI heavy job for eddyfinance-amm: live-state collection + arb quantification.
# Read-only. Keyless public RPCs only. Results -> ci-out/ (uploaded as artifact).
set -uo pipefail
echo "[eddy] custom CI job start $(date -u +%FT%TZ)"
python3 --version
cd "$(dirname "$0")/.."     # folder root
mkdir -p ci-out
python3 ci/collect.py 2>&1 | tee ci-out/collect.log
echo "[eddy] custom CI job done"
