#!/usr/bin/env python3
"""Scan the RLP program's recent signatures for a real Withdraw instruction and dump its
exact account ordering (ground truth). Bounded, read-only."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
TARGET = {"Withdraw", "MigrateCooldown"}
MAXFETCH = 400

r = rpc("getSignaturesForAddress", [RLP, {"limit": 1000}])
sigs = [s["signature"] for s in r.get("result", [])]
print("program sigs:", len(sigs))
found = {}
n = 0
for s in sigs:
    n += 1
    if n > MAXFETCH:
        break
    tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
    res = tx.get("result")
    if not res:
        continue
    logs = (res.get("meta", {}) or {}).get("logMessages") or []
    names = [l.split("Instruction: ")[-1] for l in logs if "Instruction: " in l]
    if any(x in TARGET for x in names):
        print("FOUND", s, res["slot"], names)
        found[s] = {"slot": res["slot"], "names": names, "message": res["transaction"]["message"]}
        if len(found) >= 2:
            break
print("fetched", min(n, MAXFETCH), "found", len(found))
json.dump(found, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ix_withdraw.json"), "w"), indent=2)
for s, v in found.items():
    print("\n###", s, v["slot"], v["names"])
    msg = v["message"]
    for i, k in enumerate(msg["accountKeys"]):
        print(f"  {i:2} {k['pubkey']} signer={k['signer']} w={k['writable']}")
    for ix in msg["instructions"]:
        if "JrXLmS6" in str(ix.get("programId")):
            print("  IX accounts:", ix.get("accounts"))
            print("  IX data:", str(ix.get("data"))[:100])
