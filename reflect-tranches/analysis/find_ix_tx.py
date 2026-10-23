#!/usr/bin/env python3
"""Find a real on-chain RLP `Withdraw` / `RequestWithdrawal` transaction and extract its
exact instruction account ordering (ground truth for the deployed program)."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
CAND = ["9AJaKAmBKoKCr8gQGDYmsEvEHQvTDRLj7pi7PbcSaPyW",
        "KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw"]

found = {}
for addr in CAND:
    r = rpc("getSignaturesForAddress", [addr, {"limit": 1000}])
    sigs = [s["signature"] for s in r.get("result", [])]
    print(addr, "sigs", len(sigs))
    for i in range(0, len(sigs), 25):
        batch = sigs[i:i+25]
        for s in batch:
            if s in found:
                continue
            tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
            res = tx.get("result")
            if not res:
                continue
            logs = (res.get("meta", {}) or {}).get("logMessages") or []
            names = [l.split("Instruction: ")[-1] for l in logs if "Instruction: " in l]
            if any(n in ("Withdraw", "RequestWithdrawal", "Swap", "Deposit", "MigrateCooldown") for n in names):
                found[s] = {"slot": res["slot"], "names": names,
                            "message": res["transaction"]["message"]}
                print("  FOUND", s, res["slot"], names)
        if len(found) >= 6:
            break
    if len(found) >= 6:
        break

json.dump({k: v for k, v in found.items()},
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ix_txs.json"), "w"), indent=2)
print("total found", len(found))
