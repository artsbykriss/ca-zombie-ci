#!/usr/bin/env bash
# BulbaSwap V3 heavy recon job (read-only; keyless public endpoints only).
# Writes artifacts to ../ci-out/ which the workflow uploads.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ci-out"
mkdir -p "$OUT"

echo "### 1. canonical pool init-code verification"
cd "$ROOT/analysis"
python3 "$ROOT/ci/verify_initcode.py" 2>&1 | tee "$OUT/initcode-verify.txt"

echo
echo "### 2. full pool scan (212 pools) + USD"
python3 scan_pools.py 2>&1 | tee "$OUT/scan-pools.log" | tail -3
python3 price_pools.py 2>&1 | tee "$OUT/pool-usd.log"
cp -f pool_usd.json pools_state.json token_meta.json prices.json "$OUT/" 2>/dev/null || true

echo
echo "### 3. position NFT enumeration"
python3 enum_positions.py "$OUT/positions.json" 2>&1 | tee "$OUT/positions.log"

echo
echo "### 4. periphery balance scan (sweepToken surface)"
python3 scan_periphery.py 2>&1 | tee "$OUT/periphery.log"
cp -f periphery_balances.json "$OUT/" 2>/dev/null || true

echo
echo "### 5. exhaustive balance sweep over all 35 deployed contracts"
python3 scan_all_balances.py "$OUT/all_contract_balances.json" 2>&1 | tee "$OUT/all-balances.log"

echo
echo "### CI JOB COMPLETE"
