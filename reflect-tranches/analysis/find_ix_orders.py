#!/usr/bin/env python3
"""Find real on-chain txs for the interesting instructions of BOTH programs and dump the
exact account ordering. Bounded, read-only."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
WANT = {
    RLP: {"Withdraw", "RequestWithdrawal", "Deposit", "Swap", "MigrateCooldown"},
    PROXY: {"Wrap", "Unwrap", "Claim Fees", "Swap", "Withdraw", "Update Fee", "Update Authority"},
}
out = {}
for prog, want in WANT.items():
    r = rpc("getSignaturesForAddress", [prog, {"limit": 1000}])
    sigs = [s["signature"] for s in r.get("result", [])]
    print(prog, "sigs", len(sigs), flush=True)
    got = {}
    n = 0
    for s in sigs:
        n += 1
        if n > 500 or len(got) >= 6:
            break
        tx = rpc("getTransaction", [s, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        res = tx.get("result")
        if not res:
            continue
        logs = (res.get("meta", {}) or {}).get("logMessages") or []
        # only count instruction names logged *by this program*
        seg = []
        inside = False
        for l in logs:
            if l.startswith(f"Program {prog} invoke"):
                inside = True
            elif l.startswith("Program ") and "invoke" in l and prog not in l:
                inside = False
            if inside and "Instruction: " in l:
                seg.append(l.split("Instruction: ")[-1])
        hits = [x for x in seg if x in want]
        if hits:
            key = hits[0]
            if key not in got:
                got[key] = {"sig": s, "slot": res["slot"], "message": res["transaction"]["message"]}
                print("  FOUND", key, s, res["slot"], flush=True)
    out[prog] = got
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ix_orders.json"), "w"), indent=2)
print("done", {k: list(v) for k, v in out.items()})
