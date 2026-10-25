#!/usr/bin/env bash
# Heavy job for the Nullmask finding (O6). Runs on GitHub Actions.
#
# 1. Cross-chain live-state snapshot (keyless public RPCs) -> ci-out/state.json
# 2. Source <-> deployed-bytecode integrity check for the Base impl -> ci-out/integrity.json
#
# Never prints secrets. The fork test-suite (poc/) is run by the workflow's `forge test` step.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "[nullmask] python deps"
python3 -m pip install --quiet --disable-pip-version-check eth-utils eth-abi >/dev/null 2>&1 || true

echo "[nullmask] 1/2 cross-chain state snapshot"
python3 ci/snapshot.py | tee ci-out/state.stdout.txt || echo "[nullmask] snapshot failed"

echo "[nullmask] 2/2 source<->bytecode integrity (Base impl)"
python3 ci/integrity.py | tee ci-out/integrity.stdout.txt || echo "[nullmask] integrity failed"

echo "[nullmask] results:"
ls -la ci-out/ || true
echo "[nullmask] done"
exit 0
