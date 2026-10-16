#!/usr/bin/env python3
"""Fetch full signature history for BisonFi program + ProgramData (read-only)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
PROG = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi"
PROGDATA = "42snJ7ip4zKKsip3EtaMoBo8wzoRsQJSzgUSFXAVJFfG"

def all_sigs(addr, limit=1000):
    sigs, before = [], None
    while True:
        params = [addr, {"limit": limit, "commitment": "confirmed"}]
        if before:
            params[1]["before"] = before
        r = rpc("getSignaturesForAddress", params)
        res = r.get("result", [])
        if not res:
            break
        sigs.extend(res)
        before = res[-1]["signature"]
        if len(res) < limit:
            break
        print("... fetched", len(sigs), file=sys.stderr)
    return sigs

for name, addr in [("programdata", PROGDATA), ("program", PROG)]:
    sigs = all_sigs(addr)
    with open(os.path.join(OUT, f"history-{name}.json"), "w") as f:
        json.dump(sigs, f, indent=1)
    print(name, "tx count:", len(sigs))
    for s in sigs:
        print(" ", s.get("slot"), s.get("blockTime"), s.get("signature")[:16], "err=", s.get("err"), s.get("memo", ""))
