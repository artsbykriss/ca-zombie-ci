#!/usr/bin/env python3
"""Scan the senior proxy vault's history for a real Wrap/Unwrap tx (bounded, read-only)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
VAULTS = ["E5ohyMVkBTdn3DekUPcFyLFF2Wi78Rg3Mt9QQDWgN5Mp",
          "J6fkJ53tCcentTPgiExLJmo6iKRnUKBbU9FAaKVxC461"]
WANT = {"Wrap", "Unwrap", "Swap", "Withdraw", "Claim Fees"}
found = {}
for v in VAULTS:
    r = rpc("getSignaturesForAddress", [v, {"limit": 1000}])
    sigs = [s["signature"] for s in r.get("result", [])]
    print(v, len(sigs), flush=True)
    n = 0
    for s in sigs:
        n += 1
        if n > 400 or len(found) >= 3:
            break
        tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        res = tx.get("result")
        if not res:
            continue
        names = []
        inside = False
        for l in (res.get("meta", {}) or {}).get("logMessages") or []:
            if l.startswith(f"Program {PROXY} invoke"):
                inside = True
            elif l.startswith("Program ") and "invoke" in l and PROXY not in l:
                inside = False
            if inside and l.startswith("Program log: ") and l[len("Program log: "):] in WANT:
                names.append(l[len("Program log: "):])
        for k in names:
            if k not in found:
                found[k] = {"sig": s, "slot": res["slot"], "message": res["transaction"]["message"]}
                print("FOUND", k, s, res["slot"], flush=True)
    if len(found) >= 3:
        break
json.dump(found, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "proxy_vault_ix.json"), "w"), indent=2)
print("done", list(found))
