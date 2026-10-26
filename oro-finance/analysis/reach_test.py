"""Reachability probe: for every Oro core instruction, send it with an unprivileged attacker
signer and a long placeholder account list, and report the first gate that fires.
Read-only (simulateTransaction only).
"""
import sys, json, re
sys.path.insert(0, '.')
from explore import run

A = "7orgFWEBNCsqspUTX8AZurjRfHrgRYZiswm4ewqJmH9E"
NAMES = ["autorize", "add_to_whitelist_by_auth", "whitelist", "update_price", "sell",
         "withdraw", "deposit", "mint_gold", "burn_gold", "init_integrator",
         "update_integrator_fees", "close_integrator", "withdraw_from_integrator",
         "update_integrator_market_override", "init_integrator_v2", "update_integrator_v2_fees",
         "close_integrator_v2", "withdraw_from_integrator_v2",
         "update_integrator_v2_market_overrides", "buy"]


def msg(v):
    for l in v.get("logs") or []:
        m = re.search(r"AnchorError caused by account: ([A-Za-z0-9_]+)\. Error Code: (\w+)\. Error Number: (\d+)", l)
        if m:
            return "%s %s(%s)" % (m.group(1), m.group(2), m.group(3))
        m2 = re.search(r"Error Code: (\w+)\. Error Number: (\d+)", l)
        if m2:
            return "%s(%s)" % (m2.group(1), m2.group(2))
    return json.dumps(v.get("err"))


if __name__ == "__main__":
    n = 16
    for name in NAMES:
        arglen = None
        for L in [0, 8, 16, 32, 40, 48]:
            accts = [(A, True, True)] + [(A, False, True)] * n
            v = run(name, "00" * L if L else "", accts, verbose=False)
            e = v.get("err")
            if not (e and e.get("InstructionError") and
                    e["InstructionError"][1] == {"Custom": 102}):
                arglen = L
                break
        print("%-34s arg=%s  %s" % (name, arglen, msg(v)))
        sys.stdout.flush()
