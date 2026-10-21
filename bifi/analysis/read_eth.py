import json, urllib.request
RPC="https://ethereum-rpc.publicnode.com"
def rpc(method, params):
    req=urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=40))
def call(to,data,block="latest"):
    j=rpc("eth_call",[{"to":to,"data":data},block])
    if "error" in j: return "ERR:"+str(j["error"])
    return j["result"]
def i(h):
    try: return int(h,16)
    except: return h
from eth_utils import keccak
def sel(s): return "0x"+keccak(text=s)[:4].hex()

TM="0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5"
blk=i(rpc("eth_blockNumber",[])["result"])
print("BLOCK",blk)
handlers={
 0:("ether","0x13000C4a215EfE7E414bB329b2F11c39BCF92D78","0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",18),
 1:("usdt","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3","0xdAC17F958D2ee523a2206206994597C13D831ec7",6),
 2:("dai","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3","0x6B175474E89094C44Da98b954EedeAC495271d0F",18),
 3:("link","0x25567603eb61A4A49f27e433652B5B8940D10682","0x514910771AF9Ca656af840dff83E8264EcF986CA",18),
 4:("usdc","0x128647690C7733593aA3Dd149EeEBC5e256E79217" if False else "0x128647690C7733593aA3Dd149EeBC5e256E79217","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",6),
}
out={}
for hid,(name,h,erc,dec) in handlers.items():
    d={}
    d["name"]=name; d["handler"]=h; d["erc20_read"]=call(h,sel("getERC20Addr()"))
    d["deposit_total"]=i(call(h,sel("getDepositTotalAmount()")))
    d["borrow_total"]=i(call(h,sel("getBorrowTotalAmount()")))
    d["last_updated_block"]=i(call(h,sel("getLastUpdatedBlock()")))
    d["inactive_delta"]=i(call(h,sel("getInactiveActionDelta()")))
    gexr=call(h,sel("getGlobalEXR()")); 
    if isinstance(gexr,str) and gexr.startswith("0x") and len(gexr)>=130:
        d["global_dep_exr"]=i("0x"+gexr[2:66]); d["global_bor_exr"]=i("0x"+gexr[66:130])
    sib=call(h,sel("getSIRandBIR()"))
    if isinstance(sib,str) and sib.startswith("0x") and len(sib)>=130:
        d["SIR"]=i("0x"+sib[2:66]); d["BIR"]=i("0x"+sib[66:130])
    # limit
    lim=call(h,sel("getTokenHandlerLimit()"))
    if isinstance(lim,str) and lim.startswith("0x") and len(lim)>=130:
        d["borrow_limit"]=i("0x"+lim[2:66]); d["margin_call_limit"]=i("0x"+lim[66:130])
    if name=="ether":
        b=i(rpc("eth_getBalance",[h,"latest"])["result"])
    else:
        b=i(call(erc,sel("balanceOf(address)")+h[2:].rjust(64,"0")))
    d["token_balance"]=b; d["decimals"]=dec
    # manager-side price + support
    d["price"]=i(call(TM,sel("getTokenHandlerPrice(uint256)")+str(hid).rjust(64,"0")))
    d["support"]=call(TM,sel("getTokenHandlerSupport(uint256)")+str(hid).rjust(64,"0"))
    d["borrow_limit_tm"]=i(call(TM,sel("getTokenHandlerBorrowLimit(uint256)")+str(hid).rjust(64,"0")))
    out[hid]=d
    print(json.dumps(d))
open("eth_handlers.json","w").write(json.dumps({"block":blk,"handlers":out},indent=1))
