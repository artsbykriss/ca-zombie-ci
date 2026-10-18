"""Conditional (whitelisted/off-chain) quantification + IBP status snapshot. Read-only.

Inputs:
  - analysis/census.json (current 204 underwater accounts)
  - /tmp/opencode/realt/v4b_ledger.json (per-account RealToken ledger, 202 accounts, 2026-10-17)
  - /tmp/opencode/realt/v4b_ibp_eligible.json (118 IBP-eligible RealTokens from realt.co flags)
  - analysis/wrapper_tokens.json (frozen marks)

Output: analysis/ibp_conditional.json + analysis/ibp_status.json
"""
import json
import os
import re
import sys
import time

import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

LEDGER = "/tmp/opencode/realt/v4b_ledger.json"
ELIG = "/tmp/opencode/realt/v4b_ibp_eligible.json"


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    marks = {t["address"]: t["price_1e8"] / 1e8 for t in wt["tokens"]}
    census = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "census.json")))
    under = {r["address"].lower(): r for r in census["all_liquidatable"]}

    eligible = set(x.lower() for x in json.load(open(ELIG)))
    ledger = {k.lower(): {t.lower(): a for t, a in v.items()} for k, v in json.load(open(LEDGER)).items()}

    rows = []
    for a, rec in under.items():
        l = ledger.get(a, {})
        elig_val = sum(amt * marks.get(t, 0) / 1e18 for t, amt in l.items() if t in eligible)
        all_val = sum(amt * marks.get(t, 0) / 1e18 for t, amt in l.items())
        hf = rec["hf"]
        cf = 1.0 if hf <= 0.95 else 0.5
        debt = rec["debt_usd"]
        dmax = min(debt * cf, elig_val / 1.1)
        rows.append({"address": a, "hf": hf, "debt_usd": debt, "cf": cf,
                     "ledger_value_usd_marks": round(all_val, 2),
                     "eligible_value_usd_marks": round(elig_val, 2),
                     "deployable_usd": round(dmax, 2),
                     "eligible_share": round(elig_val / all_val, 4) if all_val else 0})
    rows.sort(key=lambda x: -x["deployable_usd"])

    deployable = sum(r["deployable_usd"] for r in rows)
    out = {
        "chain": "gnosis", "block": block, "timestamp": ts,
        "ibp_eligible_tokens": len(eligible),
        "accounts_underwater": len(rows),
        "accounts_with_eligible_collateral": sum(1 for r in rows if r["eligible_value_usd_marks"] > 0),
        "eligible_collateral_usd_marks": round(sum(r["eligible_value_usd_marks"] for r in rows), 2),
        "total_collateral_usd_marks": round(sum(r["ledger_value_usd_marks"] for r in rows), 2),
        "deployable_capital_usd": round(deployable, 2),
        "net_scenarios": {
            "ibp_net_0.92": round(deployable * (1.1 * 0.92 - 1), 2),
            "ibp_net_0.945": round(deployable * (1.1 * 0.945 - 1), 2),
            "ibp_net_0.97": round(deployable * (1.1 * 0.97 - 1), 2),
        },
        "top_accounts": rows[:25],
        "note": ("Conditional only: requires a RealT-whitelisted/KYC'd account, a live Issuer Buyback "
                 "Program (paused as of this block) and issuer approval. Not achievable by an "
                 "unprivileged attacker."),
    }
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ibp_conditional.json")
    json.dump(out, open(p, "w"), indent=2)
    print("wrote", p)
    print(json.dumps({k: v for k, v in out.items() if not isinstance(v, list)}, indent=1))

    # --- live IBP status ---
    st = {"source": "https://realt.co/sell-orders/", "fetched_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    try:
        r = requests.get("https://realt.co/sell-orders/", headers={"user-agent": "Mozilla/5.0"}, timeout=40)
        html = r.text
        st["http_status"] = r.status_code
        key = '"sell_tokens_settings":'
        i = html.find(key)
        parsed = None
        if i >= 0:
            j = html.find("{", i)
            depth = 0
            for k in range(j, min(len(html), j + 5000)):
                if html[k] == "{":
                    depth += 1
                elif html[k] == "}":
                    depth -= 1
                    if depth == 0:
                        try:
                            parsed = json.loads(html[j:k + 1])
                        except Exception:  # noqa: BLE001
                            parsed = None
                        break
        st["sell_tokens_settings"] = parsed
        m2 = re.search(r'"disabled_notice":"([^"]*)"', html)
        st["disabled_notice"] = m2.group(1) if m2 else None
        m3 = re.search(r'temporarily paused token buyback[^<]*', html)
        st["page_notice"] = m3.group(0) if m3 else None
        st["allow_sell_orders_values_in_page"] = sorted(set(re.findall(r'"allow_sell_orders":"([^"]*)"', html)))
    except Exception as e:  # noqa: BLE001
        st["error"] = str(e)[:300]
    p2 = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ibp_status.json")
    json.dump(st, open(p2, "w"), indent=2)
    print("wrote", p2)
    print(json.dumps(st, indent=1)[:1200])


if __name__ == "__main__":
    main()
