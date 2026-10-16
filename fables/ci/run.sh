#!/usr/bin/env bash
# Heavy/extra CI job for the Fables Z3-H13 probe. Keyless public RPCs only; no secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[ci] live-state dump"
python3 ci/dump_state.py || echo "[ci] dump_state failed (non-fatal)"
echo "[ci] done"
