#!/usr/bin/env python3
"""Fetch all transactions (paginated) for an address from Filecoin Blockscout.
Usage: fetch_txs.py <address> <outfile> [max_pages]
"""
import json, sys, time, urllib.request, urllib.parse

BASE = "https://filecoin.blockscout.com/api/v2"

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def main():
    addr = sys.argv[1]
    out = sys.argv[2]
    max_pages = int(sys.argv[3]) if len(sys.argv) > 3 else 20
    items = []
    params = {}
    page = 0
    while page < max_pages:
        url = f"{BASE}/addresses/{addr}/transactions"
        if params:
            url += '?' + urllib.parse.urlencode(params)
        try:
            d = get(url)
        except Exception as e:
            print('page fetch error:', e); break
        batch = d.get('items', [])
        items.extend(batch)
        page += 1
        nxt = d.get('next_page_params')
        if not nxt or not batch:
            break
        params = nxt
        time.sleep(0.5)
    json.dump(items, open(out, 'w'), indent=1)
    from collections import Counter
    c = Counter((it.get('method') or '?') for it in items)
    print(f"{addr}: {len(items)} txs, {page} pages")
    for m, n in c.most_common(30):
        print(f"  {m:30s} {n}")

if __name__ == '__main__':
    main()
