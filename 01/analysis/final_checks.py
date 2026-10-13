#!/usr/bin/env python3
"""Final checks: upgrade auth curve type, vault PDA seeds, Token-2022 mint, unpriced token pricing."""
import json, urllib.request, time, base64, hashlib
from solders.pubkey import Pubkey

RPC="https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=4, timeout=60):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=timeout) as r: out=json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

# 1) curve type of upgrade authority + admin
for label,addr in [("upgrade_authority","DtCyZQSP9AjdasXJPs5m5Q8dovo73UJvUG1ieosofDwX"),
                   ("admin","DH7N1sJQxyLJqc79fk67U32mymejUiRVH8SqayTuRtG7")]:
    pk=Pubkey.from_string(addr)
    print(f"{label} {addr} is_on_curve={pk.is_on_curve()}")
    r=rpc("getAccountInfo",[addr,{"encoding":"jsonParsed"}])
    v=r["result"]["value"]
    print("   account:", None if v is None else {k:v[k] for k in ("lamports","owner","executable","space")})

# 2) brute force vault PDA seeds under zo program
ZO=Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TARGET="HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ"
cands=[]
for s in ["state_signer","vault","vaultv1","usdc_vault","state","signer","collateral","vault_signer",
          "zo_vault","usdc","zovault","statev1","vault_v1","crank","insurance"]:
    try:
        pk,b=Pubkey.find_program_address([s.encode()],ZO)
        if str(pk)==TARGET: cands.append((s,b))
    except Exception: pass
# also [state, "vaultv1"], [state,"vault"], etc
STATE=Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
for s in ["vault","vaultv1","signer","state_signer","usdc","collateral"]:
    try:
        pk,b=Pubkey.find_program_address([bytes(STATE),s.encode()],ZO)
        if str(pk)==TARGET: cands.append((f"state+{s}",b))
        pk2,b2=Pubkey.find_program_address([s.encode(),bytes(STATE)],ZO)
        if str(pk2)==TARGET: cands.append((f"{s}+state",b2))
    except Exception: pass
print("vault PDA seed candidates found:", cands)

# 3) Token-2022 mint info
MINT="7atgF8KQo4wJrD5ATGX7t1V2zVvykPJbBfNeVf1icFv1"
r=rpc("getAccountInfo",[MINT,{"encoding":"jsonParsed"}])
print("Token-2022 mint:", json.dumps(r["result"]["value"]["data"]["parsed"]["info"])[:400] if r["result"]["value"] else None)
# metadata via Metaplex
MD="metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
from solders.pubkey import Pubkey as PK
mint_pk=PK.from_string(MINT)
md,b=PK.find_program_address([b"metadata",bytes(PK.from_string(MD)),bytes(mint_pk)],PK.from_string(MD))
r2=rpc("getAccountInfo",[str(md),{"encoding":"base64"}])
v=r2["result"]["value"]
if v:
    raw=base64.b64decode(v["data"][0])
    # crude: find name/symbol strings
    import re
    txt=raw[100:400]
    print("metadata bytes sample:", txt[:200])

# 4) price unpriced mints via Jupiter lite
mints=["7ErXFX2cyDJQkJBBDMHGNrMnhiDtLSx4JbgkgC8xULZ","PhiLR4JDZB9z92rYT5xBXKCxmq4pGB1LYjtybii7aiS",
 "gQapjceHRemqLL6gVHSWzYkUUs2He9vsdZBBRzcW59q","n54ZwXEcLnc3o7zK48nhrLV4KTU5wWD4iq7Gvdt5tik",
 "pFcUy6KUPQAQKzBHLYDRpiVEz27BxGn9ha7CqeRMcd6","rnGPrVgfDG8LmBKHCpjD91jgdBRWgUd3YhdT1co3pTW",
 "2Vw7vxDAEdXvupRRPf112TM3LKZyQ7SsCef6wR5vAjki","4D8osAENNF5sW7HcYQZd4p7kptM57NmxhtmRdTAxiFDi",
 "4PCW8brVMxLnunSsrLLt9v72VukCUTwLwqFw7o78gkyQ","5HbkoVbaMnJYEuiTqeC7cBMSK2zG2MFfoxc9e6VkWPQS",
 "5QE9fJZ76YDnfuLT4RSxjZGMMD8huDgyrdevFniQ6Ak6","8ojQuBwfC7xwfL6kvcdSJzMr71NZ8eE349LnWj657jQL",
 "8yeSLFG6YW41ntGpnyTKUnyh4V2QUt4hWgkTdknj8Gje","93CJqHHMCSYmA7RhpLEw2oTwF57qiBDF1Padaew4Xi1F",
 "9CYzZod3S27NaXQurJ127ZN2ihGpS4jQhjqj4XAM7CVS","9JP9pX8uaqm1JFzDsgBuC8oyqK3AbH49WYfUKz8LgYrq",
 "9LbdhSersRjbkcWWdd4Xpgr8ADi16dwzMU1tM1Ddsq79","9nQKC2fKKKViVk6FWoj4erq3qbmkf37TjrFkiDBA1pDk",
 "9pfuwWhPV91ytBqRhJUeXTJjAp2y7sr57jRpvxM4cQiJ","BzuXXEnEybVqwAAQmCcrwaz1xmvAWohvTgrrKNowV6tZ",
 "CZE1zaDWwGdfCRqVEr45kSB8U3EJYsNHBBxGqPP3i84P","Cf4at3EqCPEQ2qGCF9okoGj8F9CmvcQXVDkJpEnJnbDs",
 "E7jFUAn8f3sgfprgc2W2xSs1HXTimFxqRRJNKL4PNTeP","GxsuYTU9CpyNA2K4wHm3HSbLoAxc7uuwb7nSKWQZeEwT"]
try:
    url="https://lite-api.jup.ag/price/v3?ids="+",".join(mints)
    req=urllib.request.Request(url,headers={"User-Agent":"research/1.0"})
    d=json.loads(urllib.request.urlopen(req,timeout=60).read())
    for m in mints:
        e=d.get(m)
        print(f"  jup {m[:12]}.. price={e.get('usdPrice') if e else None}")
except Exception as e:
    print("jupiter error:", e)
