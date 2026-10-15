#!/usr/bin/env python3
"""Hooks sweep: check every live Ociswap pool with meaningful TVL for registered hooks,
and record the pool-level fee config. Read-only."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post  # noqa: E402


def full_metadata(addr):
    items = []
    cursor = None
    while True:
        body = {"address": addr, "limit_per_page": 100}
        if cursor:
            body["cursor"] = cursor
        d = post("/state/entity/page/metadata", body)
        items.extend(d.get("items", []))
        cursor = d.get("next_cursor")
        if not cursor:
            break
    out = {}
    for m in items:
        v = m.get("value") or {}
        val = (v.get("typed") or {}).get("value")
        if val is None:
            pj = v.get("programmatic_json") or {}
            fl = pj.get("fields")
            val = fl[0].get("elements") if (fl and isinstance(fl[0], dict) and "elements" in fl[0]) else pj
        out[m["key"]] = val
    return out


def main():
    live = json.load(open("ociswap_pools_live.json"))
    live.sort(key=lambda p: -p["_tvl_usd_now"])
    top = live[:600]
    res = []
    for p in top:
        try:
            m = full_metadata(p["address"])
        except Exception as e:  # noqa: BLE001
            print("meta fail", p["address"], e, file=sys.stderr)
            continue
        hooks = m.get("hooks")
        n = 0
        if isinstance(hooks, list):
            n = len([x for x in hooks if x])
        elif isinstance(hooks, dict):
            fl = hooks.get("fields") or []
            for f in fl:
                if isinstance(f, dict) and f.get("elements"):
                    n += len(f["elements"])
        res.append({"address": p["address"], "bp": p.get("blueprint_name"),
                    "tvl": round(p["_tvl_usd_now"], 2), "hooks_n": n,
                    "fee": m.get("input_fee_rate"), "flfee": m.get("flash_loan_fee_rate"),
                    "registry": m.get("registry")})
        time.sleep(0.05)
    json.dump(res, open("ociswap_hooks_sweep.json", "w"), indent=1)
    tot = sum(r["tvl"] for r in res)
    withhooks = [r for r in res if r["hooks_n"]]
    print(f"pools checked: {len(res)}  TVL covered: ${tot:.2f}")
    print(f"pools WITH hooks: {len(withhooks)}")
    for r in withhooks[:10]:
        print("  ", r)
    from collections import Counter
    print("blueprints:", Counter(r["bp"] for r in res))
    print("fees:", Counter(str(r["fee"]) for r in res))


if __name__ == "__main__":
    main()
