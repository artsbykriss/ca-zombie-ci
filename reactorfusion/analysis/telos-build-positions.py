#!/usr/bin/env python3
"""Build telos-positions.json from holders + debtor probes + market/oracle snapshots.
Pure local computation (no network). No secrets."""
import json, os, sys

OUT = os.path.dirname(os.path.abspath(__file__))
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}
DEC = {"rfUSDC": 6, "rfUSDT": 6, "rfETH": 18, "rfTLOS": 18}
# oracle prices at 1e(36-underlyingDecimals) scale -> USD per underlying
ORACLE = {"rfUSDC": 0.99974455, "rfUSDT": 0.99969496, "rfETH": 2616.20618299, "rfTLOS": 0.01931047}
# live prices (2026-10-14): USDC/USDT DefiLlama, ETH DefiLlama, TLOS CoinGecko
LIVE = {"rfUSDC": 0.99974701, "rfUSDT": 0.99930840, "rfETH": 2437.508760682526, "rfTLOS": 0.01895246}
CF = {"rfUSDC": 0.8, "rfUSDT": 0.8, "rfETH": 0.7, "rfTLOS": 0.7}
LIQ_INCENTIVE = 1.08

def load_shards():
    data = {}
    blocks = {}
    for i in range(3):
        p = os.path.join(OUT, f"telos-debtorprobe-shard{i}.json")
        if not os.path.exists(p):
            continue
        j = json.load(open(p))
        data.update(j["data"])
        blocks[i] = j["block"]
    return data, blocks

