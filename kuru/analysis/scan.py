import json,urllib.request
R="https://rpc.monad.xyz"
def batch(calls):
    body=json.dumps([{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[c,"latest"]} for i,c in enumerate(calls)]).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=30))
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"
def u(x): return f"{x:064x}"
def a(x): return x[2:].rjust(64,'0')
NATIVE="0x0000000000000000000000000000000000000000"
# scan getBalance(id, native) for ids 0..260
calls=[]
for i in range(0,261):
    calls.append({"to":AC,"data":"cfeb0a00"+u(i)+a(NATIVE)})
res={}
for k in range(0,len(calls),50):
    d=batch(calls[k:k+50])
    for item in d:
        idx=item["id"]; r=item.get("result")
        if r and int(r,16)>0: res[k+idx]=int(r,16)/1e18
print("accounts with native MON balance:",json.dumps(res,indent=0))
# supportedSpotTokens
d=batch([{"to":AC,"data":"4d35a528"}])[0]
print("supportedSpotTokens raw:",d.get("result"))
