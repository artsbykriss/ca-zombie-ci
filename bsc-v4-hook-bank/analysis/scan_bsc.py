#!/usr/bin/env python3
import json, urllib.request, sys, time
from concurrent.futures import ThreadPoolExecutor

RPC="https://bsc-rpc.publicnode.com"
TARGET="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219".lower()

def rpc(method, params, tries=4):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for a in range(tries):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"zh4/1.0"})
            with urllib.request.urlopen(req,timeout=30) as r:
                d=json.load(r)
            if "result" in d: return d["result"]
        except Exception:
            time.sleep(0.5+a)
    return None

head=int(rpc("eth_blockNumber",[]),16)
N=int(sys.argv[1]) if len(sys.argv)>1 else 2000
start=head-N
print("head",head,"scan",start,"..",head)

hits=[]
def scan(bn):
    b=rpc("eth_getBlockByNumber",[hex(bn),True])
    if not b or not b.get("transactions"): return
    for tx in b["transactions"]:
        to=(tx.get("to") or "").lower()
        if to==TARGET:
            hits.append((bn,tx))
with ThreadPoolExecutor(max_workers=24) as ex:
    list(ex.map(scan, range(start,head+1)))

print("txs to target:",len(hits))
# receipts for status
def rc(h):
    bn,tx=h
    r=rpc("eth_getTransactionReceipt",[tx["hash"]])
    return (bn,tx,r)
recs=[]
with ThreadPoolExecutor(max_workers=24) as ex:
    recs=list(ex.map(rc,hits))
from collections import Counter
sel_c=Counter(); from_c=Counter(); status_c=Counter()
out=[]
for bn,tx,r in recs:
    status=r.get("status") if r else None
    data=tx.get("input","")
    sel=data[:10]
    sel_c[sel]+=1; from_c[tx["from"].lower()]+=1; status_c[status]+=1
    out.append({"block":bn,"hash":tx["hash"],"from":tx["from"],"nonce":tx.get("nonce"),"value":tx.get("value"),"sel":sel,"data":data,"status":status,"gasUsed":(r or {}).get("gasUsed")})
print("status:",dict(status_c))
print("selectors:",dict(sel_c))
print("distinct senders:",len(from_c))
out.sort(key=lambda x:x["block"])
open("/tmp/opencode/kh/bsc_bank_txs.json","w").write(json.dumps(out,indent=1))
for o in out[:25]:
    print(o["block"],o["hash"][:14],"st=",o["status"],"sel=",o["sel"],"from=",o["from"][:12],"nonce=",o["nonce"],"val=",o["value"],"data_len=",len(o["data"]))
