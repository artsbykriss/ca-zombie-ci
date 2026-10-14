#!/usr/bin/env python3
"""LP token supplies, balances, and meta-pool event history."""
import json, sys, os, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

def uint(h):
    if isinstance(h, dict) or not h or h == "0x": return None
    return int(h, 16)

def addr(h):
    return "0x" + h[-40:] if isinstance(h, str) and len(h) >= 42 else None

BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

LPS = {
    "baseLP": "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49",
    "metaLP": "0x63c7d72963ed6e0c255835b606bef55ebeb1b5f8",
    "p3LP": "0x9f055b5fbde5d6e693752e489d3d71f04810b4d4",
    "p4LP": "0x72a35eb0d8a8d0301a5f92c9b6191bcb7ea232e0",
    "p5LP": "0xc49ba500a20b26d7a5407e22d7a7fc08e1e2f31a",
    "p6LP": "0xa4d48e724c7f2267918b5155094fb01437980604",
    "p7LP": "0x9d5b7671cddba4bb82e99fbcedf60c4d001fe2ef",
    "p8LP": "0x9ee1ce4ccf4c0379e675d9a326d21aacdbb55f72",
    "p9LP": "0xc4acf4ddd4838e9a727ccdb75ae62af1706a7173",
}
POOLS = {
    "base": "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4",
    "meta": "0xe59234EeDC854b3b37D48EFd8a529069C3990F83",
    "p3": "0x323fdda29fa2B8028eF9Fb48c1D45e5A39214D9A",
    "p4": "0x5B4ed8321ea13047195104037798f29257EAc28c",
    "p5": "0x29c6Eb808020Ef4889A9f25d35b69edBAfB0C78e",
    "p6": "0x7f352a4332fAD433D381d700118f8C9b0A1E1abb",
    "p7": "0xB1b782f2D30505e9984e37e00C6494437d94c223",
    "p8": "0xddA06aaB425a1A390c131F790A56AB3380e3B7EC",
    "p9": "0x75Dc33f8247245E8E08852E68E7f275E2a41fD40",
}

jobs = []
for name, lp in LPS.items():
    jobs.append((f"{name}:totalSupply", lp, "0x18160ddd"))
    jobs.append((f"{name}:decimals", lp, "0x313ce567"))
    jobs.append((f"{name}:name", lp, "0x06fdde03"))
    jobs.append((f"{name}:symbol", lp, "0x95d89b41"))
    for pname, paddr in POOLS.items():
        # balanceOf(pool)
        data = "0x70a08231" + paddr[2:].rjust(64, "0")
        jobs.append((f"{name}:balOf({pname})", lp, data))

out = {}
def one(j):
    k, to, data = j
    return k, eth_call(to, data, BH)
with cf.ThreadPoolExecutor(max_workers=6) as ex:
    for k, r in ex.map(one, jobs):
        out[k] = r

res = {}
for k, r in out.items():
    name, field = k.split(":")
    res.setdefault(name, {})[field] = r

def dec_str(h):
    if not isinstance(h, str) or len(h) < 130: return h
    b = bytes.fromhex(h[2:])
    off = int.from_bytes(b[0:32], "big"); ln = int.from_bytes(b[off:off+32], "big")
    return b[off+32:off+32+ln].decode("utf-8", "replace")

for name, rec in res.items():
    ts = uint(rec.get("totalSupply"))
    d = uint(rec.get("decimals"))
    print(f"{name}: symbol={dec_str(rec.get('symbol'))} decimals={d} totalSupply={ts}", flush=True)
    for k, v in rec.items():
        if k.startswith("balOf("):
            b = uint(v)
            if b: print(f"    {k} = {b}", flush=True)

with open(os.path.join(os.path.dirname(__file__), "lp_state.json"), "w") as f:
    json.dump({"block": BLOCK, "raw": out}, f, indent=1)
print("saved lp_state.json")
