#!/usr/bin/env python3
"""Paginate Blockscout v2 endpoints, save raw pages. Read-only."""
import json, time, urllib.request, sys

HDRS = {"User-Agent": "Mozilla/5.0"}
BASE = "https://filecoin.blockscout.com/api/v2"

def get(url, tries=3):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=HDRS)
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            print("retry", url, e, file=sys.stderr)
            time.sleep(3)
    return None

def paginate(path, outfile, max_pages=6):
    items = []
    url = BASE + path
    pages = []
    for p in range(max_pages):
        d = get(url)
        if d is None:
            print("FAILED", url, file=sys.stderr)
            break
        pages.append(d)
        items.extend(d.get("items", []))
        npp = d.get("next_page_params")
        if not npp:
            break
        qs = "&".join(f"{k}={v}" for k, v in npp.items())
        url = BASE + path + ("&" if "?" in path else "?") + qs
        time.sleep(1)
    json.dump({"items": items, "pages": pages}, open(outfile, "w"), indent=1)
    print(outfile, "items:", len(items))
    return items

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
    if which in ("all", "txs"):
        paginate(f"/addresses/{POOL}/transactions", "raw_pool_txs_paged.json", 6)
    if which in ("all", "tokentx"):
        paginate(f"/tokens/{POOL}/transfers", "raw_cwfil_transfers_paged.json", 8)
    if which in ("all", "stfil"):
        paginate("/tokens/0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8/transfers", "raw_stfil_transfers_paged.json", 3)
