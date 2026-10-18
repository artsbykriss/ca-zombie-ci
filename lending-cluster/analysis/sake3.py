from rpc import call
import subprocess
from eth_abi import decode
POOL="0x3c3987a310ee13f7b8cbbe21d97d4436ba5e4b5f"; ORACLE="0x18530af497f558e23134e223244f353ea776af2a"
assets=["0x4200000000000000000000000000000000000006","0x2cae934a1e84f693fbb78ca5ed3b0a6893259441","0xba9986d2381edf1da03b0b9c1f8b00dc4aacc369","0xf24e57b1cb00d98c31f04f86328e22e8fca457fb","0x3a337a6ada9d885b6ad95ec48f9b75f197b5ae35","0x541fd749419ca806a8bc7da8ac23d346f2df8b77","0xcc0966d8418d412c599a6421b760a847eb169a8c","0x6c460b2c6d6719562d5da43e5152b375e79b9a8b","0x102d758f688a4c1c5a80b116bd945d4455460282","0xaffeb8576b927050f5a3b6fba43f360d2883a118","0x139450c2dcef827c9a2a0bb1cb5506260940c9fd","0x2a52b289ba68bbd02676640aa9f605700c9e5699"]
def sel(s): return subprocess.check_output(["cast","sig",s]).decode().strip()
def c(to,data,ch="soneium"):
    r=call(ch,to,data)
    if "result" not in r: return None
    return r["result"]
def dec(res,types):
    return decode(types,bytes.fromhex(res[2:]))
rows=[]
for a in assets:
    sym="?"; decm=None
    for t in ["string","bytes32"]:
        r=c(a,sel("symbol()"))
        if r:
            try:
                sym=dec(r,[t])[0]; sym=sym.decode(errors='ignore').strip('\x00') if isinstance(sym,bytes) else sym; break
            except: pass
    r=c(a,sel("decimals()"))
    decm=dec(r,["uint8"])[0] if r else None
    rd=c(POOL,sel("getReserveData(address)")+a[2:].rjust(64,'0'))
    v=dec(rd,["uint256"]+["uint128"]*5+["uint40","uint16","address","address","address","address","uint128","uint128","uint128"])
    cfg=v[0]; ltv=cfg&0xffff; liqth=(cfg>>16)&0xffff; bonus=(cfg>>32)&0xffff; d=(cfg>>48)&0xff
    active=(cfg>>56)&1; frozen=(cfg>>57)&1; borrowEn=(cfg>>58)&1; stable=(cfg>>59)&1; rf=(cfg>>64)&0xffff
    bcap=(cfg>>80)&0xffffffff; scap=(cfg>>116)&0xffffffff; lpf=(cfg>>152)&0xffff; emode=(cfg>>168)&0xff; debtceil=(cfg>>212)&0xffffffff
    liqIdx=v[1]/1e27; vbidx=v[3]/1e27; avail=v[13]/10**decm if decm else v[13]; tvd=v[14]/10**decm if decm else v[14]; unbacked=v[15]/10**decm if decm else v[15]
    price=None; cl=None; pyth=None
    r=c(ORACLE,sel("getAssetPrice(address)")+a[2:].rjust(64,'0'))
    if r: price=dec(r,["uint256"])[0]/1e8
    r=c(ORACLE,sel("getChainlinkSourceOfAsset(address)")+a[2:].rjust(64,'0'))
    if r: cl="0x"+r[-40:]
    r=c(ORACLE,sel("getPythSourceOfAsset(address)")+a[2:].rjust(64,'0'))
    if r: pyth="0x"+r[-40:]
    print(f"{sym:10s} {a} dec={decm} ltv={ltv/100:.2f}% liqth={liqth/100:.2f}% bonus={bonus/1e4:.3f}x active={active} frozen={frozen} borrow={borrowEn} rf={rf/100:.2f}% caps={bcap}/{scap} lpf={lpf/100:.2f}% emode={emode} avail={avail:,.2f} vDebt={tvd:,.2f} unbacked={unbacked:,.2f} price=${price if price is None else round(price,6)} cl={cl} pyth={pyth}")