def main():
    holders = json.load(open(os.path.join(OUT, "telos-holders.json")))
    probes, probe_blocks = load_shards()
    m4 = json.load(open(os.path.join(OUT, "telos-probe4.json")))
    exch = {k.split(".")[1]: m4["exchangeRateStored." + k.split(".")[1]]["v"] / 1e18 for k in
            [f"x.{m}" for m in MARKETS]}
    cash = {m: m4[f"getCash.{m}"]["v"] for m in MARKETS}
    total_borrows = {m: m4[f"totalBorrows.{m}"]["v"] for m in MARKETS}

    # holder balances
    bal = {m: {} for m in MARKETS}
    for m in MARKETS:
        for h in holders[m]:
            bal[m][h["address"].lower()] = int(h["value"])

    accounts = set(holders["_all_holders"])
    accounts |= set(probes.keys() and [a for a in probes if "|" in a] and [])
    # accounts from probe keys
    for k in probes:
        if "|" in k:
            accounts.add(k.split("|")[0])
    accounts = sorted(a.lower() for a in accounts)

    positions = {}
    underwater = []
    for a in accounts:
        rec = {"address": a, "balances": {}, "borrows": {}, "assetsIn": None, "onchain": None,
               "oracle": {"collateralUSD": 0.0, "collateralAdjUSD": 0.0, "debtUSD": 0.0,
                          "liquidityUSD": None, "shortfallUSD": None},
               "live": {"collateralUSD": 0.0, "collateralAdjUSD": 0.0, "debtUSD": 0.0,
                        "liquidityUSD": None, "shortfallUSD": None},
               "probed": a in {k.split("|")[0] for k in probes if "|" in k}}
        for m in MARKETS:
            b = bal[m].get(a, 0)
            if b:
                rec["balances"][m] = b
        if rec["probed"]:
            ai = probes.get(f"{a}|assetsIn", {})
            rec["assetsIn"] = ai.get("v") if isinstance(ai.get("v"), list) else ai.get("v")
            lq = probes.get(f"{a}|liquidity", {})
            if lq.get("v"):
                e, liq, short = lq["v"]
                rec["onchain"] = {"err": e, "liquidity": liq / 1e18, "shortfall": short / 1e18}
            rec["snapshots"] = {}
            for m in MARKETS:
                sn = probes.get(f"{a}|snap|{m}", {})
                if sn.get("v") and isinstance(sn["v"], list) and len(sn["v"]) == 4:
                    err, ctok, borrow, er = sn["v"]
                    rec["snapshots"][m] = {"err": err, "cTokenBalance": ctok,
                                           "borrowBalanceStored": borrow, "exchangeRateStored": er}
                    if ctok or borrow:
                        rec["balances"].setdefault(m, ctok)
                        if borrow:
                            rec["borrows"][m] = borrow
        # compute oracle/live values
        in_assets = set()
        if rec["assetsIn"]:
            for x in rec["assetsIn"]:
                for name, addr in MARKETS.items():
                    if x.lower() == addr:
                        in_assets.add(name)
        for m in MARKETS:
            ctok = rec["balances"].get(m, 0)
            borrow = rec["borrows"].get(m, 0)
            er = exch[m]
            underlying = (ctok / 10 ** DEC[m]) * er
            for label, prices in (("oracle", ORACLE), ("live", LIVE)):
                val = underlying * prices[m]
                debt = (borrow / 10 ** DEC[m]) * prices[m]
                rec[label]["collateralUSD"] += val if m in in_assets else 0.0
                if m in in_assets:
                    rec[label]["collateralAdjUSD"] += val * CF[m]
                rec[label]["debtUSD"] += debt
        for label in ("oracle", "live"):
            liq = rec[label]["collateralAdjUSD"] - rec[label]["debtUSD"]
            rec[label]["liquidityUSD"] = round(max(liq, 0.0), 6)
            rec[label]["shortfallUSD"] = round(max(-liq, 0.0), 6)
        positions[a] = rec
        if rec["oracle"]["shortfallUSD"] > 0:
            underwater.append(a)

    # liquidation scenarios for underwater accounts
    liq_scenarios = {}
    for a in underwater:
        rec = positions[a]
        in_assets = set()
        if rec["assetsIn"]:
            for x in rec["assetsIn"]:
                for name, addr in MARKETS.items():
                    if x.lower() == addr:
                        in_assets.add(name)
        scen = []
        for dm, debt_raw in rec["borrows"].items():
            debt_units = debt_raw / 10 ** DEC[dm]
            if debt_units <= 0:
                continue
            for cm in in_assets:
                ctok = rec["balances"].get(cm, 0)
                if ctok <= 0:
                    continue
                # max repay constrained by seize <= borrower balance:
                # seize_tokens = repay * 1.08 * P_d_oracle / (P_c_oracle * er)
                # max_repay = ctok * er * P_c_oracle / (1.08 * P_d_oracle)
                max_repay_units = (ctok / 10 ** DEC[cm]) * exch[cm] * ORACLE[cm] / (LIQ_INCENTIVE * ORACLE[dm])
                repay_units = min(debt_units, max_repay_units)
                seize_units = repay_units * LIQ_INCENTIVE * ORACLE[dm] / ORACLE[cm]
                seize_ctok = seize_units / exch[cm] if exch[cm] else 0
                # liquidator receives seizeTokens minus protocolSeizeShare (2.8%)
                PSS = 0.028
                liq_seize_units = seize_units * (1 - PSS)
                # real value at live prices
                real_cost = repay_units * LIVE[dm]
                real_received = liq_seize_units * LIVE[cm]
                redeemable = min(liq_seize_units, cash[cm] / 10 ** DEC[cm])
                scen.append({
                    "debtMarket": dm, "collateralMarket": cm,
                    "debtUnits": round(debt_units, 10), "maxRepayUnits": round(repay_units, 10),
                    "seizeUnderlying": round(seize_units, 10), "seizeCTokens": round(seize_ctok, 10),
                    "liquidatorSeizeUnderlyingAfterProtocolShare": round(liq_seize_units, 10),
                    "costLiveUSD": round(real_cost, 4), "receivedLiveUSD": round(real_received, 4),
                    "grossProfitLiveUSD": round(real_received - real_cost, 4),
                    "seizeRedeemableNow": round(redeemable, 10),
                    "collateralCashUnderlying": round(cash[cm] / 10 ** DEC[cm], 10),
                })
        liq_scenarios[a] = sorted(scen, key=lambda x: -x["grossProfitLiveUSD"])

    out = {
        "chain": "telos",
        "generated": "2026-10-14",
        "probe_blocks": probe_blocks,
        "prices": {"oracle": ORACLE, "live": LIVE,
                   "live_sources": {"USDC/USDT/ETH": "DefiLlama coins API 2026-10-14",
                                    "TLOS": "CoinGecko simple price 2026-10-14"}},
        "market_params": {"collateralFactor": CF, "exchangeRateStored": exch,
                          "cashUnderlying": {m: cash[m] / 10 ** DEC[m] for m in MARKETS},
                          "totalBorrowsUnderlying": {m: total_borrows[m] / 10 ** DEC[m] for m in MARKETS},
                          "closeFactor": 1.0, "liquidationIncentive": LIQ_INCENTIVE,
                          "whitelistedLiquidator": None},
        "n_accounts": len(accounts),
        "n_probed": sum(1 for r in positions.values() if r["probed"]),
        "underwater_onchain_oracle": underwater,
        "underwater_live_prices": [a for a in accounts if positions[a]["live"]["shortfallUSD"] > 0],
        "positions": positions,
        "liquidation_scenarios": liq_scenarios,
    }
    # summary stats
    tot_debt = sum(positions[a]["oracle"]["debtUSD"] for a in underwater)
    tot_coll = sum(positions[a]["oracle"]["collateralUSD"] for a in underwater)
    tot_sf = sum(positions[a]["oracle"]["shortfallUSD"] for a in underwater)
    profit = sum((liq_scenarios[a][0]["grossProfitLiveUSD"] if liq_scenarios.get(a) else 0.0) for a in underwater)
    probed_borrows = {m: 0 for m in MARKETS}
    for a, r in positions.items():
        if r["probed"]:
            for m, b in r["borrows"].items():
                probed_borrows[m] += b / 10 ** DEC[m]
    out["summary"] = {
        "n_holders": len(holders["_all_holders"]),
        "n_debtors_probed": len(probed_borrows) and sum(1 for r in positions.values() if r["probed"] and any(r["borrows"].values())),
        "debt_coverage_by_market": {m: {"probed": probed_borrows[m], "totalBorrows": total_borrows[m] / 10 ** DEC[m]} for m in MARKETS},
        "underwater_n": len(underwater),
        "underwater_total_shortfall_usd_oracle": round(tot_sf, 4),
        "underwater_total_debt_usd_oracle": round(tot_debt, 4),
        "underwater_total_collateral_usd_oracle": round(tot_coll, 4),
        "underwater_est_bad_debt_usd_oracle": round(max(tot_debt - tot_coll, 0.0), 4),
        "best_case_liquidation_profit_live_usd_total": round(profit, 4),
    }
    json.dump(out, open(os.path.join(OUT, "telos-positions.json"), "w"), indent=1)
    print("accounts:", len(accounts), "probed:", out["n_probed"])
    print("underwater (oracle):", underwater)
    print("underwater (live):", out["underwater_live_prices"])

if __name__ == "__main__":
    main()
