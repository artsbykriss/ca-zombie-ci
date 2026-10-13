#!/usr/bin/env python3
"""childB live reads #3: Minter state + NURI token + reinit callability simulation (read-only eth_call)."""
import json, urllib.request
from eth_hash.auto import keccak
RPC = "https://rpc.scroll.io"
def rpc(batch):
    req = urllib.request.Request(RPC, data=json.dumps(batch).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out = json.load(urllib.request.urlopen(req, timeout=120))
    return [out] if isinstance(out,dict) else sorted(out, key=lambda x: x["id"])
def sel(sig): return "0x"+keccak(sig.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to,data): return {"jsonrpc":"2.0","method":"eth_call","params":[{"to":to,"data":data},"latest"]}
MINTER="0xAAA823aa799BDa3193D46476539bcb1da5B71330"
NURI="0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"
VOTER="0xaaaf3d9cdd3602d117c67d80eec37a160c8d9869"
CC="0xAAA6Cbc9966A2DeA7e0DB75A6F7aB78F7eE5cC7e"  # guess? we'll read real
batch=[];ids=[]
def add(tag,item): item["id"]=len(batch); ids.append(tag); batch.append(item)
# Minter getters
for nm,sig in [("weekly","weekly()"),("activePeriod","activePeriod()"),("firstPeriod","firstPeriod()"),("epoch","epoch()"),
               ("timelock","timelock()"),("msig","msig()"),("commandCenter","commandCenter()"),("voter","voter()"),
               ("ve","ve()"),("rewardsDistributor","rewardsDistributor()"),("emissionsToken","emissionsToken()"),
               ("getFlation","getFlation()"),("getGrowthCap","getGrowthCap()"),("weeklyEmission","weeklyEmission()"),
               ("incentivesSize","incentivesSize()"),("calculateGrowth_weekly","calculateGrowth(uint256)")]:
    args=u(0) if "calculateGrowth" in nm else ""
    add(("Minter",nm), call(MINTER, sel(sig)+args))
# reinit simulation
add(("Minter","sim_reinit_CC"), call(MINTER, sel("reinitializeCommandCenter(address)")+a("0x000000000000000000000000000000000000dEaD")))
add(("Minter","sim_reinit_weekly"), call(MINTER, sel("reinitializeWeekly()")))
# NURI token
for nm,sig,arg in [("minter","minter()",None),("owner","owner()",None),("totalSupply","totalSupply()",None),
                   ("decimals","decimals()",None),("balanceOf_MINTER","balanceOf(address)",MINTER),
                   ("balanceOf_VOTER","balanceOf(address)",VOTER),("balanceOf_CC","balanceOf(address)",None)]:
    d=sel(sig)+(a(arg) if arg else "")
    add(("NURI",nm), call(NURI,d))
# NURI mint selector probe: mint(address,uint256) to dead
add(("NURI","sim_mint"), call(NURI, sel("mint(address,uint256)")+a("0x000000000000000000000000000000000000dEaD")+u(1)))
add(("NURI","sim_mintNoArgs"), call(NURI, sel("mint(address,uint256)")))
out={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpc(ch)
    for c,r in zip(ch,rr):
        out["::".join(ids[c["id"]+i])]=r.get("result",{"error":r.get("error")})
print(json.dumps(out,indent=1))
