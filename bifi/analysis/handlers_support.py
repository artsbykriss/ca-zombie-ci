import json, urllib.request
from eth_utils import keccak
def mk(url):
    def rpc(m,p):
        req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        return json.load(urllib.request.urlopen(req,timeout=45))
    return rpc
def sel(s): return keccak(text=s)[:4]
def enc(sig,*a):
    o=sel(sig)
    for x in a: o+=int(x).to_bytes(32,"big")
    return o
def view(rpc,h,sig,*a):
    inner=enc(sig,*a)
    data=sel("handlerViewProxy(bytes)")+(32).to_bytes(32,"big")+len(inner).to_bytes(32,"big")+inner.ljust(((len(inner)+31)//32)*32,b"\0")
    j=rpc("eth_call",[{"to":h,"data":"0x"+data.hex()},"latest"])
    if "error" in j: return "ERR:"+str(j["error"].get("message",""))[:50]
    r=bytes.fromhex(j["result"][2:])
    off=int.from_bytes(r[32:64],"big"); ln=int.from_bytes(r[off:off+32],"big"); return r[off+32:off+32+ln]
def one(rpc,to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    if "error" in j: return "ERR:"+str(j["error"].get("message",""))[:50]
    return j["result"]
def u(rpc,to,sig,*a):
    r=one(rpc,to,"0x"+enc(sig,*a).hex())
    if isinstance(r,str) and r.startswith("ERR"): return r
    return int(r,16) if r and r!="0x" else None
def vaddr(rpc,h,sig):
    r=view(rpc,h,sig)
    if isinstance(r,str): return r
    return "0x"+r[-20:].hex() if len(r)>=32 else None
CH={
 "bsc":("https://bsc-rpc.publicnode.com","0x8010f9e14c8286b9312e624370fddc07fee2fc75",
   ["0x170b6AA872166eC2F8515c2B855C34B6C7563c18","0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB","0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8","0xB67C5433d234d656002f12664d15ab4b40666D9B","0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0","0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B","0x829ED2a2BeF8b72e648f92CBF01587C7E12e8c1e"]),
 "avax":("https://api.avax.network/ext/bc/C/rpc","0x74326d2bfbf22312158850ac3b4f7ae8a0a347fd",
   ["0x446881360d6d39779D292662fca9BC85C5789dB3","0x8AbA88E8A4AB28319b782199cB17f0001EE67984","0xE893233515b7D02dD4e3D888162d4C87Dc837943","0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36","0x34DA42143b0c6E321CEb76931c637c12Bd865f7e","0xc4D1e935F02A44D44985E6b1C0eE1ee616fC146a"]),
 "kaia":("https://public-en.node.kaia.io","0x2014e42d5d63b18728b30c1e3360e0b2c0e839cd",
   ["0x829fCFb6A6EeA9d14eb4C14FaC5B29874BdBaD13","0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11","0x808c707c53c3D30d0247e4b8D78AA0D8b75CAAE1"]),
}
out={}
for chain,(url,tm,hs) in CH.items():
    rpc=mk(url); blk=int(rpc("eth_blockNumber",[])["result"],16)
    print("====",chain,blk)
    ln=u(rpc,tm,"getTokenHandlersLength()")
    print("  handlersLength",ln)
    regs=[]
    for i in range(ln or 0):
        hid=u(rpc,tm,"getTokenHandlerID(uint256)",i)
        info=one(rpc,tm,"0x"+enc("getTokenHandlerInfo(uint256)",hid).hex())
        if isinstance(info,str) and info.startswith("0x") and len(info)>=130:
            b=bytes.fromhex(info[2:]); addr="0x"+b[44:64].hex(); regs.append((hid,addr.lower()))
    print("  registered",[(h,a[:10]) for h,a in regs])
    rows={}
    for h in hs:
        hid=None
        for i,(hh,a) in enumerate(regs):
            if a==h.lower(): hid=hh
        impl=vaddr(rpc,h,"getHandlerAddr()")
        sup=u(rpc,tm,"getTokenHandlerSupport(uint256)",hid) if hid is not None else None
        rows[h.lower()]={"handlerID":hid,"impl":impl,"support":sup}
        print("  ",h[:12],"id",hid,"impl",impl,"support",sup)
    out[chain]={"block":blk,"length":ln,"rows":rows}
open("handlers_support.json","w").write(json.dumps(out,indent=1))
print("saved")
