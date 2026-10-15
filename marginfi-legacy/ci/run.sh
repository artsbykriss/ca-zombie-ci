#!/usr/bin/env bash
# marginfi-legacy custom CI job: full-account health scan (read-only Solana RPC).
# Runs from the folder root (marginfi-legacy/). Results -> ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[marginfi-legacy] health scan start $(date -u +%FT%TZ)"
python3 ci/scan_health.py 2>&1 | tee ci-out/scan_health.log
rc=${PIPESTATUS[0]}
echo "[marginfi-legacy] health scan exit=$rc $(date -u +%FT%TZ)"
# do not fail the job on scan errors; artifacts are what matter
exit 0
