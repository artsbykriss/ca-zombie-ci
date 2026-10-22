import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data,frm=None):
    p={"to":to,"data":data}
    if frm: p["from"]=frm
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[p,"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req,timeout=20))
    return d.get("result") if d.get("error") is None else "ERR "+json.dumps(d.get("error"))[:140]
def u(x): return f"{x:064x}"
def a(x): return x[2:].rjust(64,'0')
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
owner26="0x9daba38229f593d90f99062bb18ed41f57b16ce8"
NATIVE="0x0000000000000000000000000000000000000000"
# call withdraw AS the real owner (eth_call, read-only; no tx) - should succeed or fail on limiter
print("withdraw(26,native,1,fresh) AS owner26 ->", call(AC,"67f3e6c3"+u(26)+a(NATIVE)+u(1)+a("0x1111111111111111111111111111111111111111"),frm=owner26))
# KuruForwarder verifyMarginAccountRequest with dummy
KF="0x974E61BBa9C4704E8Bcc1923fdC3527B41323FAA"
print("KF.getNonce(attacker)", call(KF,"2d0335ab"+a("0x1111111111111111111111111111111111111111")))
