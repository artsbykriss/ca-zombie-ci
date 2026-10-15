#!/usr/bin/env python3
"""Efficient live-pool enumeration for Ociswap using ?cursor= pagination."""
import json
import sys
import time
import urllib.request

UA = {"User-Agent": "radix-residual-research/1.0"}


def get(url, tries=6):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            return json.loads(urllib.request.urlopen(req, timeout=60).read())
        except Exception as e:  # noqa: BLE001
            print(f"  retry {type(e).__name__} {e}", file=sys.stderr)
            time.sleep(2 + 2 * t)
    raise SystemExit(f"failed: {url}")


def tvl_usd(p):
    tv = p.get("total_value_locked") or {}
    v = (tv.get("usd") or {}).get("now")
    try:
        return float(v)
    except Exception:  # noqa: BLE001
        return 0.0


def main():
    allp = {}
    live = []
    seen_cursors = set()
    cursor = None
    pages = 0
    while pages < 400:
        url = "https://api.ociswap.com/pools?limit=100"
        if cursor is not None:
            url += f"&cursor={cursor}"
        d = get(url)
        data = d.get("data", [])
        if not data:
            break
        nz = 0
        new = 0
        for p in data:
            if p["address"] in allp:
                continue
            new += 1
            u = tvl_usd(p)
            p["_tvl_usd_now"] = u
            allp[p["address"]] = p
            if u > 0.01:
                live.append(p)
                nz += 1
        nc = d.get("cursor") or d.get("next_cursor")
        print(f"page {pages} cursor={cursor} got {len(data)} new {new} live {nz} "
              f"next={str(nc)[:30]} cum={len(allp)}", file=sys.stderr)
        if new == 0 and nc == cursor:
            break
        cursor = nc
        pages += 1
        if len(data) < 100 and not nc:
            break
        time.sleep(0.1)
    json.dump(list(allp.values()), open("ociswap_pools_scanned.json", "w"))
    json.dump(live, open("ociswap_pools_live.json", "w"), indent=1)
    live.sort(key=lambda x: -x["_tvl_usd_now"])
    print(f"scanned pools: {len(allp)}  live: {len(live)}  TVL sum: ${sum(p['_tvl_usd_now'] for p in live):.2f}")
    for p in live[:60]:
        print(f"  ${p['_tvl_usd_now']:10.2f}  {p['address']}  {p.get('blueprint_name'):14s} {p.get('name'):24s} "
              f"fee={p.get('fee_rate')} lp={p.get('lp_token_address')}")
    by_bp = {}
    for p in live:
        by_bp[p.get("blueprint_name")] = by_bp.get(p.get("blueprint_name"), 0) + p["_tvl_usd_now"]
    print("live TVL by blueprint:", {k: round(v, 2) for k, v in by_bp.items()})


if __name__ == "__main__":
    main()
