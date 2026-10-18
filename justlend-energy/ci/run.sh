#!/usr/bin/env bash
# JustLend Energy Rental (MarketG1) — CI job.
# Read-only: TronGrid triggerconstantcontract dry-runs + view reads only.
# No secrets, no keyed endpoints, no transactions.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "== fresh live-state snapshot =="
( cd analysis && python3 snapshot.py >/dev/null ) || echo "WARN: snapshot failed"
[ -f analysis/live_state.json ] && cp analysis/live_state.json ci-out/live_state.json

echo "== PoC dry-runs + shadow ledger =="
python3 poc/poc.py | tee ci-out/poc.log
cp poc/results/poc_results.json ci-out/poc_results.json

echo "== invariant checks =="
python3 - <<'EOF'
import json, sys, datetime
r = json.load(open("ci-out/poc_results.json"))
s = r["summary"]
st = r["state"]
checks = {
    "double_refund_closed": s["double_refund_closed"] is True,
    "dirty_rent_charged": s["dirty_rent_charged"] is True,
    "badDebt_gap_zero": s["badDebt_gap_sun"] == 0,
    "self_liq_net_nonpositive_1block": s["max_self_liq_net_trx"] <= 0,
    "self_liq_net_nonpositive_1_2d": s["max_self_liq_net_after_1_2d_trx"] <= 0,
    "protocol_funded_eu_zero": s["protocol_funded_EU_usd"] == 0,
    "live_energy_market_unpaused": st["rentPaused_energy"] is False,
}
verdict = {
    "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
    "block": st["block"],
    "balance_trx": st["balance_trx"],
    "checks": checks,
    "all_pass": all(checks.values()),
    "summary": s,
    "double_refund": [
        {"renter": d["renter"], "rentals_now": d["rentals_now"],
         "return_after_liquidate_ok": d["return_after_liquidate_ok"],
         "return_after_liquidate_error": d["return_after_liquidate_error"],
         "second_liquidate_ok": d["second_liquidate_ok"],
         "second_liquidate_error": d["second_liquidate_error"],
         "re_rented_since": d["re_rented_since"]}
        for d in r["double_refund"]
    ],
    "dirty_rent": r["dirty_rent"],
    "fresh_self_liquidation": r["fresh_self_liquidation"],
}
json.dump(verdict, open("ci-out/verdict.json", "w"), indent=1)
print(json.dumps(verdict, indent=1))
sys.exit(0 if verdict["all_pass"] else 1)
EOF
