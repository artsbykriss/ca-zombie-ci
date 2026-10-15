#!/usr/bin/env python3
"""Truncation test (jupSOL control), PDA check for 8QtQ1U34, chain time, mainnet-beta sig cross-check."""
import json, sys, time, hashlib, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58decode, b58encode, pda, on_curve

print("== control: jupSOL pool getSignaturesForAddress via publicnode helper")
JUP = "8VpRhuxa7sUUepdY3kQiTmX9rS5vx4WgaXiAnXq4KCtr"
t0 = time.time()
page1 = rpc("getSignaturesForAddress", [JUP, {"limit": 1000}])
print("jupSOL page1 count:", len(page1), "newest bt:", page1[0]["blockTime"], "oldest bt:", page1[-1]["blockTime"], "newest slot", page1[0]["slot"], "oldest slot", page1[-1]["slot"])
time.sleep(1.5)
page2 = rpc("getSignaturesForAddress", [JUP, {"limit": 1000, "before": page1[-1]["signature"]}])
print("jupSOL page2 count:", len(page2), "oldest bt:", (page2[-1]["blockTime"] if page2 else None))
json.dump({"page1_head": page1[:3], "page1_tail": page1[-3:], "page1_n": len(page1),
           "page2_n": len(page2), "page2_tail": page2[-3:] if page2 else []},
          open("/home/heisenberg/CA/phase-stake/analysis/trunc_test_jup.json", "w"), indent=2)

print("\n== chain time")
try:
    ei = rpc("getEpochInfo", [])
    gb = rpc("getBlockTime", [ei["absoluteSlot"]])
    print("epoch", ei["epoch"], "absSlot", ei["absoluteSlot"], "chain time:", gb, "(call it 'now')")
except Exception as e:
    print("err", e)

print("\n== PDA check: SPMBzs stake account for vote CiTY + pool phase (seeds [vote, pool])")
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"
POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
VOTE = "CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe"
for label, seeds in [
    ("[vote,pool]", [b58decode(VOTE), b58decode(POOL)]),
    ("[vote,pool,seed0]", [b58decode(VOTE), b58decode(POOL), (0).to_bytes(8, "little")]),
    ("[pool,seed0]", [b58decode(POOL), (0).to_bytes(8, "little")]),
]:
    a, b = pda(seeds, PROG)
    print(label, "->", a, "bump", b)

print("\n== mainnet-beta getSignaturesForAddress(pool, limit 1000) cross-check")
def post(url, method, params, timeout=45):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())
ok = False
for i in range(12):
    time.sleep(6)
    try:
        d = post("https://api.mainnet-beta.solana.com", "getSignaturesForAddress", [POOL, {"limit": 1000}])
        if "result" in d:
            sigs = d["result"]
            print("mainnet-beta pool sigs:", len(sigs))
            if sigs:
                print("newest:", sigs[0]["slot"], sigs[0]["blockTime"], "oldest:", sigs[-1]["slot"], sigs[-1]["blockTime"])
            json.dump(d, open("/home/heisenberg/CA/phase-stake/analysis/mb_pool_sigs.json", "w"), indent=2)
            ok = True
            break
        print("try", i, str(d.get("error"))[:100])
    except Exception as ex:
        print("try", i, "exc", str(ex)[:100])
print("got:", ok)
