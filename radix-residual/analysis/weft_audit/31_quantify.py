#!/usr/bin/env python3
"""Quantify max extractable liquidation bonus across all liquidatable CDPs (fungible path only)."""
import json

health = json.load(open("weft_cdp_health_raw.json"))

def dec(f):
    try:
        return float((f or {}).get("value") or 0)
    except Exception:
        return 0.0

def get_bonus(fs, idx):
    """config tuple at idx: [description, ltv, liq_spread, bonus]."""
    cfg = fs[idx]
    if not isinstance(cfg, dict) or cfg.get("kind") != "Tuple":
        return None
    fl = cfg.get("fields", [])
    if len(fl) >= 4:
        try:
            return float(fl[3].get("value"))
        except Exception:
            return None
    return None

BONUS = {0: 0.07, 1: 0.07, 2: 0.07, 3: 0.10, 4: 0.10, 5: 0.03, 6: 0.05, 7: 0.12}

cdp_rows = []
for cid, fields in health.items():
    if len(fields) < 14:
        continue
    liq_ltv = dec(fields[8])
    adj_loan = dec(fields[1])
    if liq_ltv <= 1.0 or adj_loan <= 0:
        continue
    loans = {}
    for e in fields[11].get("entries", []):
        res = e["key"]["value"]
        fs = e["value"]["fields"]
        loans[res] = {"value": dec(fs[3]), "adjusted": dec(fs[4])}
    colls = {}
    for e in fields[12].get("entries", []):
        res = e["key"]["value"]
        fs = e["value"]["fields"]
        colls[res] = {"value": dec(fs[2]), "liq_value": dec(fs[4]), "bonus": get_bonus(fs, 6), "liq_cost": None}
    nft_count = len(fields[13].get("entries", []))
    cdp_rows.append({
        "id": cid, "liq_ltv": liq_ltv, "adj_loan": adj_loan,
        "loans": loans, "colls": colls, "n_nft_coll": nft_count,
    })

print("liquidatable CDPs:", len(cdp_rows))
tot_repay_cap = 0.0
tot_profit_gross = 0.0
tot_profit_net = 0.0
per_asset = {}
rows_out = []
for r in cdp_rows:
    repay_cap_value = 0.5 * r["adj_loan"]  # close factor 0.5 in value terms
    # Greedy: attacker seizes highest-bonus fungible collateral first, capacity = collateral value
    # Effective: seize value = repay_value * (1+b); attacker wants max total profit
    # For each unit of repay value, profit = (1+b)(1-0.2b)-1
    options = []
    for res, c in r["colls"].items():
        b = c.get("bonus") or 0.0
        if b <= 0:
            continue
        efficiency = (1 + b) * (1 - 0.2 * b) - 1  # net profit per unit repay
        # capacity in repay-value terms: collateral value / (1+b) if fully seizable
        cap = c["value"] / (1 + b)
        options.append((efficiency, cap, res, b, c["value"]))
    options.sort(reverse=True)
    repayables = []
    remaining = repay_cap_value
    for eff, cap, res, b, cv in options:
        take = min(cap, remaining)
        if take <= 0:
            continue
        repayables.append((res, take, b, cv, eff))
        remaining -= take
    # also cap total repay by availability of loan assets (assume values ok)
    if not repayables:
        continue
    gross = sum(take * (1 + b) * (1 - 0.2 * b) - take for _, take, b, _, _ in repayables)
    # acquisition cost estimate: 0.5% of repaid value for non-XRD assets
    cost = 0.0
    per_asset_here = {}
    for res, take, b, cv, eff in repayables:
        cost += take * (0.0 if res.endswith("radxrdxxxxxxxxx009923554798xxxxxxxxxradxrd") else 0.005)
        per_asset_here[res] = per_asset_here.get(res, 0) + take
    for res, v in per_asset_here.items():
        per_asset[res] = per_asset.get(res, 0) + v
    tot_repay_cap += repay_cap_value
    tot_profit_gross += gross
    tot_profit_net += gross - cost
    rows_out.append({
        "id": r["id"], "liq_ltv": r["liq_ltv"], "repay_cap_value": repay_cap_value,
        "gross_profit": gross, "acq_cost_est": cost, "nft_colls": r["n_nft_coll"],
        "repayables": [{"res": a, "value": t, "bonus": b} for a, t, b, _, _ in repayables],
    })

rows_out.sort(key=lambda x: -x["gross_profit"])
XRD_USD = 0.0004519403550191712
print(f"\nTOTAL repay capacity (value): {tot_repay_cap:,.2f} XRD")
print(f"TOTAL gross bonus profit:    {tot_profit_gross:,.2f} XRD  (${tot_profit_gross*XRD_USD:,.2f})")
print(f"TOTAL net after est 0.5% acq: {tot_profit_net:,.2f} XRD  (${tot_profit_net*XRD_USD:,.2f})")
print()
print("Top 20 CDPs by gross profit:")
for r in rows_out[:20]:
    assets = ", ".join(f"{a['res'][-8:]}={a['value']:.1f}(b={a['bonus']})" for a in r["repayables"])
    print(f"  {r['id']}: gross={r['gross_profit']:.2f} XRD (${r['gross_profit']*XRD_USD:.4f}) cap={r['repay_cap_value']:.1f} nft={r['nft_colls']}")
    print(f"      repay: {assets}")
print()
print("Repay volume by debt asset (top):")
for res, v in sorted(per_asset.items(), key=lambda kv: -kv[1])[:12]:
    print(f"  {res}: {v:,.2f} value-units")
json.dump({"rows": rows_out, "totals": {"repay_cap_value": tot_repay_cap, "gross_xrd": tot_profit_gross,
                                         "net_xrd": tot_profit_net, "xrd_usd": XRD_USD}},
          open("weft_extract_quant.json", "w"), indent=1)
