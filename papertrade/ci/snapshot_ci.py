#!/usr/bin/env python3
"""Z3-C3 Papertrade — CI live re-verification (read-only, stdlib only, no secrets).
Writes: ci-out/papertrade_ci.json, ci-out/headroom_series.json, ci-out/economics.json, ci-out/summary.txt
"""
import json, time, os, sys, urllib.request, urllib.parse
from hashlib import sha3_256  # placeholder; keccak implemented below

# ---- minimal keccak256 (pure python, for storage key hashing) ----
_KECCAK_RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
_KECCAK_R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
_MASK64 = (1<<64)-1
def _rotl(x,n): return ((x<<n)|(x>>(64-n)))&_MASK64
def _keccak_f(a):
    for rnd in range(24):
        c=[a[x][0]^a[x][1]^a[x][2]^a[x][3]^a[x][4] for x in range(5)]
        d=[c[(x-1)%5]^_rotl(c[(x+1)%5],1) for x in range(5)]
        for x in range(5):
            for y in range(5): a[x][y]^=d[x]
        b=[[0]*5 for _ in range(5)]
        for x in range(5):
            for y in range(5): b[y][(2*x+3*y)%5]=_rotl(a[x][y],_KECCAK_R[x][y])
        for x in range(5):
            for y in range(5): a[x][y]=b[x][y]^((~b[(x+1)%5][y])&b[(x+2)%5][y])
        a[0][0]^=_KECCAK_RC[rnd]
    return a
