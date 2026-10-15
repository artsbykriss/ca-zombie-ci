#!/usr/bin/env bash
# aurora-dust CI job: re-verify key live state at a pinned block (public RPCs only, no keys).
# Writes ci-out/state-verification.json + prints a human summary.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

python3 analysis/ci_verify.py 2>&1 | tee ci-out/verify.log
exit ${PIPESTATUS[0]}
