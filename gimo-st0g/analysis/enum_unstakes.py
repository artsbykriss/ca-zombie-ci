import json,subprocess
R="https://evmrpc.0g.ai"
M="0xac06d1df23a4fa00981afac0f33a5936bd2135af"
B="0x2d9b7bf"
def rpc_batch(reqs):
    out=[]
    for i in range(0,len(reqs),100):
        chunk=reqs[i:i+100]
        p=subprocess.run(["curl","-s","-m","120","-A","Mozilla/5.0","-X","POST",R,"-H","content-type: application/json","-d",json.dumps(chunk)],capture_output=True,text=True)
        try:
            out+=json.loads(p.stdout)
        except Exception as e:
            print("batch fail",i,p.stdout[:200]); raise
    return out
n=int(subprocess.run(["cast","call",M,"nextUnstakeIndex()(uint256)","--rpc-url",R,"--block",str(int(B,16))],capture_output=True,text=True).stdout.split()[0])
print("nextUnstakeIndex",n)
sel="6e436c6e"  # unstakeAtIndex(uint256)
reqs=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":M,"data":"0x"+sel+hex(i)[2:].zfill(64)},B]} for i in range(n)]
res=rpc_batch(reqs)
recs={}
for r in res:
    if 'result' not in r: continue
    d=r['result'][2:]
    era=int(d[0:64],16); pool="0x"+d[64+24:128]; recv="0x"+d[128+24:192]; amt=int(d[192:256],16)
    recs[r['id']]=(era,pool,recv,amt)
print("records",len(recs))
json.dump({str(k):v for k,v in recs.items()},open('unstake_records.json','w'))
from collections import Counter
print("eras min/max",min(v[0] for v in recs.values()),max(v[0] for v in recs.values()))
print("total amount",sum(v[3] for v in recs.values())/1e18)
recv=set(v[2].lower() for v in recs.values())
print("unique receivers",len(recv))
