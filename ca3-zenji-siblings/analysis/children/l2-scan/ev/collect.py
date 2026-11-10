#!/usr/bin/env python3
"""Collect the exact reads cited in REPORT.md, with block numbers. Read-only."""
import json,os,urllib.request

RPCS={"op":"https://mainnet.optimism.io","base":"https://mainnet.base.org","arb":"https://arb1.arbitrum.io/rpc"}
def rpc(url,method,params):
    req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
        headers={"content-type":"application/json","user-agent":"research/1.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
def call(url,to,data,frm="0x1111111111111111111111111111111111111111"):
    r=rpc(url,"eth_call",[{"to":to,"data":data,"from":frm},"latest"])
    return {"ok":"result" in r,"result":r.get("result"),"error":r.get("error")}
def sel(sig):
    from eth_hash.auto import keccak
    return "0x"+keccak(sig.encode())[:4].hex()

out={"generated":"2026-11-10","blocks":{},"reads":{}}
for k,u in RPCS.items():
    out["blocks"][k]=int(rpc(u,"eth_blockNumber",[])["result"],16)

VPM="0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055"
EXTRA={}
for k,u in [("op",RPCS["op"]),("base",RPCS["base"])]:
    e={}
    for name,sig in [("permissionLessLiquidationEnabled","permissionLessLiquidationEnabled()"),
                     ("permissionLessCompoundEnabled","permissionLessCompoundEnabled()"),
                     ("permissionLessRangeStopEnabled","permissionLessRangeStopEnabled()"),
                     ("owner","owner()"),("paused","paused()")]:
        e[name]=call(u,VPM,sel(sig))
    for name,sig in [("liquidatorWhitelist","liquidatorWhitelist(address)"),
                     ("compounderWhitelist","compounderWhitelist(address)"),
                     ("rangeStopCallerWhitelist","rangeStopCallerWhitelist(address)")]:
        e[name]=call(u,VPM,sel(sig)+"0"*24+"1111111111111111111111111111111111111111")
    EXTRA[k]=e
out["reads"]["extra_vpm"]=EXTRA

# Contango
CONTANGO="0x6Cae28b3D09D8f8Fc74ccD496AC986FC84C0C24E"
c={}
c["paused"]=call(RPCS["arb"],CONTANGO,sel("paused()"))
c["positionNFT"]=call(RPCS["arb"],CONTANGO,sel("positionNFT()"))
c["impl_slot"]=rpc(RPCS["arb"],"eth_getStorageAt",[CONTANGO,"0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc","latest"])["result"]
out["reads"]["contango_arb"]=c

# Beefy control
BEEFY_VAULT="0x005b8Aa7aB7bB665902d4E9509B9D4e9fB87BC2b"
BEEFY_STRAT="0xDc975A6fBC3BA63592C9d296a8cfeD92dEBE65d0"
b={}
b["strategy"]=call(RPCS["base"],BEEFY_VAULT,sel("strategy()"))
b["want"]=call(RPCS["base"],BEEFY_STRAT,sel("want()"))
b["balanceOfPool"]=call(RPCS["base"],BEEFY_STRAT,sel("balanceOfPool()"))
b["harvest_from_random"]=call(RPCS["base"],BEEFY_STRAT,sel("harvest()"))
out["reads"]["beefy_base"]=b

# Morpho MetaMorpho (Extrafi XLend) Base
m={}
for v,n in [("0x5A32099837D89E3a794a44fb131CBbAD41f87a8C","weth"),("0x23479229e52Ab6aaD312D0B03DF9F33B46753B5e","usdc")]:
    d={}
    for name,sig in [("name","name()"),("totalAssets","totalAssets()"),("curator","curator()"),("owner","owner()")]:
        d[name]=call(RPCS["base"],v,sel(sig))
    d["isAllocator_random"]=call(RPCS["base"],v,sel("isAllocator(address)")+"0"*24+"1111111111111111111111111111111111111111")
    m[n]={"address":v,**d}
out["reads"]["morpho_metamorpho_base"]=m

# YieldFi
y={}
for v,n in [("0x4772D2e014F9fC3a820C444e3313968e9a5C8121","yUSD"),("0xF4F447E6AFa04c9D11Ef0e2fC0d7f19C24Ee55de","vyUSD")]:
    d={"address":v}
    for name,sig in [("name","name()"),("totalAssets","totalAssets()")]:
        d[name]=call(RPCS["base"],v,sel(sig))
    for name,sig in [("harvest","harvest()"),("rebalance","rebalance()"),("keeper","keeper()")]:
        d[name]=call(RPCS["base"],v,sel(sig))
    y[n]=d
out["reads"]["yieldfi_base"]=y

json.dump(out,open("evidence/l2_reads.json","w"),indent=1)
print(json.dumps(out["blocks"]))
for k,v in out["reads"]["extra_vpm"]["op"].items(): print("OP extra",k,v.get("result"), bool(v.get("error")))
for k,v in out["reads"]["extra_vpm"]["base"].items(): print("BASE extra",k,v.get("result"), bool(v.get("error")))
print("beefy harvest ok:", out["reads"]["beefy_base"]["harvest_from_random"])
