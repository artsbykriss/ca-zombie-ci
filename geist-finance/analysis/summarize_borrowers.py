#!/usr/bin/env python3
"""Summarise ci-out/borrowers.json: HF distribution, debt totals, worst-with-collateral list."""
import json, sys, os

path = sys.argv[1] if len(sys.argv) > 1 else "ci-out/borrowers.json"
d = json.load(open(path))
bs = d.get("borrowers", [])
print(f"head={d.get('head')} candidates={d.get('n_candidates')} live_debtors={len(bs)}")
print(f"scan: {json.dumps(d.get('scan', {}))[:300]}")

HF1 = 10**18
with_hf = [b for b in bs if "healthFactor" in b]
lt1 = [b for b in with_hf if int(b["healthFactor"]) < HF1]
zero_coll = [b for b in with_hf if int(b.get("totalCollateralETH", 0)) == 0]
print(f"with HF: {len(with_hf)}  HF<1: {len(lt1)}  zero-collateral: {len(zero_coll)}")
print(f"HF<1 with collateral: {len([b for b in lt1 if int(b.get('totalCollateralETH',0))>0])}")

# debt totals (raw units by symbol)
tot = {}
for b in bs:
    for sym, v in b.get("debt", {}).items():
        tot[sym] = tot.get(sym, 0) + int(v)
print("total live debt (raw units):", {k: str(v) for k, v in sorted(tot.items())})

print("\n--- HF<1 sorted, with collateral ---")
rows = sorted([b for b in lt1 if int(b.get("totalCollateralETH", 0)) > 0], key=lambda b: int(b["healthFactor"]))
for b in rows[:30]:
    print(f"{b['address']}  HF={b['healthFactor']}  collETH={b['totalCollateralETH']}  debtETH={b['totalDebtETH']}  debt={b['debt']}")
print(f"(total rows: {len(rows)})")

print("\n--- HF<1, zero collateral (bad debt, not liquidatable) ---")
rows2 = sorted([b for b in lt1 if int(b.get("totalCollateralETH", 0)) == 0], key=lambda b: -int(b.get("totalDebtETH", 0)))
for b in rows2[:10]:
    print(f"{b['address']}  HF={b['healthFactor']}  debtETH={b['totalDebtETH']}  debt={b['debt']}")
print(f"(total rows: {len(rows2)})")
