#!/usr/bin/env python3
"""Full state dump of Eklipse pools (parallel + incremental save)."""
import json, sys, os, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

def uint(hexs):
    if isinstance(hexs, dict) or not hexs or hexs == "0x": return None
    return int(hexs, 16)

def words(hexs):
    if isinstance(hexs, dict) or not hexs or hexs == "0x": return []
    b = hexs[2:]
    return [b[i:i+64] for i in range(0, len(b), 64)]

def addr(w):
    return "0x" + w[-40:]

BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

POOLS = {
    "base": "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4",
    "meta": "0xe59234EeDC854b3b37D48EFd8a529069C3990F83",
    "p3":   "0x323fdda29fa2B8028eF9Fb48c1D45e5A39214D9A",
    "p4":   "0x5B4ed8321ea13047195104037798f29257EAc28c",
    "p5":   "0x29c6Eb808020Ef4889A9f25d35b69edBAfB0C78e",
    "p6":   "0x7f352a4332fAD433D381d700118f8C9b0A1E1abb",
    "p7":   "0xB1b782f2D30505e9984e37e00C6494437d94c223",
    "p8":   "0xddA06aaB425a1A390c131F790A56AB3380e3B7EC",
    "p9":   "0x75Dc33f8247245E8E08852E68E7f275E2a41fD40",
}
SIGS = [("owner", "0x8da5cb5b"), ("paused", "0x5c975abb"), ("getA", "0xd46300fd"),
        ("getVirtualPrice", "0xe25aa5fa"), ("getLpToken", "0x8214f5a4"),
        ("swapStorage", "0x5fd65f0f"), ("getTokens", "0xaa6ca808"),
        ("getTokenBalances", "0xa1dc9031"), ("getTokenPrecisionMultipliers", "0xd41f6568"),
        ("getNumberOfTokens", "0xefeecb51"), ("feeDistributor", "0x0d43e8ad"),
        ("getAdminBalances", "0x18f52ce2")]

jobs = []
for name, a in POOLS.items():
    for key, sig in SIGS:
        jobs.append((name, key, a, sig))

results = {}
def one(j):
    name, key, a, sig = j
    return name, key, eth_call(a, sig, BH)

with cf.ThreadPoolExecutor(max_workers=5) as ex:
    for name, key, r in ex.map(one, jobs):
        results.setdefault(name, {})[key] = r
        if isinstance(r, dict):
            print("ERR", name, key, str(r)[:80], flush=True)

out = {"block": BLOCK, "pools": {}}
for name, rec in results.items():
    d = {"address": POOLS[name]}
    try: d["owner"] = addr(words(rec["owner"])[0])
    except Exception: d["owner"] = None
    d["paused"] = uint(rec["paused"])
    d["getA"] = uint(rec["getA"])
    d["getVirtualPrice"] = uint(rec["getVirtualPrice"])
    try: d["lpToken"] = addr(words(rec["getLpToken"])[0])
    except Exception: d["lpToken"] = None
    try:
        ws = words(rec["getTokens"]); n = uint(ws[1]); d["tokens"] = [addr(ws[2+i]) for i in range(n)]
    except Exception: d["tokens"] = None
    try:
        ws = words(rec["getTokenBalances"]); n = uint(ws[1]); d["balances"] = [uint(ws[2+i]) for i in range(n)]
    except Exception: d["balances"] = None
    try:
        ws = words(rec["getTokenPrecisionMultipliers"]); n = uint(ws[1]); d["precisionMultipliers"] = [uint(ws[2+i]) for i in range(n)]
    except Exception: d["precisionMultipliers"] = None
    try:
        ws = words(rec["getAdminBalances"]); n = uint(ws[1]); d["adminBalances"] = [uint(ws[2+i]) for i in range(n)]
    except Exception: d["adminBalances"] = None
    try: d["feeDistributor"] = addr(words(rec["feeDistributor"])[0])
    except Exception: d["feeDistributor"] = None
    try:
        ws = words(rec["swapStorage"])
        d["swapStorage_decoded"] = {"lpToken": addr(ws[0]), "initialA": uint(ws[1]), "futureA": uint(ws[2]),
                                    "initialATime": uint(ws[3]), "futureATime": uint(ws[4]), "swapFee": uint(ws[5]),
                                    "adminFee": uint(ws[6]), "defaultWithdrawFee": uint(ws[7])}
    except Exception: d["swapStorage_decoded"] = None
    out["pools"][name] = d
    print(name, json.dumps(d)[:900], flush=True)
    with open(os.path.join(os.path.dirname(__file__), "pool_state.json"), "w") as f:
        json.dump(out, f, indent=1)
print("saved pool_state.json")
