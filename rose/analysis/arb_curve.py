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
def enc_i128(v): return f"{v & (2**128-1):064x}"
def enc_u256(v): return f"{v:064x}"
GETDY='0x5e0d443f'; GDU='0x07211ef7'
# price inputs
UST_MKT=0.005336144306663744; FRAX_MKT=0.9904415456864004; MAI_MKT=0.9962366849150541
VP=1.00000028945739693  # 3pool LP virtual price
POOLS={
 'metaUST':('0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8', UST_MKT, [10**18,10**19,10**20,3*10**20,10**21,2*10**21,3*10**21,4*10**21,5*10**21,6*10**21,10**22,2*10**22,5*10**22]),
 'metaFRAX':('0xa34315F1ef49392387Dd143f4578083A9Bd33E94', FRAX_MKT, [10**18,10**20,5*10**20,10**21,15*10**20,2*10**21,25*10**20,3*10**21]),
 'metaMAI':('0x65a761136815B45A9d78d9781d22d47247B49D23', MAI_MKT, [10**17,10**18,10**19,5*10**19,78*10**18]),
}
calls=[];keys=[]
for lab,(p,mkt,sizes) in POOLS.items():
    for sz in sizes:
        calls.append((p,GETDY+enc_i128(0)+enc_i128(1)+enc_u256(sz))); keys.append((lab,sz))
res=rpc_batch(calls)
print(f"{'pool':9s} {'dx(in)':>16s} {'dy(LP out)':>16s} {'avg LP/in':>10s} {'mkt$':>8s} {'profit$':>9s}")
for (lab,sz),r in zip(keys,res):
    dy=u(r) or 0
    mkt=POOLS[lab][1]
    dxu=sz/1e18
    avg=dy/1e18/dxu
    profit=dy/1e18*VP - dxu*mkt
    print(f"{lab:9s} {dxu:>16.0f} {dy/1e18:>16.4f} {avg:>10.6f} {mkt:>8.4f} {profit:>9.2f}")
