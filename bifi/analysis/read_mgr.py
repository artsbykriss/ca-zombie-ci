import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
def call(to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    return j.get("result") or ("ERR:"+json.dumps(j.get("error",""))[:100])
from eth_utils import keccak
def sel(s): return "0x"+keccak(text=s)[:4].hex()
TM="0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5"
for f in ["handlerManagerAddr()","slotSetterAddr()","positionStorageAddr()","oracleProxy()" ,"nftAddr()","interestUpdateReward()","getFeeTotal(uint256)"]:
    try:
        print(f, call(TM, sel(f) if "(" not in f or f.endswith(")") else sel(f)))
    except Exception as e: print(f,"EXC",e)
print("handlerManager", call(TM, sel("handlerManagerAddr()")))
print("slotSetter", call(TM, sel("slotSetterAddr()")))
print("positionStorage", call(TM, sel("positionStorageAddr()")))
print("oracleProxy?", call(TM, sel("oracleProxy()")))
print("nftAddr", call(TM, sel("nftAddr()")))
