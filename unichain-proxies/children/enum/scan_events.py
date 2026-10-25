#!/usr/bin/env python3
"""Fetch IntentFunded / IntentWithdrawn / IntentRefunded logs from both Portals. READ-ONLY."""
import json, time, os
import requests

H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
BASE = "https://unichain.blockscout.com/api/v2"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ci-out")
os.makedirs(OUT, exist_ok=True)
PORTALS = ["0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97",
           "0xEC000064576f9C95a8623Bc0eff3db6d296ea6df"]
TOPICS = {
    "IntentFunded": "0xc1ed05721d27ad6b2555d61388ac393b120f5cc0e6009e53230e02c68e60064a",
    "IntentWithdrawn": "0xbb062c23e818de8ea9c157514eb098052cf36904bbe431cd50d4ec92264ca3ac",
    "IntentRefunded": "0x8d53c2b04800cf061b987a07179bb6c9730c05536b2f6a3a091fe62303682eb6",
}

def get(url, params=None, tries=6):
    for i in range(tries):
        try:
            r = requests.get(url, headers=H, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            time.sleep(1.2 * (i + 1))
        except Exception:
            time.sleep(1.2 * (i + 1))
    raise RuntimeError(f"GET failed {url}")

def fetch(portal, topic, name):
    items = []
    params = {"topic": topic}
    while True:
        d = get(f"{BASE}/addresses/{portal}/logs", params)
        items.extend(d["items"])
        nxt = d.get("next_page_params")
        if not nxt:
            break
        params = dict(nxt)
        time.sleep(0.2)
    fn = os.path.join(OUT, f"ev_{name}_{portal}.json")
    json.dump(items, open(fn, "w"))
    print(name, portal, len(items))
    return items

if __name__ == "__main__":
    summary = {}
    for name, topic in TOPICS.items():
        for p in PORTALS:
            try:
                items = fetch(p, topic, name)
                summary[f"{name}|{p}"] = len(items)
            except Exception as e:
                print("ERR", name, p, e)
    print(json.dumps(summary, indent=1))
