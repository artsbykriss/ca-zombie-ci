import json, urllib.request
RPC="https://bsc-rpc.publicnode.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
def call(to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    if "error" in j: return None
    return j["result"]
def ii(h):
    try: return int(h,16)
    except: return None
from eth_utils import keccak
def sel(s): return keccak(text=s)[:4]
def enc(sig,*args):
    out=sel(sig)
    for a in args: out+=int(a).to_bytes(32,"big")
    return out
def proxyview(h,sig,*args):
    inner=enc(sig,*args)
    data=sel("handlerViewProxy(bytes)")+(32).to_bytes(32,"big")+len(inner).to_bytes(32,"big")+inner.ljust(((len(inner)+31)//32)*32,b"\0")
    r=call(h,"0x"+data.hex())
    if not isinstance(r,str) or not r.startswith("0x") or len(r)<200: return r
    b=bytes.fromhex(r[2:]); ok=int.from_bytes(b[0:32],"big"); off=int.from_bytes(b[32:64],"big")
    ln=int.from_bytes(b[off:off+32],"big"); return ok,b[off+32:off+32+ln]
def w(r,n,div=1):
    if isinstance(r,tuple):
        p=r[1]; return [int.from_bytes(p[i*32:(i+1)*32],"big")/div for i in range(n)]
    return r
TM="0x8010f9e14c8286b9312e624370fddc07fee2fc75"
blk=ii(rpc("eth_blockNumber",[])["result"]); print("BLOCK",blk)
HS={0:("bnb","0x170b6AA872166eC2F8515c2B855C34B6C7563c18","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",18),
1:("ether2","0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB","0x2170Ed0880ac9A755fd29B2688956BD959F933F8",18),
2:("usdt","0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8","0x55d398326f99059fF775485246999027B3197955",18),
3:("dai","0xB67C5433d234d656002f12664d15ab4b40666D9B","0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3",18),
4:("usdc","0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",18),
5:("btcb","0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B","0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",18)}
out={}
for hid,(name,h,tok,dec) in HS.items():
    d={"name":name,"handler":h,"token":tok}
    d["underlying"]=w(proxyview(h,"getERC20Addr()"),1) if False else None
    r=proxyview(h,"getERC20Addr()"); d["erc20"]=w(r,1)
    d["deposit_total_unified"]=w(proxyview(h,"getDepositTotalAmount()"),1)[0] if isinstance(proxyview(h,"getDepositTotalAmount()"),tuple) else None
    d["borrow_total_unified"]=w(proxyview(h,"getBorrowTotalAmount()"),1)[0] if isinstance(proxyview(h,"getBorrowTotalAmount()"),tuple) else None
    d["last_updated"]=w(proxyview(h,"getLastUpdatedBlock()"),1)
    d["inactive_delta"]=w(proxyview(h,"getInactiveActionDelta()"),1)
    d["sir_bir"]=w(proxyview(h,"getSIRandBIR()"),2)
    d["handler_impl"]=call(h,"0x"+enc("getHandlerAddr()").hex())
    d["balance"]=ii(call(tok,"0x70a08231"+h[2:].rjust(64,"0")))
    d["price"]=ii(call(TM,"0x"+enc("getTokenHandlerPrice(uint256)",hid).hex()))
    out[hid]=d; print(json.dumps(d))
open("bsc_handlers.json","w").write(json.dumps({"block":blk,"handlers":out},indent=1))
