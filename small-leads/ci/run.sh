#!/usr/bin/env bash
# small-leads CI: reproduce live-state reads + exact bOSMO arithmetic.
# Read-only. Public endpoints only. No secrets.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p ci-out

echo "=== 1. exact snapshot math (historical validations + A/B optima) ==="
( cd bosmo-backbone/analysis && python3 exploit_math.py ) > ci-out/bosmo_exact.log 2>&1
rc=$?
if [ $rc -ne 0 ]; then echo "exploit_math failed ($rc)"; cat ci-out/bosmo_exact.log; exit $rc; fi
cp bosmo-backbone/analysis/exploit_math_output.json ci-out/bosmo_exact.json
tail -20 ci-out/bosmo_exact.log

echo "=== 2. live read + exact integer reproduction ==="
python3 bosmo-backbone/analysis/sim_bosmo.py > ci-out/bosmo_sim.json 2> ci-out/bosmo_sim.err
rc=$?
if [ $rc -ne 0 ]; then echo "bOSMO sim failed ($rc)"; cat ci-out/bosmo_sim.err; exit $rc; fi
python3 - <<'PY'
import json
live=json.load(open('ci-out/bosmo_sim.json'))
exact=json.load(open('ci-out/bosmo_exact.json'))
e=live['exploit']; x=exact
print(json.dumps({
  "block": live["as_of"]["block"], "time": live["as_of"]["time"],
  "code_id": live["contract"]["code_id"], "cw2": live["contract"]["cw2_version"],
  "mint_rate": live["rates"]["mint_osmo_per_bosmo"],
  "redeem_rate": live["rates"]["redeem_osmo_per_bosmo"],
  "ratio": live["rates"]["overpay_ratio"],
  "scenarioA_net_osmo": x["scenario_A"]["net"]/1e6,
  "scenarioB_net_osmo": x["scenario_B"]["net"]/1e6,
  "ceiling_osmo": live["state"]["delegated_total_uosmo"]/1e6,
  "usd_A": x["usd"]["A_net_usd_defillama"],
  "usd_B": x["usd"]["B_net_usd_defillama"],
  "usd_ceiling": x["usd"]["ceiling_A_usd_defillama"],
  "usd_A_pass2price": x["usd"]["A_net_usd_stated"],
  "bank_uosmo": live["state"]["bank_uosmo"],
  "staked_uosmo": live["state"]["delegated_total_uosmo"],
  "double_counted_uosmo": live["state"]["double_counted_uosmo"],
  "liabilities_all_uosmo": live["state"]["liabilities_all_uosmo"],
  "surplus_uosmo": live["state"]["unallocated_surplus_uosmo"],
}, indent=2))
PY

echo "=== done; results in ci-out/ ==="
