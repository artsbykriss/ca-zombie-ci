#!/usr/bin/env bash
set -euo pipefail
mkdir -p ci-out
python3 ci/dump_state.py > ci-out/state.json
python3 - <<'PY'
import json
s=json.load(open('ci-out/state.json'))
g=s["active_governor"]; gs=s["guardian_safe"]; e=s["economics"]
print("block", s["block"])
print("active governor", g["name"], "quorum", g["quorum"], "threshold", g["proposal_threshold"])
print("proposal guardian", g["proposal_guardian"], "safe threshold", gs["threshold"], "owners", len(gs["owners"].split(",")))
print("timelock admin", s["timelock"]["admin"], "delay", s["timelock"]["delay"])
print("treasury GTC", s["gtc"]["timelock_balance"], "delegates", s["gtc"]["timelock_delegates"])
print("guardian GTC votes", gs["gtc_votes"], "=usd", e["guardian_votes_usd"])
print("treasury_usd", e["treasury_usd"], "quorum_cost_usd", e["quorum_cost_usd"])
assert s["timelock"]["admin"].lower()==g["address"].lower(), "timelock admin must be the ACTIVE governor"
assert s["timelock"]["admin"].lower()!=s["legacy_governor"]["address"].lower(), "legacy governor must be inert"
assert g["proposal_guardian"].lower()==gs["address"].lower(), "proposal guardian must be the safe"
assert s["gtc"]["timelock_delegates"].lower()==gs["address"].lower(), "treasury GTC must be delegated to the guardian"
assert gs["gtc_votes"] >= g["quorum"], "guardian votes must exceed quorum"
print("checks: OK")
PY
