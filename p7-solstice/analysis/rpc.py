import json,urllib.request,os,time
URL=os.environ.get("SOLANA_RPC","https://api.mainnet-beta.solana.com")
def rpc(method,params,url=None,tries=6):
    u=url or URL
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(tries):
        try:
            req=urllib.request.Request(u,data=body,headers={"Content-Type":"application/json","User-Agent":"research"})
            return json.load(urllib.request.urlopen(req,timeout=60))
        except Exception as e:
            last=e; time.sleep(1.5*(i+1))
    raise last
