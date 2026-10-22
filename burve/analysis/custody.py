#!/usr/bin/env python3
"""Ground-truth custody: Diamond's shares in each vertex vault + underlying token balance of the vault."""
import json, urllib.request, concurrent.futures
RPCS=["https://berachain-rpc.publicnode.com","https://rpc.berachain.com","https://berachain.drpc.org"]
D="0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089"
def rp(m,p):
    last=None
    for u in RPCS:
        try:
            req=urllib.request.Request(u,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=30) as r: j=json.loads(r.read())
            if "result" in j: return j["result"]
            last=j
        except Exception as e: last=e
    raise RuntimeError(str(last))
def c(to,data):
    try: return rp("eth_call",[{"to":to,"data":data},"latest"])
    except Exception: return None
def pad(a): return "0"*24+a[2:].lower()
def num(h): return int(h,16) if h and h!="0x" else None

TOKENS=[("USDC.e","0x549943e04f40284185054145c6e4e9568c1d3241",6,"0x444868b6e8079ac2c55eea115250f92c2b2c4d14"),
("USDt0","0x779ded0c9e1022225f8e0630b35a9b54be713736",6,"0xf2d2d55daf93b0660297eaa10969ebe90ead5ce8"),
("BUSD","0xfcbd14dc51f0a4d49d5e53c2e0950e0bc26d0dce",18,"0x7f2b60fdff1494a0e3e060532c9980d7fad0404b"),
("NECT","0x1ce0a25d13ce4d52071ae7e02cf1f6606f4c79d3",18,"0x474f32eb1754827c531c16330db07531e901bcbe"),
("USDe","0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",18,"0xd628b5abd6829896134ffdaeea8393dc531a1efd"),
("USDa","0xff12470a969dd362eb6595ffb44c82c959fe9acc",18,"0x0d1a3ce611ce10b72d4a14dae2a4443855b6dfc3"),
("MEAD","0xedb5180661f56077292c92ab40b1ac57a279a396",18,"0x82576213872683791b9f779cf788a6d478651c78"),
("rUSD","0x09d4214c03d01f49544c0448dbe3a27f768f2b34",18,"0x3000c6bf0aaeb813e252b584c4d9a82f99e7a71d"),
("BYUSD","0x688e72142674041f8f6af4c808a4045ca1d6ac82",6,"0x2948609cdd0ac4110b63165be9d4aade66bf40f6")]

blk=int(rp("eth_blockNumber",[]),16); print("block",blk)
out=[]
for sym,tok,dec,vault in TOKENS:
    shares=num(c(vault,"0x70a08231"+pad(D)))          # balanceOf(diamond)
    totalSupply=num(c(vault,"0x18160ddd"))
    totalAssets=num(c(vault,"0x01e1d114"))
    vaultTokBal=num(c(tok,"0x70a08231"+pad(vault)))
    name=c(vault,"0x06fdde03")
    conv = None
    if shares is not None:
        conv=num(c(vault,"0x07a2d13a"+f"{shares:064x}"))  # convertToAssets(shares)
    row=dict(sym=sym,token=tok,vault=vault,dec=dec,shares=shares,totalSupply=totalSupply,totalAssets=totalAssets,
             vaultTokenBalance=vaultTokBal,assetsOfShares=conv)
    out.append(row)
    print(f"{sym:6s} vault={vault} shares={shares} totalSupply={totalSupply} totalAssets={totalAssets} vaultTokBal={vaultTokBal} convertToAssets(shares)={conv}")
json.dump({"block":blk,"rows":out},open("custody.json","w"),indent=1)
