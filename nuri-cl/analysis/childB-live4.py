#!/usr/bin/env python3
"""childB: NFP NFT transfer sample + NURI liquidity check (legacy pair + CL pools + price)."""
import json, urllib.request
RPC="https://rpc.scroll.io"
def rpcm(batch):
    req=urllib.request.Request(RPC,data=json.dumps(batch).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out=json.load(urllib.request.urlopen(req,timeout=120))
    return [out] if isinstance(out,dict) else sorted(out,key=lambda x:x["id"])
def api(params):
    url="https://scrollscan.com/api?"+params
    req=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=120))
from eth_hash.auto import keccak
def sel(sig): return "0x"+keccak(sig.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to,data): return {"jsonrpc":"2.0","method":"eth_call","params":[{"to":to,"data":data},"latest"]}
NFP="0xAAA78E8C4241990B4ce159E105dA08129345946A"
VOTER="0xaaaf3d9cdd3602d117c67d80eec37a160c8d9869"
NURI="0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"
# 1) sample NFT transfer record full fields
r=api("module=account&action=tokennfttx&contractaddress=%s&page=1&offset=2&sort=desc"%NFP)
for rec in r.get("result",[]):
    print(json.dumps({k:rec[k] for k in rec if k not in ()}, indent=1)[:1200]); print("---")
# 2) Voter.factory() legacy + reads
batch=[];ids=[]
def add(tag,item): item["id"]=len(batch); ids.append(tag); batch.append(item)
add(("Voter","factory"), call(VOTER, sel("factory()")))
add(("Voter","length"), call(VOTER, sel("length()")))
out={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpcm(ch)
    for c,rr2 in zip(ch,rr):
        out["::".join(ids[c["id"]+i])]=rr2.get("result",{"error":rr2.get("error")})
print(json.dumps(out,indent=1))
factory=out.get("Voter::factory")
if isinstance(factory,str) and factory.startswith("0x") and len(factory)>=42:
    F="0x"+factory[-40:]
    print("legacy factory:",F)
    # getPair with NURI against WETH, USDC, USDT, SCR, DAI x stable/volatile
    toks={"WETH":"0x5300000000000000000000000000000000000004","USDC":"0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4",
          "USDT":"0xf55bec9cafdbe8730f096aa55dad6d22d44099df","SCR":"0xd29687c813d741e2f938f4ac377128810e217b1b",
          "DAI":"0xca77eb3fefe3725dc33bccb54edefc3d9f764f97","wstETH":"0xf610a9dfb7c89644979b4a0f27063e9e7d7cda32"}
    pairs={}
    batch=[];ids=[]
    for name,t in toks.items():
        for stable in (False,True):
            add(("pair",name,stable), call(F, sel("getPair(address,address,bool)")+a(NURI)+a(t)+u(1 if stable else 0)))
    out2={};CH=8
    for i in range(0,len(batch),CH):
        ch=batch[i:i+CH]
        for j,c in enumerate(ch): c["id"]=j
        rr=rpcm(ch)
        for c,rr2 in zip(ch,rr):
            out2["::".join(map(str,ids[c["id"]+i]))]=rr2.get("result",{"error":rr2.get("error")})
    print(json.dumps(out2,indent=1))
    # for non-zero pairs, read reserves + tokens
    nz=[(k,v) for k,v in out2.items() if isinstance(v,str) and len(v)>=42 and int(v,16)!=0]
    batch=[];ids=[];pmeta=[]
    for k,v in nz:
        P="0x"+v[-40:]
        pmeta.append((k,P))
        add(("reserves",k), call(P, sel("getReserves()")))
        add(("token0",k), call(P, sel("token0()")))
        add(("token1",k), call(P, sel("token1()")))
        add(("totalSupply",k), call(P, sel("totalSupply()")))
    out3={};CH=8
    for i in range(0,len(batch),CH):
        ch=batch[i:i+CH]
        for j,c in enumerate(ch): c["id"]=j
        rr=rpcm(ch)
        for c,rr2 in zip(ch,rr):
            out3["::".join(map(str,ids[c["id"]+i]))]=rr2.get("result",{"error":rr2.get("error")})
    print(json.dumps(out3,indent=1))
# 3) CL factory getPool NURI pairs + liquidity
FACT="0xaaa32926fce6be95ea2c51cb4fcb60836d320c42"
batch=[];ids=[]
for name,t in {"USDC":"0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4","WETH":"0x5300000000000000000000000000000000000004","USDT":"0xf55bec9cafdbe8730f096aa55dad6d22d44099df"}.items():
    for fee in (100,500,3000,10000):
        add(("cl",name,fee), call(FACT, sel("getPool(address,address,uint24)")+a(NURI)+a(t)+u(fee)))
out4={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpcm(ch)
    for c,rr2 in zip(ch,rr):
        out4["::".join(ids[c["id"]+i])]=rr2.get("result",{"error":rr2.get("error")})
print(json.dumps(out4,indent=1))
