#!/usr/bin/env python3
"""childA: full-history period scan (votes + rewardSupply) for top FDs to split claimable vs stranded."""
import json, urllib.request, time, sys

RPC="https://rpc.scroll.io"; UA="Mozilla/5.0"
S={"votes":"0x5df81330","rewardSupply":"0x8bb28cb5"}
_id=[300000]
def call(to,data):
    _id[0]+=1
    return {"jsonrpc":"2.0","id":_id[0],"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
def pad(x):
    x=x[2:] if x.startswith("0x") else x
    return x.rjust(64,"0")
def batch(calls):
    res={}
    for i in range(0,len(calls),5):
        ch=calls[i:i+5]
        req=urllib.request.Request(RPC,data=json.dumps(ch).encode(),headers={"User-Agent":UA,"Content-Type":"application/json"})
        for a in range(4):
            try:
                with urllib.request.urlopen(req,timeout=60) as r: out=json.loads(r.read().decode()); break
            except Exception:
                if a==3: raise
                time.sleep(2*(a+1))
        by={x["id"]:x for x in out}
        for c in ch:
            x=by.get(c["id"],{})
            res[c["id"]]=x.get("result") if "result" in x else {"error":x.get("error")}
    return res

raw=json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))
P0=raw["period"]; WEEK=604800
T={"WETH":"0x5300000000000000000000000000000000000004","USDC":"0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4","USDT":"0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df","SCR":"0xd29687c813D741E2F938F4aC377128810E217b1b","NURI":"0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769"}
targets={
 "0x52239d606af3a8b41b13f9c3d7658054de4a165f":["WETH","USDC","SCR","NURI"],
 "0x5d8e5ba42c68bbd1e9ac9b22b9f1989e9fb51a26":["WETH","USDC","NURI"],
 "0x09646c9ca026181f27d50ddb629ffc1472fe546c":["USDC","SCR"],
}
calls=[];idx={}
for fd,toks in targets.items():
    fp=raw["fds"][fd]["firstPeriod"]
    ps=list(range(fp,P0+1,WEEK))+[P0+WEEK]
    for P in ps:
        c=call(fd,S["votes"]+pad(hex(P)));calls.append(c);idx[c["id"]]=(fd,P,"votes")
        for t in toks:
            c=call(fd,S["rewardSupply"]+pad(hex(P))+pad(T[t]));calls.append(c);idx[c["id"]]=(fd,P,t)
print("total calls",len(calls),file=sys.stderr)
res=batch(calls)
per={}
for cid,(fd,P,t) in idx.items():
    r=res[cid]; val=None if isinstance(r,dict) else (int(r,16) if r and r!="0x" else 0)
    per.setdefault(fd,{}).setdefault(P,{})[t]=val
out={"P0":P0,"per":{fd:{str(P):v for P,v in d.items()} for fd,d in per.items()}}
json.dump(out,open("/home/heisenberg/CA/nuri-cl/analysis/childA-history.json","w"),indent=1)
for fd,toks in targets.items():
    d=per[fd]
    for t in toks:
        claimable=sum(v.get(t,0) for P,v in d.items() if P<=P0 and v.get("votes",0)>0)
        stranded=sum(v.get(t,0) for P,v in d.items() if P<=P0 and not v.get("votes",0))
        future=sum(v.get(t,0) for P,v in d.items() if P>P0)
        active=[P for P,v in d.items() if P<=P0 and v.get(t,0)>0 and v.get("votes",0)>0]
        bal=raw["fds"][fd]["balances"].get(t)
        dec=6 if t in("USDC","USDT") else 18
        print(f"{fd} {t}: balance={bal/10**dec:.6f} sum_claimable_buckets={claimable/10**dec:.6f} sum_stranded={stranded/10**dec:.6f} future={future/10**dec:.6f} active_buckets={len(active)}")
