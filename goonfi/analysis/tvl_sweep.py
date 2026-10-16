#!/usr/bin/env python3
"""Compute per-market TVL (USD) + oracle freshness + implied price checks for the sweep."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.dirname(os.path.abspath(__file__))

d = json.load(open(os.path.join(OUT, "market-sweep.json")))
names = json.load(open(os.path.join(OUT, "mint-names.json")))

CURRENT_SLOT = max((m["oracle_info"] or {}).get("slot", 0) for m in d["markets"])
print("approx current slot:", CURRENT_SLOT)

rows = []
for m in d["markets"]:
    mint_a, mint_b = m["mint_a"], m["mint_b"]
    dec_a = (m["mint_a_info"] or {}).get("decimals", 9)
    dec_b = (m["mint_b_info"] or {}).get("decimals", 6)
    va = (m["vault_a_info"] or {}).get("amount", 0) or 0
    vb = (m["vault_b_info"] or {}).get("amount", 0) or 0
    pa = (names.get(mint_a) or {}).get("usdPrice") or 0
    pb = (names.get(mint_b) or {}).get("usdPrice") or 0
    usd_a = va / 10**dec_a * pa
    usd_b = vb / 10**dec_b * pb
    oi = m["oracle_info"] or {}
    rows.append({
        "pool": m["pool"],
        "pair": f"{(names.get(mint_a) or {}).get('symbol', mint_a[:6])}/{(names.get(mint_b) or {}).get('symbol', mint_b[:6])}",
        "vault_a": va, "dec_a": dec_a, "usd_a": round(usd_a, 2),
        "vault_b": vb, "dec_b": dec_b, "usd_b": round(usd_b, 2),
        "tvl_usd": round(usd_a + usd_b, 2),
        "oracle": m["oracle"], "P1": oi.get("P1"), "P2": oi.get("P2"), "denom": oi.get("denom"),
        "o_slot": oi.get("slot"), "o_age_slots": (CURRENT_SLOT - oi.get("slot", 0)) if oi.get("slot") else None,
        "o_ts": oi.get("ts"),
        "implied_price": (oi.get("P1") / oi.get("denom")) if oi.get("denom") else None,
    })

rows.sort(key=lambda r: -r["tvl_usd"])
tot = sum(r["tvl_usd"] for r in rows)
print(f"\nTOTAL TVL across {len(rows)} markets: ${tot:,.2f}")
print(f"{'pair':18s} {'TVL_USD':>14s} {'usdA':>12s} {'usdB':>12s} {'oracleP1/denom':>16s} {'age_slots':>10s}")
for r in rows:
    print(f"{r['pair']:18s} {r['tvl_usd']:>14,.0f} {r['usd_a']:>12,.0f} {r['usd_b']:>12,.0f} "
          f"{(r['implied_price'] if r['implied_price'] else 0):>16.6f} {r['o_age_slots'] if r['o_age_slots'] is not None else -1:>10d}")
json.dump({"total_tvl_usd": round(tot, 2), "rows": rows}, open(os.path.join(OUT, "tvl-sweep.json"), "w"), indent=1)

# largest-vault side per pool (drain target for unbound-oracle if it existed)
print("\ntop single-side exposures:")
for r in rows[:12]:
    big = "A" if r["usd_a"] > r["usd_b"] else "B"
    print(f"  {r['pair']:18s} bigger side {big}: ${max(r['usd_a'], r['usd_b']):,.0f}")
