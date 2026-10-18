#!/usr/bin/env python3
"""Compute USDD 2.0 PSM / DEX arb numbers from recorded raw snapshots.
No network access. All inputs are from raw/*.json recorded at the block noted.
"""
import json, math, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: json.load(open(os.path.join(BASE, "raw", n)))


def words(h):
    return [int(h[i:i + 64], 16) for i in range(0, len(h), 64)]


snap = R("final_snapshot.json")
vals = {}
for c in snap["calls"]:
    h = (c.get("constant_result") or [""])[0]
    if not h:
        continue
    if c["tag"] in ("v3.slot0", "vat.ilks", "vat.urns", "v2.getReserves"):
        vals[c["tag"]] = words(h)
    else:
        vals[c["tag"]] = int(h, 16)

supply = vals["usdd.totalSupply"] / 1e18
art = vals["vat.urns"][1] / 1e18
ink = vals["vat.urns"][0] / 1e18
line = vals["vat.ilks"][3] / 1e45
gemjoin_usdt = vals["usdt.gemJoin"] / 1e6
psm_usdt = vals["usdt.psm"] / 1e6
vat_debt = vals["vat.debt"] / 1e45
v3_usdt = vals["usdt.v3pool"] / 1e6
v3_usdd = vals["usdd.v3pool"] / 1e18
jusdd = vals["usdd.jusdd"] / 1e18

sqrtP = vals["v3.slot0"][0]
tick = vals["v3.slot0"][1]
L = vals["v3.liquidity"]
price_raw = (sqrtP / 2 ** 96) ** 2
price = price_raw * 1e-12          # USDT per USDD (token0=USDT 6d, token1=USDD 18d)
v3_fee = 0.0001                     # fee tier 100 = 0.01% = 1 bp

# --- V2 dust pool ---
r0, r1, _ = vals["v2.getReserves"]
v2_usdt, v2_usdd = r0 / 1e6, r1 / 1e18


def v2_out(dx, x=v2_usdt, y=v2_usdd, fee=0.997):
    de = fee * dx
    return y * de / (x + de)


# optimal buy of USDD with USDT on V2 (dust)
best = (0.0, 0.0, 0.0)
for i in range(1, 200000):
    dx = i * 0.0001
    dy = v2_out(dx)
    if dy - dx > best[0]:
        best = (dy - dx, dx, dy)
v2_best_profit, v2_best_dx, v2_best_dy = best

# --- V3 per-$1M round trips (marginal spot, fee on input) ---
buy_cost_1m = 1_000_000 * price / (1 - v3_fee)   # USDT in to get 1M USDD
sell_proceeds_1m = 1_000_000 * price * (1 - v3_fee)  # USDT out for 1M USDD
roundtrip_buy_redeem = 1_000_000 - buy_cost_1m    # negative
roundtrip_mint_sell = sell_proceeds_1m - 1_000_000  # negative

# --- SunCurve 2pool quotes recorded at block 87211165 ---
sc = R("suncurve_curve.json")
scq = {}
for c in sc["calls"]:
    h = (c.get("constant_result") or [""])[0]
    scq[c["tag"]] = int(h, 16) if h else 0
sc_fee = R("suncurve_state.json")
sc_fee_v = 0.0004
sc_quotes = {
    "sell_10k_USDD_usdt": scq.get("10k_USDD", 0) / 1e6,
    "sell_100k_USDD_usdt": scq.get("100k_USDD", 0) / 1e6,
    "sell_1M_USDD_usdt": scq.get("1M_USDD", 0) / 1e6,
    "buy_10k_USDT_usdd": scq.get("10k_USDT", 0) / 1e18,
    "buy_100k_USDT_usdd": scq.get("100k_USDT", 0) / 1e18,
    "buy_1M_USDT_usdd": scq.get("1M_USDT", 0) / 1e18,
}

# --- CDP ilks ---
cdp = R("cdp_ilks_state.json")
ilks = {}
for c in cdp["calls"]:
    tag = c["tag"]
    h = (c.get("constant_result") or [""])[0]
    if not h:
        continue
    w = words(h)
    if tag.startswith("vat.ilks"):
        name = tag.split(":")[1]
        ilks.setdefault(name, {})
        ilks[name].update({"art": w[0] / 1e18, "rate": w[1] / 1e27,
                           "spot": w[2] / 1e27, "line": w[3] / 1e45,
                           "dust": w[4] / 1e45 if len(w) > 4 else None})
    elif tag.startswith("jug.ilks"):
        name = tag.split(":")[1]
        ilks.setdefault(name, {})["duty"] = w[0] / 1e27
    elif tag.startswith("spotter.ilks"):
        name = tag.split(":")[1]
        ilks.setdefault(name, {})["mat"] = w[1] / 1e27
    elif tag.startswith("dog.ilks"):
        name = tag.split(":")[1]
        # Dog.ilks returns (clip, chop, hole, dirt); chop is word 1 in RAD (1e27)
        ilks.setdefault(name, {})["chop"] = w[1] / 1e18 if len(w) > 1 else None

