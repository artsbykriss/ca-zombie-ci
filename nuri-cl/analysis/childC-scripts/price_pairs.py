#!/usr/bin/env python3
"""Price the V2 pair tokens with DefiLlama and compute per-pair USD + total."""
import json, urllib.request, urllib.parse

d = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"))
tokens = sorted(d["tokens"].keys())
prices = {}
CH = 40
for s in range(0, len(tokens), CH):
    chunk = tokens[s:s+CH]
    ids = ",".join("scroll:" + t for t in chunk)
    url = "https://coins.llama.fi/prices/current/" + urllib.parse.quote(ids, safe=",:")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    r = json.load(urllib.request.urlopen(req, timeout=60))
    for k, v in (r.get("coins") or {}).items():
        prices[k.split(":", 1)[1].lower()] = v
    print("chunk", s, "got", len(r.get("coins") or {}), "missing:", [t for t in chunk if ("scroll:" + t) not in (r.get("coins") or {})])

def usd(token, raw):
    p = prices.get(token.lower())
    if not p or raw is None:
        return 0.0, None
    dec = p.get("decimals")
    if dec is None:
        dec = d["tokens"].get(token, {}).get("decimals")
    if dec is None:
        return 0.0, None
    return raw / 10**dec * float(p["price"]), float(p["price"])

def p_token_sym(dd, t):
    m = dd["tokens"].get(t, {})
    s = m.get("symbol")
    return s if isinstance(s, str) else None

rows = []
total = 0.0
unpriced = []
for p in d["pairs"]:
    v = 0.0
    detail = {}
    for i in (0, 1):
        t = p.get(f"token{i}")
        raw = p.get(f"balance_token{i}")
        u, pr = usd(t, raw)
        v += u
        detail[f"token{i}"] = {"address": t, "symbol": p_token_sym(d, t), "raw": raw, "price": pr, "usd": round(u, 2)}
        if pr is None and (raw or 0) > 0:
            unpriced.append((p["pair"], t, p_token_sym(d, t), raw))
    total += v
    rows.append({"pair": p["pair"], "symbol": p.get("symbol"), "stable": p.get("stable"),
                 "usd": round(v, 2), "tokens": detail, "totalSupply": p.get("totalSupply")})

def p_token_sym(dd, t):
    m = dd["tokens"].get(t, {})
    s = m.get("symbol")
    return s if isinstance(s, str) else None

rows_sorted = sorted(rows, key=lambda r: -r["usd"])
print("TOTAL V2 USD: %.2f" % total)
print("TOP 10:")
for r in rows_sorted[:10]:
    print(json.dumps(r))
print("priced tokens:", len(prices), "of", len(tokens))
print("unpriced non-zero holdings:", unpriced[:30])
json.dump({"block": d["block"], "factory": d["factory"], "prices": prices,
           "total_usd": round(total, 2), "pairs": rows_sorted,
           "unpriced_nonzero": unpriced},
          open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs-priced.json", "w"), indent=1)
print("saved childC-v2-pairs-priced.json")
