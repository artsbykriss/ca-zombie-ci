#!/usr/bin/env python3
"""Local run of the marginfi account health scan against a previously fetched balances dump
(/tmp/opencode/mfi-data/balances_all.json). Reuses ci/scan_health.py helpers.
Writes analysis/health_scan_local.json (small)."""
import json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "ci"))
from scan_health import iter_entries, decode_balances
import base58

BAL = "/tmp/opencode/mfi-data/balances_all.json"
banks = json.load(open(os.path.join(os.path.dirname(HERE), "ci", "data", "banks_compact.json")))
bank_keys = {base58.b58decode(k): v for k, v in banks.items()}

total_dep = total_bor = 0.0
n = n_bor = 0
unhealthy, init_def = [], []
per_bank_liab = {}
missing = set()
t0 = time.time()
for pk, raw in iter_entries(BAL):
    n += 1
    m_asset = m_liab = i_asset = i_liab = 0.0
    dep = bor = 0.0
    for bank_raw, a_shares, l_shares in decode_balances(raw):
        b = bank_keys.get(bank_raw)
        if b is None:
            missing.add(bank_raw.hex()); continue
        px = b["price"] or 0.0
        if px <= 0:
            continue
        dec = 10.0 ** b["dec"]
        if a_shares:
            v = a_shares * b["asv"] / dec * px
            dep += v; m_asset += v * b["awm"]; i_asset += v * b["awi"]
        if l_shares:
            v = l_shares * b["lsv"] / dec * px
            bor += v; m_liab += v * b["lwm"]; i_liab += v * b["lwi"]
            per_bank_liab[b["mint"]] = per_bank_liab.get(b["mint"], 0.0) + v
    total_dep += dep; total_bor += bor
    if bor > 0.01: n_bor += 1
    if m_liab - m_asset > 0.01:
        unhealthy.append({"account": pk, "maint_deficit_usd": round(m_liab - m_asset, 2),
                          "dep_usd": round(dep, 2), "bor_usd": round(bor, 2)})
    if i_liab - i_asset > 0.01:
        init_def.append({"account": pk, "init_deficit_usd": round(i_liab - i_asset, 2),
                         "dep_usd": round(dep, 2), "bor_usd": round(bor, 2)})

unhealthy.sort(key=lambda r: -r["maint_deficit_usd"])
init_def.sort(key=lambda r: -r["init_deficit_usd"])
xcheck = []
for k, b in banks.items():
    if not b["tls"]: continue
    nominal = b["tls"] * b["lsv"] / (10.0 ** b["dec"]) * (b["price"] or 0.0)
    if nominal > 1000:
        scanned = per_bank_liab.get(b["mint"], 0.0)
        xcheck.append({"bank": k, "mint": b["mint"], "bank_total_usd": round(nominal, 2),
                       "scanned_usd": round(scanned, 2), "ratio": round(scanned / nominal, 4) if nominal else None})
xcheck.sort(key=lambda r: -r["bank_total_usd"])
out = {
    "accounts_scanned": n, "accounts_with_borrows": n_bor,
    "total_deposits_usd": round(total_dep, 2), "total_borrows_usd": round(total_bor, 2),
    "n_unhealthy_maint": len(unhealthy), "unhealthy_total_deficit_usd": round(sum(r["maint_deficit_usd"] for r in unhealthy), 2),
    "n_init_deficit": len(init_def), "init_deficit_total_usd": round(sum(r["init_deficit_usd"] for r in init_def), 2),
    "top_unhealthy": unhealthy[:60], "top_init_deficit": init_def[:60],
    "bank_liability_crosscheck_top30": xcheck[:30], "unknown_bank_keys": list(missing)[:20],
    "elapsed_s": round(time.time() - t0, 1),
}
json.dump(out, open(os.path.join(HERE, "health_scan_local.json"), "w"), indent=1)
print(json.dumps({k: v for k, v in out.items() if not isinstance(v, list)}, indent=1))
print("top unhealthy:")
for r in unhealthy[:15]: print("  ", json.dumps(r))
print("xcheck top:")
for r in xcheck[:10]: print("  ", json.dumps(r))
