#!/usr/bin/env python3
"""Build clean evidence artifacts for the Pirate Chain deep dive.

Inputs are read-only public evidence saved under analysis/evidence/:
  - jina-stats.json / jina-history.json  (explorer.piratechain.com/stats/*.json via r.jina.ai)
  - source main.cpp at v5.9.3, v6.0.9, v6.0.10
  - gate-currency.json, coingecko.json, whattomine.json
No secrets, no keyed endpoints, no transactions.
"""
import json, re, os, csv, datetime

BASE = os.path.dirname(os.path.abspath(__file__))
EV = os.path.join(BASE, "evidence")

def load_json(path):
    with open(path, encoding="utf-8", errors="ignore") as f:
        t = f.read()
    i = t.find("{")
    return json.loads(t[i:]) if i >= 0 else json.loads(t)

def source_has(path, needle):
    with open(path, encoding="utf-8", errors="ignore") as f:
        return needle in f.read()

stats = load_json(os.path.join(EV, "jina-stats.json"))
hist = load_json(os.path.join(EV, "jina-history.json"))

# --- source-level checks -------------------------------------------------
src_5910 = os.path.join(EV, "main-v6.0.10.cpp")
src_609 = os.path.join(EV, "main-v6.0.9.cpp")
src_593 = os.path.join(EV, "main-v5.9.3.cpp")
src_checks = {
    "v5.9.3_connectblock_uses_IsCoinBase": source_has(src_593, "if (tx.IsCoinBase())"),
    "v6.0.9_connectblock_uses_IsMint": source_has(src_609, "if (tx.IsMint())"),
    "v6.0.10_connectblock_uses_IsCoinBase": source_has(src_5910, "if (tx.IsCoinBase())"),
    "v6.0.10_comment_only_coinbase_may_skip": source_has(
        src_5910, "Only the coinbase may skip input validation here"),
    "v6.0.10_has_VerifyCoinImport_reference": source_has(src_5910, "VerifyCoinImport"),
}
# `if (tx.IsMint())` also appears in CheckTransaction and elsewhere; verify the
# ConnectBlock hunk specifically by locating the fixed/vulnerable context.
def connectblock_mint_branch(path):
    txt = open(path, encoding="utf-8", errors="ignore").read()
    i = txt.find("ConnectBlock(const CBlock&")
    j = txt.find("ContextualCheckInputs(tx, state, view", i)
    if i < 0 or j < 0:
        return None
    hunk = txt[i:j]
    return {
        "is_mint_branch": "if (tx.IsMint())" in hunk,
        "is_coinbase_branch": "if (tx.IsCoinBase())" in hunk,
        "hunk_len": len(hunk),
    }
src_checks["connectblock_v6.0.9"] = connectblock_mint_branch(src_609)
src_checks["connectblock_v6.0.10"] = connectblock_mint_branch(src_5910)
src_checks["connectblock_v5.9.3"] = connectblock_mint_branch(src_593)
for k in ["connectblock_v6.0.9", "connectblock_v6.0.10", "connectblock_v5.9.3"]:
    v = src_checks[k]
    src_checks[k + "_ok"] = bool(v and (
        (k.endswith("6.0.9") and v["is_mint_branch"] and not v["is_coinbase_branch"]) or
        ((k.endswith("6.0.10") or k.endswith("5.9.3")) and v["is_coinbase_branch"] and not v["is_mint_branch"])
    ))

# --- on-chain supply history --------------------------------------------
d = hist["daily"]
idx = {day: i for i, day in enumerate(d["day"])}
rows = []
for day in d["day"]:
    if day < "2026-09-25":
        continue
    i = idx[day]
    pools = {k: d[k][i] for k in ("poolTransparent", "poolSapling", "poolIronwood", "poolSprout")}
    total = sum(pools.values())
    rows.append({
        "day": day,
        "blocks": d["blocks"][i],
        "tx": d["tx"][i],
        "coinbase": d["coinbase"][i],
        "shielding": d["shielding"][i],
        "newNotes": d["newNotes"][i],
        "poolTransparent": pools["poolTransparent"],
        "poolSapling": pools["poolSapling"],
        "poolIronwood": pools["poolIronwood"],
        "poolSprout": pools["poolSprout"],
        "total": total,
    })
for a, b in zip(rows, rows[1:]):
    b["delta_total"] = b["total"] - a["total"]
    b["delta_transparent"] = b["poolTransparent"] - a["poolTransparent"]
    b["delta_sapling"] = b["poolSapling"] - a["poolSapling"]
    b["delta_ironwood"] = b["poolIronwood"] - a["poolIronwood"]
rows[0]["delta_total"] = None

fields = ["day", "blocks", "tx", "coinbase", "shielding", "newNotes",
          "poolTransparent", "poolSapling", "poolIronwood", "poolSprout", "total",
          "delta_total", "delta_transparent", "delta_sapling", "delta_ironwood"]
