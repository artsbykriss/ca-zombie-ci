#!/usr/bin/env python3
"""Read getRentInfo for every pair seen in the 7-day window (read-only)."""
import json, time, sys, hashlib
import tronlib as T

P = "TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd"

def h2b(h):
    h = h.lower().replace("0x", "").zfill(40)
    raw = bytes.fromhex("41" + h)
    chk = hashlib.sha256(hashlib.sha256(raw).digest()).digest()[:4]
    return T.b58encode(raw + chk)

pairs = {}
def add(name, fn):
    for e in json.load(open(f"events/{name}.json")):
        r = e["result"]
        key = (r["renter"], r["receiver"], int(r.get("resourceType", 1)))
        b = e["block_number"] * 1000 + e["event_index"]
        if key not in pairs or b > pairs[key]["b"]:
            pairs[key] = {"b": b, "kind": name, "ts": e["block_timestamp"], **fn(r)}

add("RentResource", lambda r: {"amount": int(r["amount"]), "storedDeposit": int(r["securityDeposit"])})
add("ReturnResource", lambda r: {"amount": int(r["amount"]), "storedDeposit": int(r["securityDeposit"])})
add("Liquidate", lambda r: {"amount": 0, "storedDeposit": 0})

out = []
for i, (key, v) in enumerate(sorted(pairs.items())):
    renter, receiver, rt = key
    args = T.enc_addr(h2b(renter)) + T.enc_addr(h2b(receiver)) + T.enc_uint(rt)
    got = None
    for attempt in range(6):
        try:
            r = T.call_multi(P, "getRentInfo(address,address,uint256)", args, 3)
            if r.get("ok") and len(r.get("values", [])) >= 3:
                got = r["values"]
                break
        except Exception as e:
            print("err", i, e, file=sys.stderr)
        time.sleep(1.2 + attempt)
    rec = {"renter": renter, "receiver": receiver, "rt": rt,
           "amount": v["amount"], "storedDeposit": v["storedDeposit"],
           "ts": v["ts"], "lastKind": v["kind"]}
    if got is None:
        rec["error"] = True
    else:
        rec.update({"effDeposit": got[0], "globalIndex": got[1], "liquidatable": bool(got[2])})
    out.append(rec)
    if i % 50 == 0:
        print("done", i, "of", len(pairs), file=sys.stderr)
        json.dump(out, open("live_pairs_partial.json", "w"))
    time.sleep(0.3)

json.dump(out, open("live_pairs.json", "w"))
print("wrote", len(out))
