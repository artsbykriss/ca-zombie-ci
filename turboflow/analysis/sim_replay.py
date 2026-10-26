#!/usr/bin/env python3
"""Replay a real tx via simulateTransaction (read-only). Then report err+logs.
Usage: python3 sim_replay.py <SIG> [raw|parsed]"""
import sys, json
from rpc import call
from sim import simulate

def main():
    sig = sys.argv[1]
    tx = call("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0}])
    raw = tx["transaction"][0] if isinstance(tx["transaction"], list) else tx["transaction"]
    r = simulate(raw)
    v = r["value"]
    print("err:", json.dumps(v.get("err")))
    print("unitsConsumed:", v.get("unitsConsumed"))
    for l in (v.get("logs") or []):
        print("  LOG", l)
    print("accounts touched:", len(v.get("accounts") or []))

if __name__ == "__main__":
    main()
