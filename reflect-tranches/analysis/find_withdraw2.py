#!/usr/bin/env python3
"""Scan the cooldown authorities' histories for a real RLP `Withdraw` tx (bounded, read-only)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

auths = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldown_auths.json")))
found = {}
for addr in auths:
    r = rpc("getSignaturesForAddress", [addr, {"limit": 300}])
    sigs = [s["signature"] for s in r.get("result", [])]
    print(addr, "sigs", len(sigs), flush=True)
    for s in sigs:
        tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        res = tx.get("result")
        if not res:
            continue
        logs = (res.get("meta", {}) or {}).get("logMessages") or []
        names = [l.split("Instruction: ")[-1] for l in logs if "Instruction: " in l]
        if "Withdraw" in names:
            print("  FOUND WITHDRAW", s, res["slot"], flush=True)
            found[s] = {"slot": res["slot"], "names": names, "message": res["transaction"]["message"]}
            if len(found) >= 2:
                break
    if len(found) >= 2:
        break
json.dump(found, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ix_withdraw.json"), "w"), indent=2)
print("total", len(found))
