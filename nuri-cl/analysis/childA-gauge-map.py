#!/usr/bin/env python3
"""childA: recompute gauge->fd mapping + isAlive at pinned block; save childA-gauge-map.json"""
import json, urllib.request, time

RPC="https://rpc.scroll.io"; UA="Mozilla/5.0"
VOTER="0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869"
SEL={"gauges":"0xb9a09fd5","feeDistributors":"0x49e4974a","isAlive":"0x1703e5f9"}
_id=[90000]
def call(to,data):
    _id[0]+=1
    return {"jsonrpc":"2.0","id":_id[0],"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
def pad(a):
    a=a[2:] if a.startswith("0x") else a
    return a.rjust(64,"0")
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

fs=json.load(open("/home/heisenberg/CA/nuri-cl/analysis/gauges.json"))
calls=[]; idx={}
for i,g in enumerate(fs):
    for name,arg in (("gauges",g["pool"]),("isAlive",g["gauge"]),("feeDistributors",g["gauge"])):
        c=call(VOTER,SEL[name]+pad(arg)); calls.append(c); idx[c["id"]]=(i,name)
res=batch(calls)
out=[]
for i,g in enumerate(fs):
    pass
recs=[]
for cid,(i,name) in idx.items():
    r=res[cid]; val=None if isinstance(r,dict) else (("0x"+r[-40:]) if name!="isAlive" else (int(r,16) if r and r!="0x" else 0))
    recs.append((i,name,val))
byi={}
for i,name,val in recs: byi.setdefault(i,{})[name]=val
out=[{"pool":fs[i]["pool"],"gauge":fs[i]["gauge"],"gauge_from_voter":byi[i]["gauges"],"isAlive":byi[i]["isAlive"],"feeDistributor":byi[i]["feeDistributors"]} for i in range(len(fs))]
json.dump({"block":json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))["block"],"gauges":out},open("/home/heisenberg/CA/nuri-cl/analysis/childA-gauge-map.json","w"),indent=1)
n_ok=sum(1 for x in out if x["gauge_from_voter"] and x["gauge_from_voter"].lower()==x["gauge"].lower())
print("block", json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))["block"])
print("gauges:",len(out),"mapping matches:",n_ok,"alive:",sum(1 for x in out if x["isAlive"]))
print("distinct FDs:",len({x["feeDistributor"] for x in out}))
for x in out:
    if x["isAlive"]: print("ALIVE", x["gauge"], "fd", x["feeDistributor"], "pool", x["pool"])
