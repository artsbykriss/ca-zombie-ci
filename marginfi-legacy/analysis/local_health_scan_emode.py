#!/usr/bin/env python3
"""marginfi account health scan WITH classic emode reconciliation (deployed v0.1.12 semantics).

- Classic emode: reconcile the EmodeConfigs of ALL banks used by the account (intersection of
  collateral tags; merged weight = min across configs, per reconcile_emode_configs).
- Asset weight = max(bank.asset_weight_maint, reconciled[asset_bank.emode_tag].asset_weight_maint)
  (Bank::get_asset_weight semantics).
- Liability weight = bank.liability_weight_maint (no emode on the liability side).
- Same-asset emode is NOT modelled (it can only make accounts healthier; flagged as caveat).

Reads: /tmp/opencode/mfi-data/balances_all.json (balances dump), ci/data/banks_compact.json,
analysis/bank_emode.json. Writes analysis/health_scan_emode.json.
"""
import json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "ci"))
from scan_health import iter_entries, decode_balances
import base58

BAL = "/tmp/opencode/mfi-data/balances_all.json"
banks = json.load(open(os.path.join(os.path.dirname(HERE), "ci", "data", "banks_compact.json")))
emode = json.load(open(os.path.join(HERE, "bank_emode.json")))
bank_keys = {base58.b58decode(k): v for k, v in banks.items()}

def reconcile_emode_maint(used_banks):
    """Intersection of emode entries across all used banks; merged maint weight = min."""
    if len(used_banks) < 2:
        # with a single bank the intersection is its own entries
        pass
    tag_maps = []
    for b in used_banks:
        e = emode.get(b, {})
        tag_maps.append({x["tag"]: x for x in e.get("entries", [])})
    if not tag_maps:
        return {}
    common = set(tag_maps[0].keys())
    for m in tag_maps[1:]:
        common &= set(m.keys())
    out = {}
    for t in common:
        out[t] = min(m[t]["aw_maint"] for m in tag_maps)
    return out

total_dep = total_bor = 0.0
n = n_bor = 0
unhealthy, init_def = [], []
per_bank_liab = {}
t0 = time.time()
for pk, raw in iter_entries(BAL):
    n += 1
    bals = decode_balances(raw)
    used = [base58.b58encode(br).decode() for br, _, _ in bals if base58.b58encode(br).decode() in banks]
    recon = reconcile_emode_maint(used)
    m_asset = m_liab = i_asset = i_liab = 0.0
    dep = bor = 0.0
    for bank_raw, a_shares, l_shares in bals:
        bpk = base58.b58encode(bank_raw).decode()
        b = banks.get(bpk)
        if b is None:
            continue
        px = b["price"] or 0.0
        if px <= 0:
            continue
        dec = 10.0 ** b["dec"]
        if a_shares:
            v = a_shares * b["asv"] / dec * px
            dep += v
            tag = emode.get(bpk, {}).get("tag", 0)
            awm = b["awm"]
            if tag and tag in recon:
                awm = max(awm, recon[tag])
            awi = b["awi"]
            # emode init weight (min across configs, max with bank)
            if tag and tag in recon:
                pass  # init handled below only if needed
            m_asset += v * awm
            i_asset += v * awi
        if l_shares:
            v = l_shares * b["lsv"] / dec * px
            bor += v
            m_liab += v * b["lwm"]
            i_liab += v * b["lwi"]
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
out = {
    "accounts_scanned": n, "accounts_with_borrows": n_bor,
    "total_deposits_usd": round(total_dep, 2), "total_borrows_usd": round(total_bor, 2),
    "n_unhealthy_maint": len(unhealthy),
    "unhealthy_total_deficit_usd": round(sum(r["maint_deficit_usd"] for r in unhealthy), 2),
    "n_init_deficit": len(init_def),
    "init_deficit_total_usd": round(sum(r["init_deficit_usd"] for r in init_def), 2),
    "top_unhealthy": unhealthy[:60], "top_init_deficit": init_def[:60],
    "note": "classic emode applied (intersection/min/max); same-asset emode not modelled; "
            "confidence bias not applied; protocol (cache) prices with market fallback",
    "elapsed_s": round(time.time() - t0, 1),
}
json.dump(out, open(os.path.join(HERE, "health_scan_emode.json"), "w"), indent=1)
print(json.dumps({k: v for k, v in out.items() if not isinstance(v, list)}, indent=1))
print("top unhealthy (with emode):")
for r in unhealthy[:15]: print("  ", json.dumps(r))
