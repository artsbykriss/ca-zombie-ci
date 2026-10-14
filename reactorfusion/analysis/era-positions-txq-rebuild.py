#!/usr/bin/env python3
"""Rebuild tx-crawler queues as coarse 500k-block windows over uncovered ranges."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LATEST = int(sys.argv[1]) if len(sys.argv) > 1 else 72476800
WIN = 500_000
for label in ["rfUSDCe", "rfWBTC"]:
    p = os.path.join(HERE, f"era-positions-txstate-{label}.json")
    if not os.path.exists(p):
        print(label, "no state"); continue
    st = json.load(open(p))
    covered = []
    for lo, hi, n in st["done"]:
        covered.append((lo, hi))
    covered.sort()
    merged = []
    for lo, hi in covered:
        if merged and lo <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], hi)
        else:
            merged.append([lo, hi])
    # uncovered over [1900000, LATEST]
    queue = []
    cur = 1_900_000
    for lo, hi in merged:
        if lo > cur:
            for x in range(cur, lo, WIN):
                queue.append([x, min(x + WIN - 1, lo - 1)])
        cur = max(cur, hi + 1)
    if cur <= LATEST:
        for x in range(cur, LATEST + 1, WIN):
            queue.append([x, min(x + WIN - 1, LATEST)])
    st["queue"] = queue
    st["failed"] = []
    st.pop("finished", None)
    json.dump(st, open(p, "w"), indent=1)
    print(f"{label}: done_windows={len(st['done'])} covered={sum(h-l+1 for l,h in merged)} blocks, new queue={len(queue)} windows")
