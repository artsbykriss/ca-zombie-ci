#!/usr/bin/env bash
# Custom CI job for bsc-v4-hook-bank: full-trace fork run, saved to ci-out/.
# (The generic workflow also runs `forge test -vvv` afterwards.)
set -uo pipefail
mkdir -p ci-out
echo "BSC fork trace run $(date -u +%FT%TZ)" > ci-out/forge-trace.txt
if [ -z "${BSC_RPC_URL:-}" ]; then
  echo "WARN: BSC_RPC_URL not set in CI env; falling back to public RPC" >> ci-out/forge-trace.txt
fi
( cd poc && forge test -vvvv ) >> ci-out/forge-trace.txt 2>&1 || true
echo "=== forge-trace.txt tail ==="
tail -c 4000 ci-out/forge-trace.txt
