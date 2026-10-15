#!/usr/bin/env bash
# CI custom job: independent re-verification of Horizon Protocol live state + PoC numbers.
# Uses BSC_RPC_URL from CI env (never printed). Writes ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/verify.py 2>&1 | tee ci-out/verify.log
echo "--- ci-out ---"
ls -la ci-out/
