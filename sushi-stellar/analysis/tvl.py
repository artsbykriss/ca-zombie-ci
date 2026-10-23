#!/usr/bin/env python3
"""Compute per-pool and total TVL from live_state.json using DefiLlama prices (issuer-based keys)."""
import json, urllib.request, re
from concurrent.futures import ThreadPoolExecutor

STATE = "/home/heisenberg/CA/sushi-stellar/analysis/live_state.json"

def s_of(v):
    if isinstance(v, str):
        m = re.search(r"sc_string=b'([^']+)'", v)
        if m: return m.group(1)
    return v if isinstance(v, str) else None

def price(key):
    try:
        with urllib.request.urlopen(f"https://coins.llama.fi/prices/current/{key}", timeout=20) as r:
            d = json.load(r)["coins"]
        for k, v in d.items():
            if v.get("price"): return v["price"]
    except Exception:
        pass
    return None

def num(v):
    if isinstance(v, (int, float)): return float(v)
    if isinstance(v, str):
        try: return float(v)
        except Exception: return None
    return None

if __name__ == "__main__":
    d = json.load(open(STATE))
    toks = {t["token"]: t for t in d["tokens"]}
    # build price key per token from its name (issuer-based) else known
    KNOWN = {"native": 0.17673758841626908, "XLM": 0.17673758841626908,
             "USDC": 0.9995716127501052, "BLND": 0.006251497457001843,
             "AQUA": 0.0003003528345935538, "CETES": 0.06345942375369962,
             "SUSHI": 0.2152646466172278, "VELO": 0.0039165310636743245,
             "USDT0": 0.9986135299116207}
    keys = {}
    for t, m in toks.items():
        nm = s_of(m.get("name"))
        if nm and ":" in nm:
            keys[t] = "stellar:" + nm
        else:
            keys[t] = None
    pmap = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        res = list(ex.map(lambda t: price(keys[t]) if keys[t] else None, keys))
    for t, p in zip(keys, res):
        if p: pmap[t] = p
    print("PRICED TOKENS:")
    for t, m in toks.items():
        s = s_of(m.get("symbol"))
        p = pmap.get(t) or KNOWN.get(s)
        print(f"  {s:14s} {t[:12]}  price={p}")
    total = 0.0
    rows = []
    for grp in ("current", "legacy"):
        sub = 0.0
        for row in d[grp]:
            b0, b1 = num(row.get("bal0")), num(row.get("bal1"))
            t0, t1 = row.get("token0"), row.get("token1")
            s0, s1 = s_of(toks.get(t0, {}).get("symbol")), s_of(toks.get(t1, {}).get("symbol"))
            p0 = pmap.get(t0) or KNOWN.get(s0)
            p1 = pmap.get(t1) or KNOWN.get(s1)
            usd = (b0 * p0 / 1e7 if b0 and p0 else 0) + (b1 * p1 / 1e7 if b1 and p1 else 0)
            sub += usd
            rows.append((grp, row["pool"], s0, b0, s1, b1, round(usd, 2), bool(p0), bool(p1)))
        print(f"{grp}: pools={len(d[grp])} priced_usd={sub:,.2f}")
        total += sub
    print(f"TOTAL priced USD = {total:,.2f}   (DefiLlama currentChainTvls = 15,117,631)")
    json.dump({"total_priced_usd": round(total, 2), "prices": pmap, "rows": rows},
              open("/home/heisenberg/CA/sushi-stellar/analysis/tvl.json", "w"), indent=1)
    print("Top 20:")
    for r in sorted(rows, key=lambda x: -x[6])[:20]:
        print(f"  {r[1]} {r[2]}/{r[4]} bal={r[3]}/{r[5]} usd={r[6]} p=({r[7]},{r[8]})")
