#!/usr/bin/env python3
"""For each zkSwap pair: compare token balances vs stored reserves (skim surplus)."""
import json, urllib.request, time
rows=json.load(open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_pairs.json'))
RPC="https://mainnet.era.zksync.io"
SEL_BAL="0x70a08231"  # balanceOf(address)

def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    for a in range(5):
        try:
            req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
            by={x['id']:x for x in j}
            return [by.get(i,{}).get('result','0x') for i in range(len(calls))]
        except Exception as e:
            print('retry',a,e,flush=True); time.sleep(2+2*a)
    return ['0x']*len(calls)
def w(h): return int(h,16) if h and h!='0x' else None

out=[]
for s in range(0,len(rows),6):
    chunk=rows[s:s+6]; calls=[]
    for r in chunk:
        for tok in (r['token0'],r['token1']):
            calls.append((tok,SEL_BAL+'%064x'%int(r['pair'],16)))
    res=batch(calls)
    for i,r in enumerate(chunk):
        b0=w(res[2*i]); b1=w(res[2*i+1])
        r['bal0']=b0; r['bal1']=b1
        r['surplus0']=None if b0 is None else b0-r['reserve0']
        r['surplus1']=None if b1 is None else b1-r['reserve1']
        out.append(r)
        print(r['idx'],r['pair'],'surplus',r['surplus0'],r['surplus1'],flush=True)
json.dump(out,open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_balances.json','w'),indent=1)
print('nonzero surplus:')
for r in out:
    if (r['surplus0'] or 0)>0 or (r['surplus1'] or 0)>0:
        print(r['idx'],r['pair'],r['token0'],r['surplus0'],r['token1'],r['surplus1'])
