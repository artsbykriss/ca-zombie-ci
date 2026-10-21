import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
def call(to,data,frm="0x000000000000000000000000000000000000dEaD"):
    j=rpc("eth_call",[{"from":frm,"to":to,"data":data},"latest"])
    if "error" in j:
        e=j["error"]
        return "REVERT: "+e.get("message","")+" | "+str(e.get("data",""))[:80]
    return j["result"]
from eth_utils import keccak
def sel(s): return "0x"+keccak(text=s)[:4].hex()
def enc(sig,*args):
    d=sel(sig)
    for a in args: d+=int(a).to_bytes(32,"big").hex()
    return d
H="0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3"
for sig,args in [("deposit(uint256,bool)",(0,False)),("deposit(uint256,bool)",(1,False)),("borrow(uint256,bool)",(0,False)),("withdraw(uint256,bool)",(0,False)),("repay(uint256,bool)",(0,False))]:
    print(sig,args,"->",call(H,enc(sig,*args))[:220])
print("TM.applyInterestHandlers ->", call("0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",enc("applyInterestHandlers(address,uint256,bool)",0x000000000000000000000000000000000000dEaD,1,False))[:220])
print("TM.interestUpdateReward ->", call("0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",sel("interestUpdateReward()"))[:220])
print("TM.rewardClaimAll ->", call("0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",enc("rewardClaimAll(address)",0x000000000000000000000000000000000000dEaD))[:220])
