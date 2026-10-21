import json, urllib.request, sys
from eth_utils import keccak

def mk(url):
    def rpc(m,p):
        req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        return json.load(urllib.request.urlopen(req,timeout=45))
    return rpc
def sel(s): return "0x"+keccak(text=s)[:4].hex()
def one(rpc,to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    if "error" in j: return "ERR:"+str(j["error"].get("message",""))[:60]
    return j["result"]
def u(rpc,to,sig):
    r=one(rpc,to,sel(sig))
    if isinstance(r,str) and r.startswith("ERR"): return r
    return int(r,16) if r and r!="0x" else None
def addr(rpc,to,sig):
    r=one(rpc,to,sel(sig))
    if isinstance(r,str) and r.startswith("ERR"): return r
    return "0x"+r[-40:] if r and r!="0x" else None

CH={
 "ethereum":("https://ethereum-rpc.publicnode.com","0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",
   ["0x13000C4a215EfE7E414bB329b2F11c39BCF92D78","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3","0x25567603eb61A4A49f27e433652B5B8940D10682","0x128647690C7733593aA3Dd149EeBC5e256E79217"]),
 "bsc":("https://bsc-rpc.publicnode.com","0x8010f9e14c8286b9312e624370fddc07fee2fc75",
   ["0x170b6AA872166eC2F8515c2B855C34B6C7563c18","0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB","0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8","0xB67C5433d234d656002f12664d15ab4b40666D9B","0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0","0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B"]),
 "avax":("https://api.avax.network/ext/bc/C/rpc","0x74326d2bfbf22312158850ac3b4f7ae8a0a347fd",
   ["0x446881360d6d39779D292662fca9BC85C5789dB3","0x8AbA88E8A4AB28319b782199cB17f0001EE67984","0xE893233515b7D02dD4e3D888162d4C87Dc837943","0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36","0x34DA42143b0c6E321CEb76931c637c12Bd865f7e","0xc4D1e935F02A44D44985E6b1C0eE1ee616fC146a"]),
 "kaia":("https://public-en.node.kaia.io","0x2014e42d5d63b18728b30c1e3360e0b2c0e839cd",
   ["0x829fCFb6A6EeA9d14eb4C14FaC5B29874BdBaD13","0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11","0x808c707c53c3D30d0247e4b8D78AA0D8b75CAAE1"]),
}
out={}
for chain,(url,tm,handlers) in CH.items():
    rpc=mk(url)
    blk=int(rpc("eth_blockNumber",[])["result"],16)
    row={"block":blk,"manager":tm,
         "getCircuitBreaker":u(rpc,tm,"getCircuitBreaker()"),
         "owner":addr(rpc,tm,"owner()"),
         "getOwner":addr(rpc,tm,"getOwner()"),
         "handlers":{}}
    models={}
    for h in handlers:
        im=addr(rpc,h,"getInterestModelAddr()")
        row["handlers"][h.lower()]={"interestModel":im}
        if isinstance(im,str) and im.startswith("0x"):
            models[im.lower()]=None
    for m in models:
        models[m]={"blocksPerYear":u(rpc,m,"blocksPerYear()"),"getOwner":addr(rpc,m,"getOwner()")}
    row["models"]=models
    out[chain]=row
    print(chain,"blk",blk,"breaker",row["getCircuitBreaker"],"owner",row["owner"])
    for m,v in models.items():
        print("   model",m,v)
open("live_state2.json","w").write(json.dumps(out,indent=1))
print("saved live_state2.json")
