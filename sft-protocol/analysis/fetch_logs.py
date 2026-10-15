#!/usr/bin/env python3
"""Fetch paginated logs for an address from Blockscout; summarize by topic0."""
import json, sys, time, urllib.request, urllib.parse

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
    params = {}
    page = 0
    while page < max_pages:
        url = f"{BASE}/addresses/{addr}/logs"
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
        time.sleep(0.5)
    from collections import Counter
    c = Counter()
    for it in items:
        topics = it.get('topics') or []
        t0 = topics[0] if topics else None
        c[t0] += 1
    print(f"DONE {addr}: {len(items)} logs", flush=True)
    for t0, n in c.most_common(20):
        print(f"  {t0} {n}", flush=True)

if __name__ == '__main__':
    main()
