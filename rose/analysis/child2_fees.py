#!/usr/bin/env python3
"""child2_fees.py - PaymentSplitter 0xf042... probe + admin-fee excess for all pools.
Saves child2_fees.json (splitter + excess + unit price data)."""
import json, time
import requests
S=requests.Session()
RPC="https://mainnet.aurora.dev"

def rpc(method,params,tries=6,timeout=120):
    last=None
    for i in range(tries):
        try:
            r=S.post(RPC,json={"jsonrpc":"2.0","id":1,"method":method,"params":params},timeout=timeout)
            if r.status_code==429: time.sleep(2+2*i); continue
            j=r.json()
            if "error" in j: return {"ERR":j["error"]}
            return j.get("result")
        except Exception as ex: last=repr(ex)
        time.sleep(1+1.5*i)
    return {"ERR":last}

def batch(calls,chunk=40):
    out=[]
    for i in range(0,len(calls),chunk):
        part=calls[i:i+chunk]
        payload=[{"jsonrpc":"2.0","id":k,"method":m,"params":p} for k,(m,p) in enumerate(part)]
        for a in range(6):
            try:
                r=S.post(RPC,json=payload,timeout=180)
                if r.status_code==429: time.sleep(2+2*a); continue
                by={x["id"]:x for x in r.json()}
                for k in range(len(part)):
                    x=by.get(k,{}); out.append(x.get("result",{"ERR":x.get("error")}))
                break
            except Exception:
                if a==5: raise
                time.sleep(1+a)
    return out

def call(to,data): return rpc("eth_call",[{"to":to,"data":data},"latest"])
def pad(a): return a[2:].lower().rjust(64,"0")
def u(r): return int(r,16) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else None

SPLITTER="0xf042f2dabba35f83eb126116f7ff8dadfc631e97"
POOLS={
 "3pool":{"addr":"0xc90dB0d8713414d78523436dC347419164544A3f","lp":"0xff79d5bff48e1c01b722560d6ffdfce9fc883587","n":3,
          "coins":["0xe3520349f477a5f6eb06107066048508498a291b","0xb12bfca5a55806aaf64e99521918a4bf0fc40802","0x4988a896b1227218e4a686fde5eabdcabd91571f"],
          "dec":[18,6,6],"price":[1.0,1.0,1.0]},
 "metaUST":{"addr":"0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8","lp":"0x94a7644e4d9ca0e685226254f88eadc957d3c263","n":2,
          "coins":["0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc","0xff79d5bff48e1c01b722560d6ffdfce9fc883587"],
          "dec":[18,18],"price":[0.0363,None]},
 "metaFRAX":{"addr":"0xa34315F1ef49392387Dd143f4578083A9Bd33E94","lp":"0x4463a118a2fb34640ff8ef7fe1b3abacd4ac9fb7","n":2,
          "coins":["0xda2585430fef327ad8ee44af8f1f989a2a91a3d2","0xff79d5bff48e1c01b722560d6ffdfce9fc883587"],
          "dec":[18,18],"price":[0.9904,None]},
 "metaMAI":{"addr":"0x65a761136815B45A9d78d9781d22d47247B49D23","lp":"0xa7ae42224bf48ecefc5f838c230ee339e5fd8e62","n":2,
          "coins":["0xdfa46478f9e5ea86d57387849598dbfb2e964b02","0xff79d5bff48e1c01b722560d6ffdfce9fc883587"],
          "dec":[18,18],"price":[0.9962,None]},
 "RUSDpool":{"addr":"0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34","lp":"0x56f87a0cb4713eb513baf57d5e81750433f5fcb9","n":2,
          "coins":["0x19cc40283b057d6608c22f1d20f17e16c245642e","0xff79d5bff48e1c01b722560d6ffdfce9fc883587"],
          "dec":[18,18],"price":[0.31,None]},
}
PRICES={"DAI":1.0,"USDC":1.0,"USDT":1.0,"WETH":2507,"WBTC":83108,"WNEAR":5.02,"FRAX":0.9904,"MAI":0.9962,
        "UST_aurora":0.0363,"UST_global":0.0053,"RUSD":0.31,"ROSE":0.000021}

out={"block":int(rpc("eth_blockNumber",[]),16),"prices":PRICES}

# ---- PaymentSplitter ----
sp={"addr":SPLITTER}
sp["totalShares"]=u(call(SPLITTER,"0x3a98ef39"))
sp["totalReleased_0xe33b7de3"]=u(call(SPLITTER,"0xe33b7de3"))
sp["totalReleased_0xd79779b2"]=u(call(SPLITTER,"0xd79779b2"))
sp["owner"]=u(call(SPLITTER,"0x8da5cb5b"))
if sp["owner"] is None:
    r=call(SPLITTER,"0x8da5cb5b"); sp["owner_raw"]=r
