#!/usr/bin/env python3
"""Attack simulation: exact conviction path + realistic market cost from live pool reserves."""
import json, urllib.request, time, sys

RPC="https://rpc.gnosischain.com"
D=10_000_000; TWO_128=1<<128; TWO_127=1<<127
weight=998_926; decay=9_999_958; maxRatio=8_160_578; minThreshold=100*10**18
F=int("129f5d8685132a4d06c",16); T0=int("112d3380119bad2dc68",16)
POOL_SNAP=5065147249859933609428  # getPoolThresholdPoints() @48,767,103  (read again below if needed)
BLK0=48767221

def rpc(m,p):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req,timeout=60) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception: time.sleep(1.2*(a+1))
    raise RuntimeError("fail")
def call(to,data):
    try: return rpc("eth_call",[{"to":to,"data":data},"latest"])
    except Exception: return None

# refresh pool threshold points live
tpr=call("0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2","0x00735c98")
if tpr and tpr!="0x": POOL_SNAP=int(tpr,16)
print("POOL_SNAP(live getPoolThresholdPoints):", POOL_SNAP/1e18)

def _mul(a,b): return ((a*b)+TWO_127)>>128
def _pow(a,b):
    r=TWO_128
    while b>0:
        if b&1==0: a=_mul(a,a); b>>=1
        else: r=_mul(r,a); b-=1
    return r
def muldiv(a,b,c,ru=False):
    p=a*b; q=p//c
    if ru and p%c: q+=1
    return q
def conviction(t, staked):  # last_conv=0 at first allocation
    at=_pow((decay<<128)//D,t)
    return ((staked*D*(TWO_128-at))//(D-decay)+TWO_127)>>128
def weighted_average(snap,cur,el,dec=decay):
    f=_pow((dec<<128)//D,el)
    if cur>=snap: return cur-muldiv(cur-snap,f,TWO_128,True)
    return cur+muldiv(snap-cur,f,TWO_128,True)
def threshold(req,pool_amt,tp):
    if pool_amt>0 and maxRatio*pool_amt<=req*D: return (1<<256)-1
    rt=(req<<64)//pool_amt if pool_amt>0 else 0
    denom=(maxRatio<<64)//D - rt
    ws=(weight<<128)//D
    ratio=muldiv(ws,D,(denom*denom)>>64)
    da=ratio//(D-decay)
    thr=muldiv(da,tp,1<<64)
    return max(thr,muldiv(minThreshold,D,D-decay))

def simulate(X_hny, S_hny, max_blocks=3_000_000):
    """returns (executable, blocks_needed, days) for attacker staking S and requesting X"""
    X=int(X_hny*10**18); S=int(S_hny*10**18)
    T=T0+S
    # proposal snapshot at creation == poolTP at t0 == POOL_SNAP (approx; pool snapshot barely moves in-block)
    propSnap=POOL_SNAP
    t=0
    while t<=max_blocks:
        tp_pool=weighted_average(POOL_SNAP,T,t)      # pool snapshot drifts toward T0+S
        tp=max(propSnap,tp_pool)
        c=conviction(t,S)
        if c>threshold(X,F,tp):
            return (True,t,t*5/86400)
        t+= (1 if t<2000 else 500)
    return (False,None,None)

# ---- expected minimum-stake (asymptotic) formula for reference
import math
def S_asym(X):
    rho=weight/1e7; beta=maxRatio/1e7
    d=(beta - X/F)**2 - rho
    if d<=0: return None
    return rho*(T0/1e18)/d

print("\nAsymptotic minimum stake S for extraction X (ignore smoothing):")
for X in [100,250,500,1000,1500,2000,2500,2700]:
    s=S_asym(X)
    print(f"  X={X:5d} HNY  S_min_asym={s if s is None else round(s):>8}")

print("\nExact simulation (smoothing included):")
rows=[]
for X in [250,500,1000,1500,2000,2500]:
    # search minimal S
    lo,hi=1.0,200000.0
    best=None
    for _ in range(22):
        mid=(lo+hi)/2
        ok,t,days=simulate(X,mid)
        if ok: best=(mid,t,days); hi=mid
        else: lo=mid
    if best:
        # report at 1.25x minimal for a tractable wait
        S1=best[0]*1.25
        ok,t,days=simulate(X,S1)
        rows.append({"X":X,"S_min":round(best[0]),"days_at_min":round(best[2],1),"S_1.25x":round(S1),"days_1.25x":round(days,1)})
        print(f"  X={X:5d}  S_min≈{best[0]:,.0f} HNY (wait {best[2]:.0f} d) | 1.25×S: {S1:,.0f} HNY wait {days:.1f} d")
    else:
        print(f"  X={X:5d}  infeasible")
json.dump(rows,open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-attack-sim.json","w"),indent=1)

# ---- market cost model from live reserves
pools=[
 "0x4505b262dc053998c10685dc5f9098af8ae5c8ad",
 "0x89e2f342b411032a580fefa17f96da6a5bef4112",
 "0x8d374ab634a5a5396fce288d50cbe394a2018812",
 "0x60d0ec09c30c07f49722f465d865bc4a3b75e1a0",
 "0x8a0bee989c591142414ad67fb604539d917889df",
 "0x50a4867aee9cafd6ddc84de3ce59df027cb29084",
 "0x0907239acfe1d0cfc7f960fc7651e946bb34a7b0",
 "0xd1a978936d371ca638ee091c755f8622a421f4ec",
 "0xe3e70e8607e120dbf271e0af6b549531b37d14d8",
 "0x2f15206110e53e6d2eda74ee51ab7721076f6dd2",
]
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
liq=[]
for p in pools:
    t0=call(p,"0x0dfe1681"); t1=call(p,"0xd21220a7"); rr=call(p,"0x0902f1ac")
    if not (t0 and t1 and rr and len(rr)>=2+64*3): 
        print("pool skip (not v2?)",p); continue
    a="0x"+t0[2+24:2+64]; b="0x"+t1[2+24:2+64]
    raw=bytes.fromhex(rr[2:])
    r0=int.from_bytes(raw[0:32],"big"); r1=int.from_bytes(raw[32:64],"big")
    hny_r = r0 if a.lower()==HNY.lower() else (r1 if b.lower()==HNY.lower() else None)
    oth = r1 if a.lower()==HNY.lower() else r0
    liq.append({"pool":p,"token0":a,"token1":b,"r0":r0,"r1":r1,"hny_side":hny_r/1e18 if hny_r else 0})
    print(f"pool {p} {a[:10]}/{b[:10]} hny_side={hny_r/1e18 if hny_r else 0:,.2f} other={oth/1e18:,.2f}")
json.dump(liq,open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-hny-liquidity.json","w"),indent=1)
tot=sum(x["hny_side"] for x in liq)
print("total HNY-side depth (all v2 pools):",f"{tot:,.2f} HNY")
