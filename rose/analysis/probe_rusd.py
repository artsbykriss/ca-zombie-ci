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
def word(x,i):
    if not x or len(x)<2+64*(i+1): return None
    return x[2+64*i:2+64*(i+1)]

RUSD='0x19cc40283b057d6608c22f1d20f17e16c245642e'
RUSDPOOL='0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34'
VASE='0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF'
GARDENS={
 'gardenNear':'0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D',
 'gardenUsdc':'0xfbAF3eBF228eB712b1267285787e51aDd70086bB',
 'gardenUsdt':'0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596',
 'gardenWeth':'0x084355FDd5fcfd55d60C5B8626756a6906576f13',
 'gardenAtust':'0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1',
}
SEL={'name':'0x06fdde03','symbol':'0x95d89b41','decimals':'0x313ce567','totalSupply':'0x18160ddd',
     'balanceOf':'0x70a08231','coins':'0xc6610657','balances':'0x4903b0d1','A':'0xf446c1d0','fee':'0xddca3f43',
     'get_virtual_price':'0xbb7b8b80','owner':'0x8da5cb5b','lp_token':'0x82c63066','token':'0xfc0c546a',
     'totals':'0x4ffe34db','vase':'0xe53a4de2'}
calls=[];keys=[]
# RUSD token info
for s in ['name','symbol','decimals','totalSupply']:
    calls.append((RUSD,SEL[s])); keys.append(('rusd',s))
# VASE balance of RUSD (actual)
calls.append((RUSD,SEL['balanceOf']+VASE[2:].rjust(64,'0'))); keys.append(('vase','balRUSD'))
calls.append((VASE,SEL['totals']+RUSD[2:].rjust(64,'0'))); keys.append(('vase','totalsRUSD'))
# each garden's RUSD share in VASE
for lab,g in GARDENS.items():
    calls.append((VASE,'0xf7888aec'+RUSD[2:].rjust(64,'0')+g[2:].rjust(64,'0'))); keys.append((lab,'bbShareRUSD'))
# RUSD metapool
for i in range(3):
    calls.append((RUSDPOOL,SEL['coins']+f"{i:064x}")); keys.append(('rusdpool',f'coins{i}'))
for i in range(3):
    calls.append((RUSDPOOL,SEL['balances']+f"{i:064x}")); keys.append(('rusdpool',f'bal{i}'))
for s in ['A','fee','get_virtual_price','owner','lp_token','token']:
    calls.append((RUSDPOOL,SEL[s])); keys.append(('rusdpool',s))
res=rpc_batch(calls)
out={}
for (lab,k),r in zip(keys,res):
    if k in ('name','symbol'): 
        v=r
        if v and len(v)>=130 and v[2:66]=='0'*64:
            ln=int(v[66:130],16); v=bytes.fromhex(v[130:130+ln*2]).decode('utf8','replace')
        elif v: v=bytes.fromhex(v[2:66].rstrip('0')).decode('utf8','replace')
        out.setdefault(lab,{})[k]=v
    elif k.startswith('coins') or k in ('owner','lp_token','token'):
        out.setdefault(lab,{})[k]=addr(r)
    else:
        out.setdefault(lab,{})[k]=u(r)
for lab in out:
    print('===',lab)
    print(json.dumps(out[lab],indent=1))
json.dump(out, open('rusd_state.json','w'), indent=1)
