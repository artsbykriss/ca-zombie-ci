#!/usr/bin/env python3
import json, urllib.request, time
RPC='https://mainnet.aurora.dev'
def rpc_batch(calls, retries=4):
    out=[]
    for i in range(0,len(calls),8):
        chunk=calls[i:i+8]
        payload=[{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":to,"data":data},"latest"]} for j,(to,data) in enumerate(chunk)]
        for att in range(retries):
            try:
                req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
                r=json.load(urllib.request.urlopen(req,timeout=60))
                res={x["id"]:x.get("result") for x in r}
                out.extend(res.get(j) for j in range(len(chunk))); break
            except Exception as e: time.sleep(2)
        else: out.extend([None]*len(chunk))
        time.sleep(0.25)
    return out
def u(x): return int(x,16) if x and x!='0x' else None
def addr(x): return '0x'+x[-40:] if x and len(x)>=42 else None
def words(x,n=8):
    if not x: return []
    return [int(x[2+64*i:2+64*(i+1)],16) for i in range(n) if len(x)>=2+64*(i+1)]

GARDENS={
 'gardenNear':'0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D',
 'gardenUsdc':'0xfbAF3eBF228eB712b1267285787e51aDd70086bB',
 'gardenUsdt':'0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596',
 'gardenWeth':'0x084355FDd5fcfd55d60C5B8626756a6906576f13',
 'gardenAtust':'0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1',
}
SEL={'cloneInfo':'0x1d1c9390','exchangeRate':'0x3ba0b9a9','totalCollateralShare':'0x473e3ce7',
     'totalBorrow':'0x8285ef40','accrueInfo':'0xb27c0e74','roseUsd':'0x1d2eee75','feeTo':'0x017e7e58',
     'vase':'0xe53a4de2','masterContract':'0xcd446e22'}
calls=[];keys=[]
for lab,g in GARDENS.items():
    for s in SEL:
        calls.append((g,SEL[s])); keys.append((lab,s))
res=rpc_batch(calls)
out={}
for (lab,s),r in zip(keys,res):
    out.setdefault(lab,{})[s]=r
for lab in GARDENS:
    d=out[lab]
    ci=words(d['cloneInfo'],8)
    tb=words(d['totalBorrow'],4)
    ai=words(d['accrueInfo'],4)
    print(f"\n=== {lab} {GARDENS[lab]}")
    print(f"  cloneInfo: collateral={addr('0x'+format(ci[0],'040x'))} oracle={addr('0x'+format(ci[1],'040x'))} isBorrowWhitelisted={ci[2]} interestPerSec={ci[3]} liqMultiplier={ci[4]} collateralizationRate={ci[5]} borrowOpeningFee={ci[6]}")
    print(f"  exchangeRate={u(d['exchangeRate'])}")
    print(f"  totalCollateralShare={u(d['totalCollateralShare'])}")
    print(f"  totalBorrow elastic={tb[0]} base={tb[1]}")
    print(f"  accrueInfo lastAccrued={ai[0]} feesEarned={ai[1]}")
    print(f"  roseUsd={addr(d['roseUsd'])} feeTo={addr(d['feeTo'])} vase={addr(d['vase'])} master={addr(d['masterContract'])}")
json.dump({k:{kk:(v if isinstance(v,str) else v) for kk,v in vv.items()} for k,vv in out.items()}, open('gardens_state.json','w'), indent=1)
