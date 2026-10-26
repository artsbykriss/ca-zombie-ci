#!/usr/bin/env python3
"""Build the Sturdy V2 strategy table (from analysis/live-state.json) + free-liquidity USD.

READ-ONLY. Prices via DefiLlama coins API; falls back to a stated constant for pxETH
(≈ ETH) when the API does not list it. Writes analysis/strategy-table.json.
"""
import json, os, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
PETH_FALLBACK = float(os.environ.get("PXETH_USD_FALLBACK", "2348.05"))  # ≈ ETH @ 2026-10-25
LIVE = os.environ.get("LIVE_STATE", os.path.join(HERE, "live-state.json"))
OUT = os.environ.get("STRATEGY_TABLE_OUT", os.path.join(HERE, "strategy-table.json"))

def llama_prices(addrs):
    url = "https://coins.llama.fi/prices/current/" + ",".join(f"ethereum:{a}" for a in addrs)
    req = urllib.request.Request(url, headers={"User-Agent": "sturdy-recon/1.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))["coins"]

def main():
    d = json.load(open(LIVE))
    st = d["strategies"]
    assets = sorted({s["asset"].lower() for s in st})
    prices = {}
    try:
        for k, v in llama_prices(assets).items():
            prices[k.split(":")[1]] = v["price"]
    except Exception as e:
        print("price fetch failed:", e)
    rows, total = [], 0.0
    for i, s in enumerate(st):
        a = s["asset"].lower()
        price = prices.get(a) or (PETH_FALLBACK if s["assetSymbol"] == "pxETH" else 0.0)
        dec = s["assetDecimals"]
        free = (s["totalAsset"] - s["totalBorrow"]) / 10**dec
        usd = free * price
        total += usd
        o = s["oracle_live"]
        rows.append(dict(idx=i, pair=s["pair"], asset=s["asset"], assetSymbol=s["assetSymbol"],
            assetDecimals=dec, collateral=s["collateral"], collateralSymbol=s["collateralSymbol"],
            oracle=s["oracle"], oracle_name=o.get("name"), maxLTV=s["maxLTV"],
            maxOracleDeviation=s["exchangeRateInfo"].get("maxOracleDeviation"),
            totalAsset=str(s["totalAsset"]), totalBorrow=str(s["totalBorrow"]),
            totalCollateral=str(s["totalCollateral"]), freeAsset=str(s["totalAsset"] - s["totalBorrow"]),
            freeUsd=round(usd, 2), assetPriceUsd=price, protocolLiquidationFee=s["protocolLiquidationFee"],
            oracle_maxOracleDelay=o.get("MAX_ORACLE_DELAY"), oracle_priceMin=o.get("PRICE_MIN"),
            oracle_twapDuration=o.get("TWAP_DURATION"), oracle_priceLow=o.get("priceLow"),
            oracle_priceHigh=o.get("priceHigh"), oracle_deviation_1e5=o.get("deviation_1e5"),
            oracle_reverts=bool(o.get("getPrices_reverted"))))
    out = dict(block=d["block"], rpc_host=d.get("rpc_host"), pxeth_usd_fallback=PETH_FALLBACK,
               total_free_usd=round(total, 2), strategies=rows)
    json.dump(out, open(OUT, "w"), indent=1)
    print(f"block {d['block']}  strategies {len(rows)}  total free liquidity ${total:,.2f}")

if __name__ == "__main__":
    main()
