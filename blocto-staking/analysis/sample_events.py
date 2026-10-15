#!/usr/bin/env python3
"""Sample 250-block windows at exponentially increasing lookbacks for staking events.
Read-only, public endpoint."""
import json, urllib.request, sys

BASE = "https://rest-mainnet.onflow.org/v1"
UA = {"User-Agent": "Mozilla/5.0"}
CONTRACT = "A.0f9df91c9121c460.BloctoTokenStaking"
TYPES = ["MoveToken", "RewardsPaid", "NewEpoch", "TokensStaked", "TokensUnstaked",
         "TokensCommitted", "NewStakerCreated", "UnstakedTokensWithdrawn", "RewardTokensWithdrawn"]

def head():
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
    h = head()
    offsets = [250, 1000, 5000, 25000, 100000, 500000, 2000000, 10000000, 50000000, 100000000, 150000000]
    print(f"head={h}")
    for off in offsets:
        end = h - off
        if end < 1:
            continue
        start = end - 249
        counts = {}
        for t in TYPES:
            try:
                ev = get_events(f"{CONTRACT}.{t}", start, end)
                if ev:
                    counts[t] = len(ev)
            except Exception as ex:
                counts[t] = f"ERR {ex}"
        print(f"offset {off:>10} blocks  window [{start},{end}]  {counts}", flush=True)

if __name__ == "__main__":
    main()
