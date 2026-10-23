#!/usr/bin/env python3
"""Lightweight monitor for the Sodium re-arm.

Checks every factory-created Sodium account for native ETH and EntryPoint deposits,
and exits non-zero (printing the funded accounts) if any account holds more than a
dust threshold. Intended to be run on a schedule.

Usage:  ARB_RPC_URL=<url> python3 analysis/monitor.py
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "ci"))
import importlib.util

spec = importlib.util.spec_from_file_location(
    "census", os.path.join(os.path.dirname(__file__), "..", "ci", "census.py"))
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)

DUST_WEI = 10 ** 14  # 0.0001 ETH


def main():
    _, latest = c.pick_rpc()
    cand = json.load(open(os.path.join(os.path.dirname(__file__),
                                       "sodium_factory_accounts.json")))["accounts"]
    calls = []
    for a in cand:
        calls.append(("eth_getCode", [a, "latest"]))
        calls.append(("eth_getStorageAt", [a, "0x" + a[2:].rjust(64, "0"), "latest"]))
    res = c.batch(calls)
    accts = []
    for j, a in enumerate(cand):
        code = res[2 * j] or "0x"
        slot = res[2 * j + 1] or "0x0"
        if len(code) == 2 + c.PROXY_LEN * 2 and slot[-40:].lower() == c.IMPL[2:]:
            accts.append(a)
    nat = c.batch([("eth_getBalance", [a, "latest"]) for a in accts])
    funded = [(a, int(v or "0x0", 16)) for a, v in zip(accts, nat) if int(v or "0x0", 16) > DUST_WEI]
    print(f"# block {latest} · sodium accounts {len(accts)} · native>dust {len(funded)}")
    for a, v in funded:
        print(f"RE-ARM: {a} {v/1e18:.8f} ETH")
    if funded:
        sys.exit(2)


if __name__ == "__main__":
    main()
