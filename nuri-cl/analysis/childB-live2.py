#!/usr/bin/env python3
"""childB live reads #2: decode addresses, owner maps, candidate holders, NURI liquidity."""
import json, urllib.request
from eth_hash.auto import keccak

RPC = "https://rpc.scroll.io"
def rpc(batch):
    req = urllib.request.Request(RPC, data=json.dumps(batch).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out = json.load(urllib.request.urlopen(req, timeout=120))
    if isinstance(out, dict): return [out]
    return sorted(out, key=lambda x: x["id"])
def sel(sig): return "0x"+keccak(sig.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to, data): return {"jsonrpc":"2.0","method":"eth_call","params":[{"to":to,"data":data},"latest"]}
def bal(to, data=None):
    if data is None: return {"jsonrpc":"2.0","method":"eth_getBalance","params":[to,"latest"]}
    return call(to,data)

NFP  = "0xAAA78E8C4241990B4ce159E105dA08129345946A"
VE   = "0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F"
MINTER = "0xAAA823aa799BDa3193D46476539bcb1da5B71330"
NURI = "0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"

def hexa(n): return "0x"+format(n,'x')
# decode known ints from live1
known = {
 "NFP::factory": 974167037378029904608034694557683051310687063106,
 "NFP::WETH9": 473846233978378680511350941857232385279071879172,
 "NFP::voter": 974436428677326483440539530868320944455307597929,
 "NFP::impl": 483826351662162392443173046356100186435689727075,
 "VE::impl": 17585972830953291808547343173522530717538518432,
 "MINTER::impl": 1296943131922247587785103724347910663219904920952,
 "VE::emissionsToken": 974420213418887870337013456177344308269293426537,
 "VE::voter": 974436428677326483440539530868320944455307597929,
 "VE::team": 1152202014871269092184595447301850587076232901207,
}
hexed = {k: hexa(v) for k,v in known.items()}
print(json.dumps(hexed, indent=1))

VOTER = hexed["NFP::voter"]
FACT = hexed["NFP::factory"]
TEAM = hexed["VE::team"]
# candidate contract holders of veNFT / NFP NFTs
CAND = {
 "NFP":NFP, "VE":VE, "Voter":VOTER, "CLFactory":FACT, "Minter":MINTER,
 "TeamSafe":TEAM,
}
out={}
batch=[]; ids=[]
def add(tag,item):
    item["id"]=len(batch); ids.append(tag); batch.append(item)

# Voter reads
for nm,sig in [("_ve","_ve()"),("governor","governor()"),("nfpManager","nfpManager()"),("clGaugeFactory","clGaugeFactory()"),("clFactory","clFactory()"),("minter","minter()"),("feeDistributorFactory","feeDistributorFactory()"),("xToken","xToken()"),("timelock","timelock()")]:
    add(("Voter",nm), call(VOTER, sel(sig)))
# fact reads
for nm,sig in [("owner","owner()"),("nfpManager","nfpManager()"),("votingEscrow","votingEscrow()"),("voter","voter()"),("feeCollector","feeCollector()")]:
    add(("CLFact",nm), call(FACT, sel(sig)))
# balances of candidates for veNFT and NFP NFT
for nm,addr in CAND.items():
    add(("VE_bal",nm), call(VE, sel("balanceOf(address)")+a(addr)))
    add(("NFP_bal",nm), call(NFP, sel("balanceOf(address)")+a(addr)))
# NURI token reads
for nm,sig in [("totalSupply","totalSupply()"),("name","name()"),("symbol","symbol()")]:
    add(("NURI",nm), call(NURI, sel(sig)))
# NURI balances of VE / NFP / VOTER
for nm,addr in list(CAND.items()):
    add(("NURI_bal",nm), call(NURI, sel("balanceOf(address)")+a(addr)))
# ETH balances of VE and VOTER
add(("ETH_bal","VE"), bal(VE))
add(("ETH_bal","Voter"), bal(VOTER))

res={}
CH=8
for i in range(0,len(batch),CH):
    chunk=batch[i:i+CH]
    for j,c in enumerate(chunk): c["id"]=j
    r=rpc(chunk)
    for c,rr in zip(chunk,r):
        tag=ids[c["id"]+i]
        res["::".join(tag)]=rr.get("result",{"error":rr.get("error")})
print(json.dumps(res, indent=1))
