#!/usr/bin/env python3
import json, urllib.request, time
RPCS=["https://bsc-rpc.publicnode.com","https://bsc-dataseed.bnbchain.org","https://binance.llamarpc.com"]
def rpc(m,p):
    for url in RPCS:
        try:
            b=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
            r=urllib.request.Request(url,data=b,headers={"Content-Type":"application/json","User-Agent":"z"})
            with urllib.request.urlopen(r,timeout=30) as f: d=json.load(f)
            if "result" in d: return d["result"]
            if "error" in d: last=d["error"]
        except Exception as e: pass
        time.sleep(0.4)
    return {"__err__":str(last) if 'last' in dir() else "fail"}
A="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219".lower()
blk=int(rpc("eth_blockNumber",[]),16)
print("head",blk)
found=[]
bn=blk
while len(found)<6 and bn>blk-400:
    b=rpc("eth_getBlockByNumber",[hex(bn),True])
    if isinstance(b,dict):
        for tx in b.get("transactions",[]):
            if (tx.get("to") or "").lower()==A:
                found.append((bn,tx))
    bn-=1
print("found",len(found))
for bn,tx in found:
    inp=tx["input"]; sel=inp[:10]
    print("\n=== blk",bn,"hash",tx["hash"],"from",tx["from"],"nonce",tx["nonce"],"value",tx["value"],"sel",sel,"len",len(inp))
    print("input:",inp)
    # revert via eth_call at that block
    rc=rpc("eth_call",[{"from":tx["from"],"to":tx["to"],"data":inp,"value":tx["value"]},hex(bn)])
    print("eth_call ->", rc if not isinstance(rc,dict) else rc)
    # trace
    tr=rpc("debug_traceCall",[{"from":tx["from"],"to":tx["to"],"data":inp,"value":tx["value"]},hex(bn),{"tracer":"callTracer"}])
    if isinstance(tr,dict):
        def walk(t,depth=0,path=""):
            print("  "*depth,"->",t.get("type"),t.get("to","")[:14],"err=",t.get("error"),"out=",(t.get("output") or "")[:20])
            for c in t.get("calls",[]) or []: walk(c,depth+1)
        walk(tr)
    else:
        print("trace:",tr)
