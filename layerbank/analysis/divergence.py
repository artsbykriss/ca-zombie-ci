#!/usr/bin/env python3
"""LayerBank (Robinhood Chain 4663) — divergence + conditional-ceiling arithmetic.

Reads analysis/live_state.json (or analysis/reserves.json + analysis/feeds.json) and
prints/writes analysis/divergence.json:
  * per-reserve stale-vs-real gap today (oracle vs DefiLlama)
  * break-even gap = 1/LTV - 1
  * conditional net if the attacker supplies collateral bought at the REAL price,
    supplies it at the STALE oracle price and borrows the free liquidity (then defaults):
        net(g) = F * (1 - 1/(LTV*(1+g)))     capped by F (free liquidity of the borrowable asset)
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# free liquidity of the only two BORROWABLE reserves.
# Weekend snapshot (block 97,805,494, 2026-10-25 18:48 UTC): USDG $568,926.52 + 462.66 WETH ($1,092,138) = $1,661,063.62
# Current   (block 97,990,305, 2026-10-26 00:09 UTC): USDG $463,125.55 + 462.66 WETH ($1,073,540.32) = $1,536,665.87
FREE_USDG_1E6 = 463_125_547_664 / 1e6      # $463,125.55 (current)
FREE_WETH_1E18 = 462_659_995_958_982_400_000 / 1e18  # 462.66 WETH
WETH_USD = 2320.3655
FREE_USDG_USD = FREE_USDG_1E6
FREE_WETH_USD = FREE_WETH_1E18 * WETH_USD

# LTV (bps) per collateral reserve
LTV = {"NVDA": 5500, "SPY": 6000, "USDG": 8000, "WETH": 7000,
       "cbBTC": 7000, "QQQ": 5000, "SGOV": 7000, "GLD": 6000}

# oracle vs real (DefiLlama), % gap = oracle/real - 1
GAP_TODAY_PCT = {"NVDA": -0.014, "SPY": 0.204, "QQQ": 0.101, "SGOV": 0.709,
                 "GLD": 0.083, "cbBTC": 0.173, "USDG": -0.011, "WETH": -0.105}

# staleness at the weekend-freeze snapshot (block 97,805,494) and now (block 97,990,305)
AGE_H = {"NVDA": 46.89, "SPY": 48.77, "QQQ": 52.15, "SGOV": 63.66,
         "GLD": 4.33, "cbBTC": 6.91, "USDG": 3.03, "WETH": 1.44}
AGE_H_NOW = {"NVDA": 0.15, "SPY": 0.15, "QQQ": 0.15, "SGOV": 0.15,
             "GLD": 9.68, "cbBTC": 0.70, "USDG": 8.38, "WETH": 0.39}


def main():
    out = {"free_liquidity": {"USDG_usd": round(FREE_USDG_USD, 2),
                              "WETH_usd": round(FREE_WETH_USD, 2),
                              "total_usd": round(FREE_USDG_USD + FREE_WETH_USD, 2)},
           "reserves": {}}

    for sym, ltv in LTV.items():
        be = (10000 - ltv) / ltv * 100.0
        out["reserves"][sym] = {
            "ltv_pct": ltv / 100.0,
            "break_even_gap_pct": round(be, 1),
            "stale_hours_weekend_freeze": AGE_H.get(sym),
            "stale_hours_now": AGE_H_NOW.get(sym),
            "oracle_vs_real_gap_pct_now": GAP_TODAY_PCT.get(sym),
            "profitable_today": bool(GAP_TODAY_PCT.get(sym, 0) * 100 > be),
        }

    # conditional net at a hypothetical gap g, using the BEST equity LTV (SGOV/WETH/cbBTC 70%)
    best_ltv = 0.70
    table = []
    for g in [0.429, 0.60, 0.80, 1.00, 1.50, 2.00, 3.00, 5.00]:
        # borrow USDG (F=$568,926) with a 70% LTV collateral
        net_u = FREE_USDG_USD * (1 - 1 / (best_ltv * (1 + g)))
        net_w = FREE_WETH_USD * (1 - 1 / (best_ltv * (1 + g)))
        table.append({"gap_pct": round(g * 100, 1),
                      "net_borrow_USDG_usd": round(max(net_u, 0), 2),
                      "net_borrow_WETH_usd": round(max(net_w, 0), 2),
                      "net_total_usd": round(max(net_u, 0) + max(net_w, 0), 2)})
    out["conditional_net_best_equity_ltv_70pct"] = table
    out["ceiling_usd"] = round(FREE_USDG_USD + FREE_WETH_USD, 2)
    out["note"] = ("Net is capped by the free liquidity of the two borrowable reserves "
                   "(USDG + WETH). At an infinite stale-vs-real gap the attacker can drain "
                   "the whole free liquidity; the realistic 100-150% gap nets ~$0.36-0.48M.")

    json.dump(out, open(os.path.join(HERE, "divergence.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
