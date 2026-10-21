import json,subprocess
R="https://evmrpc.0g.ai"
M="0xac06d1df23a4fa00981afac0f33a5936bd2135af"
B="0x2d9b7bf"
recs={int(k):v for k,v in json.load(open('unstake_records.json')).items()}
recv=sorted(set(v[2].lower() for v in recs.values()))
def batch(reqs):
    out=[]
    for i in range(0,len(reqs),100):
        p=subprocess.run(["curl","-s","-m","120","-A","Mozilla/5.0","-X","POST",R,"-H","content-type: application/json","-d",json.dumps(reqs[i:i+100])],capture_output=True,text=True)
        try: out+=json.loads(p.stdout)
        except: print("fail",i,p.stdout[:200]); raise
    return out
sel="615acc36"
reqs=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":M,"data":"0x"+sel+"0"*24+r[2:]},"0x2d9b7bf"]} for i,r in enumerate(recv)]
res=batch(reqs)
outstanding=set()
for r in res:
    if 'result' not in r or len(r['result'])<130: continue
    d=r['result'][2:]
    try:
        n=int(d[64:128],16)
        for j in range(n):
            v=int(d[128+64*j:192+64*j],16)
            outstanding.add(v)
    except Exception as e:
        pass
print("outstanding records",len(outstanding),"of",len(recs))
cur=400
tot=0; matured=0; nm=0; narr=0
byera={}
for i in sorted(outstanding):
    era,pool,r,amt=recs[i]
    tot+=amt
    if era+3<=cur: matured+=amt; nm+=1
    else: narr+=1
    byera[era]=byera.get(era,0)+amt
print("outstanding amount 0G",tot/1e18,"matured",matured/1e18,"(n=",nm,") notmatured",narr)
print("last 8 eras:", {k:round(v/1e18,3) for k,v in sorted(byera.items())[-8:]})
json.dump({"outstanding":[i for i in sorted(outstanding)],"total_wei":str(tot),"matured_wei":str(matured)},open('outstanding.json','w'))
