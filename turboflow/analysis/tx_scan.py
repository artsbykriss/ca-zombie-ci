#!/usr/bin/env python3
"""Fetch recent program txs and decode svm-bridge instruction discriminators (incl. inner ix).
Read-only, gentle."""
import sys, json, time
from rpc import call
from b58 import b58dec
from disc import IX_BY_DISC

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    sigs = call("getSignaturesForAddress", [PID, {"limit": n}])
    print("sigs returned:", len(sigs))
    rows = []
    for s in sigs:
        rows.append({"sig": s["signature"], "slot": s["slot"], "err": s.get("err"),
                     "blockTime": s.get("blockTime")})
    # histogram of ix names over decoded txs
    from collections import Counter
    hist = Counter()
    decoded = []
    for r in rows:
        if r["err"]:
            continue
        try:
            tx = call("getTransaction", [r["sig"], {"encoding": "jsonParsed",
                      "maxSupportedTransactionVersion": 0}])
        except Exception as e:
            continue
        if tx is None:
            continue
        msg = tx["transaction"]["message"]
        keys = [k["pubkey"] if isinstance(k, dict) else k for k in msg["accountKeys"]]
        ixs = list(msg["instructions"])
        for inner in (tx["meta"].get("innerInstructions", []) or []):
            ixs += inner["instructions"]
        for ix in ixs:
            if ix.get("programId") != PID:
                continue
            d = ix.get("data")
            try:
                raw = b58dec(d)[:8] if d else b""
            except Exception:
                raw = b"?"
            nm = IX_BY_DISC.get(raw, raw.hex() if raw else "empty")
            hist[nm] += 1
            decoded.append({"sig": r["sig"], "slot": r["slot"], "ix": nm,
                            "data": d, "accts": ix.get("accounts"),
                            "keys": keys})
        time.sleep(0.15)
    print("IX histogram:", dict(hist))
    json.dump({"rows": rows, "hist": dict(hist), "decoded": decoded},
              open("tx_scan.json", "w"), indent=1)
    # print one sample per ix name
    seen = set()
    for d in decoded:
        if d["ix"] in seen: continue
        seen.add(d["ix"])
        print("\n=== ", d["ix"], "slot", d["slot"])
        print("  data:", d["data"])
        print("  accts:", json.dumps(d["accts"]))

if __name__ == "__main__":
    main()
