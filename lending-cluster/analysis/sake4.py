import json,subprocess,concurrent.futures as cf
import requests
from eth_abi import decode
RPC="https://rpc.soneium.org"; POOL="0x3c3987a310ee13f7b8cbbe21d97d4436ba5e4b5f"; ORACLE="0x18530af497f558e23134e223244f353ea776af2a"
assets=["0x4200000000000000000000000000000000000006","0x2cae934a1e84f693fbb78ca5ed3b0a6893259441","0xba9986d2381edf1da03b0b9c1f8b00dc4aacc369","0xf24e57b1cb00d98c31f04f86328e22e8fca457fb","0x3a337a6ada9d885b6ad95ec48f9b75f197b5ae35","0x541fd749419ca806a8bc7da8ac23d346f2df8b77","0xcc0966d8418d412c599a6421b760a847eb169a8c","0x6c460b2c6d6719562d5da43e5152b375e79b9a8b","0x102d758f688a4c1c5a80b116bd945d4455460282","0xaffeb8576b927050f5a3b6fba43f360d2883a118","0x139450c2dcef827c9a2a0bb1cb5506260940c9fd","0x2a52b289ba68bbd02676640aa9f605700c9e5699"]
s=requests.Session(); s.headers.update({"Content-Type":"application/json","User-Agent":"research"})
def sel(x): return subprocess.check_output(["cast","sig",x]).decode().strip()
def call(to,data):
    try:
        r=s.post(RPC,json={"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]},timeout=20).json()
        return r.get("result")
    except Exception: return None
def dec(res,types): return decode(types,bytes.fromhex(res[2:]))
def word(addr): return addr[2:].rjust(64,'0')
def symof(a):
    for t in ["string","bytes32"]:
        r=call(a,sel("symbol()"))
        if r:
            try:
                x=dec(r,[t])[0]; return x.decode(errors='ignore').strip('\x00') if isinstance(x,bytes) else x
            except: pass
    return "?"
def one(a):
    sym=symof(a); r=call(a,sel("decimals()")); decm=dec(r,["uint8"])[0] if r else 0
    rd=call(POOL,sel("getReserveData(address)")+word(a))
    v=dec(rd,["uint256"]+["uint128"]*5+["uint40","uint16","address","address","address","address","uint128","uint128","uint128"])
    cfg=v[0]; ltv=cfg&0xffff; liqth=(cfg>>16)&0xffff; bonus=(cfg>>32)&0xffff
    active=(cfg>>56)&1; frozen=(cfg>>57)&1; borrowEn=(cfg>>58)&1; rf=(cfg>>64)&0xffff
    bcap=(cfg>>80)&0xffffffff; scap=(cfg>>116)&0xffffffff; lpf=(cfg>>152)&0xffff; emode=(cfg>>168)&0xff
    atok=v[8]; vtok=v[10]
    def tot(tok):
        r=call(tok,"0x18160ddd"); return dec(r,["uint256"])[0]/10**decm if r else None
    r=call(a,"0x70a08231"+word(atok)); cash=dec(r,["uint256"])[0]/10**decm if r else None
    r=call(ORACLE,sel("getAssetPrice(address)")+word(a)); price=dec(r,["uint256"])[0]/1e8 if r else None
    r=call(ORACLE,sel("getChainlinkSourceOfAsset(address)")+word(a)); cl="0x"+r[-40:] if r else None
    r=call(ORACLE,sel("getPythSourceOfAsset(address)")+word(a)); pyth="0x"+r[-40:] if r else None
    return dict(sym=sym,addr=a,dec=decm,ltv=ltv/100,liqth=liqth/100,bonus=bonus/1e4,active=active,frozen=frozen,borrow=borrowEn,rf=rf/100,bcap=bcap,scap=scap,lpf=lpf/100,emode=emode,cash=cash,aSupply=tot(atok),vDebt=tot(vtok),price=price,cl=cl,pyth=pyth)
with cf.ThreadPoolExecutor(12) as ex:
    rows=list(ex.map(one,assets))
for x in rows:
    print(f"{x['sym']:9s} dec={x['dec']} ltv={x['ltv']:.2f}% liqth={x['liqth']:.2f}% bonus={x['bonus']:.3f}x act={x['active']} frz={x['frozen']} bor={x['borrow']} rf={x['rf']:.2f}% caps={x['bcap']}/{x['scap']} lpf={x['lpf']:.2f}% em={x['emode']} cash={x['cash']:,.2f} aSupply={x['aSupply']:,.2f} vDebt={x['vDebt']:,.2f} price=${x['price']} cl={x['cl']} pyth={x['pyth']}")
json.dump(rows,open("sake_reserves.json","w"),indent=1)
