#!/usr/bin/env python3
"""Minimal read-only JSON-RPC helper. RPC URL comes from env var named on argv[1]."""
import json,os,sys,urllib.request

def rpc(url, calls):
    if not calls: return []
    out=[]
    for i in range(0,len(calls),20):
        chunk=calls[i:i+20]
        body=json.dumps([{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for j,(t,d) in enumerate(chunk)]).encode()
        req=urllib.request.Request(url,data=body,headers={"content-type":"application/json","user-agent":"research/1.0"})
        r=json.load(urllib.request.urlopen(req,timeout=40))
        r=sorted(r,key=lambda x:x['id'])
        out+= [(x.get('result'),x.get('error')) for x in r]
    return out

if __name__=="__main__":
    var=sys.argv[1]; url=os.environ[var]
    calls=json.load(sys.stdin)  # [[to,data],...]
    res=rpc(url,calls)
    print(json.dumps(res,indent=1))
