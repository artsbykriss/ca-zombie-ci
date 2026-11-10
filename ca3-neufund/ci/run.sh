#!/usr/bin/env bash
# CI heavy job for ca3-neufund.  Keyless reads only; the Foundry suite is run
# by the workflow afterwards (poc/foundry.toml triggers `forge test -vvv`).
set -euo pipefail

echo "== live-state dump =="
python3 ci/dump_state.py | tee ci-out/live-state.txt

echo
echo "== fork test suite (also run by the workflow) =="
if [ -d poc ]; then
  ( cd poc && forge test -vvv --summary 2>&1 | tee ../ci-out/forge-test.txt )
fi

echo
echo "== gas / exit math =="
python3 - <<'PY' | tee ci-out/econ.txt
import json
d = json.load(open("ci-out/live-state.json"))
p = d.get("pulsechain", {})
print("pulsechain block", p.get("block"))
print("ETH-T balance (wei)", p.get("ETHT_balance"))
print("EUR-T balance (wei)", p.get("EURT_balance"))
print("PLS/USD", d.get("pls_usd"))
print("ETH-T exit USD", p.get("ETHT_exit_usd"))
print("claim gas (PLS)", p.get("claim_gas_pls"), "USD", p.get("claim_gas_usd"))
print("NET USD (excluding EUR-T, which has no market)", p.get("net_usd"))
PY
