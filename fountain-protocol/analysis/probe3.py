#!/usr/bin/env python3
"""Probe #3: Band oracle data (rates + lastUpdated), IRM rates, accrual state, misc."""
import json, time, urllib.request

RPC = "https://emerald.oasis.dev"
_id=0
def rpc(method, params):
    global _id; _id+=1
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode(),
                               headers={"Content-Type":"application/json","User-Agent":"fountain-probe/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req,timeout=45) as r: out=json.loads(r.read())
            if "error" in out: return {"error":out["error"]}
            return out.get("result")
        except Exception as e:
            if a==4: return {"error":str(e)}
            time.sleep(1.5*(a+1))
def call(to,data,block): return rpc("eth_call",[{"to":to,"data":data},hex(block)])
def u(h): return None if not isinstance(h,str) or h=="0x" else int(h,16)

def enc_str(s):
    b=s.encode(); return (32).to_bytes(32,"big").hex()+(len(b)).to_bytes(32,"big").hex()+b.hex().ljust(((len(b)+31)//32)*64,"0")
def enc_str2(a,b):
    ba=a.encode(); bb=b.encode()
    off2=64
    return (32).to_bytes(32,"big").hex()+(off2).to_bytes(32,"big").hex()+(len(ba)).to_bytes(32,"big").hex()+ba.hex().ljust(((len(ba)+31)//32)*64,"0")+(len(bb)).to_bytes(32,"big").hex()+bb.hex().ljust(((len(bb)+31)//32)*64,"0")

BAND="0xda7a001b254cd22e46d3eab04d937489c93174c3"
SYMS=["ROSE","ETH","WETH","USDT","USDC","WROSE","WETH(wormhole)","USDT(wormhole)","USDC(celer)","USDC(anyswap)"]
latest=int(rpc("eth_blockNumber",[]),16); block=latest-2
out={"block":block,"band":{}}
for s in SYMS:
    r=call(BAND,"0x65555bcc"+enc_str2(s,"USD"),block)
    out["band"][s]=r
# oracle price() calls for each symbol (classic oracle price(string))
ORACLES={"classic":"0x3789ae7132f2cad96553d378d13c58eb8508258f","usd":"0x512efb22d9aa6024c332e0a2faf6895786cd95aa","lpt":"0x13322c2911f73db4d4893cce068e2c6841207914"}
out["oracle_price"]={}
for label,o in ORACLES.items():
    out["oracle_price"][label]={}
    for s in ["ROSE","ETH","USDT","USDC"]:
        out["oracle_price"][label][s]=call(o,"0xfe2c6198"+enc_str(s),block)
# IRMs
IRMS={"classic":"0xa0af64406406e147df066bc7b782d682c84e5aab","usd":"0x374d7abc6d8fadce97a0fbf62a0a6d6c17a8482b","lpt":"0xba3cbebede0c4e17510664d3f3fb6d7305f72022"}
out["irms"]={}
for label,irm in IRMS.items():
    d={"code":len(rpc("eth_getCode",[irm,hex(block)]) or "0x")//2-1}
    for name,sel in [("baseRatePerBlock()","0xf14039de"),("multiplierPerBlock()","0x8726bb89"),("jumpMultiplierPerBlock()","0xb9f9850a"),
                     ("kink()","0xfd2da339"),("blocksPerYear()","0xa385fb96")]:
        d[name]=call(irm,sel,block)
    out["irms"][label]=d
# per-market getBorrowRate/getSupplyRate (uints encoded)
out["market_rates"]={}
MKT={"classic_fROSE":("0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5","0xa0af64406406e147df066bc7b782d682c84e5aab"),
     "classic_fETH":("0x275b88547185d955f66e5dd1066e040af468fc66","0xa0af64406406e147df066bc7b782d682c84e5aab"),
     "classic_fUSDT":("0x352cc3320debffa3046cf66a4e0a80d528f00285","0xa0af64406406e147df066bc7b782d682c84e5aab"),
     "classic_fUSDC":("0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258","0xa0af64406406e147df066bc7b782d682c84e5aab"),
     "lpt_fROSE":("0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9","0xba3cbebede0c4e17510664d3f3fb6d7305f72022")}
for n,(m,irm) in MKT.items():
    cash=u(call(m,"0x3b1d21a2",block)); bor=u(call(m,"0x47bd3718",block)); res=u(call(m,"0x8f840ddd",block)); rf=u(call(m,"0x173b9904",block))
    d={"cash":cash,"borrows":bor,"reserves":res,"rf":rf}
    args=(cash or 0).to_bytes(32,"big").hex()+(bor or 0).to_bytes(32,"big").hex()+(res or 0).to_bytes(32,"big").hex()
    d["getBorrowRate"]=call(irm,"0x15f24053"+args,block)
    d["getSupplyRate"]=call(irm,"0xb8168816"+args+(rf or 0).to_bytes(32,"big").hex(),block)
    out["market_rates"][n]=d
# accrualBlockNumber + exchangeRateCurrent for the money markets
MK={"classic_fROSE":"0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5","classic_fETH":"0x275b88547185d955f66e5dd1066e040af468fc66",
    "classic_fUSDT":"0x352cc3320debffa3046cf66a4e0a80d528f00285","classic_fUSDC":"0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258",
    "lpt_fROSE":"0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9"}
out["accrual"]={}
for n,m in MK.items():
    d={}
    d["accrualBlockTimestamp"]=call(m,"0xcfa99201",block)
    out["accrual"][n]=d
print(json.dumps(out,indent=1))
