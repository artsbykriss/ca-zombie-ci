import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data,frm=None):
    p={"to":to,"data":data}
    if frm: p["from"]=frm
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[p,"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req,timeout=20))
    return d.get("result") if d.get("error") is None else "ERR "+json.dumps(d.get("error"))[:120]
FRESH="0x1111111111111111111111111111111111111111"
VICTIM="0x8b736dce2071783fd9db0a423dad17cc8ed5788b"  # owner multisig
def u(x): return f"{x:064x}"
def a(x): return x[2:].rjust(64,'0')
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
tests={
 "createSubaccount(victimRootOwner=multisig) fresh": "fd8e8fb2"+a(VICTIM)+u(0),
 "createSubaccount(fresh) fresh": "fd8e8fb2"+a(FRESH)+u(0),
 "f4838452(u256 0) fresh": "f4838452"+u(0),
 "f4838452(u256 1) fresh": "f4838452"+u(1),
 "ensureRootAccount(fresh) fresh": None,
 "deposit(fresh,0,1) fresh [no value]": "8340f549"+a(FRESH)+a("0x0000000000000000000000000000000000000000")+u(10**18),
 "transferBetweenAccounts(fresh,1,0,1) fresh": None,
 "rootAccountIdOf(fresh)": "cb035e87"+a(FRESH),
 "getAccountOwner(137)": None,
}
for k,v in tests.items():
    if v is None: 
        print(f"{k:50s} -> (skipped, unknown selector)"); continue
    print(f"{k:50s} -> {call(AC,v,frm=FRESH)}")
# also compute selectors for some
