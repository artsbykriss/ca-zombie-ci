#!/usr/bin/env python3
"""Fetch BisonFi state: all program accounts (pool states), vaults, referenced accounts. Read-only."""
import base64, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
PROG = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi"
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); out=''
    while n: n,r2=divmod(n,58); out=ALPHA[r2]+out
    for c in b:
        if c==0: out='1'+out
        else: break
    return out

def get_accounts(addrs):
    out={}
    for i in range(0, len(addrs), 10):
        chunk=addrs[i:i+10]
        reqs=[{"jsonrpc":"2.0","id":j,"method":"getAccountInfo","params":[a,{"encoding":"base64","commitment":"confirmed"}]} for j,a in enumerate(chunk)]
        import urllib.request
        payload=json.dumps(reqs).encode()
        try:
            req=urllib.request.Request("https://solana-rpc.publicnode.com",data=payload,headers={"Content-Type":"application/json","User-Agent":"zr/1.0"})
            with urllib.request.urlopen(req,timeout=90) as r:
                res=json.loads(r.read())
        except Exception as e:
            print("batch err", e); continue
        byid={r.get("id"): r.get("result") for r in res if isinstance(r,dict)}
        for j,a in enumerate(chunk):
            v=(byid.get(j) or {}).get("value")
            if v is None: out[a]=None; continue
            data=base64.b64decode(v["data"][0]) if v["data"] else b""
            out[a]={"owner":v["owner"],"executable":v["executable"],"lamports":v["lamports"],"dataLen":len(data),"data_b64":v["data"][0]}
    return out

if __name__=="__main__":
    # 1) all accounts owned by the program with dataSize 2048 (pool states) via getProgramAccounts
    r=rpc("getProgramAccounts",[PROG,{"encoding":"base64","filters":[{"dataSize":2048}],"commitment":"confirmed"}])
    accts=r.get("result")
    print("pool-state-like accounts:", len(accts) if accts is not None else r.get("error"))
    states=[]
    if accts:
        for a in accts:
            data=base64.b64decode(a["account"]["data"][0])
            disc=data[:8]
            states.append({"pubkey":a["pubkey"],"lamports":a["account"]["lamports"],"disc":disc.decode('latin1'),"data_b64":a["account"]["data"][0]})
        json.dump(states, open(os.path.join(OUT,"pool-states-2048.json"),"w"), indent=1)
        for s in states:
            print(" ", s["pubkey"], "lamports", s["lamports"], "disc", repr(s["disc"]))
    # 2) other sizes
    r2=rpc("getProgramAccounts",[PROG,{"encoding":"base64","dataSlice":{"offset":0,"length":16},"commitment":"confirmed"}])
    allp=r2.get("result") or []
    sizes={}
    for a in allp:
        # dataSlice gives only 16 bytes; need full len
        pass
    print("total program accounts:", len(allp))
