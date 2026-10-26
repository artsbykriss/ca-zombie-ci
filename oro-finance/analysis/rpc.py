import json,urllib.request,time,random
ENDPOINTS=[
 "https://solana-rpc.publicnode.com",
 "https://api.mainnet-beta.solana.com",
]
PRIMARY="https://api.mainnet-beta.solana.com"
def _post(url,body,timeout=120):
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return urllib.request.urlopen(req,timeout=timeout)
def call(method,params,retries=6,ep=None):
    eps=[ep] if ep else ENDPOINTS
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        url=eps[i%len(eps)]
        try:
            r=json.load(_post(url,body))
            if "error" in r: raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:
            last=e; time.sleep(min(20,1.5*(2**i))+random.random())
    raise last
def batch(reqs,retries=6,ep=None):
    eps=[ep] if ep else ENDPOINTS
    body=json.dumps(reqs).encode()
    last=None
    for i in range(retries):
        url=eps[i%len(eps)]
        try:
            r=json.load(_post(url,body))
            if isinstance(r,dict) and "error" in r: raise RuntimeError(r["error"])
            return r
        except Exception as e:
            last=e; time.sleep(min(20,1.5*(2**i))+random.random())
    raise last
def multi(addrs,cfg=None):
    out=[]
    for i in range(0,len(addrs),100):
        cfg=cfg or {"encoding":"base64"}
        r=call("getMultipleAccounts",[addrs[i:i+100],cfg])
        out+=r["value"]
    return out
