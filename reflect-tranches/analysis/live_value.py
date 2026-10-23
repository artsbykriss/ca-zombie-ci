#!/usr/bin/env python3
"""Enumerate live RLP pools + proxy states, all token accounts they own, and value them in USD."""
import sys, os, json, base64, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e

TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"

def gpa(prog, filters=None):
    cfg = {"encoding": "base64"}
    if filters:
        cfg["filters"] = filters
    return rpc("getProgramAccounts", [prog, cfg]).get("result", [])

def ta_by_owner(owner):
    out = []
    for tp in (TOKEN, TOKEN22):
        r = rpc("getTokenAccountsByOwner", [owner, {"programId": tp}, {"encoding": "jsonParsed"}])
        for a in r.get("result", {}).get("value", []):
            info = a["account"]["data"]["parsed"]["info"]
            out.append({"pubkey": a["pubkey"], "mint": info["mint"],
                        "amount": info["tokenAmount"]["amount"],
                        "ui": info["tokenAmount"]["uiAmountString"],
                        "decimals": info["tokenAmount"]["decimals"]})
    return out

# --- assets
assets = {}
for a in gpa(RLP, [{"memcmp": {"offset": 0, "bytes": b58e(bytes([234,180,241,252,139,224,160,8]))}}]):
    d = base64.b64decode(a["account"]["data"][0])
    assets[d[9]] = {"pubkey": a["pubkey"], "mint": b58e(d[10:42]), "len": len(d)}

# --- pools
pools = []
for a in gpa(RLP, [{"memcmp": {"offset": 0, "bytes": b58e(bytes([66,38,17,64,188,80,68,129]))}}]):
    d = base64.b64decode(a["account"]["data"][0])
    o = 58
    has_cap = d[o] == 1; o += 1
    cap = int.from_bytes(d[o:o+8], "little") if has_cap else None
    if has_cap: o += 8
    ac = d[o]; o += 1
    idxs = list(d[o:o+4]); o += 4
    has_pv = d[o] == 1; o += 1
    pv = b58e(d[o:o+32]) if has_pv else None
    lp_mint = b58e(d[10:42])
    pools.append({"pubkey": a["pubkey"], "lp_mint": lp_mint, "cooldowns": int.from_bytes(d[42:50], "little"),
                  "cooldown_duration": int.from_bytes(d[50:58], "little"), "cap": cap,
                  "assetCount": ac, "assetIdxs": idxs, "protected_vault": pv, "len": len(d)})

# --- proxy states
proxy_states = {}
for a in gpa(PROXY):
    d = base64.b64decode(a["account"]["data"][0])
    if len(d) == 156:
        proxy_states[a["pubkey"]] = {"branded_mint": b58e(d[0:32]), "stablecoin_mint": b58e(d[32:64]),
                                     "fee": int.from_bytes(d[64:66], "little"),
                                     "principal": int.from_bytes(d[66:74], "little"),
                                     "commission": int.from_bytes(d[74:82], "little"),
                                     "authority": b58e(d[82:114]), "bump": d[114], "hex": d.hex()}

out = {"slot": rpc("getSlot", [])["result"], "assets": assets, "pools": pools,
       "proxy_state_count": len(proxy_states), "proxy_states": {}}

mints = set()
rows = []
for p in pools:
    if not p["protected_vault"] or p["protected_vault"] not in proxy_states:
        continue
    pv = proxy_states[p["protected_vault"]]
    # all token accounts owned by the pool PDA
    pool_tas = ta_by_owner(p["pubkey"])
    proxy_tas = ta_by_owner(p["protected_vault"])
    for t in pool_tas:
        mints.add(t["mint"])
    for t in proxy_tas:
        mints.add(t["mint"])
    rows.append({"pool": p, "proxy": pv, "pool_token_accounts": pool_tas, "proxy_token_accounts": proxy_tas})
    out["proxy_states"][p["protected_vault"]] = pv

out["rows"] = rows
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json"), "w"), indent=2)
print("slot", out["slot"], "pools", len(pools), "live", len(rows), "proxy_states", len(proxy_states))
for r in rows:
    print(f"\nPOOL {r['pool']['pubkey']} idxs={r['pool']['assetIdxs']} cap={r['pool']['cap']} cd={r['pool']['cooldown_duration']} lp={r['pool']['lp_mint']}")
    print(f"   proxy {r['proxy']['branded_mint']} stable={r['proxy']['stablecoin_mint']} fee={r['proxy']['fee']} principal={r['proxy']['principal']} comm={r['proxy']['commission']} auth={r['proxy']['authority']}")
    for t in r["pool_token_accounts"]:
        print(f"   pool ATA {t['mint']} amount={t['ui']} ({t['amount']}) dec={t['decimals']} pk={t['pubkey']}")
    for t in r["proxy_token_accounts"]:
        print(f"   proxy ATA {t['mint']} amount={t['ui']} ({t['amount']}) dec={t['decimals']} pk={t['pubkey']}")
print("\nall mints:", sorted(mints))
