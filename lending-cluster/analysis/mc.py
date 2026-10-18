import json,requests
from eth_abi import encode,decode
RPC={"soneium":"https://rpc.soneium.org","conflux":"https://evm.confluxrpc.com","fuse":"https://rpc.fuse.io","monad":"https://rpc.monad.xyz"}
MC="0xcA11bde05977b3631167028862bE2a173976CA11"
s=requests.Session(); s.headers.update({"Content-Type":"application/json","User-Agent":"research"})
def rpcc(chain,method,params,timeout=30):
    r=s.post(RPC[chain],json={"jsonrpc":"2.0","id":1,"method":method,"params":params},timeout=timeout).json()
    if "error" in r: raise Exception(r["error"])
    return r["result"]
def aggregate(chain,calls,block="latest"):
    # calls: list of (target, calldata_hex)
    payload=[(t,True,bytes.fromhex(d[2:])) for t,d in calls]
    data="0x82ad56cb"+encode(["(address,bool,bytes)[]"],[payload]).hex()
    res=rpcc(chain,"eth_call",[{"to":MC,"data":data},block])
    out=decode(["(bool,bytes)[]"],bytes.fromhex(res[2:]))[0]
    return [(ok,("0x"+b.hex())) for ok,b in out]
