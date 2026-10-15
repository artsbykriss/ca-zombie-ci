#!/usr/bin/env python3
"""Final market model: parity-normalized multi-pool routing (no fake cross-pool arb)."""
import json, math
HNY_USD=0.978918; FEE=0.997
# (name, HNY reserve, counter-asset, counter reserve units, tradable counter USD price)
RAW=[
 ("WXDAI/HNY", 3217.27, "WXDAI", 3147.11, 1.0),
 ("HNY/WETH",  1474.34, "WETH",  0.6128,  2366.0),   # ETH priced at pool parity (~2366)
 ("HNY/WXDAI2", 97.70,  "WXDAI", 95.59,   1.0),
 ("HNY/EURe",   55.62,  "EURe",  48.53,   1.16),
 ("LINK/HNY",  1120.65, "LINK",  90.02,   12.19),    # LINK at pool parity
 ("FOX/HNY",   1257.36, "FOX",   243758.20, 0.005050),
 ("AGVE/HNY",  1741.93, "AGVE",  48.32,   35.30),
 ("WATER/HNY", 1644.62, "WATER", 33527.54, 0.04803),
 ("BRIGHT/HNY", 592.84, "BRIGHT",267068.93,0.002174),
]
def build(subset):
    return [{"n":n,"R":R,"U":U*u,"liq":liq} for (n,R,c,U,u,liq) in subset]
ALL=[(n,R,c,U,U,True) for (n,R,c,U,u) in RAW]
LIQ=[(n,R,c,U,U,True) for (n,R,c,U,u) in RAW if c in ("WXDAI","WETH","EURe")]

def buy_cost(pools,S):
    SR=sum(p["R"] for p in pools)
    if S>=SR*0.999: return None
    s=sum(math.sqrt(p["R"]*p["U"]/FEE) for p in pools)
    lam=((SR-S)/s)**2
    spend=0
    for p in pools:
        a=(math.sqrt(p["R"]*p["U"]*FEE/lam)-p["U"])/FEE
        if a<0: a=0
        spend+=a
    return spend
def sell_usd(pools,Q):
    SR=sum(p["R"] for p in pools); SU=sum(p["U"] for p in pools)
    if Q>=SR*0.999: return None
    ss=sum(math.sqrt(p["R"]*p["U"]) for p in pools)
    c=(Q*FEE+SR)/ss
    mu=FEE/(c*c)
    return SU - math.sqrt(mu/FEE)*ss

rows=[]
for name,subset in [("liquid-only (xDAI/WETH/EURe)",LIQ),("all-pools parity (optimistic)",ALL)]:
    pools=build(subset)
    print(f"\n== {name}: depth {sum(p['R'] for p in pools):,.0f} HNY (${sum(p['U'] for p in pools):,.0f})")
    print(f"   {'X':>6} {'S':>6} {'buy$':>9} {'sell$':>9} {'net$':>9} {'extract$':>9}")
    for X,S in [(100,1025),(250,1025),(500,1189),(500,1486),(1000,1676),(1000,2095),(1500,2595)]:
        sp=buy_cost(pools,S); pr=sell_usd(pools,S+X)
        if sp is None or pr is None: continue
        rows.append({"scenario":name,"X":X,"S":S,"buy":round(sp,2),"sell":round(pr,2),"net":round(pr-sp,2),"extract":round(X*HNY_USD,2)})
        print(f"   {X:>6} {S:>6} {sp:>9,.0f} {pr:>9,.0f} {pr-sp:>9,.0f} {X*HNY_USD:>9,.0f}")
json.dump(rows,open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-market-final.json","w"),indent=1)
# break-even search under realistic scenario
pools=build(LIQ)
best=(-1e18,None)
for X in range(10,2600,10):
    for S in range(900,12001,50):
        sp=buy_cost(pools,S); pr=sell_usd(pools,S+X)
        if sp is None or pr is None: continue
        net=pr-sp
        if net>best[0]: best=(net,(X,S))
print("\nBest-case net (liquid-only, exhaustive grid up to S=12k):",round(best[0],2),"at (X,S)=",best[1])
