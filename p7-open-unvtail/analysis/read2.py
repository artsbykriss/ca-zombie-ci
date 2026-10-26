#!/usr/bin/env python3
"""Second-pass read-only probes: owners, roles, token holdings, init state."""
import json, urllib.request, time
from concurrent.futures import ThreadPoolExecutor
RPCS = {"op":"https://mainnet.optimism.io","polygon":"https://polygon-bor-rpc.publicnode.com",
 "zksync":"https://mainnet.era.zksync.io","bsc":"https://bsc-dataseed.binance.org",
 "scroll":"https://rpc.scroll.io"}
def rpc(chain, method, params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPCS[chain],data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req,timeout=15) as r: return json.loads(r.read())["result"]
        except Exception: time.sleep(1)
    return None
def call(chain,to,data):
    r=rpc(chain,"eth_call",[{"to":to,"data":data},"latest"])
    return r
def bal(chain,token,holder):
    r=call(chain,token,"0x70a08231"+holder[2:].rjust(64,"0"))
    return int(r,16) if r and r!="0x" else None
def pad(a): return a[2:].lower().rjust(64,"0")

# tokens to check holdings of
TOK={
 "op":{"WETH":"0x4200000000000000000000000000000000000006","USDT":"0x94b008aA00579c1307B0EF2c499aD98a8ce58e58","USDC":"0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85","wstETH":"0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb","OP":"0x4200000000000000000000000000000000000042"},
 "polygon":{"WPOL":"0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270","WETH":"0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619","USDC":"0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359","USDT":"0xc2132D05D31c914a87C6611C10748AEb04B58e8F"},
 "zksync":{"USDC":"0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4","USDCe":"0x3355df6D4c9C3035724Fd0e5Afcb1aBf2b6aB6d5","WETH":"0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91"},
 "bsc":{"WBNB":"0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c","USDT":"0x55d398326f99059fF775485246999027B3197955","USDC":"0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d","BUSD":"0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","BTCB":"0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c","ETH":"0x2170Ed0880ac9A755fd29B2688956BD959F933F8"},
 "scroll":{"WETH":"0x5300000000000000000000000000000000000004","USDC":"0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4","USDT":"0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df","wstETH":"0xf610A9dfB7C89644979b4A0f27063E9e7d7Cda32"},
}
PROXIES={
 "O1-row22":("op","0xc4d4500326981eacD020e20A81b1c479c161c7EF"),
 "O1-row18":("op","0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5"),
 "O1-row14":("polygon","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"),
 "O1-row16":("op","0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0"),
 "O1-row13":("op","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"),
 "O1-row17":("op","0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf"),
 "O1-row19":("op","0x6726CA16b1Ba702f58D835cf199672CA04E727eC"),
 "O1-row21":("polygon","0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D"),
 "O1-row20":("zksync","0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E"),
 "O1-row15":("bsc","0x4CA08cD98De12a1Df316da8f93BD0b40146e1589"),
 "O2-scr1":("scroll","0x25aB3Efd52e6470681CE037cD546Dc60726948D3"),
 "O2-scr2":("scroll","0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7"),
 "O2-scr3":("scroll","0x7BE980E327692Cf11E793A0d141D534779AF8Ef4"),
 "O2-scr4":("scroll","0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2"),
}
SELS={"owner":"0x8da5cb5b","admin":"0xf851a440","getOwners":"0xa0e67e2b",
 "implementation":"0x5c60da1b","proxiableUUID":"0x52d1902d","hasRole_admin":"0xa217fddf",
 "DEFAULT_ADMIN_ROLE":"0xa217fddf","paused":"0x5c975abb","totalSupply":"0x18160ddd",
 "totalAssets":"0x01e1d114","asset":"0x38d52e0f","name":"0x06fdde03","symbol":"0x95d89b41",
 "getRoleAdmin0":"0x248a9ca3"+ "00"*32, "underlying":"0x6f307dc3"}

def probe(label):
    chain,proxy=PROXIES[label]
    rec={"label":label,"chain":chain,"proxy":proxy,"holdings":{},"reads":{}}
    for tk,ta in TOK[chain].items():
        b=bal(chain,ta,proxy)
        if b: rec["holdings"][tk]={"token":ta,"raw":str(b)}
    for n,sel in SELS.items():
        r=call(chain,proxy,sel)
        if r and r!="0x": rec["reads"][n]=r[:130]
    # native
    rec["native"]=rpc(chain,"eth_getBalance",[proxy,"latest"])
    return rec

if __name__=="__main__":
    out=[]
    with ThreadPoolExecutor(max_workers=5) as ex:
        for r in ex.map(probe, list(PROXIES)):
            out.append(r)
    json.dump(out,open("/tmp/opencode/unvtail/live2.json","w"),indent=1)
    for r in out:
        print(f"\n{r['label']} {r['chain']} {r['proxy']}")
        print("  native", int(r['native'],16) if r.get('native') else None)
        print("  holdings", {k:v['raw'] for k,v in r['holdings'].items()})
        for n,v in r['reads'].items(): print(f"   {n} = {v}")
