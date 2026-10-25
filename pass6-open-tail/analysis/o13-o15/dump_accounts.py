#!/usr/bin/env python3
"""Dump raw account data for representative sizes; try to parse pubkey fields."""
import json, base64
from sol_rpc import get_program_accounts, get_account_info

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58e(b):
    n = int.from_bytes(b,"big"); out=""
    while n>0:
        n,r=divmod(n,58); out=ALPHABET[r]+out
    pad=0
    for c in b:
        if c==0: pad+=1
        else: break
    return "1"*pad+(out or "")

def pubkeys_in(b, n=8):
    """Heuristic: any 32-byte window that base58-encodes to 32-44 chars."""
    found=[]
    for i in range(0, len(b)-31):
        cand=b[i:i+32]
        s=b58e(cand)
        if 32<=len(s)<=44:
            found.append((i,s))
    return found

TARGETS = {
 "O13":("3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",[246,74,1064]),
 "O14":("WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",[558,150]),
 "O15":("zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ",[2312,1912,520,59956,264,7175,1064]),
}

for k,(pid,sizes) in TARGETS.items():
    print(f"\n########## {k} {pid} ##########")
    for size in sizes:
        r = get_program_accounts(pid, filters=[{"dataSize":size}], encoding="base64",
                                 dataSlice={"offset":0,"length":min(size,200)})
        res = r.get("result") or []
        if not res: 
            print(f"-- size {size}: none"); continue
        acc = res[0]
        b = base64.b64decode(acc["account"]["data"][0])
        print(f"-- size {size} n={len(res)} pubkey={acc['pubkey']}")
        print(f"   hex[:120]={b[:120].hex()}")
        # full fetch for accurate pubkey scan
        full = get_account_info(acc["pubkey"])["result"]["value"]["data"][0]
        fb = base64.b64decode(full)
        pks = pubkeys_in(fb)
        print(f"   full_len={len(fb)} pubkey-like offsets: {[(o,s) for o,s in pks[:12]]}")
