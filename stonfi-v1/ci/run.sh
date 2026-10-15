#!/usr/bin/env bash
# STON.fi v1 (TON) — CI heavy job: local TVM sandbox probes of the DEPLOYED contracts.
# Read-only: fetches public code/data (keyless toncenter) and runs @ton/sandbox in memory.
# No secrets, no mainnet transactions.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p ci-out
WORK="$(mktemp -d)"
cp poc/stonfi_v1_poc.js "$WORK/"
cd "$WORK"
cat > package.json <<'PKG'
{ "name": "stonfi-v1-poc", "private": true, "dependencies": { "@ton/sandbox": "0.22.0", "@ton/core": "0.59.0", "@ton/ton": "15.1.0", "@ton/crypto": "3.3.0" } }
PKG
echo "[ci] npm install..."
npm install --no-audit --no-fund >/dev/null 2>&1 || { echo "[ci] npm install FAILED"; exit 1; }
echo "[ci] running STON.fi v1 sandbox PoC..."
POC_OUT="$ROOT/ci-out/stonfi_v1_poc.json" node stonfi_v1_poc.js > "$ROOT/ci-out/stonfi_v1_poc_stdout.txt" 2>&1
RC=$?
if [ $RC -ne 0 ]; then echo "[ci] PoC FAILED rc=$RC"; tail -40 "$ROOT/ci-out/stonfi_v1_poc_stdout.txt"; exit $RC; fi
node -e "const fs=require('fs');const d=JSON.parse(fs.readFileSync(process.argv[1]));console.log('tests:',d.tests.map(t=>t.name).join(', '));" "$ROOT/ci-out/stonfi_v1_poc.json" || true
echo "[ci] done"; ls -la "$ROOT/ci-out"
