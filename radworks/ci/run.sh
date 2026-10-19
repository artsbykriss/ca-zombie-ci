#!/usr/bin/env bash
set -euo pipefail
mkdir -p ci-out
python3 ci/dump_state.py > ci-out/state.json
python3 - <<'PY'
import json
s=json.load(open('ci-out/state.json'))
print("block",s["block"],"RAD",s["balances"]["RAD"],"LP",s["balances"]["LP_RAD_USDC"])
PY
