import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data,frm=None):
    p={"to":to,"data":data}
    if frm: p["from"]=frm
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[p,"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req,timeout=20))
    return d.get("result") if d.get("error") is None else "ERR "+json.dumps(d.get("error"))[:120]
def u(x): return f"{x:064x}"
def a(x): return x[2:].rjust(64,'0')
FRESH="0x1111111111111111111111111111111111111111"
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
MA="0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5"
NATIVE="0x0000000000000000000000000000000000000000"
print("getAccountOwner(26)      ", call(AC,"e23d95bb"+u(26)))
print("getAccountRootId(26)     ", call(AC,"d7df6e65"+u(26)) if False else "(sel?)")
print("withdraw(26,native,1e18,fresh) fresh ->", call(AC,"67f3e6c3"+u(26)+a(NATIVE)+u(10**18)+a(FRESH),frm=FRESH))
print("withdraw(26,native,1e18,fresh) from owner? ->", call(AC,"67f3e6c3"+u(26)+a(NATIVE)+u(10**18)+a(FRESH)))
print("withdraw(94,native,1e18,fresh) fresh ->", call(AC,"67f3e6c3"+u(94)+a(NATIVE)+u(10**18)+a(FRESH),frm=FRESH))
print("getBalance(26,native)    ", call(AC,"cfeb0a00"+u(26)+a(NATIVE)))
print("getSpotReservedBalance(26,native)", call(AC,"24ba2556"+u(26)+a(NATIVE)))
# ERC20 balances of AC
for nm,tok in [("WMON","0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A"),("USDC","0x754704Bc059F8C67012fEd69BC8A327a5aafb603"),("AUSD","0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a")]:
    r=call(tok,"70a08231"+a(AC))
    try: v=int(r,16)
    except: v=r
    print(f"AC ERC20 {nm} balance:", (v/1e6 if nm=="USDC" else v/1e18) if isinstance(v,int) else v)
# MA ERC20
for nm,tok in [("WMON","0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A"),("USDC","0x754704Bc059F8C67012fEd69BC8A327a5aafb603")]:
    r=call(tok,"70a08231"+a(MA))
    try: v=int(r,16)/1e6
    except: v=r
    print(f"MA ERC20 {nm} balance:", v)
