import json,urllib.request,sys
RPCS={
 'monad':'https://rpc.monad.xyz',
 'pharos':'https://rpc.pharos.xyz',
 'robinhood':'https://rpc.mainnet.chain.robinhood.com',
 'sophon':'https://rpc.sophon.xyz',
}
def rpc(chain,method,params):
    url=RPCS[chain]
    req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={'content-type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req,timeout=60))['result']
def batch(chain,calls):
    url=RPCS[chain]
    payload=[{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]
    req=urllib.request.Request(url,data=json.dumps(payload).encode(),headers={'content-type':'application/json','User-Agent':'Mozilla/5.0'})
    out=json.load(urllib.request.urlopen(req,timeout=60))
    return {i:o.get('result') for o in sorted(out,key=lambda x:x['id']) for i in [o['id']]}
def bn(chain): return int(rpc(chain,'eth_blockNumber',[]),16)
def code(chain,addr): return rpc(chain,'eth_getCode',[addr,'latest'])
def bal(chain,addr): return int(rpc(chain,'eth_getBalance',[addr,'latest']),16)
def call(chain,to,data): return rpc(chain,'eth_call',[{'to':to,'data':data},'latest'])
def slot(chain,addr,s): return rpc(chain,'eth_getStorageAt',[addr,hex(s) if isinstance(s,int) else s,'latest'])
