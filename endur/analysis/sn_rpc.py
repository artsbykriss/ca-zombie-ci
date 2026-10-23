import json,urllib.request,sys,time
from Crypto.Hash import keccak
RPC="https://starknet-rpc.publicnode.com"
def k(name):
    h=keccak.new(digest_bits=256); h.update(name.encode()); return int.from_bytes(h.digest(),'big') & ((1<<250)-1)
def sel(name): return hex(k(name))
def bid(b):
    if isinstance(b,int): return {"block_number":b}
    return b
def call(method,params,tries=4):
    idx={"starknet_call":1,"starknet_getClassHashAt":0,"starknet_getClassAt":0,"starknet_getStorageAt":2,"starknet_getNonce":1}.get(method)
    if idx is not None and idx < len(params): params=list(params); params[idx]=bid(params[idx])
    for i in range(tries):
        try:
            body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"curl/8.5.0","Accept":"*/*"})
            r=json.load(urllib.request.urlopen(req,timeout=45))
            if "error" in r: return r["error"]
            return r.get("result")
        except Exception as e:
            if i==tries-1: return {"__exc":str(e)}
            time.sleep(1.5)
def felt(x):
    if isinstance(x,str) and x.startswith("0x"): return int(x,16)
    return int(x)
if __name__=="__main__":
    print(sel(sys.argv[1]))
