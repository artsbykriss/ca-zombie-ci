#!/usr/bin/env python3
import json,urllib.request,time,sys
RPC="https://api.mainnet-beta.solana.com"
def rpc(method,params,tries=6):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(tries):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            r=json.load(urllib.request.urlopen(req,timeout=120))
            if "error" in r and r["error"].get("code")==429:
                time.sleep(1.5*(i+1)); continue
            return r
        except Exception as e:
            last=e; time.sleep(1.5*(i+1))
    raise last
