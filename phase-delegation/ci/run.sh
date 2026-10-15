#!/usr/bin/env bash
# C2-36 Phase Delegation — CI verification job.
#
# Read-only. Public keyless Solana RPCs only (no secrets anywhere in this repo).
# Re-proves every headline claim of the report from scratch:
#   - pool account owner == canonical SPL Stake Pool program SPoo1...
#   - deployed program ELF sha256 == official program@v2.1.0 release asset
#   - withdraw/deposit authority PDAs, mint authority, fee config, no pending changes
#   - all 110 validator stake accounts PDA-controlled, zero orphans (getProgramAccounts sweep)
#   - totals reconcile, SOL price + USD valuation
# Results -> ci-out/verification.json (+ the release .so used for the hash compare).
set -uo pipefail
cd "$(dirname "$0")/.."

mkdir -p ci-out
echo "[phase-delegation] start $(date -u +%FT%TZ)"
echo "[phase-delegation] python: $(python3 --version 2>&1)"

python3 analysis/verify_all.py
rc=$?
echo "[phase-delegation] verify_all exit=$rc"
ls -la ci-out/ 2>/dev/null || true
exit $rc
