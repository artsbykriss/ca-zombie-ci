#!/usr/bin/env python3
"""Robust paginated tx fetcher with retries, saves incrementally.
Usage: fetch_all_txs.py <address> <outfile> [max_pages]
"""
import json, sys, time, urllib.request, urllib.parse, os

BASE = "https://filecoin.blockscout.com/api/v2"

def get(url, tries=5):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=50) as r:
                return json.load(r)
        except Exception as e:
            time.sleep(2 + i * 2)
    raise RuntimeError(f'failed: {url}')

def main():
    addr = sys.argv[1]
    out = sys.argv[2]
    max_pages = int(sys.argv[3]) if len(sys.argv) > 3 else 20
    items = []
    if os.path.exists(out):
        items = json.load(open(out))
    params = {}
    page = 0
    while page < max_pages:
        url = f"{BASE}/addresses/{addr}/transactions"
        if params:
            url += '?' + urllib.parse.urlencode(params)
        d = get(url)
        batch = d.get('items', [])
        items.extend(batch)
        page += 1
        nxt = d.get('next_page_params')
        json.dump(items, open(out, 'w'), indent=1)
        print(f'page {page}: +{len(batch)} total {len(items)}', flush=True)
        if not nxt or not batch:
            break
        params = nxt
        time.sleep(0.6)
    from collections import Counter
    c = Counter((it.get('method') or '?') for it in items)
    print(f"DONE {addr}: {len(items)} txs, {page} pages", flush=True)
    for m, n in c.most_common(40):
        print(f"  {m:32s} {n}", flush=True)

if __name__ == '__main__':
    main()
