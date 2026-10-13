#!/usr/bin/env python3
"""Census of live instructions on the 01 program: sample recent signatures, collect 'Instruction: X' logs."""
import json, urllib.request, time, collections

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

PROG="Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk"
sig=rpc("getSignaturesForAddress",[PROG,{"limit":200}])
sigs=[s["signature"] for s in sig["result"]]
print("program recent sigs:", len(sigs), "first bt:", sig["result"][0].get("blockTime"), "last bt:", sig["result"][-1].get("blockTime"))
cnt=collections.Counter()
details=[]
for s in sigs[:120]:
    try:
        tx=rpc("getTransaction",[s,{"encoding":"jsonParsed","maxSupportedTransactionVersion":0,"commitment":"confirmed"}])
        v=tx.get("result")
        if not v: continue
        logs=v["meta"].get("logMessages",[])
        ins=[l.split("Instruction: ")[1] for l in logs if "Instruction: " in l]
        for i in ins: cnt[i]+=1
        details.append({"sig":s,"bt":v.get("blockTime"),"err":v["meta"]["err"],"ins":ins,
                        "fee":v["meta"]["fee"]})
    except Exception as e:
        print("ERR",s,e)
    time.sleep(0.12)
json.dump(details, open("analysis/program_sig_sample.json","w"), indent=1)
print("\nInstruction frequency (last ~120 txs):")
for k,v in cnt.most_common(): print(f"  {v:4d}  {k}")
