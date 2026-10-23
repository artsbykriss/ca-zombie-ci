#!/usr/bin/env bash
set -euo pipefail
mkdir -p ci-out
python3 ci/dump_state.py > ci-out/state.json
python3 - <<'PY'
import json
s=json.load(open('ci-out/state.json'))
g=s["governor"]; gl=s["guardian"]; e=s["economics"]
print("block", s["block"])
print("governor", g["name"], "quorum", g["quorum_votes"], "threshold", g["proposal_threshold"])
print("timelock admin", s["timelock"]["admin"], "delay", s["timelock"]["delay"])
print("DOLA operator", s["dola"]["operator"], "supply", s["dola"]["total_supply"])
print("guardian deployer", gl["deployer"], "codesize", gl["deployer_codesize"], "rwg", gl["rwg"], "thr", gl["rwg_threshold"])
print("quorum_cost_usd", e["quorum_cost_usd"], "incumbent_weighted", e["incumbent_votes_weighted"])
print("extract_10m_dola_usd", e["extract_10m_dola_usd"], "extract_25m_dola_usd", e["extract_25m_dola_usd"])
print("timelock_assets_usd", e["timelock_assets_usd"])
assert s["dola"]["operator"].lower()==s["timelock"]["address"].lower(), "DOLA operator must be the timelock"
assert s["timelock"]["admin"].lower()==s["governor"]["address"].lower(), "timelock admin must be the governor"
assert s["guardian"]["governor_mills"].lower()==s["governor"]["address"].lower(), "guardian bound to governor"
assert gl["deployer_codesize"]==0, "guardian deployer must be an EOA"
print("checks: OK")
PY
