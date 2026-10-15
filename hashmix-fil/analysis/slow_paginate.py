#!/usr/bin/env python3
"""Slow pagination of Blockscout v2 endpoints (rate-limit friendly). Read-only."""
import json, time, urllib.request, sys

HDRS = {"User-Agent": "Mozilla/5.0"}
BASE = "https://filecoin.blockscout.com/api/v2"

def get(url, tries=5):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=HDRS)
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            sys.stderr.write(f"retry {i} {url} {e}\n"); sys.stderr.flush()
            time.sleep(10 + 10 * i)
    return None

def paginate(path, outfile, max_pages=10):
    items, url = [], BASE + path
    for p in range(max_pages):
        d = get(url)
        if d is None: break
        items.extend(d.get("items", []))
        npp = d.get("next_page_params")
        if not npp: break
        qs = "&".join(f"{k}={v}" for k, v in npp.items())
        url = BASE + path + ("&" if "?" in path else "?") + qs
        time.sleep(8)
    json.dump(items, open(outfile, "w"), indent=1)
    print(outfile, len(items))
    return items

if __name__ == "__main__":
    POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
    paginate(f"/tokens/{POOL}/transfers", "raw_cwfil_transfers_paged.json", 10)
    time.sleep(10)
    paginate(f"/addresses/{POOL}/logs", "raw_pool_logs_paged.json", 6)
