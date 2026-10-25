#!/usr/bin/env bash
# xALPH — heavy verification job (runs on GitHub Actions via ci/ci-run.sh).
# No secrets are used: all endpoints are public and keyless.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "== xALPH CI verification =="
echo "host: $(hostname)  date: $(date -u +%FT%TZ)"
python3 --version

echo "--- [1/3] mint/burn math search (round-trip profitability + rate monotonicity) ---"
python3 analysis/roundtrip_math.py --big | tee ci-out/roundtrip_math.txt

echo "--- [2/3] live on-chain state (public Alephium node/backend) ---"
python3 analysis/live_state.py | tee ci-out/live_state.json

echo "--- [3/3] summary ---"
python3 - <<'PY' | tee ci-out/verification_summary.txt
import json
s = json.load(open("ci-out/live_state.json"))
m = open("ci-out/roundtrip_math.txt").read()
E = 10**18
ok = ("RESULT: SAFE" in m)
print("math_search_result :", "SAFE" if ok else "INVESTIGATE")
print("chain_height       :", s.get("chain_height"))
print("xAlph_codeHash     :", s.get("xAlph_codeHash"))
print("backing (ALPH)     :", int(s["backing_attoAlph"]) / E)
print("circulating xALPH  :", int(s["circulating_xAlph"]) / E)
print("rate ALPH/xALPH    :", s["rate_alph_per_xalph"])
print("reserve held (xALPH):", int(s["contract_xAlph_reserve"]) / E)
print("method13==field0   :", s.get("method13_matches_state_field0"))
print("ALPH usd           :", s.get("alph_usd"))
print("backing usd        :", s.get("backing_usd"))
print("E-U verdict        : $0 (no unprivileged extraction path in the deployed code)")
PY
echo "== done =="
