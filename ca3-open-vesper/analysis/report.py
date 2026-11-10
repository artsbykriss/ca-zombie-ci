#!/usr/bin/env python3
"""Render the Vesper V2 fleet table + machine-readable summary from the scanner output.

Reads analysis/state-1.json, analysis/state-8453.json and analysis/prices.json; writes
analysis/fleet-table.md and (optionally) a JSON payload for ci-out/.
No network, no secrets.
"""
import json
import sys
from decimal import Decimal

PRICE_KEY = {
    "vaCBETH": "cbETH", "vaDAI": "DAI", "vaETH": "WETH", "vaFRAX": "FRAX", "vaLINK": "LINK", "vaOP": "OP",
    "vamsETH": "msETH", "vamsUSD": "msUSD", "vaRETH": "rETH", "vaSTETH": "stETH",
    "vaUSDC": "USDC", "vaWBTC": "WBTC", "vETH": "WETH", "vUSDC": "USDC", "vWBTC": "WBTC",
    "vacbETH": "cbETH", "vawstETH": "wstETH",
}
DEC = {"USDC": 6, "WBTC": 8}


def fmt(x, nd=2):
    if x is None:
        return "n/a"
    return f"{x:,.{nd}f}"


def main():
    out = None
    for i, a in enumerate(sys.argv):
        if a == "--out":
            out = sys.argv[i + 1]
    prices = json.load(open("analysis/prices.json"))
    rows = []
    total = Decimal(0)
    for f, chain in (("analysis/state-1.json", "ethereum"), ("analysis/state-8453.json", "base"),
                     ("analysis/state-10.json", "optimism")):
        d = json.load(open(f))
        for p in d["pools"]:
            sym = p["symbol"]
            key = PRICE_KEY.get(sym)
            price = Decimal(str(prices[chain][key]["price"])) if key in prices.get(chain, {}) else None
            dec = DEC.get(key, 18)
            raw = p.get("totalValue")
            human = Decimal(raw) / Decimal(10 ** dec) if raw is not None else None
            usd = (human * price) if (human is not None and price is not None) else None
            if usd:
                total += usd
            rows.append({
                "chain": chain, "symbol": sym, "pool": p["pool"], "asset": p.get("apiAssetSymbol"),
                "version": p.get("version"), "impl": p.get("impl"), "proxyAdmin": p.get("proxyAdmin"),
                "governor": p.get("governor"), "poolAccountant": p.get("poolAccountant"),
                "totalValue_raw": raw, "totalValue_human": float(human) if human is not None else None,
                "price_usd": float(price) if price is not None else None,
                "totalValue_usd": round(float(usd), 2) if usd is not None else None,
                "totalSupply": p.get("totalSupply"), "tokensHere": p.get("tokensHere"),
                "totalDebt": p.get("totalDebt"), "paused": p.get("paused"),
                "stopEverything": p.get("stopEverything"),
                "strategies": [
                    {"address": s["address"], "debt": s.get("debt"), "impl": s.get("impl")}
                    for s in p.get("strategies", [])
                ],
                "block": d["block"],
            })
    rows.sort(key=lambda r: -(r["totalValue_usd"] or 0))
    payload = {"generated_from_block": {r["chain"]: r["block"] for r in rows},
               "total_usd": round(float(total), 2), "pools": rows}
    if out:
        json.dump(payload, open(out, "w"), indent=1)

    lines = ["| # | chain | pool | asset | version | totalValue (tokens) | price USD | value USD | strategies |", "|---:|---|---|---|---|---:|---:|---:|---:|"]
    for i, r in enumerate(rows, 1):
        lines.append(
            f"| {i} | {r['chain']} | `{r['pool']}` {r['symbol']} | {r['asset']} | {r['version']} | "
            f"{fmt(r['totalValue_human'], 4)} | {fmt(r['price_usd'], 4)} | {fmt(r['totalValue_usd'])} | {len(r['strategies'])} |"
        )
    lines.append(f"| | | | | **total** | | | **{fmt(float(total))}** | |")
    open("analysis/fleet-table.md", "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))
    print("TOTAL USD", fmt(float(total)))


if __name__ == "__main__":
    main()
