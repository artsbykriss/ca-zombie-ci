#!/usr/bin/env python3
"""childB: NFP/veNFT recent-transfer owner census + SickleFactory whitelist live checks."""
import json, urllib.request, time, collections
RPC="https://rpc.scroll.io"
def api(params, tries=4):
    url="https://scrollscan.com/api?"+params
    for t in range(tries):
        try:
            req=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"})
            d=json.load(urllib.request.urlopen(req,timeout=90))
            return d
        except Exception as e:
            time.sleep(2+t*3)
    return {"status":"0","result":None}
def rpcm(batch):
    req=urllib.request.Request(RPC,data=json.dumps(batch).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    o=json.load(urllib.request.urlopen(req,timeout=120)); return [o] if isinstance(o,dict) else sorted(o,key=lambda x:x["id"])
from eth_hash.auto import keccak
def sel(s): return "0x"+keccak(s.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to,data,frm=None):
    o={"to":to,"data":data}
    if frm: o["from"]=frm
    return {"jsonrpc":"2.0","method":"eth_call","params":[o,"latest"]}

NFP="0xAAA78E8C4241990B4ce159E105dA08129345946A"
VE="0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47bb9Ce6F".lower()
VE="0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F"
STRAT="0x74969242d400c5549d8dc6bd0d0d6dc699ea319a"
BRIDGE="0x7351633d56663f2861907a573e8d4f67828ae330"

def census(contract, pages):
    """collect transfers desc; return tokenId -> latest to"""
    latest={}
    events=0
    for p in range(1,pages+1):
        d=api(f"module=account&action=tokennfttx&contractaddress={contract}&page={p}&offset=100&sort=desc")
        res=d.get("result") or []
        if not isinstance(res,list) or not res: break
        for r in res:
            events+=1
            tid=r["tokenID"]; frm=r.get("from","").lower(); to=r.get("to",r.get("contractAddress","")).lower()
            if tid not in latest:  # desc order => first seen is latest
                latest[tid]={"to":to,"from":frm,"blk":int(r["blockNumber"])}
        time.sleep(0.35)
    return latest, events

print("== NFP census (recent 12 pages)")
nfp,ev=census(NFP,12); print("nfp events:",ev,"tokens:",len(nfp))
own_nfp=collections.Counter(v["to"] for v in nfp.values())
print("nfp top owners:",own_nfp.most_common(12))
burns=sum(1 for v in nfp.values() if v["to"]=="0x0000000000000000000000000000000000000000")
print("burns in window:",burns)
print("== VE census (recent 12 pages)")
ve,ev2=census(VE,12); print("ve events:",ev2,"tokens:",len(ve))
own_ve=collections.Counter(v["to"] for v in ve.values())
print("ve top owners:",own_ve.most_common(12))
burns2=sum(1 for v in ve.values() if v["to"]=="0x0000000000000000000000000000000000000000")
print("ve burns:",burns2)
# contract-ness of owners
def getcodes(addrs):
    out={}
    items=list(addrs)
    batch=[];ids=[]
    for i,ad in enumerate(items):
        batch.append({"jsonrpc":"2.0","id":i,"method":"eth_getCode","params":[ad,"latest"]}); ids.append(ad)
    for i in range(0,len(batch),10):
        ch=batch[i:i+10]
        rr=rpcm(ch)
        for c,r in zip(ch,rr):
            out[ids[c["id"]]]=r.get("result","0x")
    return out
owners=set(list(own_nfp)+list(own_ve))
codes=getcodes(owners)
contract_owners={k:len(v) for k,v in codes.items() if len(v)>2}
print("distinct owners:",len(owners),"contract owners:",len(contract_owners))
for k,v in sorted(contract_owners.items(), key=lambda x:-x[1])[:25]:
    print("  contract",k,v)
# save
json.dump({"nfp":nfp,"ve":ve,"codes":{k:len(v) for k,v in codes.items()}},open("childB-ownercensus.json","w"),indent=1)
# SickleFactory whitelist check
batch=[]; ids=[]
def add(t,d,frm=None): d["id"]=len(batch); ids.append(t); batch.append(d)
add(("strat","factory"),  call(STRAT, sel("factory()")))
RAND="0x00000000000000000000000000000000000000A1"
# factory reads handled next round after we learn address
rr=rpcm(batch)
for c,r in zip(batch,rr):
    print(ids[c["id"]], r.get("result",{"error":r.get("error")}))
