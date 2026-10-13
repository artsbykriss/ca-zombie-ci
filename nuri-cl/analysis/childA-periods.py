#!/usr/bin/env python3
"""childA: per-FD period accounting: votes(P) and rewardSupply(P, token) around current period."""
import json, urllib.request, time, sys

RPC="https://rpc.scroll.io"; UA="Mozilla/5.0"
SEL={"votes":"0x5df81330","rewardSupply":"0x8bb28cb5"}
_id=[200000]
def call(to,data):
    _id[0]+=1
    return {"jsonrpc":"2.0","id":_id[0],"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
def pad(a):
    a=a[2:] if a.startswith("0x") else a
    return a.rjust(64,"0")
def padaddr(a):
    return a[2:].lower().rjust(64,"0")
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
def rhex(p): return hex(p)[2:]
def addr_of(tid):
    return "0x"+tid

raw=json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))
tl=json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-tokenlists.json"))["tokenlists"]
P0=raw["period"]; WEEK=604800
periods=[P0-k*WEEK for k in range(5,-1,-1)]  # P0-5..P0
CURATED={"0x5300000000000000000000000000000000000004":"WETH",
"0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4":"USDC",
"0xf55bec9cafdbe8730f096aa55dad6d22d44099df":"USDT",
"0xaaae8378809bb8815c08d3c59eb0c7d1529ad769":"NURI",
"0xd29687c813d741e2f938f4ac377128810e217b1b":"SCR",
"0xca77eb3fefe3725dc33bccb54edefc3d9f764f97":"DAI",
"0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34":"USDE",
"0x77fbf86399ed764a084f77b9accb049f3dbc32d2":"loreUSD",
"0x549423e69576b80e91dc836ae37e04209660c4ec":"LORE",
"0x330c43d22bd65a60ffea93a197f04e87faa27b70":"ABCNURI",
"0xf610a9dfb7c89644979b4a0f27063e9e7d7cda32":"WSTETH",
"0x01f0a31698c4d065659b9bdc21b3610292a1c506":"WEETH",
"0xa25b25548b4c98b0c7d3d27dca5d5ca743d68b7f":"WRSETH",
"0x80137510979822322193fc997d400d5a6c747bf7":"STONE",
"0xd44605d3e5ef9a73379ce5258b06e4383c6ff32a":"agETH",
"0xc4d46e8402f476f269c379677c99f18e22ea030e":"PufETH",
"0x3c1bca5a656e69edcd0d4e36bebb3fcdaca60cf1":"WBTC"}
fds=[fd for fd,v in raw["fds"].items() if any(v["balances"].get(k) for k in ("WETH","USDC","USDT","NURI"))]
# augment with SCR etc holders from tokenlists
holders={}
for fd,arr in tl.items():
    if not isinstance(arr,list): continue
    for x in arr:
        v=int(x["value"]); a=x["token"]["address_hash"].lower()
        if v and a in CURATED and fd not in fds:
            fds.append(fd)
fds=sorted(set(fds))
print("FDs to scan:",len(fds),file=sys.stderr)
out={}
calls=[];idx={}
for fd in fds:
    toks=set()
    for x in tl.get(fd,[]):
        if isinstance(x,dict) and int(x["value"]) and x["token"]["address_hash"].lower() in CURATED:
            toks.add(x["token"]["address_hash"].lower())
    for k in ("WETH","USDC","USDT","NURI"):
        if raw["fds"][fd]["balances"].get(k): toks.add([a for a,s in CURATED.items() if s==k][0])
    for P in periods+[P0+WEEK]:
        c=call(fd,SEL["votes"]+pad(rhex(P)));calls.append(c);idx[c["id"]]=(fd,P,"votes")
        for t in toks:
            c=call(fd,SEL["rewardSupply"]+pad(rhex(P))+padaddr(t));calls.append(c);idx[c["id"]]=(fd,P,t)
res=batch(calls)
for cid,(fd,P,t) in idx.items():
    r=res[cid]
    val=None if isinstance(r,dict) else (int(r,16) if r and r!="0x" else 0)
    out.setdefault(fd,{}).setdefault(str(P),{})[t]=val
json.dump({"period0":P0,"periods":[str(p) for p in periods]+[str(P0+WEEK)],"data":out},open("/home/heisenberg/CA/nuri-cl/analysis/childA-periods.json","w"),indent=1)
print("saved",file=sys.stderr)
# summary: for each fd, list claimable-now sum for tokens with votes>0, stranded (votes==0), future
for fd in fds:
    rows=[]
    for P in [str(p) for p in periods]+[str(P0+WEEK)]:
        d=out[fd].get(P,{})
        votes=d.get("votes")
        tokvals={t:v for t,v in d.items() if t!="votes" and v}
        if votes is not None and (votes or tokvals):
            rows.append(f"P{P} votes={votes} " + " ".join(f"{CURATED.get(t,t)[:8]}={v}" for t,v in tokvals.items()))
    print(fd, "|", " || ".join(rows) if rows else "empty")