def keccak256(data: bytes) -> bytes:
    rate=136; p=bytearray(data); p.append(0x01)
    while len(p)%rate!=0: p.append(0)
    p[-1]^=0x80
    a=[[0]*5 for _ in range(5)]
    for off in range(0,len(p),rate):
        blk=p[off:off+rate]
        for i in range(rate//8):
            lane=int.from_bytes(blk[i*8:(i+1)*8],'little')
            a[i%5][i//5]^=lane
        _keccak_f(a)
    out=b''
    for i in range(4):
        out+=a[i%5][i//5].to_bytes(8,'little')
    return out

RPCS = ["https://rpc.hyperliquid.xyz/evm", "https://hyperliquid.drpc.org"]
EX = "0x6cd5661646289fb6e65ea5c032310fded797d0a2"
ORACLE = "0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"
BATCH = "0x233Ff29b239abc1D7748605dA9b205C3e008626E"
KEEPER = "0x3721476DE31190DC1AF8908026abe20efE25cf99"
EIP1967 = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
MASK96=2**96-1; MASK128=2**128-1
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ci-out")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)

U = None
def rpc(method, params, retries=3):
    global U
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for url in ([U] if U else RPCS):
        for i in range(retries):
            try:
                req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
                j=json.loads(urllib.request.urlopen(req,timeout=25).read())
                if "result" in j:
                    U=url
                    return j["result"]
                last=j
            except Exception as e:
                last=e; time.sleep(1)
    raise RuntimeError(f"rpc failed: {last}")

def call(to,data,block="latest"):
    r=rpc("eth_call",[{"to":to,"data":data},block])
    return r

def storage(addr,slot,block="latest"):
    return rpc("eth_getStorageAt",[addr,slot,block])

def slot_hash(mid, base):
    key=bytes.fromhex(format(mid,'064x')+format(base,'064x'))
    return "0x"+keccak256(key).hex()

def snapshot():
    bn=int(rpc("eth_blockNumber",[]),16); blk=hex(bn)
    snap={"block":bn,"impls":{}}
    for name,a in (("exchange",EX),("oracle",ORACLE),("batchExecutor",BATCH)):
        snap["impls"][name]="0x"+storage(a,EIP1967,blk)[-40:]
    views={"tradingPaused":"0x53e23e2e","lpBankrollAvailable":"0x0cdd5fc4","totalLockedMargin":"0x01ad056f",
           "totalQueued":"0x53ac4b66","totalBalances":"0xa69a2ad1","oracle":"0x7dc0d1d0",
           "pauseGuardian":"0x24a3d622","marketKeeper":"0x21f55a6c","nextPositionId":"0x899346c7"}
    v={}
    for k,sel in views.items(): v[k]=call(EX,sel,blk)
    snap["tradingPaused"]=int(v["tradingPaused"],16)
    snap["lpBankrollAvailable_usd"]=int(v["lpBankrollAvailable"],16)/1e18
    snap["totalLockedMargin_usd"]=int(v["totalLockedMargin"],16)/1e18
    snap["totalQueued_usd"]=int(v["totalQueued"],16)/1e18
    snap["totalBalances_usd"]=int(v["totalBalances"],16)/1e18
    snap["pauseGuardian"]="0x"+v["pauseGuardian"][-40:]
    snap["marketKeeper"]="0x"+v["marketKeeper"][-40:]
    snap["nextPositionId"]=int(v["nextPositionId"],16)
    snap["exchange_slot_0x58"]="0x"+storage(EX,hex(0x58),blk)[-40:]
    # oracle impl hash (detects any upgrade)
    code=rpc("eth_getCode",[snap["impls"]["oracle"],"latest"])
    snap["oracle_impl_bytes"]=(len(code)-2)//2
    snap["oracle_impl_keccak"]="0x"+keccak256(bytes.fromhex(code[2:])).hex()
    # BBO + markets
    snap["bbo"]={}
    for asset,scale in ((0,10.0),(1,100.0)):
        r=call(ORACLE,"0xfb466481"+format(asset,'064x'),blk)
        bid=int(r[2:66],16); ask=int(r[66:130],16)
        snap["bbo"][str(asset)]={"bid":bid/scale,"ask":ask/scale,"mid":(bid+ask)/2/scale,
                                 "spread_bp":(ask-bid)/((bid+ask)/2)*10000}
    snap["markets"]={}
    for mid,name in ((0,"BTC"),(1,"ETH")):
        h=slot_hash(mid,0x24)
        s0=int(storage(EX,h,blk),16); s1=int(storage(EX,"0x"+format(int(h,16)+1,'064x'),blk),16)
        rec={"longOI":(s0&MASK96)/1e18,"shortOI":((s0>>96)&MASK96)/1e18,
             "longCap":(s1&MASK128)/1e18,"shortCap":((s1>>128)&MASK128)/1e18}
        rec["longHeadroom"]=rec["longCap"]-rec["longOI"]
        rec["shortHeadroom"]=rec["shortCap"]-rec["shortOI"]
        px=snap["bbo"][str(mid)]["mid"]
        rec["px"]=px
        rec["longHeadroom_usd"]=rec["longHeadroom"]*px
        rec["shortHeadroom_usd"]=rec["shortHeadroom"]*px
        snap["markets"][name]=rec
    # instruments
    snap["instruments"]={}
    for mid,name in ((0,"BTC"),(1,"ETH")):
        r=call(EX,"0xdc8a47ef"+format(mid,'064x'),blk)
        w=[int(r[2+i*64:2+(i+1)*64],16) for i in range(8)]
        snap["instruments"][name]={"rateMultiplier":w[0]/1e18,"positionMultiplier":w[1]/1e18,
            "assetIndex":w[2],"maxLeverage":w[3],"maxPositionNotional":w[4]/1e18,
            "liqOffset":w[5]/1e18,"baseRate":w[6]/1e18,"referenceNotional":w[7]/1e18}
    return snap

def keeper_crosscheck(snap):
    """Fetch the keeper's latest setOiCaps calldata (Etherscan v2 if key in env) and compare to storage."""
    key=os.environ.get("ETHERSCANV2_API_KEY")
    if not key: return {"skipped":"no ETHERSCANV2_API_KEY"}
    url=("https://api.etherscan.io/v2/api?chainid=999&apikey=%s&%s" %
         (key, urllib.parse.urlencode({"module":"account","action":"txlist","address":KEEPER,
                                       "page":1,"offset":8,"sort":"desc"})))
    try:
        req=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"})
        res=json.loads(urllib.request.urlopen(req,timeout=30).read()).get("result",[])
    except Exception as e:
        return {"error":str(e)[:100]}
    out={"txs":[]}
    seen=set()
    for t in res:
        inp=t.get("input","")
        if inp.startswith("0x628a9fd6"):
            inst=int(inp[10:74],16); a=int(inp[74:138],16); b=int(inp[138:202],16)
            if inst in seen: continue
            seen.add(inst)
            name={0:"BTC",1:"ETH"}.get(inst)
            row={"block":int(t["blockNumber"],16),"inst":inst,"keeper_a":a/1e18,"keeper_b":b/1e18}
            if name and name in snap["markets"]:
                row["storage_longCap_at_snapshot"]=snap["markets"][name]["longCap"]
                row["storage_shortCap_at_snapshot"]=snap["markets"][name]["shortCap"]
            out["txs"].append(row)
    return out

def sample_series(minutes=10, interval=20):
    series=[]
    end=time.time()+minutes*60
    while time.time()<end:
        try:
            bn=int(rpc("eth_blockNumber",[]),16); blk=hex(bn)
            rec={"t":int(time.time()),"block":bn}
            for mid,name in ((0,"BTC"),(1,"ETH")):
                h=slot_hash(mid,0x24)
                s0=int(storage(EX,h,blk),16); s1=int(storage(EX,"0x"+format(int(h,16)+1,'064x'),blk),16)
                lo=(s0&MASK96)/1e18; so=((s0>>96)&MASK96)/1e18
                lc=(s1&MASK128)/1e18; sc=((s1>>128)&MASK128)/1e18
                rec[name]={"longOI":lo,"shortOI":so,"longCap":lc,"shortCap":sc,
                           "hrLong":lc-lo,"hrShort":sc-so}
            r=call(ORACLE,"0xfb466481"+format(0,'064x'),blk)
            rec["btc_mid"]=(int(r[2:66],16)+int(r[66:130],16))/2/10
            r=call(ORACLE,"0xfb466481"+format(1,'064x'),blk)
            rec["eth_mid"]=(int(r[2:66],16)+int(r[66:130],16))/2/100
            series.append(rec)
        except Exception as e:
            series.append({"t":int(time.time()),"err":str(e)[:100]})
        time.sleep(interval)
    return series

# ---- cost table (from analysis/child3-cost-model.json, mechB round trip; USD) ----
COST = {
 "BTC": {"up": {5:{"sweep":15.47e6,"sweep_bp":2.8,"unwind_bp":3.7,"rt225":17e3,"rt450":24e3},
                10:{"sweep":30.23e6,"sweep_bp":5.0,"unwind_bp":6.2,"rt225":47e3,"rt450":61e3},
                15:{"sweep":43.36e6,"sweep_bp":7.3,"unwind_bp":8.9,"rt225":90e3,"rt450":109e3},
                30:{"sweep":57.08e6,"sweep_bp":10.9,"unwind_bp":13.5,"rt225":164e3,"rt450":190e3}},
        "down":{5:{"sweep":11.02e6,"sweep_bp":3.0,"unwind_bp":2.2,"rt225":11e3,"rt450":16e3},
                10:{"sweep":25.98e6,"sweep_bp":5.4,"unwind_bp":4.4,"rt225":37e3,"rt450":49e3},
                15:{"sweep":35.81e6,"sweep_bp":7.3,"unwind_bp":6.0,"rt225":64e3,"rt450":80e3},
                30:{"sweep":53.72e6,"sweep_bp":12.1,"unwind_bp":9.8,"rt225":142e3,"rt450":166e3}}},
 "ETH": {"up": {5:{"sweep":5.22e6,"sweep_bp":2.9,"unwind_bp":3.3,"rt225":6e3,"rt450":8e3},
                10:{"sweep":12.23e6,"sweep_bp":5.1,"unwind_bp":6.6,"rt225":20e3,"rt450":25e3},
                15:{"sweep":17.74e6,"sweep_bp":7.4,"unwind_bp":8.9,"rt225":37e3,"rt450":45e3},
                30:{"sweep":29.28e6,"sweep_bp":13.4,"unwind_bp":15.5,"rt225":98e3,"rt450":111e3}},
        "down":{5:{"sweep":4.66e6,"sweep_bp":3.1,"unwind_bp":2.7,"rt225":5e3,"rt450":7e3},
                10:{"sweep":9.94e6,"sweep_bp":5.2,"unwind_bp":4.4,"rt225":14e3,"rt450":18e3},
                15:{"sweep":15.08e6,"sweep_bp":7.6,"unwind_bp":6.3,"rt225":28e3,"rt450":35e3},
                30:{"sweep":25.40e6,"sweep_bp":13.0,"unwind_bp":11.2,"rt225":73e3,"rt450":85e3}}},
}
MULT={"BTC":814.598,"ETH":483.979}
def payout(N,move_bp,mk):
    me=max(move_bp/1e4-0.00002,0)
    if me<=0: return 0.0
    t1=1/(me*15000.0); t2=100000.0/(1e6*me*MULT[mk])
    return N*me*(0.9/(1+t1+t2))*0.98

def economics(snap):
    out={"payout_per_1M":{},"instant":{},"breakeven":{}}
    for mk in ("BTC","ETH"):
        out["payout_per_1M"][mk]={m:round(payout(1e6,m,mk),2) for m in (5,10,15,30,60)}
    for mk in ("BTC","ETH"):
        for d,hrkey in (("up","longHeadroom_usd"),("down","shortHeadroom_usd")):
            N=snap["markets"][mk][hrkey]
            for m in (5,10,15,30):
                c=COST[mk][d][m]
                pay=payout(N,m,mk)
                slow=c["sweep"]*(c["sweep_bp"]+2.0)/1e4 + (c["sweep"]*2)*2.25/1e4
                be_fast=c["rt225"]/payout(1e6,m,mk)*1e6
                be_slow=slow/payout(1e6,m,mk)*1e6
                out["instant"].setdefault(mk,{}).setdefault(d,{})[m]={
                    "N_usd":round(N),"payout_usd":round(pay),"cost_225bp":c["rt225"],"net_225bp":round(pay-c["rt225"]),
                    "net_slowunwind":round(pay-slow)}
                out["breakeven"].setdefault(mk,{}).setdefault(d,{})[m]={
                    "N_225bp":round(be_fast),"N_slowunwind":round(be_slow)}
    return out

def main():
    print("[ci] probing RPC ...")
    bn=int(rpc("eth_blockNumber",[]),16)
    print("[ci] RPC ok, block", bn, "via", U)
    snap=snapshot()
    print("[ci] snapshot at block", snap["block"])
    kc=keeper_crosscheck(snap)
    print("[ci] keeper crosscheck:", json.dumps(kc)[:200])
    print("[ci] sampling headroom series (10 min @20s) ...")
    series=sample_series(10,20)
    econ=economics(snap)
    json.dump(snap,open(os.path.join(OUT,"papertrade_ci.json"),"w"),indent=1)
    json.dump({"series":series},open(os.path.join(OUT,"headroom_series.json"),"w"),indent=1)
    json.dump({"economics":econ,"keeper_crosscheck":kc},open(os.path.join(OUT,"economics.json"),"w"),indent=1)
    lines=[]
    lines.append(f"Papertrade Z3-C3 CI re-verification — block {snap['block']} — {time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime())} UTC")
    lines.append(f"tradingPaused={snap['tradingPaused']}  lpBankroll=${snap['lpBankrollAvailable_usd']:,.2f}  totalQueued=${snap['totalQueued_usd']:,.2f}")
    lines.append(f"impls: exchange={snap['impls']['exchange']} oracle={snap['impls']['oracle']} batch={snap['impls']['batchExecutor']}")
    lines.append(f"oracle impl keccak={snap['oracle_impl_keccak']} ({snap['oracle_impl_bytes']} bytes)")
    for mk in ("BTC","ETH"):
        m=snap["markets"][mk]
        lines.append(f"{mk}: px={m['px']:.2f} longOI={m['longOI']:.2f} shortOI={m['shortOI']:.2f} "
                     f"longHR=${m['longHeadroom_usd']:,.0f} shortHR=${m['shortHeadroom_usd']:,.0f}")
    lines.append("instant-headroom net per cycle (2.25bp fees, taker unwind):")
    for mk in ("BTC","ETH"):
        for d in ("up","down"):
            for m in (5,10,15,30):
                r=econ["instant"][mk][d][m]
                lines.append(f"  {mk} {d} {m}bp: N=${r['N_usd']:,} payout=${r['payout_usd']:,} net=${r['net_225bp']:,} (slow-unwind net=${r['net_slowunwind']:,})")
    lines.append("break-even deployable N (USD):")
    for mk in ("BTC","ETH"):
        for d in ("up","down"):
            for m in (5,10,15,30):
                b=econ["breakeven"][mk][d][m]
                lines.append(f"  {mk} {d} {m}bp: ${b['N_225bp']:,} (slow-unwind ${b['N_slowunwind']:,})")
    ok=[s for s in series if "BTC" in s]
    if ok:
        import statistics as st
        for mk in ("BTC","ETH"):
            for side in ("hrLong","hrShort"):
                v=[s[mk][side]*s[mk+"_mid" if False else ("btc_mid" if mk=="BTC" else "eth_mid")] for s in ok]
                lines.append(f"headroom series {mk} {side}: min=${min(v):,.0f} max=${max(v):,.0f} median=${st.median(v):,.0f} ({len(ok)} samples)")
    txt="\n".join(lines)+"\n"
    open(os.path.join(OUT,"summary.txt"),"w").write(txt)
    print(txt)
    print("[ci] done")

if __name__=="__main__":
    main()