sp["ethBalance"]=u(rpc("eth_getBalance",[SPLITTER,"latest"]))
payees=[]
for i in range(20):
    r=call(SPLITTER,"0x8b83209b"+hex(i)[2:].rjust(64,"0"))
    v=u(r)
    if v is None:
        payees.append({"i":i,"payee":None,"err":r if isinstance(r,dict) else r}); break
    payees.append({"i":i,"payee":"0x"+hex(v)[2:].rjust(40,"0")})
sp["payees_raw"]=payees
for p in payees:
    if p["payee"]:
        p["shares"]=u(call(SPLITTER,"0xce7c2ac2"+pad(p["payee"])))
        p["released"]=u(call(SPLITTER,"0x9852595c"+pad(p["payee"])))
        p["ethBalance"]=u(rpc("eth_getBalance",[p["payee"],"latest"]))
# token balances of splitter and payees
TOKENS_ALL={"USDC":"0xb12bfca5a55806aaf64e99521918a4bf0fc40802","USDT":"0x4988a896b1227218e4a686fde5eabdcabd91571f",
 "DAI":"0xe3520349f477a5f6eb06107066048508498a291b","WETH":"0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb",
 "WBTC":"0xf4eb217ba2454613b15dbdea6e5f22276410e89e","WNEAR":"0xc42c30ac6cc15fac9bd938618bcaa1a1fae8501d",
 "RUSD":"0x19cc40283b057d6608c22f1d20f17e16c245642e","ROSE":"0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970",
 "UST":"0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc","FRAX":"0xda2585430fef327ad8ee44af8f1f989a2a91a3d2",
 "MAI":"0xdfa46478f9e5ea86d57387849598dbfb2e964b02","LP3pool":"0xff79d5bff48e1c01b722560d6ffdfce9fc883587"}
calls=[];
for a in [SPLITTER]+[p["payee"] for p in payees if p["payee"]]:
    for sym,t in TOKENS_ALL.items():
        calls.append(("eth_call",[{"to":t,"data":"0x70a08231"+pad(a)},"latest"]))
res=batch(calls)
k=0
addrs=[SPLITTER]+[p["payee"] for p in payees if p["payee"]]
tok_bal={a:{} for a in addrs}
for a in addrs:
    for sym in TOKENS_ALL:
        tok_bal[a][sym]=u(res[k]); k+=1
sp["tokenBalances"]=tok_bal
out["splitter"]=sp
print("splitter totalShares",sp["totalShares"],"totalReleased",sp["totalReleased_0xe33b7de3"],"payees",[p.get("payee") for p in payees if p.get("payee")])

# ---- pool excess ----
pools={}
for name,p in POOLS.items():
    addr=p["addr"]; n=p["n"]; d={}
    calls=[]
    for i in range(n):
        calls.append(("eth_call",[{"to":addr,"data":"0x4903b0d1"+hex(i)[2:].rjust(64,"0")},"latest"]))   # balances(i)
        calls.append(("eth_call",[{"to":p["coins"][i],"data":"0x70a08231"+pad(addr)},"latest"]))        # coin.balanceOf(pool)
    calls.append(("eth_call",[{"to":p["lp"],"data":"0x18160ddd"},"latest"]))                            # lp totalSupply
    calls.append(("eth_call",[{"to":addr,"data":"0xddca3f43"},"latest"]))                               # fee()
    res=batch(calls)
    d["lpTotalSupply"]=u(res[-2]); d["fee"]=u(res[-1]); d["coins"]=[]
    for i in range(n):
        accounted=u(res[2*i]); actual=u(res[2*i+1]);
        sym = {0:"DAI/USDC/USDT",1:"",2:""}.get(0,"")
        d["coins"].append({"i":i,"coin":p["coins"][i],"dec":p["dec"][i],"accounted":str(accounted) if accounted is not None else None,
                           "actual":str(actual) if actual is not None else None,
                           "excess":str(actual-accounted) if (actual is not None and accounted is not None) else None})
    pools[name]=d
    print(name,"excess per coin:",[c["excess"] for c in d["coins"]],"fee",d["fee"],"lpSupply",d["lpTotalSupply"])
out["pools"]=pools

# ---- stROSE vault backing ----
STROSE="0xe23d2289fbca7de725dc21a13fc096787a85e16f"; ROSE="0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970"
out["stRose"]={"roseBalance":str(u(call(ROSE,"0x70a08231"+pad(STROSE)))),
               "totalSupply":str(u(call(STROSE,"0x18160ddd"))),
               "decimals":u(call(STROSE,"0x313ce567"))}
print("stROSE",out["stRose"])
json.dump(out,open("/home/heisenberg/CA/rose/analysis/child2_fees.json","w"),indent=1)
print("saved child2_fees.json")
