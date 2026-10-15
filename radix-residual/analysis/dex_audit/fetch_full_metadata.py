#!/usr/bin/env python3
"""Fetch FULL metadata pages for top Ociswap pools (to recover 'hooks', 'registry', etc.)."""
import json
import sys

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
        t = (v.get("typed") or {})
        pj = v.get("programmatic_json") or {}
        val = t.get("value")
        if val is None:
            val = pj
        out[m["key"]] = val
    return out


def main():
    s = json.load(open("ociswap_top_summary.json"))
    addrs = [r["address"] for r in s]
    allmeta = {}
    for a in addrs:
        m = full_metadata(a)
        allmeta[a] = m
        hooks = m.get("hooks")
        print(f"{a} [{m.get('name')}] hooks={json.dumps(hooks)[:200]} registry={m.get('registry')} "
              f"fee={m.get('input_fee_rate')} flfr={m.get('flash_loan_fee_rate')}")
    json.dump(allmeta, open("ociswap_top_metadata_full.json", "w"), indent=1)


if __name__ == "__main__":
    main()
