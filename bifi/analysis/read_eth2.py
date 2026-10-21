import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(method, params):
    req=urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=40))
def call(to,data,block="latest"):
    j=rpc("eth_call",[{"to":to,"data":data},block])
    if "error" in j: return "ERR:"+json.dumps(j["error"])[:160]
    return j["result"]
def i(h):
    try: return int(h,16)
    except: return h
from eth_utils import keccak
def sel(s): return keccak(text=s)[:4]
def enc(sig,*args):
    out=sel(sig)
    for a in args: out+=int(a).to_bytes(32,"big")
    return "0x"+out.hex()

TM="0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5"
blk=i(rpc("eth_blockNumber",[])["result"])
print("BLOCK",blk)
handlers={
 0:("ether","0x13000C4a215EfE7E414bB329b2F11c39BCF92D78",18),
 1:("usdt","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3",6),
 2:("dai","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3",18),
 3:("link","0x25567603eb61A4A49f27e433652B5B8940D10682",18),
 4:("usdc","0x128647690C7733593aA3Dd149EeBC5e256E79217",6),
}
def view(h,sig,*args):
    inner=enc(sig,*args)
    r=call(h,enc("handlerViewProxy(bytes)",0x20)+"")  # placeholder
    return r
# encode handlerViewProxy(bytes) manually
def proxyview(h,sig,*args):
    inner=bytes.fromhex(enc(sig,*args)[2:])
    data=sel("handlerViewProxy(bytes)")+ (32).to_bytes(32,"big") + len(inner).to_bytes(32,"big") + inner.ljust(((len(inner)+31)//32)*32,b"\0")
    return call(h,"0x"+data.hex())

out={}
for hid,(name,h,dec) in handlers.items():
    d={"name":name,"handler":h}
    r=proxyview(h,"getERC20Addr()")
    d["getERC20Addr"]=r
    for sig in ["getDepositTotalAmount()","getBorrowTotalAmount()","getLastUpdatedBlock()","getInactiveActionDelta()"]:
        r=proxyview(h,sig)
        d[sig]= i("0x"+r[2:66]) if isinstance(r,str) and r.startswith("0x") and len(r)>=66 else r
    r=proxyview(h,"getGlobalEXR()")
    if isinstance(r,str) and r.startswith("0x") and len(r)>=130:
        d["global_dep_exr"]=i("0x"+r[2:66]); d["global_bor_exr"]=i("0x"+r[66:130])
    else: d["gexr_err"]=r
    r=proxyview(h,"getSIRandBIR()")
    if isinstance(r,str) and r.startswith("0x") and len(r)>=130:
        d["SIR"]=i("0x"+r[2:66]); d["BIR"]=i("0x"+r[66:130])
    else: d["sib_err"]=r
    d["getHandlerAddr"]=call(h,enc("getHandlerAddr()"))
    d["getHandlerID"]=i(call(h,enc("getHandlerID()")))
    d["getSiHandlerAddr"]=call(h,enc("getSiHandlerAddr()"))
    d["getOwner_proxy"]=call(h,enc("getOwner()"))
    out[hid]=d
    print(json.dumps(d))
open("eth_handlers2.json","w").write(json.dumps({"block":blk,"handlers":out},indent=1))
