#!/usr/bin/env python3
"""Corrected valuation using DEX-implied (realizable) prices for Fantom tokens."""
import json, urllib.request, time

STATE = "/tmp/opencode/ld-art2/result-liquid-driver/ci-out/live-state.json"
VAL = "/tmp/opencode/ld-art2/result-liquid-driver/ci-out/valuation.json"
OUT = "/home/heisenberg/CA/liquid-driver/analysis/valuation-dex.json"

d = json.load(open(STATE))
v = json.load(open(VAL))

# ---- collect underlying tokens ----
toks = set()
for lp, m in d["lpmeta"].items():
    for k in ("token0", "token1"):
        if m.get(k): toks.add(m[k].lower())
toks = sorted(toks)
print("underlying tokens:", len(toks))

def dexscreener_price(tok, retries=3):
    u = f"https://api.dexscreener.com/latest/dex/tokens/{tok}"
    for a in range(retries):
        try:
            with urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"}), timeout=25) as r:
                dd = json.loads(r.read().decode())
            pairs = [p for p in (dd.get("pairs") or []) if p.get("priceUsd") and p.get("chainId") == "fantom"]
            if not pairs:
                return None
            pairs.sort(key=lambda p: float((p.get("liquidity") or {}).get("usd") or 0), reverse=True)
            p = pairs[0]
            return {"usd": float(p["priceUsd"]), "liqUsd": float((p.get("liquidity") or {}).get("usd") or 0),
                    "dex": p.get("dexId"), "pair": p.get("pairAddress"),
                    "vol24h": float((p.get("volume") or {}).get("h24") or 0)}
        except Exception:
            time.sleep(0.5 * (a + 1))
    return None

dex = {}
for t in toks:
    dex[t] = dexscreener_price(t)
    if dex[t] is None:
        print(f"  {t}: no fantom DEX price")

# hardcode a few known-good where DEX is thin but token is canonical
FALLBACK = {
    "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83": {"usd": 0.05397140544942972, "note": "WFTM llama"},
    "0x04068da6c83afcfa0e13ba15a6696662335d5b75": {"usd": 1.0, "note": "USDC"},
    "0x049d68029688eabf473097a2fc38ef61633a3c7a": {"usd": 1.0, "note": "fUSDT"},
    "0xd7028092c830b5c8fce061af2e593413ebbc1fc1": {"usd": 0.05256107281470372, "note": "sFTMX llama"},
}
for t, f in FALLBACK.items():
    if dex.get(t) is None:
        dex[t] = f

def px(t):
    if not t: return None
    x = dex.get(t.lower())
    return x["usd"] if x else None

dec = d.get("token_decimals", {})
def d_of(t): return dec.get((t or "").lower(), 18)

lpmeta = d["lpmeta"]
def lp_usd(lp, amount):
    m = lpmeta.get(lp.lower(), {})
    ts, r0, r1 = m.get("totalSupply"), m.get("reserve0"), m.get("reserve1")
    if not ts or r0 is None or not amount: return None
    v0 = (px(m.get("token0")) or 0) * r0 / 10**d_of(m.get("token0"))
    v1 = (px(m.get("token1")) or 0) * r1 / 10**d_of(m.get("token1"))
    return (v0 + v1) * amount / ts

res = {"prices_dex": dex, "masterchef_lp": [], "strategy_lp": [], "shadow": []}
tot_mc = 0
for r in v["values"]["masterchef_lp"]:
    u = lp_usd(r["lpToken"], r.get("chefBalance") or 0)
    res["masterchef_lp"].append({**r, "usd_dex": u})
    if u: tot_mc += u
tot_strat = 0
for r in v["values"]["minichef_strategy_lp"]:
    u = lp_usd(r["lpToken"], r.get("amount") or 0)
    res["strategy_lp"].append({**r, "usd_dex": u})
    if u: tot_strat += u
tot_sh = 0
for r in v["values"]["shadow"]:
    u = lp_usd(r["lpToken"], r.get("amount") or 0)
    res["shadow"].append({**r, "usd_dex": u})
    if u: tot_sh += u

res["totals"] = {
    "masterchef_lp_usd_dex": tot_mc,
    "strategy_lp_usd_dex": tot_strat,
    "shadow_usd_dex": tot_sh,
}
print(json.dumps(res["totals"], indent=1))
print("\nTop strategy LP (DEX prices):")
for r in sorted([x for x in res["strategy_lp"] if x.get("usd_dex")], key=lambda x: -x["usd_dex"])[:12]:
    print(f"  {r['lpToken']} amt {r['amount']} usd_dex {round(r['usd_dex'],2)} (llama-based was {r.get('usd')})")
print("\nTop MC LP (DEX prices):")
for r in sorted([x for x in res["masterchef_lp"] if x.get("usd_dex")], key=lambda x: -x["usd_dex"])[:10]:
    print(f"  pid {r['pid']} {r['lpToken']} usd_dex {round(r['usd_dex'],2)} (llama-based was {r.get('usd')})")

with open(OUT, "w") as f:
    json.dump(res, f, indent=1)
print("saved", OUT)
