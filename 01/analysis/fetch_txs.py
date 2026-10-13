#!/usr/bin/env python3
"""Fetch recent transactions for the 01 vault PDA and extract invoked programs."""
import json, urllib.request, time, sys

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

def main():
    d=json.load(open("analysis/state_dump_raw.json"))
    sigs=[s["signature"] for s in d["signatures"]["result"]]
    print("total sigs available:", len(sigs))
    txs={}
    for s in sigs[:25]:
        try:
            tx=rpc("getTransaction",[s,{"encoding":"jsonParsed","maxSupportedTransactionVersion":0,"commitment":"confirmed"}])
            txs[s]=tx.get("result")
        except Exception as e:
            print("ERR", s, e)
        time.sleep(0.15)
    json.dump(txs, open("analysis/recent_txs.json","w"), indent=1)
    print("fetched:", sum(1 for v in txs.values() if v))
    # summarize
    for s,v in txs.items():
        if not v: continue
        bt=v.get("blockTime"); slot=v.get("slot")
        keys=[k["pubkey"] if isinstance(k,dict) else k for k in v["transaction"]["message"]["accountKeys"]]
        progs=set()
        for ins in v["transaction"]["message"]["instructions"]:
            if isinstance(ins,dict):
                pid=ins.get("programId"); progs.add(pid)
                if ins.get("program")=="spl-token": progs.add("spl-token:"+ins.get("parsed",{}).get("type","?"))
        signers=[k["pubkey"] for k in v["transaction"]["message"]["accountKeys"] if isinstance(k,dict) and k.get("signer")]
        print(f"{s[:16]}.. bt={bt} slot={slot} err={v['meta']['err']} fee={v['meta']['fee']} signers={signers}")
        print("   programs:", sorted(progs))
        # log messages summary for transfer of interest
        logs=v["meta"].get("logMessages",[])
        interesting=[l for l in logs if ('Transfer' in l or 'Program log' in l and ('withdraw' in l.lower() or 'vault' in l.lower()))][:8]
        for l in interesting: print("    log:", l[:160])

if __name__=="__main__":
    main()
