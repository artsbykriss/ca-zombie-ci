#!/usr/bin/env python3
"""Enumerate Motoswap factory pairs, reserves, and balance-vs-reserve surplus."""
import json, urllib.request, time
RPC="https://ethereum-rpc.publicnode.com"
FACTORY="0x81c9cbc47d700da1777abd831d8da3f526dfae24"
SEL={"allPairs":"0x1e3dd18b","token0":"0x0dfe1681","token1":"0xd21220a7",
     "getReserves":"0x0902f1ac","totalSupply":"0x18160ddd","balanceOf":"0x70a08231"}
def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    for a in range(4):
        try:
            req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
            by={x['id']:x for x in j}
            return [by.get(i,{}).get('result','0x') for i in range(len(calls))]
        except Exception as e:
            print('retry',a,e,flush=True); time.sleep(2)
    return ['0x']*len(calls)
def w(h): return int(h,16) if h and h!='0x' else 0
def addr(h): return '0x'+h[-40:]
n=w(batch([(FACTORY,SEL['allPairs']+"%064x"%0)])[0]) if False else 20
pairs=[]
for i in range(n):
    pairs.append(addr(batch([(FACTORY,SEL['allPairs']+"%064x"%i)])[0]))
rows=[]
for s in range(0,n,4):
    chunk=pairs[s:s+4]; calls=[]
    for p in chunk:
        for k in ['token0','token1','getReserves','totalSupply']: calls.append((p,SEL[k]))
    res=batch(calls)
    for j,p in enumerate(chunk):
        t0=addr(res[4*j]); t1=addr(res[4*j+1]); rr=res[4*j+2]
        rows.append({'idx':s+j,'pair':p,'token0':t0,'token1':t1,
                     'reserve0':w(rr[2:66]),'reserve1':w(rr[2+64:2+128]),
                     'ts':w(rr[2+128:2+192]),'totalSupply':w(res[4*j+3])})
# balances
for r in rows:
    b=batch([(r['token0'],SEL['balanceOf']+"%064x"%int(r['pair'],16)),
             (r['token1'],SEL['balanceOf']+"%064x"%int(r['pair'],16))])
    r['bal0']=w(b[0]); r['bal1']=w(b[1]); r['surplus0']=r['bal0']-r['reserve0']; r['surplus1']=r['bal1']-r['reserve1']
    print(r['idx'],r['pair'],r['token0'],r['reserve0'],r['token1'],r['reserve1'],'surplus',r['surplus0'],r['surplus1'],flush=True)
json.dump(rows,open('/home/heisenberg/CA/motoswap-vampchef/analysis/motoswap_pairs.json','w'),indent=1)
print('surplus pairs',[r['idx'] for r in rows if r['surplus0']>0 or r['surplus1']>0])
