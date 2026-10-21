import json, urllib.request
from eth_utils import keccak
def mk(url):
    def rpc(m,p):
        req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        return json.load(urllib.request.urlopen(req,timeout=45))
    return rpc
CH={
 "ethereum":("https://ethereum-rpc.publicnode.com","0x913f2dee2746cda2ab34106c47abc4a8f4e36fa5",
   [("eth","0x13000C4a215EfE7E414bB329b2F11c39BCF92D78"),("usdt","0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3"),("dai","0xD76b7060F1B646fA14740Ff6Ac670a4f0A6fc5E3"),("link","0x25567603eb61A4A49f27e433652B5B8940D10682"),("usdc","0x128647690C7733593aA3Dd149EeBC5e256E79217"),("wbtc_legacy","0x93948Aa8488F522d5b079AF84fe411FBCE476e9f")]),
 "bsc":("https://bsc-rpc.publicnode.com","0x8010f9e14c8286b9312e624370fddc07fee2fc75",
   [("bnb","0x170b6AA872166eC2F8515c2B855C34B6C7563c18"),("eth","0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB"),("usdt","0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8"),("dai","0xB67C5433d234d656002f12664d15ab4b40666D9B"),("usdc","0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0"),("btcb","0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B"),("busd_legacy","0x829ED2a2BeF8b72e648f92CBF01587C7E12e8c1e")]),
 "avax":("https://api.avax.network/ext/bc/C/rpc","0x74326d2bfbf22312158850ac3b4f7ae8a0a347fd",
   [("avax","0x446881360d6d39779D292662fca9BC85C5789dB3"),("eth","0x8AbA88E8A4AB28319b782199cB17f0001EE67984"),("usdt","0xE893233515b7D02dD4e3D888162d4C87Dc837943"),("usdc","0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36"),("dai","0x34DA42143b0c6E321CEb76931c637c12Bd865f7e"),("wbtc","0xc4D1e935F02A44D44985E6b1C0eE1ee616fC146a")]),
 "kaia":("https://public-en.node.kaia.io","0x2014e42d5d63b18728b30c1e3360e0b2c0e839cd",
   [("kai","0x829fCFb6A6EeA9d14eb4C14FaC5B29874BdBaD13"),("keth","0x07970F9D979D8594B394fE12345211C376aDfF89"),("kusdt","0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11"),("kdai","0xE03487927e137526a2dB796A9B3b4048ab615043"),("usdc","0x808c707c53c3D30d0247e4b8D78AA0D8b75CAAE1"),("kwbtc","0xa6aDE2e6c6F50a2d9b9C4b819e84b367F88C1598"),("kxrp","0x4800577A71F68eD7ef4C09cFBe7fd6E066D5F0dA")])}
def sel(s): return keccak(text=s)[:4]
def enc(sig,*a):
    o=sel(sig)
    for x in a: o+=int(x).to_bytes(32,"big")
    return o
def view(rpc,h,sig,*a):
    inner=enc(sig,*a)
    data=sel("handlerViewProxy(bytes)")+(32).to_bytes(32,"big")+len(inner).to_bytes(32,"big")+inner.ljust(((len(inner)+31)//32)*32,b"\0")
    j=rpc("eth_call",[{"to":h,"data":"0x"+data.hex()},"latest"])
    if "error" in j: return None
    r=bytes.fromhex(j["result"][2:])
    off=int.from_bytes(r[32:64],"big"); ln=int.from_bytes(r[off:off+32],"big"); return r[off+32:off+32+ln]
def one(rpc,to,data):
    j=rpc("eth_call",[{"to":to,"data":data},"latest"])
    if "error" in j: return None
    return j["result"]
def u(rpc,to,sig,*a):
    r=one(rpc,to,"0x"+enc(sig,*a).hex())
    return int(r,16) if r and r!="0x" else None
out={}
for chain,(url,tm,hs) in CH.items():
    rpc=mk(url)
    blk=int(rpc("eth_blockNumber",[])["result"],16)
    print("="*10,chain,"block",blk)
    em=one(rpc,tm,sel("getCircuitBreaker()").hex()); ow=one(rpc,tm,sel("owner()").hex()); ln=u(rpc,tm,"getTokenHandlersLength()")
    print("manager",tm,"emergency",em,"owner",ow,"len",ln)
    registered=[]
    for i in range((ln or 0)):
        hid=u(rpc,tm,"getTokenHandlerID(uint256)",i)
        info=one(rpc,tm,"0x"+enc("getTokenHandlerInfo(uint256)",hid).hex())
        if info:
            b=bytes.fromhex(info[2:]); sup=int.from_bytes(b[0:32],"big"); addr="0x"+b[44:64].hex()
            registered.append((hid,addr.lower()))
    print("registered",[(h,a[:10]) for h,a in registered])
    rows=[]
    for name,h in hs:
        erc=view(rpc,h,"getERC20Addr()")
        tok="0x"+erc[-20:].hex() if erc else None
        dec=None
        if tok and tok!="0x"+"ee"*20 and int(tok,16)!=0:
            d=u(rpc,tok,"decimals()")
            dec=d if d is not None else 18
        if name in ("eth","bnb","avax","kai"):
            bal=int(rpc("eth_getBalance",[h,"latest"])["result"],16)
        else:
            bal=u(rpc,tok,"balanceOf(address)",int(h,16))
        dep=view(rpc,h,"getDepositTotalAmount()"); bor=view(rpc,h,"getBorrowTotalAmount()")
        depi=int.from_bytes(dep[:32],"big") if dep else None
        bori=int.from_bytes(bor[:32],"big") if bor else None
        mgr=one(rpc,h,"0x"+enc("getHandlerAddr()").hex())
        slot5=one(rpc,h,"0x"+sel("getHandlerID()").hex())  # dummy
        manager_slot=rpc("eth_getStorageAt",[h,"0x5","latest"])["result"]
        price=u(rpc,tm,"getTokenHandlerPrice(uint256)",next((i for i,(hh,a) in enumerate(registered) if a==h.lower()),999))
        rows.append(dict(name=name,handler=h,token=tok,decimals=dec,balance=bal,balance_human=(bal/10**dec if bal is not None and dec else bal),
                         deposit_unified=(depi/1e18 if depi else depi),borrow_unified=(bori/1e18 if bori else bori),manager_slot=manager_slot,price_1e18=price,
                         registered=any(a==h.lower() for _,a in registered)))
        print(json.dumps(rows[-1]))
    out[chain]=dict(block=blk,manager=tm,emergency=em,owner=ow,handlers=rows,registered=registered)
open("multichain_state.json","w").write(json.dumps(out,indent=1))
