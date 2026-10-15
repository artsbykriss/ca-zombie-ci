#!/usr/bin/env python3
"""Find the last block range containing an event of a given type, via public Flow Access API.
Read-only, public endpoint. Binary/exponential search. Usage:
  find_last_event.py A.0f9df91c9121c460.BloctoTokenStaking.NewEpoch
"""
import json, urllib.request, sys, time

BASE = "https://rest-mainnet.onflow.org/v1"
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def head_height():
    req = urllib.request.Request(f"{BASE}/blocks?height=sealed", headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return int(json.loads(r.read())[0]["header"]["height"])

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
    t = sys.argv[1]
    head = head_height()
    print(f"head={head} type={t}", flush=True)
    # exponential backward scan to find a window with events
    w = 250
    lo = head
    found = None
    while lo > 0:
        start = max(0, lo - w + 1)
        ev = get_events(t, start, lo)
        print(f"  scan [{start},{lo}] -> {len(ev)} events", flush=True)
        if ev:
            found = (start, lo, ev)
            break
        lo = start - 1
        w = min(w * 2, 250000)
        time.sleep(0.2)
    if not found:
        print("NO EVENTS FOUND (to genesis)")
        return
    start, end, ev = found
    # binary search for the last 250-block chunk containing events within [start, end]
    lo_b, hi_b = start, end
    last = None
    while lo_b <= hi_b:
        mid = (lo_b + hi_b) // 2
        c_start = max(start, mid - 249)
        c = get_events(t, c_start, mid)
        print(f"  bisect [{c_start},{mid}] -> {len(c)}", flush=True)
        if c:
            last = c
            lo_b = mid + 1
        else:
            hi_b = mid - 1
        time.sleep(0.2)
    if last:
        print(f"LAST EVENT BLOCK(S): {[e['block_height'] for e in last]}")
        print(json.dumps(last[-1], indent=1)[:1500])

if __name__ == "__main__":
    main()
