#!/usr/bin/env python3
"""Collect real program instructions by scanning many txs; save full account lists."""
import json, base64
from collections import Counter
from sol_rpc import get_signatures, get_transaction

PROGS = {"O13":"3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
         "O14":"WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
         "O15":"zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"}

def main():
    out = {}
    for k,pid in PROGS.items():
        print(f"\n===== {k} {pid} =====")
        sigs=[]; before=None
        for _ in range(2):
            r=get_signatures(pid,limit=1000,before=before)
            res=r.get("result") or []
            if not res: break
            sigs.extend(res); before=res[-1]["signature"]
            if len(res)<1000: break
        c=Counter(); ex={}; nulls=0; ok=0
        for s in sigs[:400]:
            try: tx=get_transaction(s["signature"])
            except Exception: continue
            if not tx.get("result"): nulls+=1; continue
            ok+=1
            msg=tx["result"]["transaction"]["message"]
            for ix in msg.get("instructions",[]):
                if ix.get("programId")!=pid: continue
                try: raw=base64.b64decode(ix.get("data") or "")
                except Exception: continue
                d=raw[:8].hex(); c[d]+=1
                if d not in ex:
                    ex[d]={"sig":s["signature"],"n":len(ix.get("accounts",[])),
                           "accounts":ix.get("accounts",[]),"dlen":len(raw),"hex":raw.hex()}
        print(f"  scanned {ok} txs (nulls={nulls}); discs:")
        for d,n in c.most_common():
            print(f"    {d} x{n} accts={ex[d]['n']} dlen={ex[d]['dlen']} ex={ex[d]['sig'][:16]}")
        out[k]={"prog":pid,"discs":dict(c),"examples":ex,"ok":ok,"nulls":nulls}
    with open("ix_scan.json","w") as f: json.dump(out,f,indent=2)

if __name__=="__main__": main()
