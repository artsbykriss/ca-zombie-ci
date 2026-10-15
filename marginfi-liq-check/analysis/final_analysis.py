#!/usr/bin/env python3
"""Consolidate the re-derivation, pulse-verification and model-validation into final numbers.

Outputs analysis/final_numbers.json:
  * model-vs-program validation stats (delta distribution)
  * program-verified liquidatable set (from pulse): count, deficit, collateral
  * per-account table for the top candidates with fee-bound math
  * theoretical liquidation-fee bound for the whole verified set
"""
import json, os, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
scan = json.load(open(os.path.join(HERE, "rederived_underwater.json")))
pulse = json.load(open(os.path.join(HERE, "pulse_all.json")))
cands = json.load(open(os.path.join(HERE, "pulse_candidates.json")))
banks = json.load(open(os.path.join(HERE, "state", "banks_decoded.json")))

model = {r["account"]: r for r in scan["all_underwater"]}
pmap = {r["account"]: r for r in pulse if r.get("health")}

out = {}

# ---- 1. model vs program validation ----
deltas = []
for pk, r in pmap.items():
    m = model.get(pk)
    if not m:
        continue
    ph = r["health"]["health_maint"]
    deltas.append({"account": pk, "model": m["health_usd"], "program": ph,
                   "delta": ph - m["health_usd"],
                   "rel": abs(ph - m["health_usd"]) / max(abs(ph), 1e-9)})
deltas.sort(key=lambda d: -abs(d["delta"]))
out["validation"] = {
    "n": len(deltas),
    "median_abs_delta_usd": sorted(abs(d["delta"]) for d in deltas)[len(deltas)//2] if deltas else None,
    "max_abs_delta_usd": max((abs(d["delta"]) for d in deltas), default=None),
    "within_1pct": sum(1 for d in deltas if d["rel"] < 0.01),
    "worst": deltas[:8],
}

# ---- 2. program-verified liquidatable set ----
liq = [r for r in pmap.values() if r["health"]["internal_liq_err"] == 0]
healthy = [r for r in pmap.values() if r["health"]["internal_liq_err"] == 6068]
panics = [r for r in pulse if r.get("err") == "ProgramFailedToComplete"]
other_err = [r for r in pulse if r.get("err") and r["err"] != "ProgramFailedToComplete"]

# collateral detection: re-use model detail where available
def collateral(pk):
    """Unweighted seizable collateral value (asset amount x oracle low price)."""
    m = model.get(pk)
    if m is None:
        return None
    tot = 0.0
    for d in m["detail"]:
        if d["side"] == "asset":
            w = d.get("weight") or 0.0
            if w > 0:
                tot += d["value"] / w
            else:
                tot += d["amount"] * d.get("price_low", 0.0)
    return tot

rows = []
for r in liq:
    hc = r["health"]
    coll = collateral(r["account"])
    deficit = -hc["health_maint"]
    rows.append({
        "account": r["account"], "program_maint_health": hc["health_maint"],
        "program_init_health": hc["health_init"], "deficit_usd": round(deficit, 2),
        "n_balances": r["n_balances"], "banks": r["banks"],
        "seizable_collateral_usd": round(coll, 6) if coll is not None else None,
    })
rows.sort(key=lambda r: r["program_maint_health"])
out["program_verified"] = {
    "pulsed_total": len(pmap),
    "liquidatable": len(liq),
    "healthy_6068": len(healthy),
    "program_panic_legacy_banks": len(panics),
    "other_errors": len(other_err),
    "liquidatable_total_deficit_usd": round(sum(r["deficit_usd"] for r in rows), 2),
    "liquidatable_with_collateral": sum(1 for r in rows if (r["seizable_collateral_usd"] or 0) > 0.01),
    "liquidatable_collateral_total_usd": round(sum(r["seizable_collateral_usd"] or 0
                                                  for r in rows if (r["seizable_collateral_usd"] or 0) > 0.01), 4),
    "top": rows[:40],
}

# ---- 3. fee bound ----
# liquidator fee = 2.5% of seized collateral value; max seizure bounded by
#   post-liquidation health <= 0  =>  V <= deficit / (lwm*(1-f_l) - awm)
# and by available collateral. Use per-bank weights where known; conservative defaults otherwise.
fee_rows = []
for r in rows:
    coll = r["seizable_collateral_usd"]
    if coll is None:
        continue
    if coll <= 0.01:
        fee_rows.append({"account": r["account"], "seizable_usd": 0.0, "fee_usd": 0.0,
                         "reason": "no collateral to seize"})
        continue
    # max seizure bounded by deficit / (lwm*(1-f_l) - awm) and by available collateral
    seizable = min(coll, r["deficit_usd"] / 0.37)
    fee = 0.025 * seizable
    fee_rows.append({"account": r["account"], "seizable_usd": round(seizable, 6),
                     "fee_usd": round(fee, 8)})
out["fee_bound"] = {
    "total_seizable_usd": round(sum(f["seizable_usd"] for f in fee_rows), 4),
    "total_liquidator_fee_usd": round(sum(f["fee_usd"] for f in fee_rows), 6),
    "n_no_collateral": sum(1 for f in fee_rows if f["seizable_usd"] == 0),
    "rows": fee_rows[:40],
}

json.dump(out, open(os.path.join(HERE, "final_numbers.json"), "w"), indent=1)
print(json.dumps({k: {kk: vv for kk, vv in v.items() if kk not in ("top", "rows", "worst")}
                  for k, v in out.items()}, indent=1))
