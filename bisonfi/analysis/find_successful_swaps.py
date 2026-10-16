#!/usr/bin/env python3
"""Find a recent SUCCESSFUL tx containing a BisonFi disc-2 swap with real token movement."""
import json, os, sys
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

r=rpc("getSignaturesForAddress",[PROG,{"limit":250,"commitment":"confirmed"}])
sigs=[s for s in (r.get("result") or []) if s.get("err") is None]
print("clean sigs:", len(sigs))
found=[]
for s in sigs:
    tx=get_tx(s["signature"])
    if not tx: continue
    meta=tx["meta"]; msg=tx["transaction"]["message"]
    keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
    loaded=(meta.get("loadedAddresses") or {})
    keys += list(loaded.get("writable",[])) + list(loaded.get("readonly",[]))
    hit=None
    for grp in meta.get("innerInstructions",[]):
        for ins in grp["instructions"]:
            pid=ins.get("programId") or keys[ins.get("programIdIndex",0)]
            if pid!=PROG: continue
            raw=b58d(ins.get("data",""))
            if raw and raw[0]==2:
                hit={"kind":"inner","outer":grp["index"],"data":raw.hex(),"accounts":[keys[a] for a in ins["accounts"]]}
    for ins in msg["instructions"]:
        if keys[ins["programIdIndex"]]!=PROG: continue
        raw=b58d(ins["data"])
        if raw and raw[0]==2:
            hit={"kind":"direct","data":raw.hex(),"accounts":[keys[a] for a in ins["accounts"]]}
    if hit:
        hit["sig"]=s["signature"]; hit["slot"]=s["slot"]; hit["blockTime"]=tx.get("blockTime")
        hit["preTokenBalances"]=meta.get("preTokenBalances",[]); hit["postTokenBalances"]=meta.get("postTokenBalances",[])
        hit["logs"]=meta["logMessages"]
        found.append(hit)
        if len(found)>=5: break
print("found swaps:", len(found))
json.dump(found, open(os.path.join(OUT,"successful-swaps.json"),"w"), indent=1)
for f in found:
    print("\n==", f["kind"], "slot", f["slot"], f["sig"][:28], "data", f["data"])
    print("   accounts:")
    for i,a in enumerate(f["accounts"]): print(f"     {i}: {a}")
    pre={b["accountIndex"]:b for b in f["preTokenBalances"]}
    post={b["accountIndex"]:b for b in f["postTokenBalances"]}
    for i in sorted(set(pre)|set(post)):
        p=pre.get(i); q=post.get(i); b=q or p
        pv=float(p["uiTokenAmount"]["uiAmountString"].replace(",","")) if p else 0.0
        qv=float(q["uiTokenAmount"]["uiAmountString"].replace(",","")) if q else 0.0
        if abs(qv-pv)>1e-9:
            print(f"     delta idx{i} mint={b['mint'][:12]} {pv} -> {qv} d={qv-pv:+.9f}")
    for l in f["logs"][:12]:
        if "BiSoNHV" in l or "Program data" in l or "Program log" in l:
            print("     log:", l[:140])
