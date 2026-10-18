#!/usr/bin/env python3
"""Attribute vault custody to pools vs other accounts, price it, and find dead pools."""
import json, requests

V = "0x621425a1Ef6abE91058E9712575dcc4258F8d091"
ETH = 2408.452797352334  # DefiLlama coingecko:ethereum, 2026-10-18
priced = json.load(open("analysis/priced.json"))
px = {r["token"].lower(): (r["price"] or 0) for r in priced["rows"]}
px["0x0000000000000000000000000000000000000000"] = ETH
px["0x5aea5775959fbc2557cc8789bc1bf90a239d9a91"] = ETH

d = json.load(open("analysis/pool_excess.json"))
block = d["block"]
pools = d["pools"]

def usd(tok, raw):
    if raw is None:
        return 0.0
    tok = tok.lower()
    p = px.get(tok, 0)
    # decimals from priced rows, default 18
    dec = 18
    for r in priced["rows"]:
        if r["token"].lower() == tok:
            dec = r["decimals"]; break
    return raw / (10 ** dec) * p

pool_total = 0.0
rows = []
for p in pools:
    u0 = usd(p["token0"], p["vault0"])
    u1 = usd(p["token1"], p["vault1"])
    pool_total += u0 + u1
    rows.append({**p, "usd0": u0, "usd1": u1, "usd": u0 + u1})
rows.sort(key=lambda x: x["usd"], reverse=True)

total = priced["total_usd"] + 1116.526887141561623383 * ETH
print(f"block {block}")
print(f"total custody      = ${total:,.2f}")
print(f"pool-attributed    = ${pool_total:,.2f}  ({pool_total/total*100:.2f}%)")
print(f"non-pool (users+)  = ${total-pool_total:,.2f}")
print("top 15 pools:")
for r in rows[:15]:
    print(f"  ${r['usd']:>12,.2f}  {r['kind']:7} {r['pool']}  t0={r['token0']} v0={r['vault0']}  t1={r['token1']} v1={r['vault1']}")
dead = [r for r in rows if (r["reserve0"] is None or r["reserve1"] is None) and ((r["vault0"] or 0) or (r["vault1"] or 0))]
print("pools with unreadable reserves but nonzero vault balance:", len(dead))
for r in dead[:20]:
    print(" ", r["pool"], r["token0"], r["vault0"], r["token1"], r["vault1"])
json.dump({"block": block, "total_custody_usd": total, "pool_attributed_usd": pool_total,
           "non_pool_usd": total - pool_total, "pools": rows, "dead_pools": dead},
          open("analysis/attribution.json", "w"), indent=1)
