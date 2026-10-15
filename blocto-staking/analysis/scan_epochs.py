#!/usr/bin/env python3
"""Dense scan of a block range for NewEpoch events (250-block windows)."""
import json, urllib.request, sys, time, os

BASE = "https://rest-mainnet.onflow.org/v1"
UA = {"User-Agent": "Mozilla/5.0"}
T = "A.0f9df91c9121c460.BloctoTokenStaking.NewEpoch"

def get_events(start, end):
    url = f"{BASE}/events?type={T}&start_height={start}&end_height={end}"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.loads(r.read())
    out = []
    for be in data:
        for e in (be.get("events") or []):
            out.append(e)
    return out

def main():
    head = int(sys.argv[1]); n = int(sys.argv[2])
    start_all = head - n
    hits = []
    cur = start_all
    i = 0
    while cur < head:
        end = min(cur + 249, head)
        try:
            ev = get_events(cur, end)
            if ev:
                hits.extend(ev)
                print(f"HIT [{cur},{end}]: {json.dumps(ev)[:400]}", flush=True)
        except Exception as ex:
            print(f"ERR [{cur},{end}]: {ex}", flush=True)
        cur = end + 1
        i += 1
        if i % 250 == 0:
            print(f"...scanned {i} windows, at block {cur}", flush=True)
        time.sleep(0.05)
    print(f"DONE. windows={i} hits={len(hits)}")
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "epoch_scan_result.json"), "w") as f:
        json.dump({"head": head, "scanned": n, "hits": hits}, f, indent=1)

if __name__ == "__main__":
    main()
