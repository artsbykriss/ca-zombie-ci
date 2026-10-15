#!/usr/bin/env python3
"""Insider variant, corrected: for already-activated members their points are ALREADY inside T0
(no re-addition); for non-activated allowlisted members activation adds P to T0.
Read-only."""
import json, math, urllib.request, time

RPC="https://rpc.gnosischain.com"; RPC_FB="https://gnosis-rpc.publicnode.com"
D=10_000_000; TWO_128=1<<128; TWO_127=1<<127
SDAI_USD=1.2617; HNY_USD=0.978918; BLOCK_S=5.0

P=json.load(open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-params-live.json"))
q8={k:(int(v) if k in ("F","T0","TP0","maxRatio","weight","decay","minThr") else v) for k,v in P["pools"]["8"].items() if k!="live"}
q67={k:(int(v) if k in ("F","T0","TP0","maxRatio","weight","decay","minThr") else v) for k,v in P["pools"]["67"].items() if k!="live"}

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
def weighted_average(snap,cur,el,dec):
    f=_pow((dec<<128)//D,el)
    if cur>=snap: return cur-muldiv(cur-snap,f,TWO_128,True)
    return cur+muldiv(snap-cur,f,TWO_128,True)
class Pool:
    def __init__(self,q): self.F=q["F"]; self.T0=q["T0"]; self.TP0=q["TP0"]; self.maxRatio=q["maxRatio"]; self.weight=q["weight"]; self.decay=q["decay"]; self.minThr=q["minThr"]
    def threshold(self,X,tp):
        F=self.F
        if F>0 and self.maxRatio*F<=X*D: return (1<<256)-1
        rt=(X<<64)//F if F>0 else 0
        denom=(self.maxRatio<<64)//D - rt
        ws=(self.weight<<128)//D
        ratio=muldiv(ws,D,(denom*denom)>>64)
        da=ratio//(D-self.decay)
        thr=muldiv(da,tp,1<<64)
        return max(thr,muldiv(self.minThr,D,D-self.decay))
    def conviction(self,t,Pw):
        at=_pow((self.decay<<128)//D,t)
        return ((Pw*D*(TWO_128-at))//(D-self.decay)+TWO_127)>>128
    def simulate(self,X,S,extra_points,max_blocks):
        """S = final total stake (wei). extra_points = points NOT already in T0 (new activation)."""
        Pw=math.isqrt(S*10**18)
        T=self.T0+extra_points
        t=0
        while t<=max_blocks:
            tp=weighted_average(self.TP0,T,t,self.decay)
            if self.conviction(t,Pw)>self.threshold(X,tp): return t
            t+=1
            if t>2000: t+=499
            if t>200_000: t+=999
        return None

p8=Pool(q8); p67=Pool(q67)

def max_X(pool,Sw,add_points,max_blocks,lo=0.0):
    hi=pool.F/1e18
    if pool.simulate(int(hi*10**18),Sw,add_points,max_blocks) is not None: return hi
    if pool.simulate(int(lo*10**18),Sw,add_points,max_blocks) is None: return 0.0
    for _ in range(30):
        mid=(lo+hi)/2
        if pool.simulate(int(mid*10**18),Sw,add_points,max_blocks) is not None: lo=mid
        else: hi=mid
    return lo

# addr, stake, activated8, activated67 (from live memberActivatedInStrategies read)
ALLOW=[("0x809c9f8dd8ca93a41c3adca4972fa234c28f7714",4000.0,1,1),
 ("0xa25211b64d041f690c0c818183e32f28ba9647dd",600.0,1,1),
 ("0x07ad02e0c1fa0b09fc945ff197e18e9c256838c6",231.388566749169143826,1,1),
 ("0x8758e5741de847363dd2715a62431cc0cbda4ca6",156.0,1,0),
 ("0x14d92832265eeafdef9e526356fefc90105966c3",203.0,0,0),
 ("0x6c965b656c450259a6d4d95a2e68fb4319eecbc0",86.816671895508774808,1,1),
 ("0x2f9e113434aebdd70bb99cb6505e1f726c578d6d",57.6,1,1),
 ("0x625236038836cecc532664915bd0399647e7826b",53.0,0,0),
 ("0xc44caeb7f0724a156806664d2361fd6f32a2d2c8",23.0,0,0),
 ("0xb2206f941a5206b55bfa33e665687523a8bced80",8.0,0,1),
 ("0x8d5fe65f1e78244972af4106cdf8e559247491ae",3.1,0,0),
 ("0xdf8f53b9f83e611e1154402992c6f6cb7daf246c",3.0,0,0),
 ("0xed0f0c4de6150b7e3262e537d9691fc750b2ba23",3.0,0,0),
 ("0x8aac40061e258d6e45fd13e214710abdf356285a",3.0,0,0),
 ("0xbbbf9761ed965d8df66f416b01bbcb224aeafd4f",3.0,0,0)]

print(f"{'addr':44s} {'stake':>9s} {'P':>7s} | {'x8 30d':>8s} {'x8 150d':>8s} | {'x67 30d':>9s} {'x67 150d':>9s} | {'$30d':>9s} {'$150d':>9s}")
rows=[]
for a,S,act8,act67 in ALLOW:
    Sw=int(S*10**18); Pw=math.isqrt(Sw*10**18)
    e8=0 if act8 else Pw      # extra points added to T0 on activation
    e67=0 if act67 else Pw
    x8_30=max_X(p8,Sw,e8,30*86400//5); x8_150=max_X(p8,Sw,e8,150*86400//5)
    x67_30=max_X(p67,Sw,e67,30*86400//5); x67_150=max_X(p67,Sw,e67,150*86400//5)
    usd30=(x8_30+x67_30)*SDAI_USD; usd150=(x8_150+x67_150)*SDAI_USD
    rows.append({"addr":a,"stake":S,"points":Pw/1e18,"activated8":act8,"activated67":act67,
                 "x8_30":round(x8_30,1),"x8_150":round(x8_150,1),"x67_30":round(x67_30,1),"x67_150":round(x67_150,1),
                 "usd30":round(usd30,2),"usd150":round(usd150,2)})
    print(f"{a:44s} {S:9.1f} {Pw/1e18:7.2f} | {x8_30:8.1f} {x8_150:8.1f} | {x67_30:9.1f} {x67_150:9.1f} | {usd30:9.0f} {usd150:9.0f}")
json.dump({"note":"max drainable X (sDAI) within wait window, fixed own stake, correct T handling","rows":rows},
          open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-insider.json","w"),indent=1)

# combined: single largest member scenario detail (X per pool at 30/60/90/150d)
a,S="0x809c9f8dd8ca93a41c3adca4972fa234c28f7714",4000.0
Sw=int(S*10**18)
print("\nlargest member", a, "stake",S,"P",math.isqrt(Sw*10**18)/1e18)
for pool,tag,act in ((p8,"8",1),(p67,"67",1)):
    e=0
    for win in (30,60,90,150):
        X=max_X(pool,Sw,e,win*86400//5)
        print(f"  pool{tag} window {win}d -> X_max {X:,.1f} sDAI (${X*SDAI_USD:,.0f})")
print("saved gardens-sdai-insider.json")
