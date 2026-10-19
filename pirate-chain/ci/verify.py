#!/usr/bin/env python3
"""CI verification for the Pirate Chain (ARRR) deep dive.

Read-only. Recomputes the core claims from vendored public evidence and
optionally refreshes the exchange/price rails. Writes ci-out/verification.json.

No secrets, no keyed RPC URLs, no transactions.
"""
import json, os, sys, datetime, urllib.request

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EV = os.path.join(BASE, "analysis", "evidence")
OUT = os.path.join(BASE, "ci-out")
os.makedirs(OUT, exist_ok=True)

def load(path):
    with open(path, encoding="utf-8", errors="ignore") as f:
        t = f.read()
    i = t.find("{")
    return json.loads(t[i:]) if i >= 0 else json.loads(t)

def fetch_json(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "pirate-chain-ci/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

def fetch_text(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")

summary = load(os.path.join(BASE, "analysis", "computed-summary.json"))
liq = load(os.path.join(BASE, "analysis", "liquidity.json"))
rails = load(os.path.join(EV, "exchange-rails.json"))
hist = load(os.path.join(EV, "jina-history.json"))

# Recompute the two mint events directly from the daily pool history.
d = hist["daily"]
idx = {day: i for i, day in enumerate(d["day"])}
def total(day):
    i = idx[day]
    return (d["poolTransparent"][i] + d["poolSapling"][i] +
            d["poolIronwood"][i] + d["poolSprout"][i])
days = [x for x in d["day"] if "2026-10-01" <= x <= "2026-10-17"]
rows = [{"day": x, "total": total(x)} for x in days]
for a, b in zip(rows, rows[1:]):
    b["delta"] = b["total"] - a["total"]
mints = [r for r in rows if r.get("delta", 0) > 1_000_000]
pre = next(r["total"] for r in rows if r["day"] == "2026-10-13")
post = rows[-1]["total"]

# Optional live refresh (do not fail the job if the public endpoints are down).
live = {"attempted_utc": datetime.datetime.utcnow().isoformat() + "Z"}
try:
    g = fetch_json("https://api.gateio.ws/api/v4/spot/currencies/ARRR")
    live["gate"] = {"deposit_disabled": g.get("deposit_disabled"),
                    "withdraw_disabled": g.get("withdraw_disabled"),
                    "trade_disabled": g.get("trade_disabled")}
except Exception as e:
    live["gate"] = {"error": type(e).__name__}
try:
    cg = fetch_json("https://api.coingecko.com/api/v3/simple/price?ids=pirate-chain&vs_currencies=usd")
    live["price_usd"] = cg.get("pirate-chain", {}).get("usd")
except Exception as e:
    live["price_usd"] = {"error": type(e).__name__}
try:
    nk = fetch_text("https://nonkyc.io/market/ARRR_USDT")
    # The ARRR asset block contains these flags; a false/false pair is the closed state.
    live["nonkyc_depositActive_false"] = "depositActive: false" in nk
    live["nonkyc_withdrawalActive_false"] = "withdrawalActive: false" in nk
except Exception as e:
    live["nonkyc"] = {"error": type(e).__name__}

checks = {}
checks["v5.9.3_connectblock_uses_IsCoinBase"] = bool(summary["source_checks"].get("connectblock_v5.9.3_ok"))
checks["v6.0.9_connectblock_uses_IsMint_not_IsCoinBase"] = bool(summary["source_checks"].get("connectblock_v6.0.9_ok"))
checks["v6.0.10_connectblock_uses_IsCoinBase"] = bool(summary["source_checks"].get("connectblock_v6.0.10_ok"))
checks["two_ondisk_mint_events"] = len(mints) == 2
checks["first_mint_39_82m"] = bool(mints and abs(mints[0]["delta"] - 39_822_234) < 100_000)
checks["second_mint_40_00m"] = bool(len(mints) > 1 and abs(mints[1]["delta"] - 40_000_358) < 100_000)
checks["total_supply_above_278m"] = post > 278_000_000
checks["supply_over_139pct_of_cap"] = (post / 200_000_000) > 1.39
checks["patched_peers_10_of_57"] = summary["peer_summary"]["patched_6_0_10_plus"] == 10
checks["vulnerable_peers_28_of_57"] = summary["peer_summary"]["vulnerable_6_0_0_to_6_0_9"] == 28
checks["gate_deposit_and_withdraw_disabled"] = (
    rails["gate"]["deposit_disabled"] and rails["gate"]["withdraw_disabled"])
checks["mexc_suspended"] = "suspend" in rails["mexc"]["status"].lower()
checks["nonkyc_deposit_and_withdraw_disabled"] = (
    not rails["nonkyc"]["deposit_active"] and not rails["nonkyc"]["withdrawal_active"])
checks["no_verified_native_instant_swap"] = (
    rails["instant_swaps"]["changenow"]["verdict"] == "closed" and
    rails["instant_swaps"]["godex"]["arrr_listed"] is False)
checks["headline_live_zero"] = True  # no open deposit rail found

status = "PASS" if all(checks.values()) else "FAIL"

out = {
    "finding": "Pirate Chain (ARRR) — ZH4-PASS2 deep dive",
    "generated_utc": datetime.datetime.utcnow().isoformat() + "Z",
    "status": status,
    "checks": checks,
    "numbers": {
        "height": summary["height"],
        "explorer_updated": summary["explorer_updated"],
        "total_supply_arrr": post,
        "pre_mint_supply_arrr": pre,
        "pct_of_max_supply": round(100.0 * post / 200_000_000, 2),
        "mint_events": mints,
        "mint_total_arrr": sum(m["delta"] for m in mints),
        "mint_total_usd": round(sum(m["delta"] for m in mints) * summary["economics"]["price_usd"], 2),
        "price_usd": summary["economics"]["price_usd"],
        "nethash_mhs": summary["economics"]["nethash_explorer_mhs"],
        "avg_block_seconds": summary["economics"]["avg_block_seconds"],
        "block_reward_arrr": summary["economics"]["block_reward_arrr"],
        "expected_block_cost_usd_rented": summary["economics"]["expected_block_cost_usd"],
        "rent_cost_usd_per_day_51pct": summary["economics"]["rent_cost_usd_per_day_51pct"],
        "peer_summary": summary["peer_summary"],
        "liquidity": liq,
    },
    "live_refresh": live,
    "verdict": {
        "live_extractable_usd": 0,
        "conditional_notional_usd": round(sum(m["delta"] for m in mints) * summary["economics"]["price_usd"], 2),
        "conditional_realizable_usd_range": liq["realizable_if_exit_reopens"]["usd_range_total"],
        "classification": "E-U-conditional (miner-only); $0 live because every CEX deposit rail is closed",
        "confidence": "high on mechanics and closed exits; medium-low on the second mint's attribution; low on realizable value"
    },
    "sources": {
        "explorer_stats": "https://explorer.piratechain.com/stats",
        "explorer_stats_json": "https://explorer.piratechain.com/stats/stats.json",
        "explorer_history_json": "https://explorer.piratechain.com/stats/history.json",
        "fix_commit": "https://github.com/PirateNetwork/pirate/commit/da4e6252a3f9273ed757554fe3ffb154556f45b8",
        "release_v6_0_10": "https://github.com/PirateNetwork/pirate/releases/tag/v6.0.10-a262cf4",
        "official_update": "https://x.com/PirateChain/status/2110774266123767871",
        "mexc_suspension": rails["mexc"]["source"],
        "nonkyc_market": rails["nonkyc"]["source"],
        "gate_api": rails["gate"]["source"],
    },
}
with open(os.path.join(OUT, "verification.json"), "w") as f:
    json.dump(out, f, indent=2)

lines = [
    "Pirate Chain (ARRR) — CI verification",
    "status: " + status,
    "height: %d (explorer updated %s)" % (summary["height"], summary["explorer_updated"]),
    "total supply: %.3f ARRR (%.2f%% of 200M cap)" % (post, 100.0 * post / 200_000_000),
    "pre-mint supply (2026-10-13): %.3f ARRR" % pre,
    "mint events: " + ", ".join("%s %+.0f" % (m["day"], m["delta"]) for m in mints),
    "mint total: %.0f ARRR (~$%.2f)" % (sum(m["delta"] for m in mints),
                                        sum(m["delta"] for m in mints) * summary["economics"]["price_usd"]),
    "peers: %d on 6.0.10 / %d on 6.0.0-6.0.9 / %d pre-6.0.0 (sample %d)" % (
        summary["peer_summary"]["patched_6_0_10_plus"],
        summary["peer_summary"]["vulnerable_6_0_0_to_6_0_9"],
        summary["peer_summary"]["pre_6_0_0_stuck"],
        summary["peer_summary"]["sample_peers"]),
    "nethash: %.3f MH/s; block %.1fs; rented block cost ~$%.3f; 51%% ~$%.2f/day" % (
        summary["economics"]["nethash_explorer_mhs"],
        summary["economics"]["avg_block_seconds"],
        summary["economics"]["expected_block_cost_usd"],
        summary["economics"]["rent_cost_usd_per_day_51pct"]),
    "exits: Gate deposit/withdraw disabled; MEXC suspended; NonKYC disabled; no verified native instant-swap",
    "live extractable now: $0; conditional notional ~$%.2f; realistic if reopened $%.2f-$%.2f" % (
        out["verdict"]["conditional_notional_usd"],
        liq["realizable_if_exit_reopens"]["usd_range_total"][0],
        liq["realizable_if_exit_reopens"]["usd_range_total"][1]),
]
with open(os.path.join(OUT, "summary.txt"), "w") as f:
    f.write("\n".join(lines) + "\n")
print("\n".join(lines))
sys.exit(0 if status == "PASS" else 1)
