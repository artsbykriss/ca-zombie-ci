import json,os,time,urllib.request
KEY=os.environ['ETHERSCANV2_API_KEY']
d=json.load(open('prefund_scan.json'))
out=[]
for i,o in enumerate(d):
    url=f"https://api.etherscan.io/v2/api?chainid=1&module=account&action=tokentx&address={o['account']}&page=1&offset=30&sort=asc&apikey={KEY}"
    for att in range(3):
        try:
            r=json.load(urllib.request.urlopen(url,timeout=30))
            if r.get('status')=='0' and 'rate limit' in str(r.get('result','')).lower():
                time.sleep(2); continue
            rows=r.get('result') or []
            pre=[t for t in rows if int(t['blockNumber'])<=o['block']]
            o['tok_pre']=[{'sym':t['tokenSymbol'],'v':t['value'],'dec':t['tokenDecimal'],'blk':int(t['blockNumber']),'from':t['from']} for t in pre]
            o['tok_all_n']=len(rows)
            break
        except Exception as e:
            time.sleep(2)
    out.append(o)
    if i%25==0:
        print(i,flush=True); json.dump(out,open('prefund_scan_tok.json','w'),indent=1)
    time.sleep(0.22)
json.dump(out,open('prefund_scan_tok.json','w'),indent=1)
n=sum(1 for o in out if o.get('tok_pre'))
print("accounts",len(out),"with_pre_token_transfer",n)
for o in out:
    if o.get('tok_pre'): print(o['block'],o['account'],o['tok_pre'][:3])
