#!/usr/bin/env python3
"""Fetch upgrade history for GoonFi v1/v2 programdata accounts + recent program invocations."""
import json, os, sys, struct, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))


def b58(b):
    AL = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = AL[r] + s
    for byte in b:
        if byte == 0:
            s = "1" + s
        else:
            break
    return s


def programdata_of(prog_acct_bin):
    raw = open(prog_acct_bin, "rb").read()
    tag = struct.unpack("<I", raw[0:4])[0]
    assert tag == 2, tag
    return b58(raw[4:36])


def sigs(addr, limit=1000, before=None):
    params = [addr, {"limit": min(limit, 1000)}]
    if before:
        params[1]["before"] = before
    out = []
    while True:
        r = rpc("getSignaturesForAddress", params)
        if "result" not in r:
            print("ERR", json.dumps(r)[:200]); break
        batch = r["result"]
        out.extend(batch)
        if len(batch) < min(limit, 1000) or len(out) >= limit:
            break
        params[1]["before"] = batch[-1]["signature"]
        time.sleep(0.3)
    return out


def main():
    pd_v2 = programdata_of(os.path.join(OUT, "prog_v2-account.bin"))
    pd_v1 = programdata_of(os.path.join(OUT, "prog_v1-account.bin"))
    print("pd_v2", pd_v2, "pd_v1", pd_v1)
    for label, addr in [("v2", pd_v2), ("v1", pd_v1)]:
        s = sigs(addr, limit=200)
        with open(os.path.join(OUT, f"upgrades-{label}.json"), "w") as f:
            json.dump(s, f, indent=1)
        print(label, "programdata sigs:", len(s))
        for x in s[:20]:
            print("  ", x["slot"], x.get("blockTime"), x["signature"], "err=", x.get("err") is not None)
    # recent program invocations (v2)
    s = sigs("goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE", limit=60)
    with open(os.path.join(OUT, "recent-program-sigs.json"), "w") as f:
        json.dump(s, f, indent=1)
    print("recent program sigs:", len(s))
    for x in s[:10]:
        print("  ", x["slot"], x.get("blockTime"), x["signature"])


if __name__ == "__main__":
    main()
