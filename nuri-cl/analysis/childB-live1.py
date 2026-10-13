#!/usr/bin/env python3
"""childB live reads: NFP / veNURI surface (read-only, public Scroll RPC). Outputs JSON."""
import json, urllib.request, sys
from eth_hash.auto import keccak

RPC = "https://rpc.scroll.io"
def rpc(batch):
    req = urllib.request.Request(RPC, data=json.dumps(batch).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out = json.load(urllib.request.urlopen(req, timeout=90))
    if isinstance(out, dict): return [out]
    return sorted(out, key=lambda x: x["id"])

def sel(sig): return "0x"+keccak(sig.encode()).hex()[:8]
def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def enc_uint(n): return hex(n)[2:].rjust(64,"0")
def enc_bool(b): return "1".rjust(64,"0") if b else "0"*64

def eth_call(to, data, tag="latest"):
    return {"jsonrpc":"2.0","method":"eth_call","params":[{"to":to,"data":data},tag]}
def get_balance(a, tag="latest"):
    return {"jsonrpc":"2.0","method":"eth_getBalance","params":[a,tag]}
def get_storage(a, slot, tag="latest"):
    return {"jsonrpc":"2.0","method":"eth_getStorageAt","params":[a,slot,tag]}

NFP  = "0xAAA78E8C4241990B4ce159E105dA08129345946A"
NFPI = "0x54bF8621E502C36A574a3EE63eF2004c5B694463"
VE   = "0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F"
VEI  = "0x031495114a8F54d64E46A4545b2773ccb51105A0"
MINTER = "0xAAA823aa799BDa3193D46476539bcb1da5B71330"
NURI = "0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"

TOKENS = {
 "WETH":"0x5300000000000000000000000000000000000004",
 "USDC":"0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4",
 "USDT":"0xf55bec9cafdbe8730f096aa55dad6d22d44099df",
 "DAI":"0xca77eb3fefe3725dc33bccb54edefc3d9f764f97",
 "wstETH":"0xf610a9dfb7c89644979b4a0f27063e9e7d7cda32",
 "weETH":"0x01f0a31698c4d065659b9bdc21b3610292a1c506",
 "rsETH":"0x65421ba909200b81640d98b979d07487c9781b66",
 "wrsETH":"0xa25b25548b4c98b0c7d3d27dca5d5ca743d68b7f",
 "USDe":"0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
 "SCR":"0xd29687c813d741e2f938f4ac377128810e217b1b",
 "STONE":"0x80137510979822322193fc997d400d5a6c747bf7",
 "eUSD":"0x939778d83b46b456224a33fb59630b11dec56663",
 "WBTC":"0x3c1bca5a656e69edcd0d4e36bebb3fcdaca60cf1",
 "PufETH":"0xc4d46e8402f476f269c379677c99f18e22ea030e",
 "eBTC":"0x657e8c867d8b37dcc18fa4caead9c45eb088c642",
 "NURI":NURI,
}

out = {}
batch = []
ids = []
def add(tag, item):
    item["id"] = len(ids); ids.append(tag); batch.append(item)

# NFP reads
for name, sig, args in [
    ("factory","factory()",[]),
    ("WETH9","WETH9()",[]),
    ("voter","voter()",[]),
    ("totalSupply","totalSupply()",[]),
    ("ownerOf_1","ownerOf(uint256)",[1]),
    ("ownerOf_2","ownerOf(uint256)",[2]),
    ("getApproved_1","getApproved(uint256)",[1]),
    ("isApprovedOrOwner_null","isApprovedOrOwner(address,uint256)",["0x0000000000000000000000000000000000000000",1]),
]:
    d = sel(sig) + "".join(enc_uint(a) if isinstance(a,int) else enc_addr(a) for a in args)
    add(("NFP",name), eth_call(NFP,d))

# proxies: ERC1967 impl slot
S_IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
add(("NFP","impl_slot"), get_storage(NFP,S_IMPL))
add(("VE","impl_slot"), get_storage(VE,S_IMPL))
add(("MINTER","impl_slot"), get_storage(MINTER,S_IMPL))

# balances at NFP
add(("NFP","eth"), get_balance(NFP))
for sym,addr in TOKENS.items():
    add(("NFP_bal",sym), eth_call(addr, sel("balanceOf(address)")+enc_addr(NFP)))
# NURI balances elsewhere
for name,addr in [("NFP",NFP),("VE",VE),("VOTER_from_NFP",None)]:
    pass

# probe selectors on NFP: sweepToken(token,0,nobody), refundETH(), unwrapWETH9(0,nobody), random selector
NOBODY = "0x000000000000000000000000000000000000dEaD"
add(("NFP","probe_sweepToken_USDC"), eth_call(NFP, sel("sweepToken(address,uint256,address)")+enc_addr(TOKENS["USDC"])+enc_uint(0)+enc_addr(NOBODY)))
add(("NFP","probe_refundETH"), eth_call(NFP, sel("refundETH()")))
add(("NFP","probe_unwrapWETH9"), eth_call(NFP, sel("unwrapWETH9(uint256,address)")+enc_uint(0)+enc_addr(NOBODY)))
add(("NFP","probe_random"), eth_call(NFP, "0xdeadbeef"))

# veNURI reads
add(("VE","totalSupply"), eth_call(VE, sel("totalSupply()")))
add(("VE","latestTokenId"), eth_call(VE, sel("latestTokenId()")))
add(("VE","supply"), eth_call(VE, sel("supply()")))
add(("VE","emissionsToken"), eth_call(VE, sel("emissionsToken()")))
add(("VE","voter"), eth_call(VE, sel("voter()")))
add(("VE","team"), eth_call(VE, sel("team()")))
add(("VE","ownerOf_1"), eth_call(VE, sel("ownerOf(uint256)")+enc_uint(1)))
add(("VE","balanceOf_NFP"), eth_call(VE, sel("balanceOf(address)")+enc_addr(NFP)))
add(("VE","balanceOf_VE"), eth_call(VE, sel("balanceOf(address)")+enc_addr(VE)))

out = {}
CH = 8
for i in range(0, len(batch), CH):
    chunk = batch[i:i+CH]
    for j, c in enumerate(chunk):
        c["id"] = j
    res = rpc(chunk)
    for c, r in zip(chunk, res):
        tag = ids[c["id"] + i]
        key = "::".join(tag)
        out[key] = r.get("result", {"error": r.get("error")})
print(json.dumps(out, indent=1))
