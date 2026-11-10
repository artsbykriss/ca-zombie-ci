import json,os,urllib.request
URL=os.environ['BASE']
def call(to,data):
    body={"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}
    req=urllib.request.Request(URL,data=json.dumps(body).encode(),headers={"content-type":"application/json","user-agent":"research/1.0"})
    try:
        r=json.load(urllib.request.urlopen(req,timeout=25)); return r.get('result'),r.get('error')
    except Exception as e: return None,str(e)
v=json.load(open('/tmp/opencode/beefy.json'))
base=[x for x in v if x.get('chain')=='base']
print("base vaults",len(base))
ok=[]
for x in base[:60]:
    a=x.get('vault')
    if not a: continue
    r,e=call(a,"0x1da550ba")  # strategy()
    if r and len(r)>=66:
        ok.append((x['id'],a,"0x"+r[-40:]))
        if len(ok)>=5: break
for o in ok: print(o)
json.dump(ok,open('evidence/beefy_base_strategies.json','w'),indent=1)
