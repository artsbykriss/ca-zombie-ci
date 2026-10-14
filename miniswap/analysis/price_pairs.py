#!/usr/bin/env python3
"""Price all MiniSwap pair tokens via DefiLlama; compute per-pair reserve USD and excess USD."""
import json, subprocess, sys

d = json.load(open("analysis/pairs_raw.json"))
tokens = set()
for p in d["pairs"]:
    tokens.add(p["token0"]); tokens.add(p["token1"])
tokens = sorted(tokens)
addrs = [f"ethereum:{t}" for t in tokens]
prices = {}
for i in range(0, len(addrs), 60):
    part = addrs[i:i+60]
    url = "https://coins.llama.fi/prices/current/" + ",".join(part)
    out = subprocess.run(["curl","-s","--max-time","40",url], capture_output=True).stdout
    try:
        j = json.loads(out)
        prices.update(j.get("coins", {}))
    except Exception as e:
        print("price fetch err", e, out[:200], file=sys.stderr)

def price(t):
    c = prices.get(f"ethereum:{t}")
    return c["price"] if c else None

rows = []
tot = 0.0; tot_excess = 0.0
for p in d["pairs"]:
    d0 = p["decimals0"] if p["decimals0"] is not None else 18
    d1 = p["decimals1"] if p["decimals1"] is not None else 18
    p0 = price(p["token0"]); p1 = price(p["token1"])
    v0 = (p["reserve0"]/10**d0)*p0 if (p0 is not None and p["reserve0"] is not None) else None
    v1 = (p["reserve1"]/10**d1)*p1 if (p1 is not None and p["reserve1"] is not None) else None
    v = (v0 or 0)+(v1 or 0)
    e0 = p["excess0"] or 0; e1 = p["excess1"] or 0
    ev0 = (e0/10**d0)*p0 if p0 else 0
    ev1 = (e1/10**d1)*p1 if p1 else 0
    tot += v; tot_excess += (ev0 or 0)+(ev1 or 0)
    rows.append({**p, "price0": p0, "price1": p1, "usd0": v0, "usd1": v1, "usd": v, "excess_usd": (ev0 or 0)+(ev1 or 0)})

rows.sort(key=lambda r: -r["usd"])
json.dump({"block": d["block"], "total_usd": tot, "total_excess_usd": tot_excess, "rows": rows},
          open("analysis/priced_pairs.json","w"), indent=1)
print(f"block={d['block']} pairs={len(rows)} total_usd={tot:,.2f} total_excess_usd={tot_excess:,.4f}")
print(f"{'pair':44s} {'sym0':10s} {'sym1':10s} {'usd':>10s} {'excess$':>8s}")
for r in rows[:20]:
    print(f"{r['pair']:44s} {str(r['symbol0'])[:10]:10s} {str(r['symbol1'])[:10]:10s} {r['usd']:10,.2f} {r['excess_usd']:8,.2f}")
print("--- unpriced tokens ---")
for t in tokens:
    if price(t) is None: print(" ", t)
