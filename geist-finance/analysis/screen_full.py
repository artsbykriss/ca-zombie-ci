#!/usr/bin/env python3
"""Full screen: every live underwater borrower from ci-out/borrowers.json -> best liquidation pair."""
import importlib.util, json

spec = importlib.util.spec_from_file_location("sb", "analysis/scan_borrowers.py")
sb = importlib.util.module_from_spec(spec); spec.loader.exec_module(sb)
sb.choose_rpc()

oracle = {"DAI": 0.999895350000000000, "ETH": 2519.052063000000000000, "WFTM": 0.107457370000000000,
          "BTC": 68615.038815340000000000, "fUSDT": 0.999498260000000000, "USDC": 0.999915790000000000,
          "CRV": 0.354000000000000000, "MIM": 0.998663350000000000, "LINK": 8.722330000000000000}
market = {"DAI": 0.0129, "ETH": 26.3, "WFTM": 0.0684, "BTC": 1066.0, "fUSDT": 0.0567,
          "USDC": 0.117, "CRV": 0.00427, "MIM": 0.0426, "LINK": 0.215}
bonus = {"DAI": 1.05, "ETH": 1.05, "WFTM": 1.10, "BTC": 1.10, "fUSDT": 1.05,
         "USDC": 1.05, "CRV": 1.10, "MIM": 1.05, "LINK": 1.10}
dec = {"DAI": 18, "ETH": 18, "WFTM": 18, "BTC": 8, "fUSDT": 6, "USDC": 6, "CRV": 18, "MIM": 18, "LINK": 18}
r = {k: oracle[k] / market[k] for k in oracle}

# live cash + aTokens
cash, atoks = {}, {}
for (sym, asset, vdebt) in sb.RESERVES:
    rd = sb.rpc("eth_call", [{"to": sb.POOL, "data": "0x35ea6a75" + asset[2:].rjust(64, "0")}, "latest"])
    b = bytes.fromhex(rd[2:])
    atoks[sym] = "0x" + b[224+12:256].hex()
    bal = sb.rpc("eth_call", [{"to": asset, "data": "0x70a08231" + atoks[sym][2:].rjust(64, "0")}, "latest"])
    cash[sym] = int(bal, 16) / 10**dec[sym]

d = json.load(open("ci-out/borrowers.json"))
bs = d["borrowers"]
HF1 = 10**18
cands = [b for b in bs if "healthFactor" in b and int(b["healthFactor"]) < HF1 and int(b.get("totalCollateralETH", 0)) > 0]
print(f"HF<1 with collateral: {len(cands)}")

addrs = [b["address"] for b in cands]
multi = sb.multicall_balances_multi(list(atoks.values()), addrs)
inv = {v: k for k, v in atoks.items()}

rows = []
for o in cands:
    a = o["address"]
    coll = {inv[t]: v / 10**dec[inv[t]] for t, v in multi.get(a, {}).items()}
    debt = {k: int(v) / 10**dec[k] for k, v in o["debt"].items()}
    best = None
    for dtsym, dv in debt.items():
        for c, cv in coll.items():
            if cash[c] <= 0:
                continue
            pf = r[dtsym] * bonus[dtsym] / r[c]
            if pf <= 1.02:
                continue
            r_max = min(0.5 * dv, cv * oracle[c] / (oracle[dtsym] * bonus[dtsym]))
            seize_units = min(r_max * oracle[dtsym] * bonus[dtsym] / oracle[c], cv, cash[c])
            realisable = seize_units * market[c]
            cost = r_max * market[dtsym]
            profit = realisable - cost
            if best is None or profit > best["profit_usd"]:
                best = {"debt": dtsym, "coll": c, "pf": pf, "repay_max": r_max, "coll_amt": cv,
                        "seize_units": seize_units, "realisable_usd": realisable, "cost_usd": cost,
                        "profit_usd": profit}
    if best and best["profit_usd"] > 1:
        rows.append({"address": a, "hf": o["healthFactor"], "coll": coll, "debt": debt, **best})

rows.sort(key=lambda x: -x["profit_usd"])
print(f"profitable (est > $1): {len(rows)}")
tot = 0
for x in rows[:25]:
    print(f"{x['address']} HF={x['hf']}  best {x['coll']} <- debt {x['debt']}")
    print(f"    repay {x['repay_max']:.4f} {x['debt']} -> seize {x['seize_units']:.4f} {x['coll']} "
          f"(bal {x['coll_amt']:.2f}) PF={x['pf']:.2f} realisable ${x['realisable_usd']:,.0f} "
          f"cost ${x['cost_usd']:,.0f} profit ${x['profit_usd']:,.0f}")
    tot += x["profit_usd"]
print(f"sum of estimated profits (all profitable rows): ${sum(x['profit_usd'] for x in rows):,.0f}")
json.dump(rows, open("ci-out/liq_screen.json", "w"), indent=1)
