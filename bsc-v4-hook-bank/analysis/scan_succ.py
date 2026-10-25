#!/usr/bin/env python3
import json, urllib.request, time
RPCS=["https://bsc-rpc.publicnode.com","https://binance.llamarpc.com","https://bsc-dataseed.bnbchain.org"]
def rpc(m,p):
    last=None
    for url in RPCS:
        try:
            b=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
            r=urllib.request.Request(url,data=b,headers={"Content-Type":"application/json","User-Agent":"z"})
            with urllib.request.urlopen(r,timeout=30) as f: d=json.load(f)
            if "result" in d: return d["result"]
            last=d.get("error")
        except Exception as e: last=str(e)
        time.sleep(0.25)
    return {"__err__":str(last)}
A="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219".lower()
blk=int(rpc("eth_blockNumber",[]),16)
print("head",blk)
succ=[]; nf=0; nseen=0
bn=blk
while nseen<1500 and bn>blk-1500:
    rs=rpc("eth_getBlockReceipts",[hex(bn)])
    if isinstance(rs,list):
        for r in rs:
            if (r.get("to") or "").lower()==A:
                nseen+=1
                if r.get("status")=="0x1": succ.append((bn,r))
                else: nf+=1
    bn-=1
print("seen",nseen,"succ",len(succ),"failed",nf)
for bn,r in succ[:5]:
    print("\n=== SUCCESS blk",bn,r["transactionHash"],"gasUsed",int(r['gasUsed'],16))
    for lg in r.get("logs",[]):
        tps=lg.get("topics",[])
        print("   addr",lg["address"],"t0",tps[0][:20] if tps else None,"ntop",len(tps),"dlen",len(lg.get("data","")))
json.dump([{"blk":b,"tx":r["transactionHash"],"gas":int(r["gasUsed"],16),"logs":[{"addr":l["address"],"topics":l["topics"],"data":l["data"]} for l in r.get("logs",[])]} for b,r in succ], open("bsc_bank_succ.json","w"), indent=1)
print("saved bsc_bank_succ.json")
