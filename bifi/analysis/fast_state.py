import json, urllib.request
from eth_utils import keccak
def batch(url, calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]
    req=urllib.request.Request(url,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    r=json.load(urllib.request.urlopen(req,timeout=60))
    out={x["id"]:x for x in r}
    return [out.get(i,{}) for i in range(len(calls))]
def sel(s): return "0x"+keccak(text=s)[:4].hex()
def call(to,data): return {"to":to,"data":data}
def bal(tok,who): return call(tok,"0x70a08231"+who[2:].rjust(64,"0"))
CH={
 "ethereum":("https://ethereum-rpc.publicnode.com","0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",
   [("eth","0x13000C4a215EfE7E414bB329b2F11c39BCF92D78","0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",18),
    ("usdt","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3","0xdAC17F958D2ee523a2206206994597C13D831ec7",6),
    ("dai","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3","0x6B175474E89094C44Da98b954EedeAC495271d0F",18),
    ("link","0x25567603eb61A4A49f27e433652B5B8940D10682","0x514910771AF9Ca656af840dff83E8264EcF986CA",18),
    ("usdc","0x128647690C7733593aA3Dd149EeBC5e256E79217","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",6),
    ("wbtc_legacy","0x93948Aa8488F522d5b079AF84fe411FBCE476e9f","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",8)]),
 "bsc":("https://bsc-rpc.publicnode.com","0x8010f9e14c8286b9312e624370fddc07fee2fc75",
   [("bnb","0x170b6AA872166eC2F8515c2B855C34B6C7563c18","0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",18),
    ("eth","0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB","0x2170Ed0880ac9A755fd29B2688956BD959F933F8",18),
    ("usdt","0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8","0x55d398326f99059fF775485246999027B3197955",18),
    ("dai","0xB67C5433d234d656002f12664d15ab4b40666D9B","0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3",18),
    ("usdc","0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",18),
    ("btcb","0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B","0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",18),
    ("busd_legacy","0x829ED2a2BeF8b72e648f92CBF01587C7E12e8c1e","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",18)]),
 "avax":("https://api.avax.network/ext/bc/C/rpc","0x74326d2bfbf22312158850ac3b4f7ae8a0a347fd",
   [("avax","0x446881360d6d39779D292662fca9BC85C5789dB3","0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",18),
    ("eth","0x8AbA88E8A4AB28319b782199cB17f0001EE67984","0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB",18),
    ("usdt","0xE893233515b7D02dD4e3D888162d4C87Dc837943","0xc7198437980c041c805A1EDcbA50c1Ce5db95118",6),
    ("usdc","0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36","0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",6),
    ("dai","0x34DA42143b0c6E321CEb76931c637c12Bd865f7e","0xd586E7F844cEa2F87f50152665BCbc2C279D8d70",18),
    ("wbtc","0xc4D1e935F02A44D44985E6b1C0eE1ee616fC146a","0x50b7545627a5162F82A992c33b87aDc75187B218",8)]),
 "kaia":("https://public-en.node.kaia.io","0x2014e42d5d63b18728b30c1e3360e0b2c0e839cd",
   [("kai","0x829fCFb6A6EeA9d14eb4C14FaC5B29874BdBaD13","0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",18),
    ("keth","0x07970F9D979D8594B394fE12345211C376aDfF89","0x0000000000000000000000000000000000000000",18),
    ("kusdt","0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11","0x0000000000000000000000000000000000000000",6),
    ("kdai","0xE03487927e137526a2dB796A9B3b4048ab615043","0x0000000000000000000000000000000000000000",18),
    ("usdc","0x808c707c53c3D30d0247e4b8D78AA0D8b75CAAE1","0x0000000000000000000000000000000000000000",6),
    ("kwbtc","0xa6aDE2e6c6F50a2d9b9C4b819e84b367F88C1598","0x0000000000000000000000000000000000000000",8),
    ("kxrp","0x4800577A71F68eD7ef4C09cFBe7fd6E066D5F0dA","0x0000000000000000000000000000000000000000",6)])}
out={}
for chain,(url,tm,hs) in CH.items():
    calls=[]
    for name,h,tok,dec in hs:
        calls.append(call(tm,sel("getCircuitBreaker()")))
        calls.append(call(tm,sel("getTokenHandlersLength()()")))
        if tok.lower().startswith("0xeeee") or int(tok,16)==0:
            calls.append(("ETHBAL",h))
        else:
            calls.append(call(tok,"0x70a08231"+h[2:].rjust(64,"0")))
    res=batch(url,calls)
    blk=None
    rows=[]
    for i,(name,h,tok,dec) in enumerate(hs):
        r=res[i*3]
        print(chain,name,"emergency",r.get("result"),end=" ")
        b=res[i*3+2]
        print("bal_raw",b.get("result"),"bal", (int(b["result"],16)/10**dec if b.get("result") not in (None,"0x") else None))
        rows.append(dict(name=name,handler=h,token=tok,decimals=dec,balance_raw=b.get("result"),balance=(int(b["result"],16)/10**dec if b.get("result") not in (None,"0x") else None)))
    out[chain]=rows
print(json.dumps(out,indent=1))
