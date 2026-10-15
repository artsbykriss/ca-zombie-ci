#!/usr/bin/env python3
"""WannaSwap pair enumeration + Trisolaris farm/bar/maker balances."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "aurora"
WF = "0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246"
TRI = "0xFa94348467f64D5A457F75F8bc40495D33c65aBB"
MC1 = "0x1f1Ed214bef5E83D8f5d0eB5D7011EB965D0D79B"
MC2 = "0x3838956710bcc9D122Dd23863a0549ca8D5675D6"
XTRI = "0x802119e4e253D5C19aA06A5d567C5a41596D6803"
TRIMAKER = "0xe793455c9728fc91A3E5a33FAfF9eB2F228aE151"
PTRI = "0xe559092D2e80d9B1d91a641CE25bACC3cFdCF689"
USDCMAKER = "0x5EBd5e963A00500B6a1234c621811c52AF0aAade"
USDC = "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802"
WANNA = "0x7faA64Faf54750a2E3eE621166635fEAF406Ab22"

BAL = sel("balanceOf(address)")
TS = sel("totalSupply()")
GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")
DEC = sel("decimals()")

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("Aurora block:", int(blk,16))
    # balances
    checks = [
        ("MC1 TRI", TRI, BAL+enc_addr(MC1)), ("MC1 native", None, MC1),
        ("MC2 TRI", TRI, BAL+enc_addr(MC2)), ("MC2 native", None, MC2),
        ("xTRI TRI bal", TRI, BAL+enc_addr(XTRI)), ("xTRI totalSupply", XTRI, TS),
        ("TriMaker TRI", TRI, BAL+enc_addr(TRIMAKER)), ("TriMaker pTRI", PTRI, BAL+enc_addr(TRIMAKER)),
        ("TriMaker USDC", USDC, BAL+enc_addr(TRIMAKER)), ("TriMaker native", None, TRIMAKER),
        ("pTRI totalSupply", PTRI, TS),
        ("USDCMaker USDC", USDC, BAL+enc_addr(USDCMAKER)), ("USDCMaker native", None, USDCMAKER),
        ("TRI totalSupply", TRI, TS),
    ]
    for label, tok, data in checks:
        r = rpc(CHAIN, "eth_getBalance", [data, "latest"]) if tok is None else rpc(CHAIN,"eth_call",[{"to":tok,"data":data},"latest"])
        v = int(r,16) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else r
        print(f"{label:24s} {str(v)[:80]}")
    # WannaSwap pairs
    n = int(rpc(CHAIN,"eth_call",[{"to":WF,"data":sel("allPairsLength()")},"latest"]),16)
    print("WannaSwap allPairsLength:", n)
    addrs=[]
    for i in range(0,n,25):
        res = batch(CHAIN, [("eth_call",[{"to":WF,"data":sel("allPairs(uint256)")+enc_uint(j)},"latest"]) for j in range(i,min(i+25,n))], chunk=25)
        for r in res:
            if isinstance(r,str) and r.startswith("0x") and len(r)>=42:
                addrs.append("0x"+r[2:][24:64])
    print("fetched:", len(addrs))
    reserves={}
    for i in range(0,len(addrs),30):
        chunk=addrs[i:i+30]
        res = batch(CHAIN, [("eth_call",[{"to":a,"data":GR},"latest"]) for a in chunk], chunk=15)
        for a,r in zip(chunk,res):
            if isinstance(r,str) and len(r)>=2+192:
                raw=r[2:]
                reserves[a]=(int(raw[:64],16), int(raw[64:128],16))
    live={a:v for a,v in reserves.items() if v[0]>10**12 or v[1]>10**12}
    print("pairs with reserves:", len(reserves), "live:", len(live))
    # tokens
    tok={}
    items=list(live.items())
    for i in range(0,len(items),25):
        chunk=items[i:i+25]
        calls=[]
        for a,_ in chunk:
            calls.append(("eth_call",[{"to":a,"data":T0},"latest"]))
            calls.append(("eth_call",[{"to":a,"data":T1},"latest"]))
        res = batch(CHAIN, calls, chunk=20)
        for k,(a,rv) in enumerate(chunk):
            t0="0x"+res[2*k][2:][24:64] if isinstance(res[2*k],str) and len(res[2*k])>=42 else None
            t1="0x"+res[2*k+1][2:][24:64] if isinstance(res[2*k+1],str) and len(res[2*k+1])>=42 else None
            tok[a]=(t0,t1,rv)
    # decimals for tokens
    toks=sorted({t for v in tok.values() for t in v[:2] if t})
    dec={}
    for i in range(0,len(toks),30):
        chunk=toks[i:i+30]
        res=batch(CHAIN,[("eth_call",[{"to":t,"data":DEC},"latest"]) for t in chunk],chunk=15)
        for t,r in zip(chunk,res):
            try: dec[t]=int(r,16)
            except Exception: dec[t]=18
    # prices
    prices={}
    for i in range(0,len(toks),40):
        ids=",".join(f"aurora:{t}" for t in toks[i:i+40])
        try:
            with urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/"+ids, headers={"User-Agent":"research"}), timeout=30) as r:
                d=json.load(r)
            for k,v in (d.get("coins") or {}).items():
                prices[k.split(":")[1]]=v.get("price")
        except Exception as e:
            pass
    rows=[]
    for a,(t0,t1,(r0,r1)) in tok.items():
        d0,d1=dec.get(t0,18),dec.get(t1,18)
        p0,p1=prices.get(t0) or 0, prices.get(t1) or 0
        usd=(r0/10**d0)*p0+(r1/10**d1)*p1
        rows.append({"usd":usd,"pair":a,"t0":t0,"t1":t1,"h0":r0/10**d0,"h1":r1/10**d1,"p0":p0,"p1":p1})
    rows.sort(key=lambda x:-x["usd"])
    total=sum(r["usd"] for r in rows)
    print(f"WannaSwap total pair USD: ${total:,.2f} (DefiLlama $118,329)")
    for r in rows[:15]:
        print(f"  ${r['usd']:>10,.2f} {r['pair']} {r['t0'][:10]} {r['h0']:,.4f}@{r['p0']} | {r['t1'][:10]} {r['h1']:,.4f}@{r['p1']}")
    json.dump(rows, open("/home/heisenberg/CA/aurora-dust/analysis/wannaswap-pairs.json","w"), indent=1)

if __name__=="__main__":
    main()
