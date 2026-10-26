#!/usr/bin/env bash
# Perena (numeraire) CI job — re-runs the read-only simulation battery on a GitHub runner.
# No secrets, no keys, public RPC only. Writes results to ../ci-out/ (uploaded as artifacts).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ci-out"
mkdir -p "$OUT"
cd "$ROOT/analysis"

echo "[perena-ci] slot probe:"
python3 - <<'PY' 2>&1 | tee "$OUT/perena_ci.log"
import json
from rpc import call
print(json.dumps({"slot": call("getSlot",[]), "version": call("getVersion",[])}))
PY

echo "[perena-ci] decoding live pools -> $OUT/pools.json"
python3 decode_pools.py > "$OUT/pools.json" 2> "$OUT/pools.err" || true

echo "[perena-ci] pool USD totals"
python3 - <<'PY' 2>&1 | tee -a "$OUT/perena_ci.log"
import json
d=json.load(open('pools.json')); tot=0
for k,v in d.items():
    if 'err' in v: continue
    s=sum(v['pairs'][i]['x_reserve_amount']/(10**v['pairs'][i]['decimals']) for i in range(v['num_stables']))
    tot+=s
print("numeraire pool reserves (all stables @ $1): $%.2f"%tot)
PY

echo "[perena-ci] HINT-BYPASS battery (hinted swap guard)"
python3 perena_hint_test.py 2>&1 | tee "$OUT/perena_hint_test.log" | tail -40

echo "[perena-ci] AUTHORITY battery (privileged setters vs unprivileged payer)"
python3 perena_auth_test.py 2>&1 | tee "$OUT/perena_auth_test.log" | tail -40

echo "[perena-ci] done"
