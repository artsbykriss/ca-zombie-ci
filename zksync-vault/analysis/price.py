#!/usr/bin/env python3
"""Price the vault's holdings with DefiLlama and compute real-token totals/excess."""
import json, requests, time

V = "0x621425a1Ef6abE91058E9712575dcc4258F8d091"
d = json.load(open("analysis/sweep.json"))
block = d["block"]
res = d["results"]

# Only tokens with a plausible non-dust balance; keep everything for the record.
cands = {a: r for a, r in res.items() if r["balance"] and r["balance"] > 0}
keys = [f"zksync:{a}" for a in cands]
prices = {}
for i in range(0, len(keys), 80):
    chunk = keys[i:i+80]
    for attempt in range(4):
        try:
            j = requests.get("https://coins.llama.fi/prices/current/" + ",".join(chunk), timeout=45).json()
            prices.update(j.get("coins", {}))
            break
        except Exception as e:
            time.sleep(2)
    print(f"priced {min(i+80,len(keys))}/{len(keys)}", flush=True)

SPAM = ("claim", "airdrop", "http", ".com", ".live", ".app", ".org", "visit", "reward", "bonus", "official")
rows = []
for a, r in cands.items():
    p = prices.get(f"zksync:{a}", {})
    dec = r["decimals"]
    bal = r["balance"] / (10 ** dec)
    exc = max(0, (r["balance"] - (r["reserves"] or 0))) / (10 ** dec)
    usd = bal * p.get("price", 0) if p.get("price") else 0.0
    exc_usd = exc * p.get("price", 0) if p.get("price") else 0.0
    rows.append({"token": a, "symbol": r["symbol"], "decimals": dec,
                 "balance": bal, "excess": exc, "price": p.get("price"),
                 "usd": usd, "excess_usd": exc_usd,
                 "spam_name": any(s in (r["symbol"] or "").lower() for s in SPAM)})

rows.sort(key=lambda x: x["usd"], reverse=True)
total = sum(r["usd"] for r in rows)
exc_total = sum(r["excess_usd"] for r in rows)
print(f"block {block}: priced total ERC20 = ${total:,.2f}; priced excess = ${exc_total:,.4f}")
print("top 30 by USD:")
for r in rows[:30]:
    print(f"  {r['usd']:>14,.2f}  {r['balance']:>22.8f} {str(r['symbol'])[:22]:22} {r['token']}  excess={r['excess']:.8f} (${r['excess_usd']:.4f})")
print("top excess by USD:")
for r in sorted(rows, key=lambda x: x["excess_usd"], reverse=True)[:15]:
    print(f"  ${r['excess_usd']:.6f}  {r['excess']:.8f} {r['symbol']} {r['token']}")
json.dump({"block": block, "total_usd": total, "excess_usd_priced": exc_total, "rows": rows},
          open("analysis/priced.json", "w"), indent=1)
