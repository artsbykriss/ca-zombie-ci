#!/usr/bin/env python3
"""Census of the most recent N program signatures using the official RPC (not truncated).
Read-only. Usage: python3 tx_scan2.py <N>"""
import sys, json, time
from rpc import call
from b58 import b58dec
from disc import IX_BY_DISC

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"
EP = "https://api.mainnet-beta.solana.com"

def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    sigs = call("getSignaturesForAddress", [PID, {"limit": min(n, 1000)}], ep=EP)
    print("sigs:", len(sigs), "slots", sigs[0]["slot"], "->", sigs[-1]["slot"], flush=True)
    from collections import Counter
    hist = Counter()
    decoded = []
    rows = []
    for k, s in enumerate(sigs):
        rows.append({"sig": s["signature"], "slot": s["slot"], "err": s.get("err")})
        if s.get("err"):
            continue
        tx = None
        for attempt in range(5):
            try:
                tx = call("getTransaction", [s["signature"], {"encoding": "jsonParsed",
                          "maxSupportedTransactionVersion": 0}], ep=EP)
                break
            except Exception:
                time.sleep(1.0 + attempt)
        if tx is None:
            continue
        msg = tx["transaction"]["message"]
        keys = [x["pubkey"] if isinstance(x, dict) else x for x in msg["accountKeys"]]
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
            decoded.append({"sig": s["signature"], "slot": s["slot"], "ix": nm,
                            "data": d, "accts": ix.get("accounts")})
        if k % 100 == 0:
            print("  ...", k, dict(hist), flush=True)
        time.sleep(0.22)
    print("HISTOGRAM:", dict(hist))
    json.dump({"rows": rows, "hist": dict(hist), "decoded": decoded},
              open("tx_scan_full.json", "w"), indent=1)

if __name__ == "__main__":
    main()
