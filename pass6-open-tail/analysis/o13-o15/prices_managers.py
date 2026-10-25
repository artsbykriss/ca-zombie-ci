#!/usr/bin/env python3
import json, base64, urllib.request
from collections import Counter
from sol_rpc import get_program_accounts

ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); out=''
    while n>0: n,r=divmod(n,58); out=ALPH[r]+out
    pad=0
    for c in b:
        if c==0: pad+=1
        else: break
    return '1'*pad+(out or '')

# Index accounts (246): 1-byte disc, manager(32), tokenMint(32), minDeposit u64, fee u16, bump u8, [mint(32)+target(u16)]*5
r = get_program_accounts("3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
                         filters=[{"dataSize":246}], encoding="base64",
                         dataSlice={"offset":0,"length":246})
res = r.get("result") or []
mgr = Counter()
for a in res:
    b = base64.b64decode(a["account"]["data"][0])
    m = b58e(b[1:33])
    mgr[m]+=1
print("Index accounts:", len(res))
print("top managers:")
for m,c in mgr.most_common(10):
    print("  ",m,c)

# prices
def fetch(url):
    req=urllib.request.Request(url, headers={"User-Agent":"audit/1.0"})
    return json.loads(urllib.request.urlopen(req,timeout=30).read().decode())
mints={"USDC":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
       "SOL":"So11111111111111111111111111111111111111112",
       "USDT":"Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
       "BONK":"DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
       "JUP":"JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
       "JLP":"27G8MtK7VtTcCHkpASjSDdkWWYfoqT6ggEuKidVJidD4",
       "JTO":"jtojtomepa8beP8AuQc6eXt5FriJwfFMwQx2v2f9mCL",
       "PYTH":"HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3"}
try:
    url="https://coins.llama.fi/prices/current/"+",".join(f"solana:{m}" for m in mints.values())
    pj=fetch(url)
    print("\nPRICES:")
    for sym,m in mints.items():
        c=pj.get("coins",{}).get(f"solana:{m}")
        print(f"  {sym:8s} {c.get('price') if c else None}  ({c.get('symbol') if c else '-'}) conf={c.get('confidence') if c else '-'}")
    json.dump(pj, open("prices.json","w"), indent=1)
except Exception as e:
    print("price err", e)