with open(os.path.join(BASE, "onchain-supply-daily.csv"), "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader(); w.writerows(rows)

mint_events = [r for r in rows if r.get("delta_total") and r["delta_total"] > 1_000_000]
mint_total = sum(r["delta_total"] for r in mint_events)

# --- peer version distribution ------------------------------------------
up = stats["upgrade"]
versions = up["versions"]
def vtuple(x):
    parts = [int(p) for p in x.split(".")]
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts[:3])
def bucket(pred):
    return sum(v["peers"] for v in versions if pred(v["version"]))
peer_summary = {
    "sample_peers": up["peers"],
    "patched_6_0_10_plus": bucket(lambda x: vtuple(x) >= (6, 0, 10)),
    "vulnerable_6_0_0_to_6_0_9": bucket(lambda x: (6, 0, 0) <= vtuple(x) < (6, 0, 10)),
    "pre_6_0_0_stuck": bucket(lambda x: vtuple(x) < (6, 0, 0)),
    "versions": versions,
}
peer_summary["patched_pct"] = round(100.0 * peer_summary["patched_6_0_10_plus"] / up["peers"], 2)
peer_summary["vulnerable_pct"] = round(100.0 * peer_summary["vulnerable_6_0_0_to_6_0_9"] / up["peers"], 2)
peer_summary["stuck_pct"] = round(100.0 * peer_summary["pre_6_0_0_stuck"] / up["peers"], 2)
with open(os.path.join(BASE, "peer-versions.json"), "w") as f:
    json.dump(peer_summary, f, indent=2)

# --- economics -----------------------------------------------------------
cg = json.load(open(os.path.join(EV, "coingecko.json")))
price = cg["market_data"]["current_price"]["usd"]
wtm = json.load(open(os.path.join(EV, "whattomine.json")))
difficulty = float(wtm["difficulty"])
# Pirate powLimit = 0x0f0f... -> 2^256/powLimit ~= 16
# H = difficulty * 16 / block_time (solutions/s)
nethash_explorer = float(stats["networkSolps"])
block_time = float(stats["avgBlockSeconds"])
diff_implied_solps = difficulty * 16.0 / block_time
# NiceHash Equihash public market, 2026-10-17/18: 0.5722-0.6342 BTC/GSol/day.
# Use the mid/upper band and BTC ~ $82k (ChangeNOW page snapshot) -> ~$51,429/GSol/day.
usd_per_gsol_day = 51429.0
def rent_cost_usd(hashrate_solps, share):
    gsolps = hashrate_solps * share / 1e9
    return gsolps * usd_per_gsol_day
econ = {
    "price_usd": price,
    "block_reward_arrr": stats["reward"],
    "block_reward_usd": stats["reward"] * price,
    "blocks_per_day": 86400.0 / block_time,
    "daily_emission_arrr": stats["reward"] * 86400.0 / block_time,
    "daily_emission_usd": stats["reward"] * 86400.0 / block_time * price,
    "difficulty": difficulty,
    "avg_block_seconds": block_time,
    "nethash_explorer_solps": nethash_explorer,
    "nethash_difficulty_implied_solps": round(diff_implied_solps, 1),
    "nethash_explorer_mhs": round(nethash_explorer / 1e6, 3),
    "rent_cost_usd_per_day_10pct": round(rent_cost_usd(nethash_explorer, 0.10), 2),
    "rent_cost_usd_per_day_51pct": round(rent_cost_usd(nethash_explorer, 0.51), 2),
    "expected_block_cost_usd": round(rent_cost_usd(nethash_explorer, 1.0) * block_time / 86400.0, 4),
    "expected_block_cost_usd_10pct_share": round(rent_cost_usd(nethash_explorer, 0.10) * (block_time / 0.10) / 86400.0, 4),
    "expected_block_cost_usd_51pct_share": round(rent_cost_usd(nethash_explorer, 0.51) * (block_time / 0.51) / 86400.0, 4),
    "nicehash_usd_per_gsol_day_assumption": usd_per_gsol_day,
}
with open(os.path.join(BASE, "economics.json"), "w") as f:
    json.dump(econ, f, indent=2)

# --- summary -------------------------------------------------------------
summary = {
    "generated_utc": datetime.datetime.utcnow().isoformat() + "Z",
    "explorer_updated": stats["updated"],
    "height": stats["height"],
    "total_supply_arrr": stats["supply"],
    "circulating_supply_arrr": stats["circulating"],
    "max_supply_arrr": stats["maxSupply"],
    "pct_of_max": round(100.0 * stats["supply"] / stats["maxSupply"], 2),
    "pools": stats["pools"],
    "mint_events": mint_events,
    "mint_total_arrr": mint_total,
    "mint_total_usd": round(mint_total * price, 2),
    "official_first_mint_arrr": 39_800_000,
    "second_mint_arrr": 40_000_000,
    "pre_mint_supply_arrr": rows[[r["day"] for r in rows].index("2026-10-13")]["total"],
    "peer_summary": peer_summary,
    "source_checks": src_checks,
    "economics": econ,
}
with open(os.path.join(BASE, "computed-summary.json"), "w") as f:
    json.dump(summary, f, indent=2)
print(json.dumps(summary, indent=2)[:6000])
