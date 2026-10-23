#!/usr/bin/env python3
"""Dump raw hex of one account of each size for RLP + proxy, to infer layouts."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"

def dump(prog, label):
    r = rpc("getProgramAccounts", [prog, {"encoding": "base64"}])
    seen = {}
    for a in r["result"]:
        d = base64.b64decode(a["account"]["data"][0])
        seen.setdefault(len(d), (a["pubkey"], d))
    print(f"===== {label} =====")
    for s in sorted(seen):
        pk, d = seen[s]
        print(f"-- size {s} sample {pk}")
        print("   ", d.hex())

dump(RLP, "RLP")
dump(PROXY, "PROXY")
