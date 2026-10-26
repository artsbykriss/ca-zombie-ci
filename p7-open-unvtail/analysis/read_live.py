#!/usr/bin/env python3
"""Read-only live reads for O1/O2 unverified-impl proxy tail. Keyless public RPCs."""
import json, urllib.request, sys, time
from concurrent.futures import ThreadPoolExecutor

RPCS = {
 "op":      "https://mainnet.optimism.io",
 "polygon": "https://polygon-bor-rpc.publicnode.com",
 "zksync":  "https://mainnet.era.zksync.io",
 "bsc":     "https://bsc-dataseed.binance.org",
 "scroll":  "https://rpc.scroll.io",
}
def rpc(chain, method, params):
    url = RPCS[chain]
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req, timeout=15) as r:
                return json.loads(r.read())["result"]
        except Exception:
            time.sleep(1)
    return None
def code_size(chain, addr):
    c = rpc(chain, "eth_getCode", [addr, "latest"])
    return (len(c)-2)//2 if c and c != "0x" else 0
def bal_of(chain, token, holder):
    data = "0x70a08231" + holder[2:].rjust(64,"0")
    r = rpc(chain, "eth_call", [{"to":token,"data":data}, "latest"])
    return int(r,16) if r and r!="0x" else None
def storage(chain, addr, slot):
    return rpc(chain, "eth_getStorageAt", [addr, slot, "latest"])
EIP1967 = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN   = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
TOK = {
 "op": {"WETH":"0x4200000000000000000000000000000000000006","USDT":"0x94b008aA00579c1307B0EF2c499aD98a8ce58e58","USDC":"0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"},
 "polygon": {"WPOL":"0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270","WETH":"0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"},
 "zksync": {"USDC":"0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4","USDCe":"0x3355df6D4c9C3035724Fd0e5Afcb1aBf2b6aB6d5"},
 "bsc": {},
 "scroll": {"WETH":"0x5300000000000000000000000000000000000004","USDC":"0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4","USDT":"0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df"},
}
TARGETS = [
 ("O1-row22","op","0xc4d4500326981eacD020e20A81b1c479c161c7EF","0x833Be3F17779387a9988DD7f176083b7c8dAd126",["WETH"]),
 ("O1-row18","op","0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5","0x62C9E5e52351E02635f48072fa20c03bb650F787",["WETH"]),
 ("O1-row14","polygon","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4","0xcFe82450B4cd92023A8e184AC75b2ebb24cEdb10",["WPOL"]),
 ("O1-row16","op","0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0","0x028361fD38df0b7Ca722064cEe0F3010355F6409",["WETH"]),
 ("O1-row13","op","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4","0x7b5fDb8C89A616d319202704B0eA18b168654281",["WETH","USDT"]),
 ("O1-row17","op","0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf","0xeE91925Aacca9b96a77a977Ab1DD1688f596858e",["USDT","USDC"]),
 ("O1-row19","op","0x6726CA16b1Ba702f58D835cf199672CA04E727eC","0x1616156771EC4F8F515f8AfFe377c6192113FDff",["WETH"]),
 ("O1-row21","polygon","0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D","0x15F069F9d0b546b328dd4314634Ad3291cC85AF6",["WETH"]),
 ("O1-row20","zksync","0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E","0x442DbDE560FaD77fF197dD719777F840392a48b3",["USDC","USDCe"]),
 ("O1-row15","bsc","0x4CA08cD98De12a1Df316da8f93BD0b40146e1589","0x5abfa214d1ab283e82af40b7129c2c349039eac2",[]),
 ("O2-scr1","scroll","0x25aB3Efd52e6470681CE037cD546Dc60726948D3","0xe9CDb9C251A58D4F86aE49d03005c02a108CC314",["USDC","WETH"]),
 ("O2-scr2","scroll","0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7","0x26623DC729c3Ef363D93b6a0617A41d4D245DEB9",["WETH"]),
 ("O2-scr3","scroll","0x7BE980E327692Cf11E793A0d141D534779AF8Ef4","0x20F4E8cBf7C0062464E1496164B6847112ec41BF",["USDC","WETH"]),
 ("O2-scr4","scroll","0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2","0x655157817E602Fb72ED23ab0188f6C9AB89d83Ff",["WETH"]),
]
PROBES=[("owner","0x8da5cb5b"),("admin","0xf851a440"),("getOwners","0xa0e67e2b"),
        ("paused","0x5c975abb"),("implementation","0x5c60da1b"),("proxiableUUID","0x52d1902d"),
        ("totalAssets","0x01e1d114"),("asset","0x38d52e0f"),("symbol","0x95d89b41")]

def do_target(t):
    label,chain,proxy,impl,toks=t
    rec={"label":label,"chain":chain,"proxy":proxy,"impl":impl}
    rec["proxy_code"]=code_size(chain,proxy); rec["impl_code"]=code_size(chain,impl)
    rec["proxy_native"]=rpc(chain,"eth_getBalance",[proxy,"latest"])
    rec["eip1967_impl_slot"]=storage(chain,proxy,EIP1967)
    rec["eip1967_admin_slot"]=storage(chain,proxy,ADMIN)
    rec["balances"]={}
    for tk in toks:
        ta=TOK[chain].get(tk)
        if ta: rec["balances"][tk]={"token":ta,"raw":bal_of(chain,ta,proxy)}
    rec["probes"]={}
    for name,sel in PROBES:
        r=rpc(chain,"eth_call",[{"to":proxy,"data":sel},"latest"])
        if r and r!="0x": rec["probes"][name]=r[:200]
    return rec

if __name__=="__main__":
    out={"blocks":{},"targets":[]}
    with ThreadPoolExecutor(max_workers=4) as ex:
        futs={ex.submit(do_target,t):t for t in TARGETS}
        for f in futs:
            try: out["targets"].append(f.result())
            except Exception as e: out["targets"].append({"error":str(e),"t":futs[f][0]})
    for c in RPCS:
        out["blocks"][c]=int(rpc(c,"eth_blockNumber",[]),16)
    json.dump(out,open("/tmp/opencode/unvtail/live1.json","w"),indent=1)
    print("done")
