#!/usr/bin/env python3
"""Compute final TVL totals + evidence summary for the report; writes totals.json."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import ledger_state  # noqa: E402


def main():
    oci = json.load(open("ociswap_pools_live.json"))
    dp = json.load(open("defiplaza_pairs_live.json"))
    from collections import Counter
    oci_tot = sum(p["_tvl_usd_now"] for p in oci)
    bp = Counter()
    for p in oci:
        bp[p.get("blueprint_name")] += p["_tvl_usd_now"]
    dp_tot = sum(p.get("tvlUSD") or 0 for p in dp)
    dp_dex = Counter()
    for p in dp:
        dp_dex[p.get("dexAddress")] += (p.get("tvlUSD") or 0)
    out = {
        "ledger": ledger_state(),
        "ociswap": {"live_pools": len(oci), "tvl_usd": round(oci_tot, 2),
                    "by_blueprint": {k: round(v, 2) for k, v in bp.items()},
                    "top10": [{"addr": p["address"], "bp": p["blueprint_name"],
                               "name": p.get("name"), "usd": round(p["_tvl_usd_now"], 2)}
                              for p in sorted(oci, key=lambda x: -x["_tvl_usd_now"])[:10]]},
        "defiplaza": {"live_pairs": len(dp), "tvl_usd": round(dp_tot, 2),
                      "by_dex": {k: round(v, 2) for k, v in dp_dex.items()},
                      "top10": [{"addr": p["address"], "base": p["baseToken"][:40],
                                 "quote": p["quoteToken"][:40], "usd": round(p.get("tvlUSD") or 0, 2)}
                                for p in sorted(dp, key=lambda x: -(x.get("tvlUSD") or 0))[:10]]},
        "combined_tvl_usd": round(oci_tot + dp_tot, 2),
        "xrd_price_usd": 0.0004519766729587112,
        "price_source": "https://coins.llama.fi/prices/current/coingecko:radix (2026-10-15)",
    }
    json.dump(out, open("totals.json", "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
