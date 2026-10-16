#!/usr/bin/env python3
"""Find a recent SUCCESSFUL direct BisonFi swap tx and dump its exact instruction + accounts."""
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

r=rpc("getSignaturesForAddress",[PROG,{"limit":60,"commitment":"confirmed"}])
sigs=r.get("result",[])
out=[]
for s in sigs:
    if s.get("err") is not None: continue
    tx=get_tx(s["signature"])
    if not tx: continue
    meta=tx["meta"]; msg=tx["transaction"]["message"]
    keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
    loaded=(meta.get("loadedAddresses") or {})
    keys += list(loaded.get("writable",[])) + list(loaded.get("readonly",[]))
    # direct: first instruction program == PROG
    if not msg["instructions"]: continue
    pid=keys[msg["instructions"][0]["programIdIndex"]]
    if pid!=PROG: continue
    ins=msg["instructions"][0]
    raw=b58d(ins["data"])
    accts=[keys[a] for a in ins["accounts"]]
    out.append({"sig":s["signature"],"slot":s["slot"],"blockTime":tx.get("blockTime"),
                "data_hex":raw.hex(),"accounts":accts,"naccounts":len(accts),
                "logs":meta["logMessages"][:14],
                "preTokenBalances":meta.get("preTokenBalances",[]),"postTokenBalances":meta.get("postTokenBalances",[])})
    print("FOUND direct swap slot",s["slot"],s["signature"][:24],"data",raw.hex(),"nacc",len(accts))
    if len(out)>=3: break
json.dump(out, open(os.path.join(OUT,"direct-swap-samples.json"),"w"), indent=1)
for o in out:
    print("\n== slot",o["slot"],o["sig"])
    print("  accounts:")
    for i,ac in enumerate(o["accounts"]): print(f"    {i}: {ac}")
    print("  logs:")
    for l in o["logs"]: print("    ",l[:150])
    print("  token deltas:")
    pre={b["accountIndex"]:b for b in o["preTokenBalances"]}
    post={b["accountIndex"]:b for b in o["postTokenBalances"]}
    for i in sorted(set(pre)|set(post)):
        p=pre.get(i); q=post.get(i); b=q or p
        pv=float(p["uiTokenAmount"]["uiAmountString"].replace(",","")) if p else 0.0
        qv=float(q["uiTokenAmount"]["uiAmountString"].replace(",","")) if q else 0.0
        if abs(qv-pv)>1e-9:
            print(f"    idx{i} mint={b['mint'][:12]} owner={b.get('owner')} {pv} -> {qv} d={qv-pv:+.9f}")
