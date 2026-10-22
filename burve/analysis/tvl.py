#!/usr/bin/env python3
"""Compute the Diamond's closure values / TVL + key config."""
import json, urllib.request, concurrent.futures
from bera import words, addr
RPCS = ["https://berachain-rpc.publicnode.com", "https://rpc.berachain.com", "https://berachain.drpc.org"]
D = "0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089"
def rp(m,p):
    last=None
    for u in RPCS:
        try:
            req=urllib.request.Request(u,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=30) as r: j=json.loads(r.read())
            if "result" in j: return j["result"]
            last=j
        except Exception as e: last=e
    raise RuntimeError(str(last))
def c(to,data): return rp("eth_call",[{"to":to,"data":data},"latest"])
def tryc(to,data):
    try: return c(to,data)
    except Exception: return None

blk=int(rp("eth_blockNumber",[]),16); print("block",blk)
toks_raw=c(D,"0xaa6ca808"); wt=words(toks_raw); ntok=int(wt[1],16)
tokens=[addr(wt[2+i]) for i in range(ntok)]
print("ntok",ntok)
for i,t in enumerate(tokens): print("  ",i,t)
print("numVertices",int(c(D,"0x9d5d7807"),16))
print("initTarget",int(c(D,"0xa597404e"),16))
print("adjustor",addr(words(c(D,"0x6ed7a2c3"))[0]))
print("bgtExchanger",addr(words(c(D,"0x20fd72b5"))[0]))
pe=tryc(D,"0x59055b9b")
print("protocolEarnings raw",pe[:200] if pe else None)
sf=tryc(D,"0x09ece0f2")
if sf:
    w=words(sf); print("getSimplexFees words",[int(x,16) for x in w])
# closures
ids=list(range(0, 1<<ntok))
def gv(i):
    r=tryc(D, "0xf80e073a"+"".join(f"{i:064x}"))
    return i,r
res={}
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as ex:
    for i,r in ex.map(gv, ids):
        if r: res[i]=r
tot=[0]*ntok
print("closures returning:",len(res))
for i in sorted(res):
    w=words(res[i])
    n=int(w[0],16); target=int(w[1],16)
    bal=[int(w[2+j],16) for j in range(16)]
    vs=int(w[18],16); bgt=int(w[19],16)
    if all(b==0 for b in bal) and vs==0: continue
    nz=[(j,bal[j]) for j in range(ntok) if bal[j]]
    print(f"cid {i}: n={n} target={target} valueStaked={vs} bgt={bgt} bal={nz}")
    for j in range(ntok): tot[j]+=bal[j]
print("total nominal per token:",tot)
json.dump({"block":blk,"ntok":ntok,"tokens":tokens,"totals":[str(x) for x in tot],
           "closures":{str(k):res[k] for k in res}},open("closure-values.json","w"),indent=1)
