#!/usr/bin/env python3
"""Pull recent txs for the exchange & oracle, collect top-level instruction tags."""
import json,sys,os,base64,collections,time
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n=0
    for c in s: n=n*58+A.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    return b'\x00'*(len(s)-len(s.lstrip('1')))+b
EX="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
OR="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
out={"exchange":{},"oracle":{}}
for name,prog in [("exchange",EX),("oracle",OR)]:
    r=rpc("getSignaturesForAddress",[prog,{"limit":20}])
    sigs=[x["signature"] for x in r.get("result",[])]
    tags=collections.Counter(); top_tags=collections.Counter()
    examples={}
    for s in sigs:
        tr=rpc("getTransaction",[s,{"encoding":"jsonParsed","maxSupportedTransactionVersion":1,"commitment":"confirmed"}])
        res=tr.get("result")
        if not res: continue
        for ix in res["transaction"]["message"]["instructions"]:
            if ix.get("programId")!=prog: continue
            d=ix.get("data")
            if not d: continue
            try: raw=b58d(d)
            except Exception: continue
            tag=raw[0]
            top_tags[tag]+=1
            if tag not in examples: examples[tag]=d[:60]
        for grp in res["meta"].get("innerInstructions",[]) or []:
            for ix in grp["instructions"]:
                if ix.get("programId")!=prog: continue
                d=ix.get("data")
                if not d: continue
                try: raw=b58d(d)
                except Exception: continue
                tags[raw[0]]+=1
                if raw[0] not in examples: examples[raw[0]]=d[:60]
        time.sleep(0.05)
    print(f"=== {name} {prog}: {len(sigs)} recent sigs")
    print("  top-level tags:",dict(top_tags))
    print("  all(incl inner) tags:",dict(tags))
    for t,e in sorted(examples.items()): print(f"    tag {t:#04x}: data={e}")
    out[name]={"sigs":len(sigs),"top_tags":dict(top_tags),"all_tags":dict(tags),"examples":{str(k):v for k,v in examples.items()}}
json.dump(out,open("/home/heisenberg/CA/cardboard-trade/analysis/oracle-re/recent_tags.json","w"),indent=1)
