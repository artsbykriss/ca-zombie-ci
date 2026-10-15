#!/usr/bin/env python3
"""GDC token state + DHC/UP liquidity checks."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

GDC = "0xe3342358e7ccbaebdd1139ad0274c53c5b3ef822"
PAIR = "0x9cd8d04c30ed78afef7ed00ab1a2a028d476331c"
WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
DHC = "0x743F15f4d2481774d970f286f0EbAD9C3Daed6E9"
UP = "0x36F20660b9947929Ab3edd8727B5Af60260333A7"

SIGS = ["receive()","depositFor(address)","bindReferrer(address)","inviter(address)",
        "effectiveReferralCount(address)","addLiquidityUnlockTime(address)","users(address)",
        "hasDeposited(address)","swapping()","LP_MIN_BALANCE()","SELL_USER_PERCENT()",
        "swapSellAward()","totalSupply()","balanceOf(address)"]

def main():
    blk = rpc("bsc","eth_blockNumber",[])
    print("BSC block:", int(blk,16))
    code = rpc("bsc","eth_getCode",[GDC,"latest"])
    print("GDC codelen:", len(code)//2-1)
    for sig in SIGS:
        if sig.endswith("()") and "(" not in sig[:-2]:
            s = sel(sig)
            print(f"{'YES' if s[2:] in code[2:] else 'no '} {sig} {s}")
    # check view functions
    for name, data in [
        ("GDC totalSupply", sel("totalSupply()")),
        ("GDC pair WBNB bal", sel("balanceOf(address)")+enc_addr(PAIR)),
        ("GDC pair GDC bal", sel("balanceOf(address)")+enc_addr(PAIR)),
        ("GDC pair reserves", None),
    ]:
        if data is None:
            r = rpc("bsc","eth_call",[{"to":PAIR,"data":sel("getReserves()")},"latest"])
            if isinstance(r,str) and len(r)>=2+192:
                raw=r[2:]; print(f"{name}: r0={int(raw[:64],16)} r1={int(raw[64:128],16)}")
        else:
            to = GDC if name.startswith("GDC total") or name.startswith("GDC pair") else PAIR
            r = rpc("bsc","eth_call",[{"to":to,"data":data},"latest"])
            v = int(r,16) if isinstance(r,str) and r!="0x" else r
            print(f"{name}: {v}")
    # DHC / UP liquidity via GeckoTerminal (single calls with backoff)
    for net, addr, label in [("bsc","0x743f15f4d2481774d970f286f0ebad9c3daed6e9","DHC"),
                             ("bsc","0x36f20660b9947929ab3edd8727b5af60260333a7","UPbnb")]:
        try:
            url=f"https://api.geckoterminal.com/api/v2/networks/{net}/tokens/{addr}/pools?page=1"
            with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"research"}),timeout=30) as r:
                d=json.load(r)
            pools=[(p["attributes"]["name"],p["attributes"]["address"],p["attributes"].get("reserve_in_usd")) for p in (d.get("data") or [])[:3]]
            print(f"{label} pools: {pools if pools else 'NONE'}")
        except Exception as e:
            print(f"{label} pools ERR {str(e)[:80]}")

if __name__ == "__main__":
    main()
