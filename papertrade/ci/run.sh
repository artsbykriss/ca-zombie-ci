#!/usr/bin/env bash
# Z3-C3 Papertrade — CI live re-verification job (read-only).
# Runs from the finding folder root (workflow: working-directory: papertrade).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[ci] papertrade live re-verification $(date -u +%FT%TZ)"
python3 ci/snapshot_ci.py 2>&1 | tee ci-out/ci.log
rc=${PIPESTATUS[0]}
echo "[ci] snapshot_ci.py exit=$rc"
exit $rc
