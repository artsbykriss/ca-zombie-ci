#!/usr/bin/env python3
"""Fetch recent txs invoking the BisonFi program; save + decode a direct swap example."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
PROG = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi"

def batch(reqs, retries=8):
    return [rpc(req["method"], req["params"]) for req in reqs]

def get_tx(sig):
    for ver in (0,1):
        r=rpc("getTransaction",[sig,{"encoding":"json","maxSupportedTransactionVersion":ver,"commitment":"confirmed"}])
        if r.get("result"): return r["result"]
    return None

if __name__=="__main__":
    r=rpc("getSignaturesForAddress",[PROG,{"limit":40,"commitment":"confirmed"}])
    sigs=r.get("result",[])
    print("recent program sigs:", len(sigs))
    direct=[]
    for s in sigs:
        tx=get_tx(s["signature"])
        if not tx: continue
        logs=tx["meta"].get("logMessages",[])
        inv=[l for l in logs if "Program BiSoNHV" in l]
        if inv:
            direct.append({"sig":s["signature"],"slot":s["slot"],"tx":tx})
            if len(direct)>=3: break
    json.dump(direct, open(os.path.join(OUT,"recent-bisonfi-swaps.json"),"w"), indent=1)
    for d in direct:
        print("== direct swap", d["slot"], d["sig"][:32])
        for l in d["tx"]["meta"]["logMessages"]:
            if "BiSoNHV" in l or "Instruction" in l or "RFQ" in l or "Program log" in l:
                print("   ", l[:160])
