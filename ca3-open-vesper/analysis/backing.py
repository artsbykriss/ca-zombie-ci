#!/usr/bin/env python3
"""Compute booked NAV vs realisable backing per pool.

Booked NAV  = pool.totalDebt + pool.tokensHere (== totalValue()).
Realisable  = pool.tokensHere + Σ strategy.tvl()   (tvl() is the strategy's own
              mark of what it actually holds; dummy/stranded strategies return 0 and
              legacy v3 strategies may revert -> counted as 0 and flagged).

This is a health metric (H-O / S), not an attacker-profit number.
"""
import json
import sys


# Positions whose tvl() mark cannot be realised: the venue has no cash and the strategy
# holds no idle underlying. Verified on-chain (block in analysis/state-*.json).
ILLIQUID = {
    "0x64ef984fdaa7d13d71aadeee50e5826a69b33c76": (
        "Sonne USDC market getCash()=0, strategy idle USDC.e=0, strategy.withdraw() transfers 0"
    ),
}


def main():
    out = None
    for i, a in enumerate(sys.argv):
        if a == "--out":
            out = sys.argv[i + 1]
    res = []
    for f, chain in (("analysis/state-1.json", "ethereum"), ("analysis/state-8453.json", "base"),
                     ("analysis/state-10.json", "optimism")):
        d = json.load(open(f))
        for p in d["pools"]:
            if not p.get("strategies"):
                continue
            here = p.get("tokensHere") or 0
            debt = p.get("totalDebt") or 0
            real = here
            dead = []
            for s in p["strategies"]:
                # v6 strategies expose tvl(); v3-era strategies (Alpha-Lend, CompoundLeverage)
                # expose totalValue(). Use whichever answers; a reverting pair means a dummy.
                tvl = s.get("tvl")
                if tvl is None:
                    tvl = s.get("totalValue")
                if tvl is None:
                    dead.append({"address": s["address"], "debt": s.get("debt"), "tvl": None})
                    continue
                if s["address"].lower() in ILLIQUID:
                    dead.append({"address": s["address"], "debt": s.get("debt"), "tvl": tvl,
                                 "illiquid": ILLIQUID[s["address"].lower()]})
                    continue
                real += tvl
                if tvl == 0 and (s.get("debt") or 0) > 0:
                    dead.append({"address": s["address"], "debt": s.get("debt"), "tvl": 0})
            if debt == 0:
                continue
            res.append({
                "chain": chain, "symbol": p["symbol"], "pool": p["pool"],
                "booked_nav_raw": p.get("totalValue"), "realisable_raw": real,
                "shortfall_raw": (p.get("totalValue") or 0) - real,
                "shortfall_pct": round(100.0 * ((p.get("totalValue") or 0) - real) / (p.get("totalValue") or 1), 3),
                "dead_strategies": dead, "block": d["block"],
            })
    res.sort(key=lambda r: -r["shortfall_pct"])
    if out:
        json.dump(res, open(out, "w"), indent=1)
    for r in res:
        print(f"{r['symbol']:9s} booked={r['booked_nav_raw']} realisable={r['realisable_raw']} "
              f"shortfall={r['shortfall_pct']}% dead={len(r['dead_strategies'])}")


if __name__ == "__main__":
    main()
