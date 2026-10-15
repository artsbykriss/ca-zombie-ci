#!/usr/bin/env python3
"""Enumerate all DefiPlaza Radix pairs via cursor pagination."""
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


def main():
    pairs = {}
    cursor = 0
    pages = 0
    while pages < 100:
        d = get(f"https://radix.defiplaza.net/api/pairs?cursor={cursor}&limit=100")
        data = d.get("data", [])
        if not data:
            break
        new = 0
        for p in data:
            if p["address"] not in pairs:
                pairs[p["address"]] = p
                new += 1
        nc = d.get("cursor")
        print(f"cursor {cursor} got {len(data)} new {new} next {nc} cum {len(pairs)}", file=sys.stderr)
        if new == 0:
            break
        if nc is None:
            break
        cursor = nc
        pages += 1
        time.sleep(0.15)
    allp = list(pairs.values())
    json.dump(allp, open("defiplaza_pairs_raw.json", "w"), indent=1)
    allp.sort(key=lambda x: -(x.get("tvlUSD") or 0))
    live = [p for p in allp if (p.get("tvlUSD") or 0) > 0.01]
    json.dump(live, open("defiplaza_pairs_live.json", "w"), indent=1)
    print(f"total pairs {len(allp)} live {len(live)} TVL ${sum(p['tvlUSD'] for p in live):.2f}")
    for p in live[:60]:
        print(f"  ${p.get('tvlUSD'):10.2f} {p['address']}  base={p.get('baseToken','')[:40]} quote={p.get('quoteToken','')[:40]}")
        print(f"       basePool={p.get('basePool')} quotePool={p.get('quotePool')} dex={p.get('dexAddress')}")
    dexs = {}
    for p in allp:
        dexs[p.get("dexAddress")] = dexs.get(p.get("dexAddress"), 0) + 1
    print("dex components:", dexs)


if __name__ == "__main__":
    main()
