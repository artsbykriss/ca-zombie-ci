#!/usr/bin/env python3
"""Parallel scan of a block range for one event type (250-block windows).
Usage: scan_events_parallel.py <eventType> <head> <nBlocks> <outfile>
"""
import json, urllib.request, sys
from concurrent.futures import ThreadPoolExecutor

BASE = "https://rest-mainnet.onflow.org/v1"
UA = {"User-Agent": "Mozilla/5.0"}

def get_events(t, start, end):
    url = f"{BASE}/events?type={t}&start_height={start}&end_height={end}"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.loads(r.read())
    out = []
    for be in data:
        for e in (be.get("events") or []):
            out.append(e)
    return out

def main():
    t = sys.argv[1]; head = int(sys.argv[2]); n = int(sys.argv[3]); outfile = sys.argv[4]
    windows = []
    cur = head - n
    while cur < head:
        end = min(cur + 249, head)
        windows.append((cur, end)); cur = end + 1
    hits = []
    def work(w):
        s, e = w
        try:
            return (w, get_events(t, s, e))
        except Exception as ex:
            return (w, f"ERR {ex}")
    with ThreadPoolExecutor(max_workers=8) as ex:
        for i, (w, ev) in enumerate(ex.map(work, windows)):
            if isinstance(ev, list) and ev:
                hits.extend(ev)
                print(f"HIT [{w[0]},{w[1]}]: {json.dumps(ev)[:500]}", flush=True)
            if (i + 1) % 500 == 0:
                print(f"...{i+1}/{len(windows)}", flush=True)
    print(f"DONE type={t} windows={len(windows)} hits={len(hits)}")
    json.dump({"type": t, "head": head, "scanned": n, "hits": hits}, open(outfile, "w"), indent=1)

if __name__ == "__main__":
    main()
