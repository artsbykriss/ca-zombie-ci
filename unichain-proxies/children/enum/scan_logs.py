#!/usr/bin/env python3
"""Fetch IntentPublished logs from the two Eco Portals on Unichain. READ-ONLY.
topic0 = 0x43974895be1bcec7344337863fa7de24a0d1c315c0a994f663fe0ee220ddc8e4
"""
import json, time, os
import requests

H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
BASE = "https://unichain.blockscout.com/api/v2"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ci-out")
os.makedirs(OUT, exist_ok=True)
TOPIC = "0x43974895be1bcec7344337863fa7de24a0d1c315c0a994f663fe0ee220ddc8e4"
PORTALS = [
    "0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97",
    "0xEC000064576f9C95a8623Bc0eff3db6d296ea6df",
]

def get(url, params=None, tries=6):
    for i in range(tries):
        try:
            r = requests.get(url, headers=H, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            time.sleep(1.5 * (i + 1))
        except Exception:
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"GET failed {url} {params}")

def fetch_logs(portal):
    items = []
    params = {"topic": TOPIC}
    page = 0
    while True:
        d = get(f"{BASE}/addresses/{portal}/logs", params)
        items.extend(d["items"])
        page += 1
        nxt = d.get("next_page_params")
        print(f"[logs {portal[:10]}] page {page}: +{len(d['items'])} total {len(items)} next={bool(nxt)}")
        if not nxt:
            break
        params = dict(nxt)
        time.sleep(0.25)
    with open(os.path.join(OUT, f"logs_{portal}.json"), "w") as f:
        json.dump(items, f, indent=1)
    return items

if __name__ == "__main__":
    all_logs = {}
    for p in PORTALS:
        all_logs[p] = fetch_logs(p)
    for p, items in all_logs.items():
        print(p, "IntentPublished count", len(items))
        # sanity: show decoded params of first
        it = items[0]
        print(json.dumps(it.get("decoded"), indent=1)[:800])
