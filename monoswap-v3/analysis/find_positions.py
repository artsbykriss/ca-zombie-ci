#!/usr/bin/env python3
"""Find LP positions (tokenIds) that hold liquidity in the main USDB/WETH pool."""
import json, urllib.request, concurrent.futures as cf, sys
RPCS=["https://blast-rpc.publicnode.com","https://rpc.blast.io","https://blast.drpc.org"]
NPM="0x0f0c3de3cd5185454ede5ef184bc9c7f4133fb90"
MAIN="0x0d44f3f22f917cc57368a6d30ba18d5801789cd9"
def call(rpc,to,data,t=12):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}).encode()
    req=urllib.request.Request(rpc,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req,timeout=t) as r: return json.loads(r.read()).get("result")
def cc(to,data,i=0):
    for a in range(3):
        try: return call(RPCS[(i+a)%3],to,data)
        except Exception: continue
    return None
def pos(i):
    h=cc(NPM,"0x99fbab88"+hex(i)[2:].rjust(64,"0"),i)
    if not h or len(h)<2+64*12: return None
    w=[h[2:][k*64:(k+1)*64] for k in range(12)]
    u=lambda x:int(x,16)
    return {"id":i,"t0":"0x"+w[2][-40:],"t1":"0x"+w[3][-40:],"fee":u(w[4]),"tl":u(w[5]),"tu":u(w[6]),"liq":u(w[7]),"owed0":u(w[10]),"owed1":u(w[11])}
ids=list(range(1,11407))
found=[]
with cf.ThreadPoolExecutor(max_workers=12) as ex:
    for r in ex.map(pos, ids):
        if r and (r["t0"].lower()==MAIN.lower() or r["t1"].lower()==MAIN.lower()):
            found.append(r)
            print("FOUND", r, flush=True)
found.sort(key=lambda r:-r["liq"])
json.dump(found, open("/home/heisenberg/CA/monoswap-v3/analysis/main_pool_positions.json","w"), indent=1)
print("total main-pool positions:", len(found))
if found:
    print("biggest:", found[0])
