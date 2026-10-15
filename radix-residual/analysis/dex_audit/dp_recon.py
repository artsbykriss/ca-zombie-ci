#!/usr/bin/env python3
"""DefiPlaza live recon: pair configs, LP tokens, resource symbols (read-only)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details  # noqa: E402


def chunked(addrs, n=20):
    out = {"items": []}
    for i in range(0, len(addrs), n):
        d = entity_details(addrs[i:i + n])
        out["items"].extend(d["items"])
    return out


def main():
    pairs = json.load(open("defiplaza_pairs_live.json"))
    pairs.sort(key=lambda p: -(p.get("tvlUSD") or 0))
    top = pairs[:10]
    res = set()
    for p in top:
        res.add(p["baseToken"])
        res.add(p["quoteToken"])
    rd = chunked(sorted(res))
    json.dump(rd, open("dp_resources.json", "w"), indent=1)
    for it in rd["items"]:
        det = it.get("details") or {}
        meta = {m["key"]: ((m["value"].get("typed") or {}).get("value"))
                for m in it.get("metadata", {}).get("items", [])}
        print(f"{it['address']}  symbol={meta.get('symbol')} name={str(meta.get('name'))[:24]} "
              f"div={ ((det.get('state') or {}).get('fields') or [{}])} supply={det.get('total_supply')}")

    comps = [p["address"] for p in top]
    cd = chunked(comps)
    json.dump(cd, open("dp_top_pairs.json", "w"), indent=1)
    for p, it in zip(top, cd["items"]):
        det = it.get("details") or {}
        st = det.get("state") or {}
        flat = {}
        for f in st.get("fields", []):
            flat[f.get("field_name")] = f.get("value") if "value" in f else f.get("fields")
        print(f"\n=== {it['address']} [{det.get('blueprint_name')}] tvlUSD={p.get('tvlUSD'):.2f}")
        print("   state:", json.dumps(flat)[:800])
        meta = {m["key"]: ((m["value"].get("typed") or {}).get("value")
                           or (m["value"].get("programmatic_json") or {}))
                for m in it.get("metadata", {}).get("items", [])}
        for k, v in meta.items():
            print(f"   meta {k}: {json.dumps(v)[:120]}")


if __name__ == "__main__":
    main()
