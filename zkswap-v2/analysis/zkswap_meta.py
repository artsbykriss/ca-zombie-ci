#!/usr/bin/env python3
"""Decode zkSwap pairs: symbols/decimals + DefiLlama prices; derive TVL."""
import json, urllib.request, time

rows=json.load(open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_pairs.json'))
toks=sorted(set([r['token0'] for r in rows]+[r['token1'] for r in rows]))
SEL={'symbol':'0x95d89b41','decimals':'0x313ce567'}

def rpc_batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    req=urllib.request.Request("https://mainnet.era.zksync.io",data=json.dumps(payload).encode(),
        headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
    by={x['id']:x for x in j}
    return [by.get(i,{}).get('result','0x') for i in range(len(calls))]

def dec_str(h):
    if not h or h=='0x': return ''
    b=bytes.fromhex(h[2:])
    if len(b)>=64:
        off=int.from_bytes(b[:32],'big'); ln=int.from_bytes(b[off:off+32],'big')
        return b[off+32:off+32+ln].decode('utf8','replace')
    return b.rstrip(b'\x00').decode('utf8','replace')

meta={}
for s in range(0,len(toks),5):
    chunk=toks[s:s+5]; calls=[]
    for t in chunk: calls += [(t,SEL['symbol']),(t,SEL['decimals'])]
    res=rpc_batch(calls)
    for i,t in enumerate(chunk):
        meta[t]={'symbol':dec_str(res[2*i]),'decimals':int(res[2*i+1],16) if res[2*i+1] not in ('0x','') else None}
    print('meta',s,flush=True)

# DefiLlama prices
ids=['zksync:'+t for t in toks]
prices={}
for s in range(0,len(ids),20):
    url='https://coins.llama.fi/prices/current/'+','.join(ids[s:s+20])
    try:
        with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'research/1.0'}),timeout=30) as r:
            j=json.load(r)
        prices.update({k.split(':')[1].lower():v for k,v in j.get('coins',{}).items()})
    except Exception as e: print('llama err',e)
    time.sleep(0.3)

for t in toks:
    m=meta[t]; p=prices.get(t.lower(),{})
    if 'symbol' not in m or m.get('decimals') is None: print('no-meta',t)
    print(t, m.get('symbol'), m.get('decimals'), p.get('price'), p.get('symbol'))
json.dump({'meta':meta,'prices':prices},open('/home/heisenberg/CA/zkswap-v2/analysis/zkswap_tokenmeta.json','w'),indent=1)
