import json,urllib.request
R="https://rpc.monad.xyz"
def call(to,data):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}).encode()
    req=urllib.request.Request(R,body,{"content-type":"application/json","User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req,timeout=20))
    return d.get("result") if d.get("error") is None else "ERR"
def a(x): return x[2:].rjust(64,'0')
AC="0x264123a9B96Cc1193944cC25C188f1bD3dFa670e"; MA="0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5"
USDC="0x754704Bc059F8C67012fEd69BC8A327a5aafb603"
print("USDC symbol", bytes.fromhex(call(USDC,"95d89b41")[2:]).decode('utf8','ignore'))
print("USDC decimals", int(call(USDC,"313ce567"),16))
for nm,ad in [("AC",AC),("MA",MA)]:
    r=call(USDC,"70a08231"+a(ad)); print(nm,"USDC raw",int(r,16))
