#!/usr/bin/env python3
"""Enumerate Blockscout-verified contracts named ImmutableProxy on Unichain (chain 130).
READ-ONLY. Public endpoints only. Writes raw pages to ci-out/.
"""
import json, time, os, sys
import requests

H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
BASE = "https://unichain.blockscout.com/api/v2"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ci-out")
os.makedirs(OUT, exist_ok=True)

def get(url, params=None, tries=5):
    for i in range(tries):
        try:
            r = requests.get(url, headers=H, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            time.sleep(1.5 * (i + 1))
        except Exception as e:
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"GET failed {url} {params}")

def page_search(q, name):
    items = []
    params = {"q": q}
    page = 0
    while True:
        d = get(f"{BASE}/smart-contracts", params)
        items.extend(d["items"])
        page += 1
        nxt = d.get("next_page_params")
        print(f"[{name}] page {page}: +{len(d['items'])} total {len(items)} next={bool(nxt)}")
        if not nxt:
            break
        params = dict(nxt)
        time.sleep(0.3)
    with open(os.path.join(OUT, f"search_{name}.json"), "w") as f:
        json.dump(items, f, indent=1)
    return items

if __name__ == "__main__":
    res = {}
    for q, name in [("ImmutableProxy", "ImmutableProxy"), ("Proxy", "Proxy")]:
        try:
            res[name] = page_search(q, name)
        except Exception as e:
            print("ERR", name, e)
    for name, items in res.items():
        addrs = [it["address"]["hash"] for it in items]
        print(name, "count", len(addrs))
