#!/usr/bin/env python3
"""Exact multi-pool (Uniswap-V2-style) routing cost for the Gardens drain attack."""
import json, math
HNY_USD = 0.978918
FEE = 0.997  # 0.3% fee kept 99.7%
# (name, HNY reserve, other reserve in units, other USD/unit)
POOLS = [
 ("WXDAI/HNY", 3217.27, 3147.11, 1.0),
 ("HNY/WETH",  1474.34, 0.61,   4000.0),
 ("HNY/WXDAI2", 97.70,  95.59,   1.0),
 ("HNY/EURe",   55.62,  48.53,   1.16),
 ("LINK/HNY",  1120.65, 90.02,   15.0),
 ("FOX/HNY",   1257.36, 243758.20, 0.0050206),
 ("AGVE/HNY",  1741.93, 48.32,   35.23),
 ("WATER/HNY", 1644.62, 33527.54, 0.04797262911),
 ("BRIGHT/HNY", 592.84, 267068.93, 0.002174038067),
]
P=[{"n":n,"R":R,"U":U*u,"u":u} for (n,R,U,u) in POOLS]

def buy_cost(S):
    """Minimum USD spend to buy S HNY from the pool set."""
    SR=sum(p["R"] for p in P)
    tot_sqrt=sum(math.sqrt(p["R"]*p["U"]/FEE) for p in P)
    if S>=SR*0.999: return None,None
    lam=((SR-S)/tot_sqrt)**2
    spend=0.0; got=0.0; alloc=[]
    for p in P:
        a=(math.sqrt(p["R"]*p["U"]*FEE/lam)-p["U"])/FEE
        if a<0: a=0.0
        outp=p["R"]*(a*FEE)/(p["U"]+a*FEE) if a>0 else 0.0
        spend+=a; got+=outp; alloc.append((p["n"],a,outp))
    return spend,got,alloc

def sell_proceeds(Q):
    """Maximum USD proceeds selling Q HNY into the pool set."""
    SR=sum(p["R"] for p in P)
    tot_sqrt=sum(math.sqrt(p["R"]*p["U"]/FEE) for p in P)
    SU=sum(p["U"] for p in P)
    if Q>=SR*0.999: return None,None
    mu=((SU-Q*0)*0+ (SU / 1))  # placeholder
    # From water-fill: q_i = (sqrt(U_i R_i FEE/mu) - R_i)/FEE ; total out = sum U_i - sum sqrt(U_i R_i mu /FEE)
    # total out = SELL_USD = SU - sqrt(mu/FEE)*sum sqrt(U_i R_i)
    # and sum q_i = Q = (1/FEE)( sqrt(FEE/mu) * sum sqrt(U_i R_i) - SR )
    tot_sqrt_ur=sum(math.sqrt(p["R"]*p["U"]) for p in P)
    # solve: Q*FEE = sqrt(FEE/mu)*tot_sqrt_ur - SR -> sqrt(FEE/mu) = (Q*FEE+SR)/tot_sqrt_ur
    # -> mu = FEE / ((Q*FEE+SR)/tot_sqrt_ur)^2
    c=(Q*FEE+SR)/tot_sqrt_ur
    mu=FEE/(c*c)
    out=SU - math.sqrt(mu/FEE)*tot_sqrt_ur
    alloc=[]; sold=0.0
    for p in P:
        q=(math.sqrt(p["U"]*p["R"]*FEE/mu)-p["R"])/FEE if p["R"]<math.sqrt(p["U"]*p["R"]*FEE/mu) else 0.0
        q=max(0.0,q)
        outp=p["U"]*(q*FEE)/(p["R"]+q*FEE) if q>0 else 0.0
        sold+=q; alloc.append((p["n"],q,outp))
    return out,sold,alloc

print("Total HNY-side depth:", f"{sum(p['R'] for p in P):,.0f} HNY (${sum(p['U'] for p in P):,.0f} other-side)")
print(f"\n{'X':>6} {'S':>6} {'buyUSD':>9} {'sellUSD':>9} {'netUSD':>9} {'extractUSD':>10} {'net/extract':>11}")
rows=[]
combos=[(10,1025),(100,1025),(250,1025),(250,1282),(500,1189),(500,1486),(1000,1676),(1000,2095),(2000,4843),(2000,6053),(2500,16559)]
for X,S in combos:
    sp,got,_=buy_cost(S)
    pr,_,_=sell_proceeds(S+X)
    if sp is None or pr is None: print(X,S,"too big"); continue
    rows.append({"X":X,"S":S,"buy_usd":round(sp,2),"sell_usd":round(pr,2),"net_usd":round(pr-sp,2),"extract_usd":round(X*HNY_USD,2)})
    print(f"{X:>6} {S:>6} {sp:>9,.0f} {pr:>9,.0f} {pr-sp:>9,.0f} {X*HNY_USD:>10,.0f} {(pr-sp)/(X*HNY_USD):>11.2f}")
json.dump(rows,open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-market-cost.json","w"),indent=1)

print("\nMinimum-cost attack (X→0):")
for X,S in [(1,895),(1,1025),(1,1200)]:
    sp,got,_=buy_cost(S); pr,_,_=sell_proceeds(S+X)
    print(f"  X={X} S={S}: buy ${sp:,.0f} sell ${pr:,.0f} net ${pr-sp:,.0f} extract ${X*HNY_USD:.2f}")

print("\nBreak-even check: is there ANY X where net>=0?")
best=(-1e18,None)
for X in range(1,2700,25):
    Slo=900.0; Shi=40000.0
    for _ in range(60):
        mid=(Slo+Shi)/2
        sp,got,_=buy_cost(mid); pr,_,_=sell_proceeds(mid+X)
        if sp is None or pr is None: Shi=mid; continue
        if pr-sp>0: Shi=mid
        else: Slo=mid
    sp,got,_=buy_cost(Shi); pr,_,_=sell_proceeds(Shi+X)
    net=pr-sp if (sp is not None and pr is not None) else float('-inf')
    if net>best[0]: best=(net,(X,round(Shi)))
print("  best net:", round(best[0],2), "at (X,S)=", best[1])
