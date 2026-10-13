#!/usr/bin/env python3
"""childB live #7: contract owner check, TeamSafe veNFTs, gauge period state, NURI price."""
import json, urllib.request
RPC="https://rpc.scroll.io"
def rpcm(batch):
    req=urllib.request.Request(RPC,data=json.dumps(batch).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    o=json.load(urllib.request.urlopen(req,timeout=120)); return [o] if isinstance(o,dict) else sorted(o,key=lambda x:x["id"])
from eth_hash.auto import keccak
def sel(s): return "0x"+keccak(s.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to,data): return {"jsonrpc":"2.0","method":"eth_call","params":[{"to":to,"data":data},"latest"]}
SFACT="0x8e5ad312483fb369d8a5e724cb50e5b5b3228865"
OWNER="0xc7adb2647f7777aa697d40de8ae1a0b23bf2c663"
VE="0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F"
TEAM="0xc9d28676b7d470210a3c490b60729660ee5a7257"
GAUGE="0xc32dff16353bce12e0bc85963c2caf41bac5ca25"
batch=[];ids=[]
def add(t,item): item["id"]=len(batch); ids.append(t); batch.append(item)
add(("Sickle","admins_of_owner"), call(SFACT, sel("admins(address)")+a(OWNER)))
add(("Sickle","sickles_of_owner"), call(SFACT, sel("sickles(address)")+a(OWNER)))
add(("Sickle","isActive"), call(SFACT, sel("isActive()")))
add(("Sickle","registry"), call(SFACT, sel("registry()")))
# TeamSafe veNFTs
for i in range(9):
    add(("TeamSafe","veNFT_%d"%i), call(VE, sel("tokenOfOwnerByIndex(address,uint256)")+a(TEAM)+u(i)))
# gauge current period data
# current period = now/604800; compute after
out={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpcm(ch)
    for c,r in zip(ch,rr):
        out["::".join(ids[c["id"]+i])]=r.get("result",{"error":r.get("error")})
for k,v in out.items():
    print(f"{k:46s} {str(v)[:90]}")
# collect NFT ids and read locked()
ids_ve=[int(v,16) for k,v in out.items() if k.startswith("TeamSafe") and isinstance(v,str) and len(v)==66]
print("TeamSafe veNFT ids:",ids_ve)
batch=[];ids=[]
for tid in ids_ve:
    add(("locked",tid), call(VE, sel("locked(uint256)")+u(tid)))
    add(("voted",tid), call(VE, sel("voted(uint256)")+u(tid)))
out2={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpcm(ch)
    for c,r in zip(ch,rr):
        out2["::".join(map(str,ids[c["id"]+i]))]=r.get("result",{"error":r.get("error")})
tot=0
for k,v in out2.items():
    if k.startswith("locked") and isinstance(v,str) and len(v)==130:
        amt=int(v[:66],16)
        # int128 two's complement if needed
        end=int(v[66:],16)
        print(f"{k:22s} amount={amt/1e18:.2f} NURI end={end}")
        if k.startswith("locked"): tot+=amt/1e18
    else:
        print(f"{k:22s} {str(v)[:80]}")
print("TeamSafe total locked NURI:",round(tot,2))
# DefiLlama price NURI
try:
    d=json.load(urllib.request.urlopen("https://coins.llama.fi/prices/current/scroll:0xAAAE8378809bB8815c08D3C59Eb0c7D1529aD769",timeout=60))
    print("llama:",json.dumps(d)[:400])
except Exception as e:
    print("llama err",e)
