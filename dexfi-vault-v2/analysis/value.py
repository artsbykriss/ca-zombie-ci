#!/usr/bin/env python3
"""Value DexFi vault LP positions in USD using Uniswap V3 math + DefiLlama prices."""
import json, sys, urllib.request, math

def sqrt_ratio_at_tick(tick):
    # sqrt(1.0001^tick) * 2^96  (float; plenty for USD estimation)
    return int(math.exp(tick/2.0*math.log(1.0001)) * (2**96))

def s24(x):
    x = int(x) & 0xFFFFFF
    return x - 0x1000000 if x >= 0x800000 else x

def amounts_for_liquidity(sqrtP, sqrtA, sqrtB, L):
    if sqrtA > sqrtB: sqrtA, sqrtB = sqrtB, sqrtA
    if sqrtP <= sqrtA:
        a0 = (L << 96) * (sqrtB - sqrtA) // sqrtB // sqrtA
        a1 = 0
    elif sqrtP < sqrtB:
        a0 = (L << 96) * (sqrtB - sqrtP) // sqrtB // sqrtP
        a1 = L * (sqrtP - sqrtA) // (2**96)
    else:
        a0 = 0
        a1 = L * (sqrtB - sqrtA) // (2**96)
    return a0, a1

def llama_prices(chain, tokens):
    out={}
    toks=[t for t in tokens if t]
    for i in range(0,len(toks),50):
        chunk=toks[i:i+50]
        ids=",".join(f"{chain}:{t}" for t in chunk)
        try:
            req=urllib.request.Request(f"https://coins.llama.fi/prices/current/{ids}",headers={"User-Agent":"Mozilla/5.0"})
            d=json.loads(urllib.request.urlopen(req,timeout=40).read())
            for k,v in d.get("coins",{}).items():
                out[k.split(":",1)[1].lower()]=v["price"]
        except Exception as e:
            print("price err",e)
    return out

def decimals(chain, tokens):
    import rpc_scan as R
    url=R.working_rpc(chain, R.FACTORY[chain], "0x"+R.SEL["vaultsCount"])
    sel=R.selector("decimals()")
    out={}
    toks=[t for t in tokens if t]
    for i in range(0,len(toks),50):
        chunk=toks[i:i+50]
        try:
            res=R.rpc_batch(url,[(t,"0x"+sel) for t in chunk])
            for t,h in zip(chunk,res):
                out[t.lower()]= R.dec_uint(h) if h and h!="0x" else 18
        except Exception as e:
            print("dec err",e)
    return out

def main(fn, chain="base"):
    import rpc_scan as R
    NAT = R.NATIVE
    d=json.load(open(fn))
    recs=d["records"]
    toks=set()
    for r in recs:
        for f in r.get("farms",[]):
            if f.get("pos_token0"): toks.add(f["pos_token0"])
            if f.get("pos_token1"): toks.add(f["pos_token1"])
            if f.get("stakingToken") and not f.get("tokenId"): toks.add(f["stakingToken"])
    px=llama_prices(chain,list(toks))
    dec=decimals(chain,list(toks))
    tot=0
    rows=[]
    for r in recs:
        v=0
        for f in r.get("farms",[]):
            try:
                if f.get("tokenId"):
                    L=f.get("pos_liq") or 0
                    if L<=0: continue
                    sqrtP=f.get("sqrtPriceX96")
                    t0=f.get("pos_token0"); t1=f.get("pos_token1")
                    tl=f.get("pos_tickLower"); tu=f.get("pos_tickUpper")
                    if sqrtP is None or tl is None or tu is None: continue
                    sA=sqrt_ratio_at_tick(s24(tl)); sB=sqrt_ratio_at_tick(s24(tu))
                    a0,a1=amounts_for_liquidity(sqrtP,sA,sB,L)
                    # decimals
                    p0=px.get((t0 or "").lower(),0); p1=px.get((t1 or "").lower(),0)
                    v += a0/(10**dec.get((t0 or "").lower(),18))*p0 + a1/(10**dec.get((t1 or "").lower(),18))*p1
                else:
                    amt=f.get("liq") or 0
                    p=px.get((f.get("stakingToken") or "").lower(),0)
                    v += amt/(10**dec.get((f.get("stakingToken") or "").lower(),18))*p
            except Exception as e:
                pass
        # residual native
        nat = NAT.get(chain, "0x4200000000000000000000000000000000000006")
        v += (r.get("nativeBal") or 0)/(10**dec.get(nat.lower(),18))*px.get(nat.lower(),0)
        tot+=v
        rows.append((v,r["vault"],r.get("supply"),r.get("published"),len(r.get("farms",[]))))
    rows.sort(reverse=True)
    print(f"chain={chain} vaults={len(recs)} total_usd={tot:,.2f}")
    for v,addr,sup,pub,nf in rows[:30]:
        print(f"  ${v:>14,.2f}  {addr} supply={sup} pub={pub} farms={nf}")
    return tot,rows

if __name__=="__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv)>2 else "base")
