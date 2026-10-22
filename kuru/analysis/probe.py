import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data,frm=None,val="0x0"):
    p={"to":to,"data":data,"value":val}
    if frm: p["from"]=frm
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[p,"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    try:
        d=json.load(urllib.request.urlopen(req,timeout=20))
        return {"ok":True,"result":d.get("result"),"error":d.get("error")}
    except Exception as e:
        return {"ok":False,"err":str(e)}
FRESH="0x1111111111111111111111111111111111111111"
def u40(x): return f"{x:064x}"
def u256(x): return f"{x:064x}"
def addr(a): return a[2:].rjust(64,'0')
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
MA="0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5"
out={}
# reads
reads={
 "AC.rootAccountIdOf(fresh)": ("cb035e87"+addr(FRESH)),
 "AC.withdrawalAuthority()": "0c4ea33a",
 "AC.authority()": "bf7e214f",
 "AC.withdrawalsFrozen()": "a836af93",
 "AC.protocolPaused()": "425fad58",
 "AC.feeCollector()": "c415b95c",
 "AC.owner()": "8da5cb5b",
 "AC.getBalance(1,0)": "cfeb0a00"+u40(1)+addr("0x0000000000000000000000000000000000000000"),
 "AC.getSpotReservedBalance(1,0)": "24ba2556"+u40(1)+addr("0x0000000000000000000000000000000000000000"),
 "MA.owner()": "8da5cb5b",
}
for k,v in reads.items():
    out[k]=call(AC if k.startswith("AC") else MA, v)
# auth probes (fresh caller)
probes={
 "AC.withdraw(1,0,1e18,fresh) fresh": (AC,"67f3e6c3"+u40(1)+addr("0x0000000000000000000000000000000000000000")+u256(10**18)+addr(FRESH)),
 "AC.withdraw(0,...) fresh": (AC,"67f3e6c3"+u40(0)+addr("0x0000000000000000000000000000000000000000")+u256(10**18)+addr(FRESH)),
 "AC.setAuthority(fresh) fresh": (AC,"7a9e5e4b"+addr(FRESH)),
 "AC.setWithdrawalAuthority(fresh) fresh": (AC,"0cd09628"+addr(FRESH)),
 "AC.createSubaccount(fresh) fresh": (AC,"fd8e8fb2"+addr(FRESH)),
 "AC.loseWager(fresh,1,1,true,1) fresh": (AC,"f4838452"+addr(FRESH)+u256(1)+u256(1)+u256(1)+u256(1)),
 "AC.toggleProtocolState(false) fresh": (AC,"e004f924"+u256(0)),
 "AC.upgradeToAndCall(fresh,0x) fresh": (AC,"4f1ef286"+addr(FRESH)+u256(64)+u256(0)),
 "MA.withdraw(1e18,0) fresh": (MA,"00f714ce"+u256(10**18)+addr("0x0000000000000000000000000000000000000000")),
 "MA.batchWithdrawMaxTokens([0]) fresh": (MA,"0f163fa8"+u256(32)+u256(1)+addr("0x0000000000000000000000000000000000000000")),
 "MA.toggleProtocolState(false) fresh": (MA,"e004f924"+u256(0)),
}
for k,(to,data) in probes.items():
    out[k]=call(to,data,frm=FRESH)
# fulfillApprovedWithdrawal
# tuple: (account,token,recipient,amount,nonce,deadline,authorityEpoch) then bytes offset
acc=addr(FRESH); tok=addr("0x0000000000000000000000000000000000000000"); rec=addr(FRESH)
tup = acc+tok+rec+u256(10**18)+u256(0)+u256(2**255)+u256(0)
# head: tuple is static (7 words) => offset to tuple? For a struct + bytes, struct is inline in head if static.
# signature: ((addr,addr,addr,uint,uint,uint,uint64),bytes): head = 7 words tuple + 1 word offset(bytes)
data = "0a3c83c3" + tup + u256(7*32) + u256(0)
out["AC.fulfillApprovedWithdrawal(fresh,...,sig=0x) fresh"]=call(AC,data,frm=FRESH)
json.dump(out,open("probe_results.json","w"),indent=1)
for k,v in out.items():
    r=v.get("result"); e=v.get("error")
    print(f"{k:52s} -> {('OK '+str(r)[:80]) if e is None else ('ERR '+json.dumps(e)[:140])}")
