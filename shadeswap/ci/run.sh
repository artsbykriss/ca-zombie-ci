#!/usr/bin/env bash
# ShadeSwap (Secret Network) — CI verification job (read-only; public keyless endpoints only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p ci-out

python3 -m pip install --quiet --disable-pip-version-check cryptography 2>/dev/null || pip3 install --quiet cryptography || true

python3 ci/ci_check.py 2>&1 | tee ci-out/ci-run.log
echo "CI check finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
