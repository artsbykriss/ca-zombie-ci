#!/usr/bin/env bash
# Heavy/verification job for ca2-open-tron-trio (runs on GitHub Actions).
# - deterministic ABI/dispatcher/runtime checks (offline)
# - read-only live constant-call spot checks against TronGrid (no keys, no broadcast)
# Results -> ci-out/ (uploaded as artifacts). Foundry tests run separately by poc.yml.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "== static checks =="
python3 analysis/static_check.py | tee ci-out/static_check.log

echo "== decompiler artifacts (heimdall, generated locally; runner has no heimdall) =="
for n in CherryPool PokerGame FireFull; do
  cp "analysis/decompile/${n}_evm-decompiled.sol" "ci-out/decompile_${n}.sol" 2>/dev/null || true
  cp "analysis/decompile/${n}_evm-abi.json" "ci-out/heimdall_${n}_abi.json" 2>/dev/null || true
done

echo "== read-only live spot checks =="
if python3 -c "import requests" >/dev/null 2>&1; then
python3 - <<'PY' | tee ci-out/live_spot_checks.log
import json, sys, time, urllib.request
sys.path.insert(0, "analysis")
import tronlib as T
C = {"CherryPool":"TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
     "PokerGame":"TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
     "FireFull":"TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW"}
F = T.fresh_address()
out = {"block": None, "calls": {}}
try:
    out["block"] = T.now_block()
    for name, addr in C.items():
        acct = T.get_account(addr)
        r = T.trigger(F, addr, "withdrawTronAll()" if name=="CherryPool" else "withdraw()", "")
        out["calls"][name] = {
            "address": addr,
            "balance_trx": acct.get("balance", 0) / 1e6,
            "constant_result": r.get("constant_result"),
            "energy_used": r.get("energy_used"),
            "message": (r.get("result") or {}).get("message"),
            "code": (r.get("result") or {}).get("code"),
        }
        time.sleep(1.2)
except Exception as e:  # noqa: BLE001
    out["error"] = str(e)[:300]
json.dump(out, open("ci-out/live_spot_checks.json", "w"), indent=1)
print(json.dumps(out, indent=1))
PY
else
  echo '{"skipped":"python requests not installed on runner"}' > ci-out/live_spot_checks.json
  echo "requests missing; live spot checks skipped"
fi

echo "== summary =="
python3 - <<'PY' | tee ci-out/summary.txt
import json
s=json.load(open("ci-out/static_check.json"))
print("static_all_pass:", s["all_pass"])
for k in ("CherryPool","PokerGame","FireFull"):
    print(k, "runtime", s[k]["runtime_bytes"], "B; selectors", s[k]["abi_functions"],
          "; hidden", s[k]["hidden_selectors"])
l=json.load(open("ci-out/live_spot_checks.json"))
print("live block:", l.get("block"))
for k,v in l.get("calls",{}).items():
    print(k, v["balance_trx"], "TRX; ret", v["constant_result"], "energy", v["energy_used"])
PY

echo "done"
