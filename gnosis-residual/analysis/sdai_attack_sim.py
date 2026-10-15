#!/usr/bin/env python3
"""Exact attack economics for 1Hive Gardens sDAI pools 8/67 (Gnosis).
- Reads live F/T0/TP0/cvParams; replicates on-chain conviction/threshold integer math
  and validates against live calculateThreshold (must match exactly).
- Quadratic point system: P = isqrt(S * 1e18)  (S = HNY wei staked).
- 'Hypothetical fresh attacker IF allowlisted': buy S HNY -> stake -> drain X sDAI -> sell S HNY back.
- HNY market cost: exact multi-pool water-fill model (same as parent report) with LIVE reserves.
Read-only. No secrets."""
import json, math, urllib.request, time

RPC="https://rpc.gnosischain.com"
RPC_FB="https://gnosis-rpc.publicnode.com"
D=10_000_000; TWO_128=1<<128; TWO_127=1<<127
HNY_USD=0.978918
SDAI_USD=1.2617
GAS_USD=0.10
BLOCK_S=5.0

STR8 = "0xaa0195986ffe8f3371444fa77ee3ed04ac787eea"
STR67= "0x96dee4849a6ab9e51ae36712794318001515dc91"
SDAI = "0xaf204776c7245bF4147c2612BF6e5972Ee483701"
SEL={"cvParams":"0x2506b870","getPoolAmount":"0x4ab4ba42","totalPointsActivated":"0xaba9ffee",
     "getPoolThresholdPoints":"0x00735c98","calculateThreshold":"0x59a5db8b"}

def rpc(method,params,url=RPC):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    last=None
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=60) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            last=e; time.sleep(1.0*(a+1)); url=RPC_FB if url==RPC else RPC
    raise RuntimeError(last)

def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i+1,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    body=json.dumps(payload).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    last=None
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=90) as r: d=json.load(r)
            return {i["id"]:(i.get("result") if "error" not in i else None) for i in d}
        except Exception as e:
            last=e; time.sleep(1.0*(a+1))
    raise RuntimeError(last)

blk=int(rpc("eth_blockNumber",[]),16)
print("block:",blk)
calls=[]
for s in (STR8,STR67):
    calls += [(s,SEL["cvParams"]),(s,SEL["getPoolAmount"]),(s,SEL["totalPointsActivated"]),
              (s,SEL["getPoolThresholdPoints"])]
    for X in (250,500,1000,2000,4000,6000):
        calls.append((s,SEL["calculateThreshold"]+hex(X*10**18)[2:].rjust(64,"0")))
out=batch(calls)
POOLS={}
i=0
for pid,s in ((8,STR8),(67,STR67)):
    cv=out[i+1]; F=int(out[i+2],16); T0=int(out[i+3],16); TP0=int(out[i+4],16)
    w=[cv[2+64*k:2+64*(k+1)] for k in range(4)]
    live={}
    for k,X in enumerate((250,500,1000,2000,4000,6000)):
        live[X]=int(out[i+5+k],16)
    POOLS[pid]=dict(F=F,T0=T0,TP0=TP0,maxRatio=int(w[0],16),weight=int(w[1],16),
                    decay=int(w[2],16),minThr=int(w[3],16),live=live)
    i+=10
    print(f"pool{pid}: F={F/1e18:,.6f} sDAI  T0={T0/1e18:,.4f} pts TP0={TP0/1e18:,.4f}  cvParams={POOLS[pid]['maxRatio'],POOLS[pid]['weight'],POOLS[pid]['decay'],POOLS[pid]['minThr']}")
