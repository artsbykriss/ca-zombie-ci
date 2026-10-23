import json,urllib.request,time
ENDPOINTS=["https://base-rpc.publicnode.com","https://mainnet.base.org","https://base.drpc.org"]
def rpc(url,m,p,timeout=25):
    req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","method":m,"params":p,"id":1}).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req,timeout=timeout))
def call_any(m,p,eps=None,timeout=25):
    eps=eps or ENDPOINTS
    last=None
    for url in eps:
        for _ in range(2):
            try: return rpc(url,m,p,timeout)
            except Exception as e:
                last=e; time.sleep(0.5)
    raise last
def pad(a):
    return a.lower().replace("0x","").rjust(64,"0")
