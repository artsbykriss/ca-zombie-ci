#!/usr/bin/env python3
"""Find a real proxy `Unwrap` (or Wrap) tx via the branded mint's history."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
BMINT = "sro4agJ6nJ89MJgj2DfDdx8zXVqSyZfCZjbhBfQaJU5"
WANT = {"Unwrap": None, "Wrap": None}
found = {}
r = rpc("getSignaturesForAddress", [BMINT, {"limit": 1000}])
sigs = [s["signature"] for s in r.get("result", [])]
print("branded mint sigs:", len(sigs), flush=True)
n = 0
for s in sigs:
    n += 1
    if n > 600 or len(found) >= 2:
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
        if inside and l.startswith("Program log: "):
            nm = l[len("Program log: "):]
            if nm in WANT:
                names.append(nm)
    for k in names:
        if k not in found:
            found[k] = {"sig": s, "slot": res["slot"], "message": res["transaction"]["message"]}
            print("FOUND", k, s, res["slot"], flush=True)
json.dump(found, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "proxy_user_ix.json"), "w"), indent=2)
print("done", list(found), "fetched", n)
