#!/usr/bin/env python3
"""JustLock final accounting: per-lock value + H-O / S splits.

Valuation:
 - XRD: DefiLlama coingecko:radix (recorded at run time; prefixed here)
 - other tokens: Astrolescent /tokens tokenPriceXRD * xrd_price_usd (aggregator
   last-price; LP/NFT positions priced only where a price exists)
"""
import json

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
XRD_LLAMA = 0.0004519403550191712  # DefiLlama 2026-10-15
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"

summary = json.load(open(f"{OUT}/jl_summary.json"))
meta = json.load(open(f"{OUT}/jl_resource_metadata.json"))
astro = {t["address"]: t for t in json.load(open(f"{OUT}/astro_tokens.json"))}

rows = summary["rows"]
out_rows = []
tot = {"H-O": 0.0, "S": 0.0, "H-O_no_price": [], "S_no_price": []}
for nid, r in sorted(rows.items(), key=lambda kv: int(kv[0].strip("#"))):
    if r["unlocked_at"] is not None:
        continue  # spent receipt (vault empty)
    # value in USD
    amt = float(r["amount"]) if r["amount"] else 0.0
    usd = None
    px_src = None
    if r["resource"] == XRD:
        usd = amt * XRD_LLAMA
        px_src = "defillama-xrd"
    elif r["resource"] in astro:
        usd = amt * astro[r["resource"]]["tokenPriceXRD"] * XRD_LLAMA
        px_src = "astrolescent"
    cat = "S" if r["unlockable_at"] is None else "H-O"
    has_value = amt > 0 or (r["nft_count"] or 0) > 0
    if usd is not None and has_value:
        tot[cat] += usd
    elif has_value:
        tot[cat + "_no_price"].append(
            {"lock": nid, "resource": r["resource"],
             "symbol": (meta.get(r["resource"]) or {}).get("symbol"),
             "amount": r["amount"]})
    out_rows.append({**r, "lock": nid, "verdict": cat if has_value else "H-O-empty",
                     "usd": round(usd, 4) if usd is not None else None, "px": px_src})

json.dump({"rows": out_rows, "totals": tot,
           "xrd_price_usd": XRD_LLAMA, "xrd_price_src": "defillama"},
          open(f"{OUT}/jl_valuation.json", "w"), indent=1)
print("H-O (time-locked, priced): $%.2f" % tot["H-O"])
print("S   (forever, priced):     $%.2f" % tot["S"])
print("H-O unpriced positions:", len(tot["H-O_no_price"]))
print("S unpriced positions:", len(tot["S_no_price"]))
# top values
top = sorted([r for r in out_rows if r["usd"]], key=lambda r: -r["usd"])[:15]
for r in top:
    print(f"  {r['lock']:>7s} {r['verdict']:8s} {str(r['symbol'] if 'symbol' in r else '')[:10]:10s} "
          f"amt={r['amount']} usd={r['usd']}")
# per-resource aggregates for report
agg = {}
for r in out_rows:
    k = (r["verdict"], r["resource"])
    a = agg.setdefault(k, {"verdict": r["verdict"], "resource": r["resource"],
                           "symbol": (meta.get(r["resource"]) or {}).get("symbol"),
                           "amount": 0.0, "usd": 0.0, "locks": 0})
    a["amount"] += float(r["amount"]) if r["amount"] else 0.0
    a["usd"] += r["usd"] or 0.0
    a["locks"] += 1
json.dump(sorted(agg.values(), key=lambda x: -x["usd"]),
          open(f"{OUT}/jl_valuation_by_resource.json", "w"), indent=1)
