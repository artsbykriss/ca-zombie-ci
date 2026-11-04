#!/usr/bin/env python3
"""Aggregate the C-1 correction numbers from analysis/state.json.

Prices are the 2026-11-04 snapshot used in the report (DefiLlama):
WBTC $77,812.09, WETH $2,299.78, ARB $0.1596, USDC.e $1.00.
Premium rates are the all-in (premium + cLevel spread + 0.3% minting fee)
quotes at the highest valid delta-0.2 strike for 13 NOV 2026 08:00 UTC,
measured on the same snapshot.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ANALYSIS = os.path.dirname(HERE)
STATE = os.path.join(ANALYSIS, "state.json")
OUT = os.path.join(os.path.dirname(ANALYSIS), "ci-out", "aggregate.json")

PRICE = {"WBTC": 77812.09, "WETH": 2299.78, "ARB": 0.1596, "USDC": 1.00}
SYM = {
    "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f": "WBTC",
    "0x82af49447d8a07e3bd95bd0d56f35241523fbab1": "WETH",
    "0x912ce59144191c1204e64559fe8253a0e49e6548": "ARB",
    "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8": "USDC",
}
# all-in premium rate at the delta-0.2 strike, 13 NOV 2026 08:00 UTC
RATE = {
    "pSV-WBTC/USDCe-C": 0.01616,
    "pSV-WETH/USDCe-C": 0.024944,
    "pSV-WETH/USDCe-P": 0.032076,
    "pSV-WBTC/USDCe-P": 0.021589,
    "pSV-ARB/USDCe-C": 0.033263,
    "pSV-ARB/USDCe-P": 0.052113,
}


def main():
    d = json.load(open(STATE))
    rows = []
    tot = {"nominal": 0.0, "real": 0.0, "pool_cash": 0.0, "premium": 0.0, "hypothetical_net": 0.0, "revive_net": 0.0}
    for v in d["vaults"]:
        sym = SYM.get(v["asset"].lower(), "USDC")
        px = PRICE[sym]
        nominal = v["totalAssets"] * px
        real = v["real_balance"] * px
        pool_cash = v["sum_pool_cash_token"] * px
        rate = RATE.get(v["name"], 0.0)
        premium = nominal * rate
        row = {
            "name": v["name"],
            "vault": v["vault"],
            "asset": sym,
            "totalAssets_tokens": v["totalAssets"],
            "totalLockedAssets_tokens": v["totalLockedAssets"],
            "available_tokens": v["available"],
            "real_balance_tokens": v["real_balance"],
            "verifed_short_tokens": v["sum_actual_collateral_token"],
            "pool_cash_tokens": v["sum_pool_cash_token"],
            "backed_pct": (100.0 * v["sum_pool_cash_token"] / v["sum_actual_collateral_token"]) if v["sum_actual_collateral_token"] else None,
            "nominal_usd": nominal,
            "real_usd": real,
            "pool_cash_usd": pool_cash,
            "allin_premium_rate": rate,
            "premium_usd": premium,
            "hypothetical_net_if_collateral_real_usd": nominal - premium,
            "revive_net_usd": real + pool_cash - premium,
        }
        rows.append(row)
        for k in tot:
            key = {"nominal": "nominal_usd", "real": "real_usd", "pool_cash": "pool_cash_usd",
                   "premium": "premium_usd", "hypothetical_net": "hypothetical_net_if_collateral_real_usd",
                   "revive_net": "revive_net_usd"}[k]
            tot[k] += row[key]
    out = {"block": d["block"], "block_timestamp": d["block_timestamp"], "prices": PRICE, "rows": rows, "totals": tot}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
