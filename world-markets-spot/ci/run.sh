#!/usr/bin/env bash
# World Markets Spot (Concord Exchange, MegaETH) — custom CI job.
# Read-only: keyless public MegaETH RPC only. No keys, no secrets, no transactions.
# Writes results to ci-out/ (uploaded as CI artifacts).
set -uo pipefail

FOLDER="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$FOLDER/ci-out"
mkdir -p "$OUT"

echo "=== World Markets Spot — CI state dump ==="
echo "folder: $FOLDER"
echo "block/date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if command -v python3 >/dev/null 2>&1; then
  python3 "$FOLDER/ci/dump_state.py" 2>&1 | tee "$OUT/dump.log"
  RC=${PIPESTATUS[0]}
else
  echo "python3 not available" >&2
  RC=1
fi

echo "--- ci-out contents ---"
ls -la "$OUT" || true
echo "exit=$RC"
exit "$RC"
