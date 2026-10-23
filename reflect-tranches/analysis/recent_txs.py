#!/usr/bin/env python3
"""Fetch recent signatures + a sample tx for the RLP and proxy programs (read-only)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

for label, prog in [("rlp", "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"),
                    ("proxy", "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")]:
    r = rpc("getSignaturesForAddress", [prog, {"limit": 25}])
    sigs = r.get("result", [])
    print(f"===== {label}: {len(sigs)} recent sigs")
    for s in sigs[:25]:
        print("  ", s["signature"], s["slot"], s.get("blockTime"), "err" if s.get("err") else "ok")
    if sigs:
        tx = rpc("getTransaction", [sigs[0]["signature"], {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        json.dump(tx, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), f"sample_tx_{label}.json"), "w"), indent=2)
        res = tx.get("result")
        if res:
            msg = res["transaction"]["message"]
            print("  accounts:", msg["accountKeys"][:20])
