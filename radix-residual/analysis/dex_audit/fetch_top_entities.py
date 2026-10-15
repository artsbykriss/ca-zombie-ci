#!/usr/bin/env python3
"""Fetch live on-chain state for top Ociswap pools + DefiPlaza pairs (read-only)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details, ledger_state  # noqa: E402


def prog(v):
    """Extract a readable value from a metadata item value."""
    try:
        t = v.get("typed") or {}
        if t.get("value") is not None:
            return t["value"]
        pj = v.get("programmatic_json")
        if pj and pj.get("fields"):
            return pj["fields"][0].get("value")
        return v.get("raw_hex")
    except Exception:  # noqa: BLE001
        return None


def meta_dict(it):
    out = {}
    for m in it.get("metadata", {}).get("items", []):
        out[m["key"]] = prog(m["value"])
    return out


def main():
    live = json.load(open("ociswap_pools_live.json"))
    live.sort(key=lambda p: -p["_tvl_usd_now"])
    ls = ledger_state()
    print("ledger:", ls)
    top = live[:12]
    addrs = [p["address"] for p in top]
    d = entity_details(addrs)
    json.dump(d, open("ociswap_top_entities.json", "w"), indent=1)
    summary = []
    for p, it in zip(top, d["items"]):
        det = it.get("details") or {}
        bp = det.get("blueprint_name")
        meta = meta_dict(it)
        row = {
            "api_tvl_usd": round(p["_tvl_usd_now"], 2),
            "address": it["address"],
            "blueprint": bp,
            "package": det.get("package_address"),
            "name": meta.get("name"),
            "input_fee_rate": meta.get("input_fee_rate"),
            "flash_loan_fee_rate": meta.get("flash_loan_fee_rate"),
            "x_share": meta.get("x_share"),
            "hooks": meta.get("hooks"),
            "registry": meta.get("registry"),
            "liquidity_pool": meta.get("liquidity_pool"),
            "lp_address": meta.get("lp_address"),
            "flash_loan_address": meta.get("flash_loan_address"),
            "x_address": meta.get("x_address"),
            "y_address": meta.get("y_address"),
            "tick_spacing": meta.get("tick_spacing"),
        }
        summary.append(row)
        print(json.dumps(row, indent=1))
    json.dump(summary, open("ociswap_top_summary.json", "w"), indent=1)

    print("\n--- packages seen ---")
    print({r["package"]: r["blueprint"] for r in summary})

    print("\n--- low/zero fee pools among live ---")
    for p in live:
        try:
            fr = float(p.get("fee_rate") or 0)
        except Exception:  # noqa: BLE001
            fr = -1
        if fr <= 0.0005:
            print(f"  fee={fr} {p['address']} {p.get('blueprint_name')} {p.get('name')} ${p['_tvl_usd_now']:.2f}")
    from collections import Counter
    c = Counter(str(p.get("fee_rate")) for p in live)
    print("fee_rate histogram (live pools):", dict(c.most_common(20)))
    c2 = Counter(str(p.get("blueprint_name")) for p in live)
    print("blueprint histogram (live pools):", dict(c2.most_common(20)))


if __name__ == "__main__":
    main()
