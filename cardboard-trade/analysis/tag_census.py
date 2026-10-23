#!/usr/bin/env python3
# Independent tag census: first byte of every EXCHANGE-program invocation seen in recent txs.
import json,urllib.request,time,collections
RPC="https://api.mainnet-beta.solana.com"
A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n=0
    for c in s: n=n*58+A.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big')
def rpc(m,p):
    for _ in range(5):
        try:
            req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            return json.load(urllib.request.urlopen(req,timeout=90))
        except Exception as e:
            time.sleep(2)
    return {}
EX="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
OR="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
sigs=[]
for prog in (OR,EX):
    r=rpc("getSignaturesForAddress",[prog,{"limit":18}])
    sigs += [x["signature"] for x in r.get("result",[])]
sigs=list(dict.fromkeys(sigs))
print("txs to scan:",len(sigs))
tags=collections.Counter(); oracle_tags=collections.Counter(); examples={}
for s in sigs:
    r=rpc("getTransaction",[s,{"encoding":"json","maxSupportedTransactionVersion":1,"commitment":"confirmed"}])
    res=r.get("result")
    if not res: continue
    for grp in res["meta"].get("innerInstructions") or []:
        for ix in grp["instructions"]:
            keys=res["transaction"]["message"]["accountKeys"]
            pid=keys[ix["programIdIndex"]] if "programIdIndex" in ix else ix.get("programId")
            data=ix.get("data")
            if not data: continue
            try: b=b58d(data)
            except Exception: continue
            tag=b[0]
            if pid==EX:
                tags[tag]+=1
                examples.setdefault(tag,(s,data,len(b)))
            elif pid==OR:
                oracle_tags[tuple(b[:2])]+=1
print("\n== EXCHANGE inner-invocation tags (first byte) ==")
for t,c in sorted(tags.items()):
    print(f"  tag 0x{t:02x}  count={c}  example_len={examples[t][2]}  sig={examples[t][0][:20]}.. data={examples[t][1][:60]}")
print("\n== ORACLE top-level data prefixes ==")
for t,c in sorted(oracle_tags.items()):
    print(f"  bytes {bytes(t).hex()}  count={c}")
json.dump({"exchange_tags":{hex(k):v for k,v in tags.items()},"oracle_prefixes":{bytes(k).hex():v for k,v in oracle_tags.items()},"txs_scanned":len(sigs)},open("tag_census.json","w"),indent=1)
