#!/usr/bin/env python3
"""Liquidation profitability matrix for Geist (Fantom) at the frozen oracle prices vs live DEX prices.
No RPC: uses measured constants (analysis/live-state.json + measured pool prices).
Profit factor per $1 of debt repaid (attacker buys debt on DEX, seizes collateral, sells on DEX):
    PF = (oracle_debt / market_debt) * bonus / (oracle_coll / market_coll)
"""
import json

oracle = {  # 1e18 USD from the frozen feeds
    "DAI": 0.999895350000000000, "ETH": 2519.052063000000000000, "WFTM": 0.107457370000000000,
    "BTC": 68615.038815340000000000, "fUSDT": 0.999498260000000000, "USDC": 0.999915790000000000,
    "CRV": 0.354000000000000000, "MIM": 0.998663350000000000, "LINK": 8.722330000000000000,
}
market = {  # live local DEX marginal price (pool ratio, Spooky==Spirit)
    "DAI": 0.0129, "ETH": 26.3, "WFTM": 0.0684, "BTC": 1066.0, "fUSDT": 0.0567,
    "USDC": 0.117, "CRV": 0.00427, "MIM": 0.0426, "LINK": 0.215,
}
bonus = {  # liquidation bonus from reserve config (bps+10000)
    "DAI": 1.05, "ETH": 1.05, "WFTM": 1.10, "BTC": 1.10, "fUSDT": 1.05,
    "USDC": 1.05, "CRV": 1.10, "MIM": 1.05, "LINK": 1.10,
}
cash = {  # aToken cash (underlying units) - caps what can be seized/redeemed
    "DAI": 632692.86, "ETH": 488.33, "WFTM": 0.0, "BTC": 113.48, "fUSDT": 7634561.11,
    "USDC": 469779.98, "CRV": 107517.02, "MIM": 173780.29, "LINK": 6119.62,
}
r = {k: oracle[k] / market[k] for k in oracle}

print(f"{'debt':6s} {'r_debt':>8s} | " + " ".join(f"{c:>7s}" for c in market))
print("-" * 100)
for d in market:
    row = f"{d:6s} {r[d]:8.1f} | "
    for c in market:
        pf = r[d] * bonus[d] / r[c] if cash[c] > 0 else 0.0
        row += f"{pf:7.2f} "
    print(row + "   (0 = collateral has no cash -> seizure reverts)")

print()
print("Profit factor > 1 => profitable per $ of debt repaid (before DEX price impact of size).")
print("Collateral reserves with cash (seizable):", [c for c in cash if cash[c] > 0])
print("Absolute profit is capped by the collateral reserve's cash AND by the DEX depth to sell it.")
