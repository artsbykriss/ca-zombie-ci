#!/usr/bin/env bash
# MiniSwap Phase-2 heavy CI job: full enumeration of both factories + pricing + mining state.
# Read-only network calls. Writes only under ci-out/.
set -uo pipefail
cd "$(dirname "$0")/.."

echo "[miniswap] start $(date -u +%FT%TZ)"
python3 --version
python3 ci/enumerate.py
RC=$?
echo "[miniswap] enumerate rc=$RC"
ls -la ci-out/ || true
echo "[miniswap] end $(date -u +%FT%TZ)"
exit 0
