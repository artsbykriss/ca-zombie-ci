#!/usr/bin/env python3
"""Enumerate TurboFlow svm-bridge program accounts by Anchor discriminator.
Read-only, public RPC. Saves raw JSON."""
import sys, json, base64, time
from rpc import call
from disc import ACC_DISC
from b58 import b58enc

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def gpa(disc, extra=None):
    f = [{"memcmp": {"offset": 0, "bytes": b58enc(disc)}}]
    if extra: f += extra
    cfg = {"encoding": "base64", "filters": f}
    return call("getProgramAccounts", [PID, cfg])

def main():
    out = {}
    for name, d in ACC_DISC.items():
        try:
            res = gpa(d)
        except Exception as e:
            out[name] = {"error": str(e)}
            print(f"{name}: ERROR {e}")
            time.sleep(0.4)
            continue
        accts = []
        for r in res:
            raw = base64.b64decode(r["account"]["data"][0])
            accts.append({"pubkey": r["pubkey"], "lamports": r["account"]["lamports"],
                          "len": len(raw), "data_b64": r["account"]["data"][0],
                          "owner": r["account"]["owner"]})
        out[name] = {"count": len(accts), "accounts": accts}
        print(f"{name}: {len(accts)} accounts; lens={sorted(set(a['len'] for a in accts))}")
        time.sleep(0.35)
    json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else "state_raw.json", "w"), indent=1)

if __name__ == "__main__":
    main()
