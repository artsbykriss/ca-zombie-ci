#!/usr/bin/env python3
"""Fetch runtime bytecode for impls + proxies (keyless RPC). Save hex to analysis/code/."""
import json, urllib.request, os, time
RPCS = {
 "op":"https://mainnet.optimism.io","polygon":"https://polygon-bor-rpc.publicnode.com",
 "zksync":"https://mainnet.era.zksync.io","bsc":"https://bsc-dataseed.binance.org",
 "scroll":"https://rpc.scroll.io",
}
def rpc(chain, method, params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPCS[chain],data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req,timeout=20) as r: return json.loads(r.read())["result"]
        except Exception: time.sleep(1)
    return None
PAIRS=[
 ("row22_op","op","0xc4d4500326981eacD020e20A81b1c479c161c7EF","0x833Be3F17779387a9988DD7f176083b7c8dAd126"),
 ("row18_op","op","0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5","0x62C9E5e52351E02635f48072fa20c03bb650F787"),
 ("row14_poly","polygon","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4","0xcFe82450B4cd92023A8e184AC75b2ebb24cEdb10"),
 ("row16_op","op","0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0","0x028361fD38df0b7Ca722064cEe0F3010355F6409"),
 ("row13_op","op","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4","0x7b5fDb8C89A616d319202704B0eA18b168654281"),
 ("row17_op","op","0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf","0xeE91925Aacca9b96a77a977Ab1DD1688f596858e"),
 ("row19_op","op","0x6726CA16b1Ba702f58D835cf199672CA04E727eC","0x1616156771EC4F8F515f8AfFe377c6192113FDff"),
 ("row21_poly","polygon","0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D","0x15F069F9d0b546b328dd4314634Ad3291cC85AF6"),
 ("row20_zksync","zksync","0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E","0x442DbDE560FaD77fF197dD719777F840392a48b3"),
 ("row15_bsc","bsc","0x4CA08cD98De12a1Df316da8f93BD0b40146e1589","0x5abfa214d1ab283e82af40b7129c2c349039eac2"),
 ("scr1","scroll","0x25aB3Efd52e6470681CE037cD546Dc60726948D3","0xe9CDb9C251A58D4F86aE49d03005c02a108CC314"),
 ("scr2","scroll","0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7","0x26623DC729c3Ef363D93b6a0617A41d4D245DEB9"),
 ("scr3","scroll","0x7BE980E327692Cf11E793A0d141D534779AF8Ef4","0x20F4E8cBf7C0062464E1496164B6847112ec41BF"),
 ("scr4","scroll","0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2","0x655157817E602Fb72ED23ab0188f6C9AB89d83Ff"),
]
os.makedirs("/tmp/opencode/unvtail/code",exist_ok=True)
for name,chain,proxy,impl in PAIRS:
    for tag,a in (("proxy",proxy),("impl",impl)):
        c=rpc(chain,"eth_getCode",[a,"latest"])
        if c and c!="0x":
            open(f"/tmp/opencode/unvtail/code/{name}.{tag}.hex","w").write(c)
            print(f"{name}.{tag} {chain} {a} {(len(c)-2)//2} bytes")
        else:
            print(f"{name}.{tag} {chain} {a} EMPTY")
