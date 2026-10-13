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
        time.sleep(0.2)
    return out
def u(x): return int(x,16) if x and x!='0x' else None
def ei(v): return f"{v & (2**128-1):064x}"
def eu(v): return f"{v:064x}"
GDU='0x07211ef7'
METAS={'metaUST':('0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8',0.005336144306663744),
       'metaFRAX':('0xa34315F1ef49392387Dd143f4578083A9Bd33E94',0.9904415456864004),
       'metaMAI':('0x65a761136815B45A9d78d9781d22d47247B49D23',0.9962366849150541)}
print("== ROUND TRIP via exchange_underlying: USDC(idx2) -> meta(0) -> USDC(idx2)")
for lab,(p,mkt) in METAS.items():
    for x_usdc in [1,10,100,1000,5000]:
        X=x_usdc*10**6
        r=rpc_batch([(p,GDU+ei(2)+ei(0)+eu(X))])
        a=u(r[0]) if r and r[0] else None
        if not a: print(f"  {lab} {x_usdc} USDC: step1 revert"); continue
        r2=rpc_batch([(p,GDU+ei(0)+ei(2)+eu(a))])
        b=u(r2[0]) if r2 and r2[0] else None
        out_usdc = b/1e6 if b else 0
        print(f"  {lab:8s} {x_usdc:>6} USDC -> {a/1e18:>14.4f} meta -> {out_usdc:>10.4f} USDC   profit={out_usdc-x_usdc:+.4f}")
print()
print("== REVERSE ROUND TRIP: meta(0) -> USDC(idx2) -> meta(0)")
for lab,(p,mkt) in METAS.items():
    for x_meta in [1,10,100,1000]:
        X=x_meta*10**18
        r=rpc_batch([(p,GDU+ei(0)+ei(2)+eu(X))])
        a=u(r[0]) if r and r[0] else None
        if not a: print(f"  {lab} {x_meta} meta: step1 revert"); continue
        r2=rpc_batch([(p,GDU+ei(2)+ei(0)+eu(a))])
        b=u(r2[0]) if r2 and r2[0] else None
        print(f"  {lab:8s} {x_meta:>6} meta -> {a/1e6:>10.4f} USDC -> {b/1e18 if b else 0:>12.4f} meta   profit={(b/1e18-x_meta) if b else 0:+.4f}")
