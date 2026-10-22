import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data,frm=None):
    p={"to":to,"data":data}
    if frm: p["from"]=frm
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[p,"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req,timeout=20))
    return d.get("result") if d.get("error") is None else "ERR "+json.dumps(d.get("error"))[:90]
def u(x): return f"{x:064x}"
def a(x): return x[2:].rjust(64,'0')
FRESH="0x1111111111111111111111111111111111111111"
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
N="0x0000000000000000000000000000000000000000"
probes={
 "transferBetweenAccounts(26,94,native,1e18) fresh":"77b8e8e2"+u(26)+u(94)+a(N)+u(10**18),
 "authorizeAccountSigner(26,fresh,0xffffffff,2^64-1) fresh":"72732a03"+u(26)+a(FRESH)+u(0xffffffff)+u(2**64-1),
 "approveBuilder(26,fresh,0,2^64-1) fresh":"fa599b24"+u(26)+a(FRESH)+u(0)+u(2**64-1),
 "setTokenWithdrawalsFrozen(native,true) fresh":None,
 "rootAccountIdOf(feeCollector)":"cb035e87"+a("0x62ee1b8d1efdf8f73c78db87b888406b194e266a"),
 "rootAccountIdOf(owner multisig)":"cb035e87"+a("0x8b736dce2071783fd9db0a423dad17cc8ed5788b"),
}
for k,v in probes.items():
    if v is None: print(f"{k:60s} -> skipped"); continue
    print(f"{k:60s} -> {call(AC,v,frm=FRESH)}")
