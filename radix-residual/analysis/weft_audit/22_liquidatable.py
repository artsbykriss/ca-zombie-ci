#!/usr/bin/env python3
"""Analyze liquidatable CDPs: positions, collateral, bonus potential."""
import json

health = json.load(open("weft_cdp_health_raw.json"))

def dec(f):
    try:
        return float((f or {}).get("value") or 0)
    except Exception:
        return 0.0

# collateral configs (id -> (name, ltv, spread, bonus))
CCOLL = {
    0: ("Ecosystem market mover", 0.75, 0.05, 0.07),
    1: ("Global Market Mover", 0.75, 0.05, 0.07),
    2: ("Stable coin", 0.65, 0.05, 0.07),
    3: ("Volatile assets 1 (Project Tokens)", 0.10, 0.05, 0.10),
    4: ("Volatile assets 2 (Culture Coins)", 0.10, 0.05, 0.10),
    5: ("Efficiency same resources", 0.95, 0.01, 0.03),
    6: ("Efficiency highly correlated", 0.90, 0.02, 0.05),
    7: ("Conservative Default LTV", 0.50, 0.10, 0.12),
}

def parse_positions(fields, idx, kind):
    pos = {}
    mp = fields[idx]
    for e in mp.get("entries", []):
        res = e["key"]["value"]
        fs = e["value"]["fields"]
        # CollateralPositionData: [price, amount, value, health_value, liquidation_value, discounted_value, config, config_version, resource_config, is_from_nft, resource_type]
        # LoanPositionData: [price, units, amount, value, adjusted_value, config, config_version, resource_config]
        if kind == "coll":
            pos[res] = {"price": dec(fs[0]), "amount": dec(fs[1]), "value": dec(fs[2]),
                        "liq_value": dec(fs[4]), "discounted": dec(fs[5])}
        else:
            pos[res] = {"price": dec(fs[0]), "units": dec(fs[1]), "amount": dec(fs[2]),
                        "value": dec(fs[3]), "adjusted": dec(fs[4])}
    return pos

rows = []
for cid, fields in health.items():
    if len(fields) < 14:
        continue
    row = {
        "id": cid,
        "loan": dec(fields[0]),
        "adj_loan": dec(fields[1]),
        "coll": dec(fields[2]),
        "health_coll": dec(fields[3]),
        "liq_coll": dec(fields[4]),
        "health_ltv": dec(fields[7]),
        "liq_ltv": dec(fields[8]),
        "loans": parse_positions(fields, 11, "loan"),
        "colls": parse_positions(fields, 12, "coll"),
    }
    rows.append(row)

open_rows = [r for r in rows if r["liq_ltv"] > 1.000001 and r["loan"] > 0]
open_rows.sort(key=lambda r: -r["liq_coll"])
print("liquidatable CDPs:", len(open_rows))
print()
print("TOP 30 by liquidation collateral value:")
for r in open_rows[:30]:
    print(f"{r['id']}: liq_ltv={r['liq_ltv']:.3f} loan={r['loan']:.3f} liq_coll={r['liq_coll']:.4f}")
    for res, p in r["loans"].items():
        print(f"    LOAN {res[:46]} amt={p['amount']:.6f} units={p['units']:.6f} price={p['price']:.6f} val={p['value']:.3f}")
    for res, p in r["colls"].items():
        print(f"    COLL {res[:46]} amt={p['amount']:.6f} price={p['price']:.8f} val={p['value']:.6f} liqval={p['liq_value']:.6f}")

# aggregate potential bonus: repayable = min(loan_close_factor*loan, liq_coll/(1+bonus)); assume close factor 0.5, bonus from collateral config
# we don't know per-collateral config here; use the weighted approach: bonus_est conservatively at 5%
tot_liqcoll = sum(r["liq_coll"] for r in open_rows)
tot_loan = sum(r["loan"] for r in open_rows)
tot_adj = sum(r["adj_loan"] for r in open_rows)
big = [r for r in open_rows if r["liq_coll"] > 1.0]
print()
print("aggregate: total loan(nominal valued) =", round(tot_loan, 2))
print("aggregate: total adjusted loan =", round(tot_adj, 2))
print("aggregate: total liquidation collateral =", round(tot_liqcoll, 4), "XRD")
big.sort(key=lambda r: -r["liq_coll"])
print("CDPs with liq_coll > 1 XRD:", len(big), "-> sum liq_coll:", round(sum(r['liq_coll'] for r in big), 2))
json.dump(open_rows, open("weft_liquidatable_cdps.json", "w"), indent=1)
