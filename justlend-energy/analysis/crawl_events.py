#!/usr/bin/env python3
"""Crawl RentResource / ReturnResource / Liquidate events for MarketG1 (read-only)."""
import json, time, urllib.parse, urllib.request, sys, os

BASE = "https://api.trongrid.io/v1/contracts/TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd/events"
OUT = "events"
os.makedirs(OUT, exist_ok=True)

def get(url, tries=6):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=50) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            print("retry", i, e, file=sys.stderr)
            time.sleep(2 * (i + 1))
    raise RuntimeError("failed " + url)

def crawl(name, max_pages=200):
    url = f"{BASE}?event_name={name}&limit=200&only_confirmed=true"
    rows = []
    seen = set()
    for page in range(max_pages):
        j = get(url)
        data = j.get("data", [])
        for e in data:
            tid = (e.get("transaction_id"), e.get("event_index"))
            if tid in seen:
                continue
            seen.add(tid)
            rows.append(e)
        meta = j.get("meta") or {}
        nxt = (meta.get("links") or {}).get("next")
        print(f"{name} page {page} got {len(data)} total {len(rows)}", file=sys.stderr)
        if not nxt or not data:
            break
        url = nxt
        time.sleep(0.35)
    json.dump(rows, open(f"{OUT}/{name}.json", "w"))
    print(name, len(rows))

if __name__ == "__main__":
    for n in sys.argv[1:] or ["RentResource", "ReturnResource", "Liquidate"]:
        crawl(n)
