#!/usr/bin/env python3
"""Find a real proxy `Wrap`/`Unwrap`/`Claim Fees` tx by scanning the ProxyState's history."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
STATE = "FD4YydhzPpSmXwnHsX1oJBE4er4m9mg4ezaBN9cXgQbz"
WANT = {"Wrap", "Unwrap", "Claim Fees", "Swap", "Withdraw", "Update Fee", "Update Authority"}
found = {}
for addr in [STATE, "HAsdi8ZHEL7ydCgEC61AoNqB47QNVsabzUDimsjJx1yW"]:
    r = rpc("getSignaturesForAddress", [addr, {"limit": 1000}])
    sigs = [s["signature"] for s in r.get("result", [])]
    print(addr, len(sigs), flush=True)
    for s in sigs:
        if len(found) >= 3:
            break
        tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        res = tx.get("result")
        if not res:
            continue
        logs = (res.get("meta", {}) or {}).get("logMessages") or []
        inside = False
        names = []
        for l in logs:
            if l.startswith(f"Program {PROXY} invoke"):
                inside = True
            elif l.startswith("Program ") and "invoke" in l and PROXY not in l:
                inside = False
            if inside:
                for w in WANT:
                    if l.strip() == f"Program log: {w}":
                        names.append(w)
        if names:
            k = names[0]
            if k not in found:
                found[k] = {"sig": s, "slot": res["slot"], "message": res["transaction"]["message"]}
                print("  FOUND", k, s, res["slot"], flush=True)
    if len(found) >= 3:
        break
json.dump(found, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "proxy_ix_orders.json"), "w"), indent=2)
print("done", list(found))
