#!/usr/bin/env python3
"""Assert the decisive gates for the TAC JettonProxy target from CI output."""
import json
import sys

live = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "ci-out/live_checks.json"))
ton = json.load(open(sys.argv[2] if len(sys.argv) > 2 else "ci-out/ton_state.json"))

checks = {
    "single_voter_1_of_1": live.get("total_voters") == 1,
    "single_group": live.get("total_groups") == 1,
    "simulation_mode_none": int(live.get("ccl_simulation_mode_slot5", "0x0"), 16) == 0,
    "current_root_valid": live.get("current_root_check") == 1,
    "forged_receiveMessage_reverts_InvalidMerkleProof": "b05e92fa"
    in str(live.get("forged_receiveMessage_error", "")),
    "proxy_code_unchanged": ton.get("proxy", {}).get("code_match") is True,
    "ccl_ton_code_unchanged": ton.get("ccl", {}).get("code_match") is True,
    "release_ops_seen": ton.get("in_ops", {}).get("0x7817b330", 0) > 0
    and ton.get("out_ops", {}).get("0x0f8a7ea5", 0) > 0,
}

usdt = [
    j
    for j in ton.get("verified_jettons", [])
    if j.get("master") == "0:b113a994b5024a16719f69139328eb759596c38a25f59028b146fecdc3621dfe"
]
checks["usdt_balance_gt_500k"] = bool(usdt) and usdt[0]["amount"] > 500_000

for k, v in checks.items():
    print(f"{'PASS' if v else 'FAIL'}  {k}")
if not all(checks.values()):
    sys.exit(1)
print(f"USDT in proxy: {usdt[0]['amount']:.6f}")
print("TAC gates OK")
