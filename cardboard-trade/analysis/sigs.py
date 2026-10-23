#!/usr/bin/env python3
import json,urllib.request,sys,base64
RPC=sys.argv[1] if len(sys.argv)>1 else "https://api.mainnet-beta.solana.com"
def rpc(method,params,url=RPC):
    req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=90))
EX="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
OR="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
for name,prog in [("EXCHANGE",EX),("ORACLE",OR)]:
    r=rpc("getSignaturesForAddress",[prog,{"limit":15}])
    sigs=[x["signature"] for x in r.get("result",[])]
    print(f"== {name} {prog} recent sigs: {len(sigs)}")
    for s in sigs[:15]:
        print("  ",s)