json.dump({"block":blk,"pools":{str(k):v for k,v in POOLS.items()}},
          open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-params-live.json","w"),indent=1,default=str)

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
    def __init__(self,pid,q):
        self.pid=pid; self.F=q["F"]; self.T0=q["T0"]; self.TP0=q["TP0"]
        self.maxRatio=q["maxRatio"]; self.weight=q["weight"]; self.decay=q["decay"]; self.minThr=q["minThr"]
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
    def conviction(self,t,P):
        at=_pow((self.decay<<128)//D,t)
        return ((P*D*(TWO_128-at))//(D-self.decay)+TWO_127)>>128
    def simulate(self,X,S,max_blocks=1_500_000):
        P=math.isqrt(S*10**18)
        T=self.T0+P
        t=0
        while t<=max_blocks:
            tp=weighted_average(self.TP0,T,t,self.decay)
            if self.conviction(t,P)>self.threshold(X,tp): return t
            t+=1
            if t>2000: t+=499
            if t>200_000: t+=999
        return None

print("\n== validation of integer threshold vs live calculateThreshold:")
allok=True
for pid,q in POOLS.items():
    p=Pool(pid,q)
    for X,lv in q["live"].items():
        mine=p.threshold(X*10**18,q["T0"])
        if mine!=(1<<256)-1 or lv!=(1<<256)-1:
            m=mine==lv; allok&=m
            if not m: print(f"  pool{pid} X={X}: mine={mine} live={lv} MATCH={m}")
print("  all match:",allok)

def min_stake(pool,X,max_blocks):
    lo,hi=1.0,3_000_000.0
    if pool.simulate(X,int(hi*10**18),max_blocks) is None: return None
    for _ in range(25):
        mid=(lo+hi)/2
        if pool.simulate(X,int(mid*10**18),max_blocks) is not None: hi=mid
        else: lo=mid
    return hi

# ---------- HNY market ----------
def rpc_batch_call(pairs):
    payload=[{"jsonrpc":"2.0","id":i+1,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(pairs)]
    body=json.dumps(payload).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req,timeout=90) as r: d=json.load(r)
    return {i["id"]:i.get("result") for i in d}
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
POOL_ADDRS=["0x4505b262dc053998c10685dc5f9098af8ae5c8ad","0x89e2f342b411032a580fefa17f96da6a5bef4112",
 "0x60d0ec09c30c07f49722f465d865bc4a3b75e1a0","0x8a0bee989c591142414ad67fb604539d917889df",
 "0x50a4867aee9cafd6ddc84de3ce59df027cb29084","0x0907239acfe1d0cfc7f960fc7651e946bb34a7b0",
 "0xd1a978936d371ca638ee091c755f8622a421f4ec","0xe3e70e8607e120dbf271e0af6b549531b37d14d8",
 "0x2f15206110e53e6d2eda74ee51ab7721076f6dd2",
 "0x8d374ab634a5a5396fce288d50cbe394a2018812"]
COUNTER={"0xe91d153e0b41518a2ce8dd3d7944fa863463a97d":("WXDAI",0.9998698103379232),
 "0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1":("WETH",None),"0xe2e73a1c69ecf83f464efce6a5be353a37ca09b2":("LINK",None),
 "0x21a42669643f45bc0e086b8fc2ed70c23d67509d":("FOX",None),"0x3a97704a1b25f08aa230ae53b352e2e72ef52843":("AGVE",None),
 "0x83ff60e2f93f8edd0637ef669c69d5fb4f64ca8e":("BRIGHT",None),"0x4291f029b9e7acb02d49428458cf6fceac545f81":("WATER",None),
 "0xcb444e90d8198415266c6a2724b7900fb12fc56e":("EURe",1.16)}
FEE=0.997
pairs=[]
for p in POOL_ADDRS: pairs += [(p,"0x0dfe1681"),(p,"0xd21220a7"),(p,"0x0902f1ac")]
out=rpc_batch_call(pairs)
pools=[]
for k,p in enumerate(POOL_ADDRS):
    t0,t1,rr=out[3*k+1],out[3*k+2],out[3*k+3]
    if not (t0 and t1 and rr and len(rr)>=2+64*3): continue
    a="0x"+t0[2+24:]; b="0x"+t1[2+24:]
    raw=bytes.fromhex(rr[2:]); r0=int.from_bytes(raw[0:32],"big"); r1=int.from_bytes(raw[32:64],"big")
    if a.lower()==HNY.lower(): R,U,ctok=r0/1e18,r1/1e18,b
    else: R,U,ctok=r1/1e18,r0/1e18,a
    if ctok not in COUNTER: continue
    pools.append({"pool":p,"HNY":R,"counter":U,"ctok":ctok,"name":COUNTER[ctok][0],"usd":COUNTER[ctok][1]})
for p in pools:
    if p["usd"] is None: p["usd"]=p["HNY"]*HNY_USD/p["counter"]
def build(scen):
    sel=[p for p in pools if scen=="all" or p["name"] in {"WXDAI","WETH","EURe"}]
    return [{"R":p["HNY"],"U":p["counter"]*p["usd"]} for p in sel]
def buy_cost(ps,S):
    SR=sum(p["R"] for p in ps)
    if S>=SR*0.999: return None
    s=sum(math.sqrt(p["R"]*p["U"]/FEE) for p in ps)
    lam=((SR-S)/s)**2
    spend=0
    for p in ps:
        a=(math.sqrt(p["R"]*p["U"]*FEE/lam)-p["U"])/FEE
        if a<0: a=0
        spend+=a
    return spend
def sell_usd(ps,Q):
    SR=sum(p["R"] for p in ps); SU=sum(p["U"] for p in ps)
    if Q>=SR*0.999: return None
    ss=sum(math.sqrt(p["R"]*p["U"]) for p in ps)
    c=(Q*FEE+SR)/ss
    mu=FEE/(c*c)
    return SU - math.sqrt(mu/FEE)*ss
liq=build("liquid"); allp=build("all")
print("\n== HNY depth live (block %d): liquid %d HNY side, all %d HNY side"%(blk,sum(p['R'] for p in liq),sum(p['R'] for p in allp)))
for p in pools: print(f"   {p['name']:7s} {p['pool']} HNY={p['HNY']:9.2f} {p['name']:6s}={p['counter']:11.2f} usd={p['usd']:.4f}")

# ---------- tables ----------
results={}
for pid,q in POOLS.items():
    pool=Pool(pid,q)
    rows=[]
    print(f"\n== pool {pid}: drainable poolAmount={q['F']/1e18:,.2f} sDAI (${q['F']/1e18*SDAI_USD:,.0f})  T0={q['T0']/1e18:.2f}pts  maxRatio={q['maxRatio']/1e7}")
    Xs=[250,500,750,1000] if pid==8 else [1500,3000,4000,5000,6000,8000]
    for X in Xs:
        Xw=X*10**18
        if pool.threshold(Xw,q["T0"])==(1<<256)-1: print(f"  X={X}: over maxRatio"); continue
        S30=min_stake(pool,Xw,30*86400//5)
        S60=min_stake(pool,Xw,60*86400//5)
        S150=min_stake(pool,Xw,150*86400//5)
        def wait(S):
            t=pool.simulate(Xw,int(S*10**18),2_000_000)
            return None if t is None else t*BLOCK_S/86400
        row={"X":X,"X_usd":round(X*SDAI_USD,2)}
        if S30:
            w=wait(S30); bc=buy_cost(liq,S30); sc=sell_usd(liq,S30); bca=buy_cost(allp,S30); sca=sell_usd(allp,S30)
            row.update(S30=round(S30),wait30=round(w,1) if w else None,
              net_real=round(X*SDAI_USD-(bc-sc)-GAS_USD,2) if bc and sc else None,
              net_opt=round(X*SDAI_USD-(bca-sca)-GAS_USD,2) if bca and sca else None,
              buy=round(bc,2) if bc else None,sell=round(sc,2) if sc else None,
              buy_all=round(bca,2) if bca else None,sell_all=round(sca,2) if sca else None)
        if S60: w6=wait(S60); row.update(S60=round(S60),wait60=round(w6,1) if w6 else None,
              net_real60=round(X*SDAI_USD-(buy_cost(liq,S60)-sell_usd(liq,S60))-GAS_USD,2) if buy_cost(liq,S60) and sell_usd(liq,S60) else None)
        if S150: w150=wait(S150); row.update(S150=round(S150),wait150=round(w150,1) if w150 else None)
        rows.append(row)
        print("  X=%5d $%8.2f | S30=%-8s net_real30=%-9s net_opt30=%-9s | S60=%-8s net60=%-9s | S150=%-8s wait150=%s"%(
            X,row["X_usd"],row.get("S30"),row.get("net_real"),row.get("net_opt"),row.get("S60"),row.get("net_real60"),
            row.get("S150"),row.get("wait150")))
    results[pid]=rows

json.dump({"block":blk,"hny_usd":HNY_USD,"sdai_usd":SDAI_USD,"pools":results,
           "hny_pools":[{"name":p["name"],"pool":p["pool"],"HNY":p["HNY"],"counter":p["counter"],"usd":p["usd"]} for p in pools]},
          open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-attack-sim.json","w"),indent=1)
print("\nsaved.")
