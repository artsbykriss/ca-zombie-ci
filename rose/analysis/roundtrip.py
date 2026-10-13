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
GETDY='0x5e0d443f'; GDU='0x07211ef7'
META={'metaUST':('0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8',0.005336144306663744),
      'metaFRAX':('0xa34315F1ef49392387Dd143f4578083A9Bd33E94',0.9904415456864004),
      'metaMAI':('0x65a761136815B45A9d78d9781d22d47247B49D23',0.9962366849150541)}
POOLA='0xc90dB0d8713414d78523436dC347419164544A3f'
# Test A: underlying round trip base coin(1=DAI,2=USDC,3=USDT) -> meta token(0) -> back
sizes=[10**18,10**20,10**21,3*10**21,10**22]
print("== underlying round-trip: base coin (idx2=USDC) -> meta(0) -> base coin(2), for metas")
for lab,(p,mkt) in META.items():
    for X in sizes:
        calls=[(p,GDU+ei(2)+ei(0)+eu(X)),(p,GDU+ei(0)+ei(2)+eu(10**30))]  # second needs dynamic
        r=rpc_batch([(p,GDU+ei(2)+ei(0)+eu(X))])
        a=u(r[0]) if r and r[0] else None
        if not a: print(f"  {lab} X={X}: step1 failed"); continue
        r2=rpc_batch([(p,GDU+ei(0)+ei(2)+eu(a))])
        b=u(r2[0]) if r2 and r2[0] else None
        print(f"  {lab} USDC {X/1e6:>8.2f} -> {a/1e18 if a else 0:>12.4f} meta -> back {b/1e6 if b else 0:>10.4f} USDC  profit={((b-X)/1e6) if b else 0:+.4f}")
# Test B: 3pool round trip
print("== 3pool DAI->USDC->DAI")
for X in [10**18,10**21,10**22]:
    r=rpc_batch([(POOLA,GETDY+ei(0)+ei(1)+eu(X))])
    a=u(r[0]) if r and r[0] else None
    if not a: print('  fail'); continue
    r2=rpc_batch([(POOLA,GETDY+ei(1)+ei(0)+eu(a))])
    b=u(r2[0]) if r2 and r2[0] else None
    print(f"  DAI {X/1e18:.2f} -> USDC {a/1e6:.4f} -> DAI {b/1e18 if b else 0:.6f}  profit={( (b-X)/1e18) if b else 0:+.6f}")
# Test C: meta pool route consistency: USDC ->(underlying) meta vs USDC ->3pool LP -> meta
print("== route compare: USDC -> underlying UST/FRAX/MAI  vs  USDC->3poolLP->meta")
for lab,(p,mkt) in META.items():
    for X in [10**21, 10**22]:
        r=rpc_batch([(p,GDU+ei(2)+ei(0)+eu(X))])
        direct=u(r[0]) if r and r[0] else None
        # route2: USDC -> LP via 3pool (idx1->? USDC is coin1 in 3pool) then LP -> meta via get_dy(1->0)
        r2=rpc_batch([(POOLA,GETDY+ei(1)+ei(2)+eu(X))])  # USDC->USDT? no. 3pool coins: 0 DAI,1 USDC,2 USDT. LP not a coin.
        # correct: 3pool add_liquidity then meta exchange; approximate with get_virtual_price: LP amount = X * 1e18/vprice
        lp = int(X * 10**18 / 1000000289745739693)
        r3=rpc_batch([(p,GETDY+ei(1)+ei(0)+eu(lp))])
        via=u(r3[0]) if r3 and r3[0] else None
        print(f"  {lab} X={X/1e6:.0f} USDC: direct={direct/1e18 if direct else 0:.4f} meta, via-LP={via/1e18 if via else 0:.4f} meta")
