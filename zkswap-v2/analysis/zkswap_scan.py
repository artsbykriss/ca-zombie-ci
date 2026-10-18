#!/usr/bin/env python3
"""Enumerate zkSwap V2 (zkSync Era) factory pairs and reserves. Public RPC only. Batched."""
import json, urllib.request, time, sys

RPC = "https://mainnet.era.zksync.io"
FACTORY = "0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d"
SEL = {"allPairs":"0x1e3dd18b","token0":"0x0dfe1681","token1":"0xd21220a7",
       "getReserves":"0x0902f1ac","totalSupply":"0x18160ddd"}

def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    for attempt in range(5):
        try:
            req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),
                headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
            by={x["id"]:x for x in j}
            out=[]
            for i in range(len(calls)):
                x=by.get(i,{})
                out.append(x.get("result","0x") if "error" not in x else "0x")
            return out
        except Exception as e:
            print("retry",attempt,e,flush=True); time.sleep(2+attempt*2)
    return ["0x"]*len(calls)

def w(h): return int(h,16) if h and h!="0x" else 0
def addr(h): return "0x"+h[-40:] if h and h!="0x" else "0x"+"0"*40

pairs=[]
for start in range(0,48,8):
    cs=[(FACTORY,SEL["allPairs"]+"%064x"%i) for i in range(start,min(start+8,48))]
    for i,r in zip(range(start,start+len(cs)),batch(cs)):
        pairs.append(addr(r))
    print("pairs",start,flush=True)

rows=[]
for start in range(0,48,4):
    chunk=pairs[start:start+4]
    cs=[]
    for p in chunk:
        for k in ["token0","token1","getReserves","totalSupply"]: cs.append((p,SEL[k]))
    res=batch(cs)
    for j,p in enumerate(chunk):
        t0=addr(res[4*j]); t1=addr(res[4*j+1]); rr=res[4*j+2]
        r0=w(rr[2:66]); r1=w(rr[2+64:2+128]); ts=w(rr[2+128:2+192])
        sup=w(res[4*j+3])
        rows.append({"idx":start+j,"pair":p,"token0":t0,"token1":t1,"reserve0":r0,"reserve1":r1,"ts":ts,"totalSupply":sup})
        print(start+j,p,t0,r0,t1,r1,ts,sup,flush=True)
json.dump(rows,open("/home/heisenberg/CA/zkswap-v2/analysis/zkswap_pairs.json","w"),indent=1)
print("saved",len(rows))
