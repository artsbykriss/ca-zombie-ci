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
def enc_i128(v): return f"{v & (2**128-1):064x}"
def enc_u256(v): return f"{v:064x}"
POOLS={
 '3pool': '0xc90dB0d8713414d78523436dC347419164544A3f',
 'metaUST':'0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8',
 'metaFRAX':'0xa34315F1ef49392387Dd143f4578083A9Bd33E94',
 'metaMAI':'0x65a761136815B45A9d78d9781d22d47247B49D23',
}
SEL_GETDY='0x5e0d443f'   # get_dy(int128,int128,uint256)
SEL_GDU='0x07211ef7'     # get_dy_underlying(int128,int128,uint256)
# sizes per pool
SIZES={
 '3pool':[10**6,10**8,10**10,10**12],
 'metaUST':[10**18,10**20,10**21,10**22,57*10**21],
 'metaFRAX':[10**18,10**21,10**22,3*10**21],
 'metaMAI':[10**18,10**20,10**21,78*10**18],
}
calls=[];keys=[]
for lab,p in POOLS.items():
    for sz in SIZES[lab]:
        # direction 0->1 (token0 in)
        calls.append((p,SEL_GETDY+enc_i128(0)+enc_i128(1)+enc_u256(sz))); keys.append((lab,'0->1',sz))
        # direction 1->0
        calls.append((p,SEL_GETDY+enc_i128(1)+enc_i128(0)+enc_u256(sz))); keys.append((lab,'1->0',sz))
    # underlying for metas
    for sz in SIZES[lab][:3]:
        calls.append((p,SEL_GDU+enc_i128(0)+enc_i128(1)+enc_u256(sz))); keys.append((lab,'under0->1',sz))
        calls.append((p,SEL_GDU+enc_i128(1)+enc_i128(0)+enc_u256(sz))); keys.append((lab,'under1->0',sz))
res=rpc_batch(calls)
for (lab,d,sz),r in zip(keys,res):
    print(f"{lab:8s} {d:10s} dx={sz:>22d} => dy={u(r)}")
