#!/usr/bin/env python3
import json, os, sys, urllib.request
from eth_utils import keccak
KAT = os.environ.get("KATANA_RPC_URL", "https://rpc.katana.network")
def sel(s): return "0x"+keccak(text=s)[:4].hex()
def batch(url, calls):
    reqs=[]
    for i,(to,sig,args) in enumerate(calls):
        data=sel(sig)
        for a in args:
            data += a.to_bytes(32,"big").hex() if isinstance(a,int) else "0"*24+a[2:]
        reqs.append({"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":to,"data":data},"latest"]})
    req=urllib.request.Request(url,data=json.dumps(reqs).encode(),headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req,timeout=60) as r: res=json.loads(r.read())
    out=[None]*len(calls)
    for d in res:
        if "result" in d: out[d["id"]]=d["result"]
    return out
def u(x): return None if x in (None,"0x") else int(x,16)
def ad(x): return None if not x or x=="0x" else "0x"+x[-40:]
def st(x):
    if not x or len(x)<130: return None
    n=int(x[2:66],16); return bytes.fromhex(x[130:130+n*2]).decode(errors="replace")
T={"minter":"0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0","vbUSDC":"0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36","vbUSDT":"0x2DCa96907fde857dd3D816880A0df407eeB2D2F2","vbWBTC":"0x0913DA6Da4b42f538B445599b46Bb4622342Cf52","vbETH":"0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62","yvvbUSDC":"0x80c34BD3A3569E126e7055831036aa7b212cB159"}
specs={"name()":(),"symbol()":(),"decimals()":(),"totalSupply()":(),"totalAssets()":(),"asset()":(),"owner()":(),"paused()":(),"token()":(),"endpoint()":(),"bridge()":(),"globalInitializationCounter()":(),"secondaryChainBalance()":(),"approvalRequired()":(),"balance()":(),"totalDebt()":(),"peers(uint32)":(30101,)}
calls=[];keys=[]
for n,a in T.items():
    for s,args in specs.items():
        calls.append((a,s,args)); keys.append((n,s))
res={}
for i in range(0,len(calls),40):
    vals=batch(KAT,calls[i:i+40])
    for (n,s),v in zip(keys[i:i+40],vals):
        res.setdefault(n,{})[s]=v
out={}
for n,f in res.items():
    o={}
    for s,v in f.items():
        if s in("name()","symbol()"): o[s]=st(v)
        elif s in("totalSupply()","totalAssets()","globalInitializationCounter()","secondaryChainBalance()","paused()","decimals()","balance()","totalDebt()","approvalRequired()"): o[s]=u(v)
        elif s=="peers(uint32)": o[s]=v
        else: o[s]=ad(v)
    out[n]=o
print(json.dumps(out,indent=1))
