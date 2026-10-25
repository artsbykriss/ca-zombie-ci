#!/usr/bin/env python3
"""Consolidated: scan real txs, decode instruction data correctly (base58/base64),
group by discriminator, and run attacker-substitution simulations."""
import json, base64, time, sys
from collections import Counter, defaultdict
from sol_rpc import get_signatures, get_transaction, rpc
import sim_attacker as SA

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for ch in s: n=n*58+ALPH.index(ch)
    b=n.to_bytes((n.bit_length()+7)//8,'big'); pad=0
    for ch in s:
        if ch=='1': pad+=1
        else: break
    return b'\x00'*pad+b

DISC = json.load(open("disc_maps.json"))

PROGS = {"O13":"3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
         "O14":"WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
         "O15":"zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"}

def decode(s, dmap):
    for fn in (b58d, lambda x: base64.b64decode(x)):
        try:
            raw = fn(s)
        except Exception:
            continue
        if len(raw) >= 8 and raw[:8].hex() in dmap:
            return raw, ("base58" if fn is b58d else "base64")
    # fall back to base58 anyway
    try: return b58d(s), "base58?"
    except Exception: return b"", "fail"

def scan(k, pid, nsigs=200):
    dmap = DISC[k]
    sigs=[]; before=None
    for _ in range(1):
        r=get_signatures(pid,limit=1000,before=before)
        res=r.get("result") or []
        sigs.extend(res)
        if len(res)<1000: break
    print(f"[{k}] {len(sigs)} sigs; scanning {min(nsigs,len(sigs))}")
    groups=defaultdict(list)
    for s in sigs[:nsigs]:
        try: tx=get_transaction(s["signature"])
        except Exception: continue
        if not tx.get("result"): continue
        m=tx["result"]["transaction"]["message"]
        ixs=list(m.get("instructions",[]))
        for ii in (tx["result"].get("meta",{}) or {}).get("innerInstructions",[]) or []:
            ixs.extend(ii.get("instructions",[]))
        for ix in ixs:
            if ix.get("programId")!=pid: continue
            raw,enc=decode(ix.get("data") or "", dmap)
            if len(raw)<8: continue
            d=raw[:8].hex()
            groups[d].append({"sig":s["signature"],"n":len(ix.get("accounts",[])),
                              "dlen":len(raw),"enc":enc,"name":dmap.get(d,"?")})
        time.sleep(0.02)
    out={}
    for d,lst in groups.items():
        out[d]={"name":dmap.get(d,"?"),"count":len(lst),"n":lst[0]["n"],
                "dlen":lst[0]["dlen"],"enc":lst[0]["enc"],"example":lst[0]["sig"]}
    print(f"[{k}] instructions found:")
    for d,v in sorted(out.items(), key=lambda x:-x[1]['count']):
        print(f"   {d} {v['name']:40s} x{v['count']:4d} accts={v['n']} dlen={v['dlen']} enc={v['enc']}")
    return out

if __name__=="__main__":
    which = sys.argv[1] if len(sys.argv)>1 else "O13"
    pid=PROGS[which]
    res=scan(which,pid, int(sys.argv[2]) if len(sys.argv)>2 else 200)
    json.dump(res, open(f"ix_groups_{which}.json","w"), indent=1)
