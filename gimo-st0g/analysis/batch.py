import json,subprocess,sys
R="https://evmrpc.0g.ai"
M="0xac06d1df23a4fa00981afac0f33a5936bd2135af"
def batch(calls):
    reqs=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":M,"data":d},"0x2d9b7bf"]} for i,d in enumerate(calls)]
    p=subprocess.run(["curl","-s","-m","120","-A","Mozilla/5.0","-X","POST",R,"-H","content-type: application/json","-d",json.dumps(reqs)],capture_output=True,text=True)
    return json.loads(p.stdout)
sel="eb8ad76e"  # eraRate(uint256)
calls=[("0x"+sel+hex(i)[2:].zfill(64)) for i in range(0,401)]
res=batch(calls)
out={}
for r in res:
    if 'result' in r: out[r['id']]=int(r['result'],16)
json.dump(out,open('era_rates.json','w'),indent=0)
print("got",len(out))
prev=None
for i in range(0,401):
    v=out.get(i)
    if v is None: print(i,"MISSING"); continue
    if i%10==0 or (prev and abs(v-prev)>3e14): print(i,v, (v-prev) if prev else '')
    prev=v
