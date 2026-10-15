#!/usr/bin/env bash
# Virtue (IOTA L1) — CI job: read-only state verification + dev-inspect regression suite.
# Runs from the finding folder (virtue/). No secrets used; public IOTA RPC only.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"   # -> virtue/
cd "$HERE"
mkdir -p ci-out

echo "== [1/3] live state verification (public RPC) =="
python3 ci/verify_state.py 2>&1 | tee ci-out/state_check.log
STATE_RC=${PIPESTATUS[0]}

echo
echo "== [2/3] dev-inspect regression suite =="
NODE_RC=0
SDKDIR="$(mktemp -d)"
cp ci/dev_inspect_tests.mjs "$SDKDIR/"
(
  cd "$SDKDIR"
  npm init -y >/dev/null 2>&1
  npm install @iota/iota-sdk --no-audit --no-fund >/dev/null 2>&1
  if [ -d node_modules/@iota/iota-sdk ]; then
    node dev_inspect_tests.mjs
  else
    echo "npm install failed — dev-inspect suite cannot run"
    exit 2
  fi
) 2>&1 | tee ci-out/dev_inspect_tests.log
NODE_RC=${PIPESTATUS[0]}

echo
echo "== [3/3] summary =="
{
  echo "state_check_rc=$STATE_RC"
  echo "dev_inspect_rc=$NODE_RC"
  echo "checkpoint=$(python3 -c "import json;print(json.load(open('ci-out/state_check.json'))['latest_checkpoint'])" 2>/dev/null || echo n/a)"
  echo "finished_utc=$(date -u +%FT%TZ)"
} | tee ci-out/summary.txt

if [ "$STATE_RC" -ne 0 ] || [ "$NODE_RC" -ne 0 ]; then
  echo "CI RESULT: FAIL (state=$STATE_RC dev_inspect=$NODE_RC)"
  exit 1
fi
echo "CI RESULT: PASS (all gates verified)"
