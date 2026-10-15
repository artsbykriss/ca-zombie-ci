#!/usr/bin/env python3
"""Enumerate ALL Ociswap pools and DefiPlaza pairs. Read-only, public APIs."""
import json
import sys
import time
import urllib.request

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
UA = {"User-Agent": "radix-residual-research/1.0"}


def get(url, tries=6):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            return json.loads(urllib.request.urlopen(req, timeout=90).read())
        except Exception as e:  # noqa: BLE001
            print(f"  retry {type(e).__name__} {e}", file=sys.stderr)
            time.sleep(2 + 2 * t)
    raise SystemExit(f"failed: {url}")


def main():
    # ---- Ociswap ----
    pools = []
    offset = 0
    while True:
        d = get(f"https://api.ociswap.com/pools?limit=100&offset={offset}")
        data = d.get("data", [])
        if not data:
            break
        pools.extend(data)
        print(f"ociswap offset {offset}: got {len(data)}", file=sys.stderr)
        offset += len(data)
        if len(data) < 100:
            break
        time.sleep(0.2)
    json.dump(pools, open("ociswap_pools_raw.json", "w"))
    print(f"ociswap total pools: {len(pools)}")

    live = []
    for p in pools:
        try:
            usd = float(p.get("tvl_usd") or (p.get("total_value_locked") or {}).get("usd", {}).get("now") or 0)
        except Exception:  # noqa: BLE001
            usd = 0.0
        p["_tvl_usd_now"] = usd
        if usd > 0.01:
            live.append(p)
    print(f"ociswap pools with TVL>0.01 USD: {len(live)}")
    json.dump(live, open("ociswap_pools_live.json", "w"), indent=1)
    tot = sum(p["_tvl_usd_now"] for p in live)
    print(f"ociswap total TVL USD (sum of pools): {tot:.2f}")
    live.sort(key=lambda x: -x["_tvl_usd_now"])
    for p in live[:40]:
        print(f"  {p['address']} {p.get('blueprint_name'):14s} {p.get('name'):22s} "
              f"${p['_tvl_usd_now']:.2f} fee={p.get('fee_rate')} lp={p.get('lp_token_address')}")

    # ---- DefiPlaza ----
    pairs = []
    cursor = 0
    seen = set()
    while True:
        d = get(f"https://radix.defiplaza.net/api/pairs?cursor={cursor}&limit=100")
        data = d.get("data", [])
        if not data:
            break
        new = [x for x in data if x.get("address") not in seen]
        for x in new:
            seen.add(x.get("address"))
        pairs.extend(new)
        print(f"defiplaza cursor {cursor}: got {len(data)} new {len(new)}", file=sys.stderr)
        if len(data) < 100:
            break
        cursor = d.get("cursor", cursor + len(data))
        time.sleep(0.2)
    json.dump(pairs, open("defiplaza_pairs_raw.json", "w"))
    print(f"defiplaza total pairs: {len(pairs)}")
    pairs.sort(key=lambda x: -(x.get("tvlUSD") or 0))
    livep = [p for p in pairs if (p.get("tvlUSD") or 0) > 0.01]
    json.dump(livep, open("defiplaza_pairs_live.json", "w"), indent=1)
    print(f"defiplaza pairs TVL>0.01: {len(livep)}  total TVL USD: {sum(p['tvlUSD'] for p in livep):.2f}")
    for p in livep[:40]:
        print(f"  {p['address']} {p.get('baseToken','')[:26]}.. / {p.get('quoteToken','')[:26]}.. "
              f"${p.get('tvlUSD'):.2f} baseTVL={p.get('baseTVL')} quoteTVL={p.get('quoteTVL')}")

    # ---- ledger state ----
    from rdx import ledger_state
    ls = ledger_state()
    json.dump(ls, open("ledger_state.json", "w"), indent=1)
    print("ledger:", ls)

    # ---- prices ----
    ids = ["coingecko:radix"]
    tokens = set()
    for p in live:
        tokens.add(p.get("base_token"))
        tokens.add(p.get("quote_token"))
    # price keyed by resource address
    addrs = sorted(t for t in tokens if t)
    chunks = [addrs[i:i + 30] for i in range(0, len(addrs), 30)]
    prices = {}
    for c in chunks:
        q = ",".join(f"radix:{a}" for a in c)
        try:
            d = get(f"https://coins.llama.fi/prices/current/{q}")
            prices.update(d.get("coins", {}))
        except SystemExit:
            print("price chunk failed", c)
        q2 = ",".join(f"coingecko:radix")
        time.sleep(0.2)
    d = get("https://coins.llama.fi/prices/current/coingecko:radix")
    prices.update(d.get("coins", {}))
    json.dump(prices, open("prices_llama.json", "w"), indent=1)
    for k, v in list(prices.items())[:60]:
        print(f"  {k}: ${v.get('price')}")


if __name__ == "__main__":
    main()
