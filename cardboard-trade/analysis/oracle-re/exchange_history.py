#!/usr/bin/env python3
"""Scan exchange history for top-level instruction tags; dump vault + config."""
import json,sys,os,base64,collections,time
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n=0
    for c in s: n=n*58+A.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    return b'\x00'*(len(s)-len(s.lstrip('1')))+b
EX="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
r=rpc("getSignaturesForAddress",[EX,{"limit":200}])
sigs=[x["signature"] for x in r.get("result",[])]
print("exchange sigs:",len(sigs))
toplevel=collections.Counter(); inner=collections.Counter(); tl_ex={}
seen_nonpush=0
for i,s in enumerate(sigs):
    tr=rpc("getTransaction",[s,{"encoding":"jsonParsed","maxSupportedTransactionVersion":1,"commitment":"confirmed"}])
    res=tr.get("result")
    if not res: continue
    for ix in res["transaction"]["message"]["instructions"]:
        if ix.get("programId")!=EX: continue
        d=ix.get("data")
        try: raw=b58d(d) if d else b""
        except Exception: raw=b""
        toplevel[raw[0] if raw else None]+=1
        tl_ex.setdefault(raw[0] if raw else None,d[:50] if d else "")
        seen_nonpush+=1
    for grp in res["meta"].get("innerInstructions",[]) or []:
        for ix in grp["instructions"]:
            if ix.get("programId")!=EX: continue
            d=ix.get("data")
            try: raw=b58d(d) if d else b""
            except Exception: raw=b""
            inner[raw[0] if raw else None]+=1
    if i%40==0: print("  ..",i)
print("TOP-LEVEL exchange tags:",dict(toplevel))
for t,d in tl_ex.items(): print(f"   top tag {t}: {d}")
print("INNER exchange tags:",dict(inner))
# vault
print("=== vault / config ===")
for name,addr in [("vault?","DSnqZ6ctbYfBf5bf5VnDGdEFrhzPHXSFmk4d7dGkbFE"),("config","HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B")]:
    rr=rpc("getAccountInfo",[addr,{"encoding":"jsonParsed"}])
    print(name,addr,json.dumps(rr.get("result",{}).get("value",{}))[:400])
