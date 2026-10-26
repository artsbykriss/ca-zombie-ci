#!/usr/bin/env python3
"""Diff-based struct layout inference from many same-type accounts (offline, fast)."""
import sys, json, base64
from collections import Counter

def main():
    st = json.load(open(sys.argv[1]))
    name = sys.argv[2]
    accts = st[name]["accounts"]
    raws = [base64.b64decode(a["data_b64"]) for a in accts]
    n = len(raws[0])
    print(f"{name}: {len(raws)} accounts, len={n}")
    cols = list(zip(*raws))
    dist = []
    for off, col in enumerate(cols):
        c = Counter(col)
        dist.append((len(c), c))
    print("off  distinct  top_values")
    for off, (d, c) in enumerate(dist):
        if d == 1:
            continue
        if d <= 10:
            print(f"{off:04x}  d={d:4d}  {c.most_common(10)}")
    print("constant runs (off,len,val):")
    i = 0
    while i < n:
        if dist[i][0] == 1:
            j = i
            while j < n and dist[j][0] == 1:
                j += 1
            if j - i >= 3:
                print(f"   0x{i:04x} len={j-i:4d} val={cols[i][0]:02x}")
            i = j
        else:
            i += 1

if __name__ == "__main__":
    main()
