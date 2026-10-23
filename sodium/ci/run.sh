#!/usr/bin/env bash
# Custom heavy job for the sodium finding (runs on the CI runner; ARB_RPC_URL is set).
# Non-fatal: always exit 0 so the Foundry PoC step still runs and artifacts upload.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[sodium] running account census (ARB_RPC_URL set: $([ -n "${ARB_RPC_URL:-}" ] && echo yes || echo no))..."
python3 ci/census.py > ci-out/census.log 2>&1 || echo "[sodium] census exited non-zero"
echo "[sodium] census tail:"
tail -25 ci-out/census.log 2>/dev/null || true
ls -la ci-out/ || true
exit 0
