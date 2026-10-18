#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== katana-bridge CI: validation (public RPC, read-only) =="
python3 ci/check.py
echo "== validation OK =="
echo "CI job runs the Foundry suite separately: poc/test/KatanaBridge.t.sol (20 tests)"
