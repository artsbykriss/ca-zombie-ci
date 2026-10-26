#!/usr/bin/env bash
# Heavy job for the Omnipair (Solana) deep-dive — p7-solana-c.
#
# READ-ONLY against Solana JSON-RPC.  No signing, no broadcast: only
#   getProgramAccounts / getMultipleAccounts / getAccountInfo / getSlot /
#   getTokenSupply / getTokenLargestAccounts / simulateTransaction
#   (sigVerify=false, replaceRecentBlockhash=true).
#
# Nothing secret is stored here.  If ALCHEMY_API_KEY is present in the runner
# environment, a keyed Solana RPC endpoint is constructed at runtime and passed
# to the scripts via $OMNI_RPC_URL; otherwise keyless public endpoints are used.
set -uo pipefail

cd "$(dirname "$0")/.."   # finding folder root
echo "[omnipair] start $(date -u +%FT%TZ)"
python3 --version
mkdir -p ci-out

if [ -n "${ALCHEMY_API_KEY:-}" ]; then
  export OMNI_RPC_URL="https://solana-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}"
  echo "[omnipair] using keyed Alchemy RPC (constructed at runtime)"
else
  echo "[omnipair] using keyless public RPC"
fi

echo "== 1. enumerate + decode live state =="
python3 analysis/enumerate.py 2>&1 | tee ci-out/enumerate.log

echo "== 2. TVL =="
python3 analysis/tvl.py 2>&1 | tee ci-out/tvl.log

echo "== 3. adversarial simulation matrix =="
python3 analysis/sim_matrix.py all 2>&1 | tee ci-out/sim_matrix.log
rc=${PIPESTATUS[0]}

echo "== 4. borrow account-shape probe =="
python3 analysis/probe_borrow.py 2>&1 | tee ci-out/borrow_probe.log || true

echo "== 5. summary =="
python3 - <<'PY' 2>&1 | tee ci-out/ci_summary.txt
import json
def load(p):
    try: return json.load(open(p))
    except Exception as e: return {"error": str(e)}
sm = load("ci-out/sim_matrix.json")
t1 = sm.get("t1_liquidate_all", {})
print("liquidate probes:", t1.get("n"), "not_undercollateralized:", t1.get("n_not_undercollateralized"),
      "succeeded:", t1.get("n_succeeded"))
print("liquidatable:", json.dumps(t1.get("succeeded")))
import collections
def classify(x):
    if x.get("err") is None:
        return "SUCCESS"
    if x.get("err_name"):
        return x["err_name"]["name"]
    return "OTHER:" + json.dumps(x.get("err"))
c = collections.Counter(classify(x) for x in (t1.get("all") or []))
print("t1 error distribution:", dict(c))
t7 = sm.get("t7_liquidate_measure", {})
print("t7 n_liquidatable:", t7.get("n_liquidatable"))
for m in (t7.get("measured") or []):
    print("   ", m.get("pos"), "err=", (m.get("err_name") or {}).get("name") if m.get("err_name") else m.get("err"), "deltas=", json.dumps(m.get("deltas")))
for k in ("t2_substitution","t3_flashloan","t4_claim_fees","t5_borrow","t6_remove_collateral"):
    v = sm.get(k, {})
    print("--", k)
    for kk, vv in (v.items() if isinstance(v, dict) else []):
        if isinstance(vv, dict):
            print("   ", kk, "->", (vv.get("err_name") or {}).get("name") if vv.get("err_name") else ("SUCCESS" if vv.get("err") is None else vv.get("err")))
t8 = sm.get("t8_price_manipulation", {})
print("-- t8_price_manipulation")
print("   baseline:", (t8.get("baseline") or {}).get("err_name"))
print("   swap+liquidate:", (t8.get("swap_then_liquidate") or {}).get("err_name"))
print("   ema_proof:", json.dumps(t8.get("ema_proof")))
tv = load("analysis/tvl.json")
print("TVL adapter:", tv.get("tvl_adapter_cash_plus_collateral_usd"),
      "onchain:", tv.get("tvl_onchain_reserve_plus_collateral_usd"))
PY

echo "== files =="
ls -la ci-out
echo "[omnipair] done $(date -u +%FT%TZ) rc=$rc"
exit 0
