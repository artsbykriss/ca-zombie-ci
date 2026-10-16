#!/usr/bin/env bash
# CI extra job for the L6 Fables re-probe. Keyless public RPC only; read-only.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[ci] live-state dump"
python3 ci/dump_live.py || echo "[ci] dump_live failed (non-fatal)"
echo "[ci] done"
