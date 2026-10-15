#!/usr/bin/env bash
# CI heavy job for pools-finance: run the read-only IOTA devInspect suite and write results.
# No secrets, no keyed RPCs, no transactions. Public RPC only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
WORK="$(mktemp -d)"
cd "$WORK"
npm init -y >/dev/null 2>&1
npm i --no-audit --no-fund @iota/iota-sdk >/dev/null 2>&1
cp "$OLDPWD/ci/devinspect-suite.mjs" .
node devinspect-suite.mjs "$OLDPWD/ci-out/devinspect-results.json"
# quick summary for the log
node -e "
const r=require('$OLDPWD/ci-out/devinspect-results.json');
console.log('checkpoint:',r.block);
for (const t of r.tests) console.log(t.id, t.status, t.error||'', JSON.stringify(t.returns));
" || true
echo "CI devinspect suite done"
