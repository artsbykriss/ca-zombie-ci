#!/usr/bin/env python3
"""Scan every historical CherryPool TRX depositor for a non-zero current TRX claim.

Read-only view calls. Writes analysis/cherry_scan.json incrementally.
"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
C = "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR"
ZERO = T.enc_addr(T.hex_to_addr("0" * 40))
FRESH = T.fresh_address()

ev = json.load(open(f"{OUT}/events.json"))
users = []
for r in ev["CherryPool"]["OnDeposit"]:
    try:
        u = T.hex_to_addr(r["result"]["1"])
    except Exception:
        continue
    if u not in users:
        users.append(u)

res = {"block": T.now_block(), "users": len(users), "nonzero": [], "rows": []}
for i, u in enumerate(users):
    try:
        r = T.trigger(FRESH, C, "tokenUserAmountOf(address,address)", T.enc_addr(u) + ZERO)
        w = "".join(r.get("constant_result") or [])
        bal = int(w, 16) if w else None
    except Exception as e:  # noqa: BLE001
        bal = None
    res["rows"].append({"user": u, "trx_claim_sun": bal})
    if bal:
        res["nonzero"].append({"user": u, "sun": bal})
        print(f"[{i}] NONZERO {u} {bal/1e6:.6f} TRX", flush=True)
    if i % 25 == 0:
        json.dump(res, open(f"{OUT}/cherry_scan.json", "w"), indent=1)
        print(f"[{i}/{len(users)}] scanned", flush=True)
    time.sleep(1.05)
json.dump(res, open(f"{OUT}/cherry_scan.json", "w"), indent=1)
print("DONE nonzero:", len(res["nonzero"]), "sum:",
      sum(x["sun"] for x in res["nonzero"]) / 1e6)
