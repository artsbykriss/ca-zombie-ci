import json,sys,urllib.request
RPC={"soneium":"https://rpc.soneium.org","conflux":"https://evm.confluxrpc.com","fuse":"https://rpc.fuse.io","monad":"https://rpc.monad.xyz"}
def call(chain,to,data,block="latest"):
    req={"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},block]}
    r=urllib.request.Request(RPC[chain],data=json.dumps(req).encode(),headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(r,timeout=30) as f: return json.load(f)
def code(chain,addr,block="latest"):
    req={"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[addr,block]}
    r=urllib.request.Request(RPC[chain],data=json.dumps(req).encode(),headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(r,timeout=30) as f: return json.load(f)
def rpc(chain,method,params):
    req={"jsonrpc":"2.0","id":1,"method":method,"params":params}
    r=urllib.request.Request(RPC[chain],data=json.dumps(req).encode(),headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(r,timeout=30) as f: return json.load(f)
if __name__=="__main__":
    ch,to,data=sys.argv[1],sys.argv[2],sys.argv[3]
    print(json.dumps(call(ch,to,data),indent=1))
