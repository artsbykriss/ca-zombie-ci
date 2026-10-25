#!/usr/bin/env bash
# pass7-recon custom heavy job (runs in GitHub Actions, public repo).
# Count reconciliation + live sanity re-reads of the OPEN candidates (keyless public RPCs)
# + secret/keyed-URL scan. Results -> ci-out/ (uploaded as artifacts).
set -uo pipefail
cd "$(dirname "$0")/.."          # -> pass7-recon/
echo "[pass7-recon] python: $(python3 --version 2>&1)"
python3 ci/build_counts.py 2>/dev/null || python3 analysis/build.py
python3 ci/check.py
rc=$?
echo "[pass7-recon] validation exit=$rc"
exit $rc
