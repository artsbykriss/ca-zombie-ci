#!/usr/bin/env python3
"""Screen live underwater borrowers for profitable liquidation pairs.

For each borrower with HF<1 and collateral, evaluate every (debt, collateral) pair:
  profit factor PF = r_debt * bonus / r_coll          (r = oracle/market price)
  realisable collateral value = value of the collateral balance if sold into the live DEX pools
Rank and print the best candidates for the fork PoC.
Input: /tmp/opencode/recent_live_borrowers.json (from the local probe) + on-chain balances.
"""
import importlib.util, json, sys

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

# reserve cash (read live)
cash = {}
for (sym, asset, vdebt) in sb.RESERVES:
    rd = sb.rpc("eth_call", [{"to": sb.POOL, "data": "0x35ea6a75" + asset[2:].rjust(64, "0")}, "latest"])
    b = bytes.fromhex(rd[2:])
    atok = "0x" + b[224+12:256].hex()
    bal = sb.rpc("eth_call", [{"to": asset, "data": "0x70a08231" + atok[2:].rjust(64, "0")}, "latest"])
    cash[sym] = int(bal, 16) / 10**dec[sym]

data = json.load(open('/tmp/opencode/recent_live_borrowers.json'))
HF1 = 10**18
cands = [o for o in data if "HF" in o and int(o["HF"]) < HF1 and int(o.get("collETH", "0")) > 0]
print(f"candidates: {len(cands)}")

# fetch collateral balances for all candidates
atoks = {}
for (sym, asset, vdebt) in sb.RESERVES:
    rd = sb.rpc("eth_call", [{"to": sb.POOL, "data": "0x35ea6a75" + asset[2:].rjust(64, "0")}, "latest"])
    b = bytes.fromhex(rd[2:])
    atoks[sym] = "0x" + b[224+12:256].hex()
addrs = [o["address"] for o in cands]
multi = sb.multicall_balances_multi(list(atoks.values()), addrs)
inv = {v: k for k, v in atoks.items()}

rows = []
for o in cands:
    a = o["address"]
    coll = {inv[t]: v / 10**dec[inv[t]] for t, v in multi.get(a, {}).items()}
    debt = {k: int(v) / 10**dec[k] for k, v in o["debt"].items()}
    best = None
    for d, dv in debt.items():
        for c, cv in coll.items():
            if cash[c] <= 0:
                continue
            pf = r[d] * bonus[d] / r[c]
            if pf <= 1.02:
                continue
            # max repayable per position (close factor 50% per call; repeated calls allowed,
            # so effectively the whole debt), capped by the collateral available for seizure
            r_max_debt = 0.5 * dv
            r_max_coll = cv * oracle[c] / (oracle[d] * bonus[d])
            r_max = min(r_max_debt, r_max_coll)
            # realisable value of the seized collateral (capped by the reserve cash)
            seize_units = r_max * oracle[d] * bonus[d] / oracle[c]
            seize_units = min(seize_units, cv, cash[c])
            realisable = seize_units * market[c]
            cost = r_max * market[d]
            profit_est = realisable - cost
            if best is None or profit_est > best["profit_est_usd"]:
                best = {"debt": d, "coll": c, "pf": pf, "repay_max": r_max, "coll_amt": cv,
                        "coll_realisable_usd": realisable, "cost_usd": cost, "profit_est_usd": profit_est}
    if best and best["profit_est_usd"] > 0:
        rows.append({"address": a, "hf": o["HF"], "coll_usd_oracle": int(o["collETH"]) / 1e18,
                     "coll": coll, "debt": debt, **best})

rows.sort(key=lambda x: -x["profit_est_usd"])
print(f"profitable candidates: {len(rows)}")
for x in rows[:15]:
    print(f"{x['address']} HF={x['hf']}")
    print(f"    debt {x['debt']}")
    print(f"    coll {x['coll']}")
    print(f"    best: repay {x['repay_max']:.4f} {x['debt']} -> seize {x['coll_amt']:.4f} {x['coll']}  PF={x['pf']:.2f}  "
          f"realisable ${x['coll_realisable_usd']:,.0f}  cost ${x['cost_usd']:,.0f}  est profit ${x['profit_est_usd']:,.0f}")
json.dump(rows, open('/tmp/opencode/liq_candidates.json', 'w'), indent=1)
