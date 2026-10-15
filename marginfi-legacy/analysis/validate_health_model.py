#!/usr/bin/env python3
"""Validate the local health model against the protocol's own on-chain health cache for accounts
whose cache is fresh (< 6h). Compares asset_value_maint / liability_value_maint.
Reads: /tmp/opencode/mfi-data/balances_all.json, /tmp/opencode/mfi-data/health_caches.json,
ci/data/banks_compact.json, analysis/bank_emode.json. Writes analysis/health_validation.json."""
import base64, json, os, struct, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "ci"))
from scan_health import iter_entries, decode_balances
import base58

D = "/tmp/opencode/mfi-data"
banks = json.load(open(os.path.join(os.path.dirname(HERE), "ci", "data", "banks_compact.json")))
emode = json.load(open(os.path.join(HERE, "bank_emode.json")))
bank_keys = {base58.b58decode(k): v for k, v in banks.items()}
I80F48 = float(1 << 48)

# health caches: pubkey -> (av_m, lv_m, av_i, lv_i, ts, flags)
caches = {}
for pk, raw in iter_entries(os.path.join(D, "health_caches.json")):
    def f16(b): return int.from_bytes(b, 'little', signed=True) / I80F48
    caches[pk] = {
        "av_i": f16(raw[0:16]), "lv_i": f16(raw[16:32]),
        "av_m": f16(raw[32:48]), "lv_m": f16(raw[48:64]),
        "ts": struct.unpack_from('<q', raw, 96)[0],
        "flags": struct.unpack_from('<I', raw, 104)[0],
    }
print("caches:", len(caches))

def reconcile(used):
    maps = []
    for b in used:
        maps.append({x["tag"]: x for x in emode.get(b, {}).get("entries", [])})
    if not maps: return {}
    common = set(maps[0])
    for m in maps[1:]: common &= set(m)
    return {t: min(m[t]["aw_maint"] for m in maps) for t in common}

now = time.time()
rows = []
n = 0
for pk, raw in iter_entries(os.path.join(D, "balances_all.json")):
    c = caches.get(pk)
    if not c or not c["ts"]:
        continue
    age = now - c["ts"]
    if age > 6 * 3600:
        continue
    n += 1
    bals = decode_balances(raw)
    used = [base58.b58encode(br).decode() for br, _, _ in bals if base58.b58encode(br).decode() in banks]
    recon = reconcile(used)
    m_a = m_l = 0.0
    for bank_raw, a_sh, l_sh in bals:
        bpk = base58.b58encode(bank_raw).decode()
        b = banks.get(bpk)
        if not b: continue
        px = b["price"] or 0.0
        if px <= 0: continue
        dec = 10.0 ** b["dec"]
        if a_sh:
            awm = b["awm"]
            tag = emode.get(bpk, {}).get("tag", 0)
            if tag and tag in recon: awm = max(awm, recon[tag])
            m_a += a_sh * b["asv"] / dec * px * awm
        if l_sh:
            m_l += l_sh * b["lsv"] / dec * px * b["lwm"]
    if m_l < 100 and m_a < 100:
        continue
    rows.append({"account": pk, "cache_av_m": round(c["av_m"], 2), "model_av_m": round(m_a, 2),
                 "cache_lv_m": round(c["lv_m"], 2), "model_lv_m": round(m_l, 2),
                 "cache_flags": c["flags"], "age_h": round(age / 3600, 2)})

rows.sort(key=lambda r: -r["cache_lv_m"])
print(f"fresh caches with positions: {len(rows)}")
ok = 0
for r in rows[:25]:
    if r["cache_lv_m"] > 0:
        rel = abs(r["model_lv_m"] - r["cache_lv_m"]) / r["cache_lv_m"]
    else:
        rel = 0
    flag = "OK" if rel < 0.05 else ("~" if rel < 0.2 else "DIFF")
    if rel < 0.05: ok += 1
    print(f"{flag} {r['account'][:20]} cache av_m={r['cache_av_m']:>14,.0f} lv_m={r['cache_lv_m']:>14,.0f} | "
          f"model av_m={r['model_av_m']:>14,.0f} lv_m={r['model_lv_m']:>14,.0f} | age={r['age_h']}h flags={r['cache_flags']}")
json.dump(rows[:200], open(os.path.join(HERE, "health_validation.json"), "w"), indent=1)
