#!/usr/bin/env bash
# Rose (Aurora) CI evidence dump — read-only, keyless public RPC. Writes ci-out/state.json
set -uo pipefail
mkdir -p ci-out
python3 ci/state_dump.py > ci-out/state_dump.log 2>&1 || true
ls -la ci-out/
tail -40 ci-out/state_dump.log
