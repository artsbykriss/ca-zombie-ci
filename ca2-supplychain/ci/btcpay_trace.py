#!/usr/bin/env python3
"""BTCPay incident: read-only trace of the two vendor-named addresses.

Runs in CI. No keys, no transactions. Writes JSON to stdout.
"""
import json, time
import requests

S = requests.Session()
S.headers.update({"User-Agent": "ca2-supplychain-research/1.0"})

ADDRS = {
    "btc": {
        "address": "bc1p0f7wmcnesrapznymf9ljdn04pudgmh96sqtrm9vmgqxdh666fh8qvn63r7",
        "base": "https://blockstream.info/api",
        "price_id": "bitcoin",
        "decimals": 8,
    },
    "ltc": {
        "address": "ltc1qp49tmfdueyaqrmgrx0uyx4uegyygt8yt02whee",
        "base": "https://litecoinspace.org/api",
        "price_id": "litecoin",
        "decimals": 8,
    },
}

def get(url, tries=5):
    last = None
    for i in range(tries):
        try:
            r = S.get(url, timeout=45)
            r.raise_for_status()
            return r
        except Exception as e:
            last = e
            time.sleep(2 + i * 2)
    raise last

def get_json(url):
    return get(url).json()

def tip(base):
    return int(get(f"{base}/blocks/tip/height").text.strip())

def all_txs(base, addr):
    txs, cursor, pages = [], None, 0
    while True:
        url = f"{base}/address/{addr}/txs" + (f"/chain/{cursor}" if cursor else "")
        batch = get_json(url)
        pages += 1
        if not batch:
            break
        txs.extend(batch)
        cursor = batch[-1]["txid"]
        if len(batch) < 25 or pages > 80:
            break
        time.sleep(0.15)
    return txs, pages

def main():
    prices = get_json("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,litecoin&vs_currencies=usd")
    out = {"prices_usd": prices, "addresses": {}, "tips": {}}
    for sym, cfg in ADDRS.items():
        out["tips"][sym] = tip(cfg["base"])
        stats = get_json(f"{cfg['base']}/address/{cfg['address']}")
        txs, pages = all_txs(cfg["base"], cfg["address"])
        times = [t["status"]["block_time"] for t in txs if t.get("status", {}).get("confirmed")]
        funded = stats["chain_stats"]["funded_txo_sum"]
        spent = stats["chain_stats"]["spent_txo_sum"]
        bal = funded - spent
        price = prices[cfg["price_id"]]["usd"]
        out["addresses"][sym] = {
            "address": cfg["address"],
            "chain_stats": stats["chain_stats"],
            "mempool_stats": stats.get("mempool_stats"),
            "first_seen_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(min(times))) if times else None,
            "last_seen_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(max(times))) if times else None,
            "txs_paginated": len(txs),
            "pages_fetched": pages,
            "funded_native": funded / 10**cfg["decimals"],
            "spent_native": spent / 10**cfg["decimals"],
            "balance_native": bal / 10**cfg["decimals"],
            "price_usd": price,
            "funded_usd": (funded / 10**cfg["decimals"]) * price,
            "balance_usd": (bal / 10**cfg["decimals"]) * price,
            "first_txid": txs[-1]["txid"] if txs else None,
            "last_txid": txs[0]["txid"] if txs else None,
        }
    print(json.dumps(out, indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
