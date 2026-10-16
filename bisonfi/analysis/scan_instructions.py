#!/usr/bin/env python3
"""Scan recent BisonFi program txs: cluster direct instruction discriminators + account shapes."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
PROG = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi"
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''

def get_tx(sig):
    for ver in (0,1):
        r=rpc("getTransaction",[sig,{"encoding":"json","maxSupportedTransactionVersion":ver,"commitment":"confirmed"}])
        if r.get("result"): return r["result"]
    return None

r=rpc("getSignaturesForAddress",[PROG,{"limit":120,"commitment":"confirmed"}])
sigs=r.get("result",[])
print("sigs:",len(sigs))
clusters={}
examples={}
for s in sigs:
    tx=get_tx(s["signature"])
    if not tx: continue
    meta=tx["meta"]; msg=tx["transaction"]["message"]
    keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
    loaded=(meta.get("loadedAddresses") or {})
    keys += list(loaded.get("writable",[])) + list(loaded.get("readonly",[]))
    found=[]
    for grp in meta.get("innerInstructions",[]):
        for ins in grp["instructions"]:
            pid=ins.get("programId") or keys[ins.get("programIdIndex",0)]
            if pid!=PROG: continue
            raw=b58d(ins.get("data",""))
            disc=raw[0] if raw else None
            accts=[keys[a] for a in ins.get("accounts",[])]
            found.append((disc, len(raw), len(accts), accts, raw.hex()))
    for ins in msg["instructions"]:
        pid=keys[ins["programIdIndex"]]
        if pid!=PROG: continue
        raw=b58d(ins["data"])
        disc=raw[0] if raw else None
        accts=[keys[a] for a in ins["accounts"]]
        found.append((disc, len(raw), len(accts), accts, raw.hex()))
    for disc, dl, na, accts, hx in found:
        key=(disc, dl, na)
        clusters.setdefault(key, 0)
        clusters[key]+=1
        if key not in examples:
            examples[key]={"sig":s["signature"],"slot":s["slot"],"accts":accts,"hex":hx,"logs":meta["logMessages"][:6]}
print("\nclusters (disc, datalen, naccounts) -> count")
for k,v in sorted(clusters.items(), key=lambda x:-x[1]):
    print("  ",k,"x",v)
    ex=examples[k]
    print("     example slot",ex["slot"],ex["sig"][:24])
    print("     data:",ex["hex"][:80])
    print("     accounts:")
    for a in ex["accts"]: print("       ",a)
json.dump({str(k):examples[k] for k in examples}, open(os.path.join(OUT,"instruction-clusters.json"),"w"), indent=1)
