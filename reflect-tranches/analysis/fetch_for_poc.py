#!/usr/bin/env python3
"""Fetch all mainnet accounts + program ELFs needed for the LiteSVM auth harness.
Writes poc/accounts.json and poc/programs/*.so. READ-ONLY."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POC = os.path.join(ROOT, "poc")
os.makedirs(os.path.join(POC, "programs"), exist_ok=True)

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

ADDRS = {
    # RLP
    "rlp_settings": "9q89A973AWTkvWi87tKPj8GSw58b6JJhWALCJ1MGXNFc",
    "perm_supremo": "8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625",
    "perm_manager": "CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY",
    "perm_empty": "GNwSK8YpM85bd2YeJaA2BmUxGVqEe4hyCLqc8eR2PCgt",
    "pool0": "HcSqywSCt1tQ9XPD2ztEmZ3kaWc1ZgB7vs8GxCbbH7pw",
    "pool4": "5dVxqyK1m3f4ZiPjZEhwgTLH5wZrU79d4Bsd67pgQk46",
    "pool5": "GtMx2AbDG4HgSwD4biU3PB73fWDkX8kYx1yX44RRZvLq",
    "asset0": "27K2omY6vfgx2SH8htus5pb4CXT29tXhvFFXgy5UTwZr",       # AvZZF (USDC+)
    "asset3": "BVW2eUgNcFxzBwnXd71fgwqERyJt5Y4XfvVn1UgxPVzZ",       # HnnG (eHYUSD)
    "mint0": "AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj",
    "mint3": "HnnGv3HrSqjRpgdFmx7vQGjntNEoex1SU4e9Lxcxuihz",
    "lp0": "Aa1uLLCFrJ3tLsKZnnxomovBDcikxTyNJEHwje7k9xNE",
    "lp5": "jrZjCWLJMu5rabYcu1fbkZPK6daMdjLbyQM5NVeVGNG",
    "cooldown_matured": "7eaiKPdYedBqCSbLhUB7ktbFkK8CMjdLTAoRiAM94ZUP",   # auth KuBAWM6p, pool0
    "cooldown_escrow": "8gxZyBDPM5i5ShMohYBGknta6vLVxDQMJX8Q4FdXFFYV",
    "cooldown_matured2": "AUP5aADKPjA4KRFtLy7tpo17ziZuG73NZj43Po6Ss5f5",  # auth KuBAWM6p, pool5
    "cooldown_escrow2": "HBrdrfQ8d4ALUqAMaL1tvVud5ULTn4nidWBvb2Ucj2jg",
    "pool0_ata0": "Dh1sPTGc9YycHKnw5t4S1Ss24TtcoWTiD61azGSmtoS5",
    "pool5_ata3": "48cUs7CDhTh29uXBM4LjuK4GJMtHtv3MyWNgn9FfsmVn",
    "streamprice_rlp": "7vwbmCQKApjcjGL3ci6UuMk12RALHh2SQTEPqo5RLU8y",
    # exact accounts of a real on-chain RLP Withdraw tx (slot 460429494), pool AAyszk / mint 3b8X44fL
    "pool_a": "AAyszkQtxXEgFPwq6E19TkcuyJpK9gpxofk9LZzhdE9j",
    "lp_a": "JrGsMfJodyVEqLGnyAKa9qHzRqZ9dzFfeSjouV3qEeG",
    "asset_a": "HqZ7TKBR6DLhFLnCujsTdnQ3WSdVoHiV9BXQWhGx7mbJ",
    "mint_a": "3b8X44fLF9ooXaUm3hhSgjpmVs6rZZ3pPoGnGahc3Uu7",
    "pool_a_ata": "GYgwMfwfjwtBZhx1ongrGC5cbqAWJfL8qZEFwejMptHv",
    "streamprice_a": "z9WRzdCfvHtVjGSLQjfNhynRY6XZHRX9hSJFgWV7j9A",
    "proxy_state_a": "By42A3QzVt1KERdnJcPESGWR3YoN2GSbzZroQFGJ6Qjm",
    "proxy_vault_a": "J6fkJ53tCcentTPgiExLJmo6iKRnUKBbU9FAaKVxC461",
    "cooldown_a": "H9AihFBfAwVuwimeySWM1Xk9w9iUpS5Lj2qXq5S3vDru",
    "cooldown_a_escrow": "6HqnrLXX7WTMXLkzLpC9EWaYB6T7MKXz9PJwNt4JDs3r",
    # Proxy
    "proxy_state0": "FD4YydhzPpSmXwnHsX1oJBE4er4m9mg4ezaBN9cXgQbz",     # pool0 senior, auth apyaB89k
    "proxy_state_admin": "HAsdi8ZHEL7ydCgEC61AoNqB47QNVsabzUDimsjJx1yW",  # auth KuBAWM6p
    "proxy_vault0": "E5ohyMVkBTdn3DekUPcFyLFF2Wi78Rg3Mt9QQDWgN5Mp",     # USDC+ ATA of proxy_state0
    "streamprice_proxy": "4DyKf93NzxTruQh5KMWGH9NkoE32tBBf33m3zyu2Efm3",
    "streamprice_proxy2": "Dxotk9fx271hzyWof9VvmxVt3pxYia4gaiTtk71qDpnt",
    # from the real on-chain proxy `Claim Fees` tx (slot 460231056, ProxyState FD4Yydhz)
    "proxy_oracle0": "GWdwWDhYFUc8ZD6uCTtEAAwx97V1ZCsxPWGL7vhSha6w",
    "proxy_cfg0": "V8eHEsRUBcxpkYZN2jhjYLzJFhbWbFvpNJYBp1YHNar",
    "authority_ata0": "UVw4BJXJqnVpi9Qw98KXcHNYS6ZG836ZcX8rqibTnFq",
}

def get(pk):
    v = rpc("getAccountInfo", [pk, {"encoding": "base64"}])["result"]["value"]
    if not v:
        return None
    return {"lamports": v["lamports"], "owner": v["owner"],
            "executable": v["executable"], "data": v["data"][0],
            "rentEpoch": v.get("rentEpoch", 0), "space": v.get("space")}

accts = {}
for name, pk in ADDRS.items():
    a = get(pk)
    if a is None:
        print("MISSING", name, pk)
        continue
    a["pubkey"] = pk
    accts[name] = a
    print(f"{name:22} {pk} owner={a['owner'][:10]} len={len(base64.b64decode(a['data']))}")

# branded mints + largest holders
branded = {}
for name in ("proxy_state0", "proxy_state_admin"):
    if name not in accts:
        continue
    d = base64.b64decode(accts[name]["data"])
    bm = str(__import__("solders.pubkey", fromlist=["Pubkey"]).Pubkey.from_bytes(d[0:32]))
    r = rpc("getProgramAccounts", [TOKEN, {"encoding": "base64",
             "filters": [{"dataSize": 165}, {"memcmp": {"offset": 0, "bytes": bm}}]}])
    holders = []
    for a in r.get("result", []):
        d = base64.b64decode(a["account"]["data"][0])
        amt = int.from_bytes(d[64:72], "little")
        owner = str(__import__("solders.pubkey", fromlist=["Pubkey"]).Pubkey.from_bytes(d[32:64]))
        if amt > 0:
            holders.append({"address": a["pubkey"], "amount": amt, "owner": owner})
    holders.sort(key=lambda h: -h["amount"])
    branded[name] = {"branded_mint": bm, "holders": holders[:5]}
    print(f"{name} branded_mint={bm} holders={[(h['address'], h['amount'], h['owner']) for h in holders[:3]]}")
    a = get(bm)
    if a:
        a["pubkey"] = bm
        accts[f"{name}_branded_mint"] = a
    for i, h in enumerate(holders[:2]):
        ha = get(h["address"])
        if ha:
            ha["pubkey"] = h["address"]
            accts[f"{name}_holder{i}"] = ha

# program ELFs
for name, pk in [("spl_token", TOKEN), ("ata", ATA)]:
    v = rpc("getAccountInfo", [pk, {"encoding": "base64"}])["result"]["value"]
    d = base64.b64decode(v["data"][0])
    if v["owner"].startswith("BPFLoaderUpgradeab1e"):
        pd = str(__import__("solders.pubkey", fromlist=["Pubkey"]).Pubkey.from_bytes(d[4:36]))
        v2 = rpc("getAccountInfo", [pd, {"encoding": "base64"}])["result"]["value"]
        elf = base64.b64decode(v2["data"][0])[45:]
    else:  # BPFLoader2 -> ELF stored directly in the program account
        elf = d
    open(os.path.join(POC, "programs", f"{name}.so"), "wb").write(elf)
    print(f"{name} ELF {len(elf)} magic {elf[:4].hex()}")

out = {"slot": rpc("getSlot", [])["result"], "accounts": accts, "branded": branded}
json.dump(out, open(os.path.join(POC, "accounts.json"), "w"), indent=1)
print("wrote poc/accounts.json, accounts:", len(accts), "slot", out["slot"])
