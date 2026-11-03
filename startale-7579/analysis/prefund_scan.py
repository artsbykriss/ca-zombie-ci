import json, urllib.request, time, sys
import os
RPC=os.environ.get('ARCHIVE_RPC','https://eth.drpc.org')
rows=[]
for f in ['accountcreated_logs_26134433_26234433.json','accountcreated_logs_26234434_26334433.json']:
    rows+=json.load(open(f))['result']
rows.sort(key=lambda r:int(r['blockNumber'],16))
accts=[(int(r['blockNumber'],16),'0x'+r['topics'][1][-40:],r['transactionHash']) for r in rows]

def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_getBalance","params":[a,hex(b)]} for i,(b,a,_) in enumerate(calls)]
    for attempt in range(4):
        try:
            req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
            with urllib.request.urlopen(req,timeout=60) as r:
                out=json.load(r)
            res={}
            for o in out:
                res[o['id']]=int(o['result'],16) if isinstance(o.get('result'),str) else None
            return [res.get(i) for i in range(len(calls))]
        except Exception as e:
            print("retry",attempt,e,file=sys.stderr); time.sleep(2+3*attempt)
    return [None]*len(calls)

out=[]
for i in range(0,len(accts),20):
    chunk=accts[i:i+20]
    time.sleep(0.25)
    pre=batch([(b-1,a,h) for b,a,h in chunk])
    now=batch([(26334433,a,h) for b,a,h in chunk])
    for (b,a,h),p,n in zip(chunk,pre,now):
        out.append({'block':b,'account':a,'tx':h,'prefund_wei':p,'now_wei':n})
    print(i,len(out),file=sys.stderr)
json.dump(out,open('prefund_scan.json','w'),indent=1)
tot=sum(o['prefund_wei'] or 0 for o in out)
print("n",len(out),"sum_prefund_eth",tot/1e18,"nonzero",sum(1 for o in out if (o['prefund_wei'] or 0)>0))
nz=sorted([o for o in out if (o['prefund_wei'] or 0)>0], key=lambda o:-o['prefund_wei'])
print("max 15:")
for o in nz[:15]: print(o['block'],o['account'],o['prefund_wei']/1e18,o['now_wei']/1e18)
print("now nonzero:",sum(1 for o in out if (o['now_wei'] or 0)>0))
print("sum_now_eth",sum(o['now_wei'] or 0 for o in out)/1e18)
