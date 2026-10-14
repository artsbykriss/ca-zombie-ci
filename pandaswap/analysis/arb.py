#!/usr/bin/env python3
"""Stale-price arbitrage estimator for all PandaSwap pairs.

For each pair, using DefiLlama token USD prices as the external market:
  - direction A: pool sells token0 (buy token0 from pool with token1, sell at market)
  - direction B: pool sells token1
Optimize input size numerically (constant-product, 0.3% fee). Report net USD profit.
Assumes external market absorbs at the given price (upper bound; CI refines with PancakeSwap quotes).
"""
import json, os, sys, math

HERE = os.path.dirname(os.path.abspath(__file__))


def out_amount(amount_in, r_in, r_out, fee=0.997):
    if amount_in <= 0 or r_in <= 0 or r_out <= 0:
        return 0.0
    return r_out * amount_in * fee / (r_in + amount_in * fee)


def best_profit(r0, r1, p0, p1):
    """Returns (best_dir, best_in_usd, best_profit_usd, in0, in1) using decimal-adjusted reserves."""
    best = (None, 0.0, 0.0)
    # direction A: pay token1, receive token0, sell token0 at p0
    # maximize f(in1) = out0(in1)*p0 - in1*p1 ; out0 uses r1 as in-reserve, r0 as out-reserve
    lo, hi = 0.0, r1 * 100  # scan up to 100x pool in-reserve
    for _ in range(200):
        # ternary search
        m1 = lo + (hi - lo) / 3
        m2 = hi - (hi - lo) / 3
        f1 = out_amount(m1, r1, r0) * p0 - m1 * p1
        f2 = out_amount(m2, r1, r0) * p0 - m2 * p1
        if f1 < f2:
            lo = m1
        else:
            hi = m2
    in1 = (lo + hi) / 2
    prof = out_amount(in1, r1, r0) * p0 - in1 * p1
    if prof > best[2]:
        best = ("pay1_get0", in1 * p1, prof)
    # direction B: pay token0, receive token1
    lo, hi = 0.0, r0 * 100
    for _ in range(200):
        m1 = lo + (hi - lo) / 3
        m2 = hi - (hi - lo) / 3
        f1 = out_amount(m1, r0, r1) * p1 - m1 * p0
        f2 = out_amount(m2, r0, r1) * p1 - m2 * p0
        if f1 < f2:
            lo = m1
        else:
            hi = m2
    in0 = (lo + hi) / 2
    prof = out_amount(in0, r0, r1) * p1 - in0 * p0
    if prof > best[2]:
        best = ("pay0_get1", in0 * p0, prof)
    return best


def main():
    priced = json.load(open(os.path.join(HERE, "priced.json")))
    d = json.load(open(os.path.join(HERE, "all-pairs.json")))
    pairs = d["pairs"]; tokens = d["tokens"]; prices = priced["prices"]
    rows = []
    total = 0.0
    for p, v in pairs.items():
        t0, t1 = v.get("token0"), v.get("token1")
        r0raw, r1raw = v.get("reserve0"), v.get("reserve1")
        if not (t0 and t1 and r0raw and r1raw):
            continue
        p0 = prices.get(t0.lower()); p1 = prices.get(t1.lower())
        if not p0 or not p1:
            continue
        d0 = tokens.get(t0, {}).get("decimals") or 18
        d1 = tokens.get(t1, {}).get("decimals") or 18
        r0 = r0raw / 10 ** d0; r1 = r1raw / 10 ** d1
        if r0 <= 0 or r1 <= 0:
            continue
        pool_price0 = r1 / r0 * (p1 / p0) if r0 else 0  # implied USD ratio pool vs market
        dirn, in_usd, prof = best_profit(r0, r1, p0, p1)
        pool_val = r0 * p0 + r1 * p1
        if prof > 0.05:
            rows.append({
                "pair": p, "sym0": tokens.get(t0, {}).get("symbol"), "sym1": tokens.get(t1, {}).get("symbol"),
                "t0": t0, "t1": t1, "usd_pool": round(pool_val, 2),
                "dir": dirn, "in_usd": round(in_usd, 2), "profit_usd": round(prof, 2),
                "dev_pct": round((pool_price0 - 1) * 100, 1),
            })
            total += prof
    rows.sort(key=lambda r: -r["profit_usd"])
    out = {"total_arb_usd": round(total, 2), "rows": rows}
    json.dump(out, open(os.path.join(HERE, "arb.json"), "w"), indent=1)
    print(f"TOTAL STALE-PRICE ARB (upper bound vs DefiLlama): ${total:,.2f}")
    for r in rows[:30]:
        print(f"  ${r['profit_usd']:>8.2f}  {r['sym0']}/{r['sym1']:<10} pool=${r['usd_pool']:>9.2f} dev={r['dev_pct']:>7.1f}% {r['dir']} in=${r['in_usd']:>8.2f}  {r['pair']}")


if __name__ == "__main__":
    main()
