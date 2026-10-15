#!/usr/bin/env python3
"""Balances of all Gardens pools' strategies (native + token) + top HNY holders cross-check."""
import json, urllib.request, time, sys, subprocess
RPC="https://rpc.gnosischain.com"
OUT="/home/heisenberg/CA/gnosis-residual/analysis"
def rpc(m,p):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(6):
        try:
            with urllib.request.urlopen(req,timeout=120) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            time.sleep(1.5*(a+1))
    raise RuntimeError("fail")
def call(to,data):
    try: return rpc("eth_call",[{"to":to,"data":data},"latest"])
    except Exception: return None
def bal(addr): return int(rpc("eth_getBalance",[addr,"latest"]),16)/1e18

comm=json.load(open(f"{OUT}/gardens-communities.json"))
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
NT="0x0000000000000000000000000000000000000000"
res=[]
for c in comm:
    row={"community":c["community"],"name":c["name"],"hny":c["hny_balance"],"native":bal(c["community"]),"members":c["totalMembers"],"pools":[]}
    for p in c["pools"]:
        nb=bal(p["strategy"])
        tokbal=None
        if p["token"]!=NT:
            r=call(p["token"],"0x70a08231"+"00"*12+p["strategy"][2:])
            tokbal=int(r,16)/1e18 if r and r!="0x" else None
        else:
            tokbal=nb; nb=0.0
        row["pools"].append({"id":p["poolId"],"strategy":p["strategy"],"token":p["token"],"token_balance":tokbal,"native":nb})
    res.append(row)
    print(json.dumps(row)[:300])
with open(f"{OUT}/gardens-pool-balances.json","w") as f: json.dump(res,f,indent=1)
print("written")