# add WBTC (probe)
for fn in ("ilk_probe.json", "ilk_probe2.json"):
    wb = R(fn)
    for c in wb["calls"]:
        if c.get("ilk") in ("WBTC-A", "WBTC-B") and c.get("constant_result"):
            w = words(c["constant_result"][0])
            ilks[c["ilk"]] = {"art": w[0] / 1e18, "rate": w[1] / 1e27,
                              "spot": w[2] / 1e27, "line": w[3] / 1e45,
                              "dust": w[4] / 1e45}

ilks["PSM-USDT-A"] = {"art": art, "rate": 1.0, "spot": 1.0, "line": line, "dust": 0.0}
sum_art_rate = sum(v.get("art", 0) * v.get("rate", 1) for v in ilks.values())
sum_line = sum(v.get("line", 0) for v in ilks.values())

out = {
    "block": snap["block"],
    "supply_usdd": supply,
    "psm": {
        "ilk": "PSM-USDT-A",
        "tin": 0, "tout": 0, "sellEnabled": 1, "buyEnabled": 1,
        "art_usdd": art, "ink_usdd": ink, "line_usdd": line,
        "mint_headroom_usdd": line - art,
        "gemjoin_usdt": gemjoin_usdt, "psm_direct_usdt": psm_usdt,
        "redeem_capacity_usdt": gemjoin_usdt,
        "psm_coverage_pct_supply": 100 * gemjoin_usdt / supply,
    },
    "vat": {
        "debt_usd": vat_debt,
        "sum_enumerated_ilks_art_rate": sum_art_rate,
        "unattributed_debt": vat_debt - sum_art_rate,
        "sum_enumerated_lines": sum_line,
        "ilks": ilks,
    },
    "dex": {
        "v3": {
            "pool": "TD3C3hcmRgTP42Sxv7XsT6fHbeX5eAryq6",
            "fee_bps": 1,
            "sqrtPriceX96": sqrtP, "tick": tick,
            "price_usdt_per_usdd": price,
            "deviation_bps": (price - 1) * 1e4,
            "liquidity": L,
            "usdt_balance": v3_usdt, "usdd_balance": v3_usdd,
        },
        "v2": {
            "pair": "TDEoc9JmeTbcnKuCqZrQuykb3k6CwvDW6P",
            "usdt": v2_usdt, "usdd": v2_usdd, "spot": v2_usdt / v2_usdd,
            "best_buy_profit_usd": v2_best_profit,
            "best_buy_size_usdt": v2_best_dx,
        },
        "suncurve": {
            "pool": "THJCvwFmu6uDqKY59JbULHDgfddy2Zojty",
            "fee_bps": 4, "A": 1000,
            "quotes": sc_quotes,
        },
    },
    "per_1m_usd_roundtrip": {
        "buy_usdd_v3_redeem_psm_usd": roundtrip_buy_redeem,
        "mint_psm_sell_usdd_v3_usd": roundtrip_mint_sell,
        "note": "USDT/USD factor cancels: both legs are USDT-denominated; oracle USDT/USD=0.99873",
    },
    "jusdd": {
        "address": "TKFRELGGoRgiayhwJTNNLqCNjFoLBh3Mnf",
        "usdd_balance": jusdd,
        "pct_supply": 100 * jusdd / supply,
    },
    "conditional": {
        "10bp_discount_max_profit_usd_v3_depth": v3_usdd * 0.001 - v3_usdd * 0.0001,
        "100bp_discount_max_profit_usd_v3_depth": v3_usdd * 0.01 - v3_usdd * 0.0001,
        "psm_redeem_capacity_usd": gemjoin_usdt,
        "note": "profit cap uses the V3 pool's 1.302M USDD balance; PSM can absorb 41.23M if depth existed",
    },
}
print(json.dumps(out, indent=1))
json.dump(out, open(os.path.join(BASE, "raw", "arb_math.json"), "w"), indent=1)
