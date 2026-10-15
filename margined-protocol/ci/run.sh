#!/usr/bin/env bash
# Custom CI job for margined-protocol (Neutron + Osmosis, CosmWasm).
# Read-only: public LCD queries + read-only tx dry-runs (simulate, never broadcast).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "== margined-protocol verification (read-only) =="
python3 --version
python3 ci/verify.py 2>&1 | tee ci-out/verify.log
echo "== done =="
