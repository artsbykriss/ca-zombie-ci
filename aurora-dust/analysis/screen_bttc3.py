#!/usr/bin/env python3
"""BTTC scans v2: correct price chain key (bittorrent); SpookySwap + Intercroneswap + JustMoney/others."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint
import urllib.request

GR=sel("getReserves()"); T0=sel("token0()"); T1=sel("token1()"); BAL=sel("balanceOf(address)")
APL=sel("allPairsLength()"); AP=sel("allPairs(uint256)"); DEC=sel("decimals()")

def price_map(tokens):
    prices={}
    toks=sorted(set(t for t in tokens if t))
    for i in range(0,len(toks),40):
        ids=",".join(f"bittorrent:{t}" for t in toks[i:i+40])
        try:
            with urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/"+ids,headers={"User-Agent":"research"}),timeout=30) as r:
                d=json.load(r)
            for k,v in (d.get("coins") or {}).items():
                prices[k.split(":")[1].lower()]=v.get("price")
        except Exception: pass
    return prices

def scan(factory,label,limit=500):
    chain="bttc"
    try: n=int(rpc(chain,"eth_call",[{"to":factory,"data":APL},"latest"]),16)
    except Exception as e:
        print(f"== {label}: allPairsLength failed"); return None
    addrs=[]
    for i in range(0,min(n,limit),30):
        res=batch(chain,[("eth_call",[{"to":factory,"data":AP+enc_uint(j)},"latest"]) for j in range(i,min(i+30,n,limit))],chunk=30)
        for r in res:
            if isinstance(r,str) and r.startswith("0x") and len(r)>=42: addrs.append("0x"+r[2:][24:64])
    pairs=[]
    for i in range(0,len(addrs),25):
        chunk=addrs[i:i+25]; calls=[]
        for a in chunk:
            calls.append(("eth_call",[{"to":a,"data":T0},"latest"]))
            calls.append(("eth_call",[{"to":a,"data":T1},"latest"]))
            calls.append(("eth_call",[{"to":a,"data":GR},"latest"]))
        res=batch(chain,calls,chunk=20)
        for k,a in enumerate(chunk):
            t0r,t1r,gr=res[3*k],res[3*k+1],res[3*k+2]
            if not (isinstance(t0r,str) and len(t0r)>=42 and isinstance(gr,str) and len(gr)>=2+192): continue
            t0="0x"+t0r[2:][24:64]; t1="0x"+t1r[2:][24:64]
            raw=gr[2:]; r0=int(raw[:64],16); r1=int(raw[64:128],16)
            pairs.append({"pair":a,"t0":t0,"t1":t1,"r0":r0,"r1":r1})
    for i in range(0,len(pairs),25):
        chunk=pairs[i:i+25]; calls=[]
        for p in chunk:
            calls.append(("eth_call",[{"to":p["t0"],"data":BAL+enc_addr(p["pair"])},"latest"]))
            calls.append(("eth_call",[{"to":p["t1"],"data":BAL+enc_addr(p["pair"])},"latest"]))
        res=batch(chain,calls,chunk=20)
        for k,p in enumerate(chunk):
            try: p["b0"]=int(res[2*k],16); p["b1"]=int(res[2*k+1],16)
            except Exception: p["b0"]=p["b1"]=None
    rows=[p for p in pairs if p.get("b0") is not None]
    toks=sorted({t for r in rows for t in (r["t0"],r["t1"])})
    dec={}
    for i in range(0,len(toks),30):
        chunk=toks[i:i+30]
        res=batch(chain,[("eth_call",[{"to":t,"data":DEC},"latest"]) for t in chunk],chunk=15)
        for t,r in zip(chunk,res):
            try: dec[t]=int(r,16)
            except Exception: dec[t]=18
    prices=price_map(toks)
    tb=tr=0.0
    for r in rows:
        d0,d1=dec.get(r["t0"],18),dec.get(r["t1"],18)
        p0,p1=prices.get(r["t0"],0),prices.get(r["t1"],0)
        r["usd_bal"]=(r["b0"]/10**d0)*p0+(r["b1"]/10**d1)*p1
        r["usd_res"]=(r["r0"]/10**d0)*p0+(r["r1"]/10**d1)*p1
        tb+=r["usd_bal"]; tr+=r["usd_res"]
    live=sorted([r for r in rows if r["usd_bal"]>0.5],key=lambda x:-x["usd_bal"])
    skim=[r for r in rows if r["b0"]>r["r0"] or r["b1"]>r["r1"]]
    print(f"== {label}: pairs={len(rows)} USD(bal)=${tb:,.2f} USD(res)=${tr:,.2f} live={len(live)} skim-able={len(skim)}")
    for r in live[:10]:
        print(f"   ${r['usd_bal']:>10,.2f} {r['pair']} {r['t0'][:10]} b0={r['b0']} | {r['t1'][:10]} b1={r['b1']}")
    return {"label":label,"pairs":len(rows),"usd_bal":tb,"usd_res":tr,"top":live[:12],"skimable":skim[:10]}

if __name__=="__main__":
    out={}
    out["spookyswap"]=scan("0xEE4bC42157cf65291Ba2FE839AE127e3Cc76f741","spookyswap-bttc",limit=500)
    out["intercroneswap"]=scan("0x0cEE0dFb5C680e3CcAA46FA28D5057f204E24F0a","intercroneswap-bttc",limit=500)
    json.dump(out,open("/home/heisenberg/CA/aurora-dust/analysis/l2-26-bttc2.json","w"),indent=1,default=str)
    print("done")
