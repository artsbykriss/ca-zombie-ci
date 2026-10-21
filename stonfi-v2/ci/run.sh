#!/usr/bin/env bash
# STON.fi V2 (TON) — bytecode-level sandbox PoC.
# Read-only: everything runs in @ton/sandbox; no network writes, no keys, no broadcasts.
set -euo pipefail
cd "$(dirname "$0")/../poc"
mkdir -p ../ci-out
npm install --no-audit --no-fund --loglevel=error
set +e
node run.js 2>&1 | tee ../ci-out/poc.log
RC=${PIPESTATUS[0]}
set -e
cp results.json ../ci-out/results.json 2>/dev/null || true
node -e "const r=require('./results.json');console.log('SUMMARY',r.passed+'/'+r.total)" >> ../ci-out/poc.log 2>/dev/null || true
exit $RC
