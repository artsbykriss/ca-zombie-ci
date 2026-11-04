#!/usr/bin/env bash
# Heavy/mid-weight job for ca3-premia-c1. Read-only; no secrets.
# The Foundry fork suite is run by the workflow after this script.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

# Keyless: ARB_RPC_URL is injected by CI; the script falls back to a public endpoint.
python3 -m pip install --quiet eth-hash >/dev/null 2>&1 || true
python3 analysis/scripts/collect_state.py > ci-out/state_stdout.json 2> ci-out/state_err.txt \
  || echo "collect_state failed (see ci-out/state_err.txt)"
cp analysis/state.json ci-out/state.json 2>/dev/null || true
python3 analysis/scripts/aggregate.py > ci-out/aggregate_stdout.json 2> ci-out/aggregate_err.txt \
  || echo "aggregate failed (see ci-out/aggregate_err.txt)"

exit 0
