import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(method, params):
    req=urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=40))
def call(to,data,block="latest"):
    j=rpc("eth_call",[{"to":to,"data":data},block])
    if "error" in j: return "ERR:"+json.dumps(j["error"])[:120]
    return j["result"]
def i(h):
    try: return int(h,16)
    except: return h
from eth_utils import keccak
def sel(s): return keccak(text=s)[:4]
def enc(sig,*args):
    out=sel(sig)
    for a in args: out+=int(a).to_bytes(32,"big")
    return out
def proxyview(h,sig,*args):
    inner=enc(sig,*args)
    data=sel("handlerViewProxy(bytes)")+ (32).to_bytes(32,"big") + len(inner).to_bytes(32,"big") + inner.ljust(((len(inner)+31)//32)*32,b"\0")
    r=call(h,"0x"+data.hex())
    if not isinstance(r,str) or not r.startswith("0x") or len(r)<200: return r
    b=bytes.fromhex(r[2:])
    ok=int.from_bytes(b[0:32],"big"); off=int.from_bytes(b[32:64],"big")
    ln=int.from_bytes(b[off:off+32],"big"); payload=b[off+32:off+32+ln]
    return ok,payload.hex()
def words(payload,n):
    payload=bytes.fromhex(payload)
    return [int.from_bytes(payload[i*32:(i+1)*32],"big") for i in range(n)]

TM="0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5"
blk=i(rpc("eth_blockNumber",[])["result"])
print("BLOCK",blk)
handlers={0:("ether","0x13000C4a215EfE7E414bB329b2F11c39BCF92D78",18),
 1:("usdt","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3",6),
 2:("dai","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3",18),
 3:("link","0x25567603eb61A4A49f27e433652B5B8940D10682",18),
 4:("usdc","0x128647690C7733593aA3Dd149EeBC5e256E79217",6)}
out={}
for hid,(name,h,dec) in handlers.items():
    d={"name":name,"handler":h}
    for sig,n in [("getERC20Addr()",1),("getDepositTotalAmount()",1),("getBorrowTotalAmount()",1),("getLastUpdatedBlock()",1),("getInactiveActionDelta()",1),("getGlobalEXR()",2),("getSIRandBIR()",2),("getAmount(address)",4)]:
        if sig=="getAmount(address)": continue
        r=proxyview(h,sig)
        if isinstance(r,tuple): d[sig]=words(r[1],n)
        else: d[sig]=r
    d["getHandlerAddr"]=call(h,"0x"+enc("getHandlerAddr()").hex())
    d["getHandlerID"]=i(call(h,"0x"+enc("getHandlerID()").hex()))
    out[hid]=d
    print(json.dumps(d))
open("eth_handlers3.json","w").write(json.dumps({"block":blk,"handlers":out},indent=1))
