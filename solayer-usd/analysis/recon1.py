#!/usr/bin/env python3
"""Step 1 recon: dump key accounts for Solayer USD (sUSD) target. Read-only, keyless."""
import json, base64, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

MINT   = "LAYER4xPpTCb3QL8S9u41EAhAX7mhBn8Q6xMTwY2Yzc"
AUTH   = "7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru"
PROG   = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
PDATA  = "7bzcebKDN8qDkftxobwArKJL8xSGaZ6zBPaY4C4wEhkf"
POOL   = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
TOK22  = "BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
USDC   = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

out = {}
slot = s.get_slot()["result"]
out["slot"] = slot

def ai(k, enc="base64"):
    return s.get_account_info(k, enc)["result"]["value"]

for name, key in [("mint_susd", MINT), ("auth", AUTH), ("prog", PROG), ("pdata", PDATA),
                  ("pool", POOL), ("tok22", TOK22), ("usdc", USDC)]:
    v = ai(key)
    if v is None:
        out[name] = None; continue
    d = v["data"][0]
    out[name] = {"owner": v["owner"], "lamports": v["lamports"], "space": v["space"],
                 "executable": v["executable"], "data_b64": d}
    print(name, key, "owner", v["owner"], "space", v["space"], "exec", v["executable"])

# mint parsed
for name, key in [("mint_susd", MINT), ("tok22", TOK22), ("usdc", USDC)]:
    r = s.rpc("getAccountInfo", [key, {"encoding": "jsonParsed", "commitment": "confirmed"}])
    out[name + "_parsed"] = r["result"]["value"]
    print(name, "parsed:", json.dumps(r["result"]["value"].get("data", {}).get("parsed", {}).get("info", {})))

# supplies
for name, key in [("mint_susd", MINT), ("tok22", TOK22), ("usdc", USDC)]:
    r = s.get_token_supply(key)
    out[name + "_supply"] = r.get("result")
    print(name, "supply", r.get("result", {}).get("value"))

# token accounts of pool
for pid, label in [("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", "spl"),
                   ("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb", "t22")]:
    try:
        r = s.get_token_accounts_by_owner(POOL, program_id=pid)
        out["pool_tokaccts_" + label] = r.get("result")
        for it in (r.get("result") or {}).get("value", []):
            print("pool", label, it["pubkey"], it["account"]["data"]["parsed"]["info"].get("mint"),
                  it["account"]["data"]["parsed"]["info"].get("tokenAmount"))
    except Exception as e:
        print("err", label, e)

# program account -> programdata
pv = ai(PROG)
raw = base64.b64decode(pv["data_b64"])
out["prog_programdata_addr"] = b58enc(raw[4:36])
print("programdata from program acct:", out["prog_programdata_addr"])

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon1.json"), "w"), indent=1)
print("slot", slot)
print("saved recon1.json")
