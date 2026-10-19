import json,urllib.request,time
RPC='https://bsc-rpc.publicnode.com'
API='https://four.meme/meme-api/v1/public/token/search'
def post(url,body):
    req=urllib.request.Request(url,data=json.dumps(body).encode(),headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req,timeout=30) as r: return json.loads(r.read())
def batch(calls):
    payload=[{'jsonrpc':'2.0','id':i,'method':'eth_call','params':[{'to':to,'data':data},'latest']} for i,(to,data) in enumerate(calls)]
    for _ in range(3):
        try:
            r=post(RPC,payload)
            if isinstance(r,list):
                out=[None]*len(calls)
                for x in r: out[x['id']]=x.get('result')
                return out
        except Exception as e: time.sleep(1)
    return [None]*len(calls)
SEL={'feeRate':'0x978bbdb9','feeAccumulated':'0x6d370ff2','minDispatch':'0x110395bd','rateFounder':'0x6f0e5053','rateHolder':'0x6234b84f','rateBurn':'0x18a4acea','rateLiquidity':'0xeda528d4','pair':'0xa8aa1b31','token0':'0x0dfe1681','getReserves':'0x0902f1ac'}
d=post(API,{'type':'VOL_DAY_1','listType':'NOR_DEX','pageIndex':1,'pageSize':40,'status':'TRADE','sort':'DESC','version':'V9'})
toks=d['data']
keys=['feeRate','feeAccumulated','minDispatch','rateFounder','rateHolder','rateBurn','rateLiquidity','pair']
calls=[(t['tokenAddress'],SEL[k]) for t in toks for k in keys]
res=[]
for i in range(0,len(calls),40): res+=batch(calls[i:i+40]); time.sleep(0.2)
vals={}
for i,t in enumerate(toks):
    vals[t['tokenAddress']]={k:(int(res[i*len(keys)+j],16) if res[i*len(keys)+j] and res[i*len(keys)+j]!='0x' else None) for j,k in enumerate(keys)}
live=[t for t in toks if (vals[t['tokenAddress']]['feeRate'] or 0)>0]
print('live',len(live))
# reserves
calls2=[]; pairs=[]
for t in live:
    p=vals[t['tokenAddress']]['pair']
    if p and p!=0:
        calls2+=[(p,SEL['token0']),(p,SEL['getReserves'])]; pairs.append((t,p))
r2=[]
for i in range(0,len(calls2),40): r2+=batch(calls2[i:i+40]); time.sleep(0.2)
for i,(t,p) in enumerate(pairs):
    t0=r2[i*2]; rv=r2[i*2+1]
    if not t0 or not rv: continue
    t0='0x'+t0[-40:]; r0=int(rv[2:66],16); r1=int(rv[66:130],16)
    wbnb='0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c'
    rq,rt=(r0,r1) if t0.lower()==wbnb else (r1,r0)
    v=vals[t['tokenAddress']]
    v['pair_addr']=p; v['reserve_quote_wei']=rq; v['reserve_token']=rt
    v['price_bnb']=rq/rt if rt else 0
    v['accrued_bnb']=(v['feeAccumulated'] or 0)*v['price_bnb']
    v['min_bnb']=(v['minDispatch'] or 0)*v['price_bnb']
json.dump({'tokens':toks,'vals':vals},open('/tmp/opencode/of_live.json','w'),indent=1)
for t in live:
    v=vals[t['tokenAddress']]
    swap_alloc=(v['rateFounder'] or 0)+(v['rateHolder'] or 0)+(v['rateLiquidity'] or 0)
    print(f"{t['shortName'][:14]:15s} {t['tokenAddress'][:10]} d1=${t.get('day1Vol',0):>8} fee={v['feeRate']} F/H/B/L={v['rateFounder']}/{v['rateHolder']}/{v['rateBurn']}/{v['rateLiquidity']} swapAlloc={swap_alloc} acc={v['feeAccumulated']} accBNB={v.get('accrued_bnb',0):.6f} min={v['minDispatch']} minBNB={v.get('min_bnb',0):.4f} reservesQ={v.get('reserve_quote_wei',0)/1e18:.2f}BNB")
