#!/usr/bin/env python3
"""childA: fetch full token balances for every gauge feeDistributor via scrollscan public API."""
import json, urllib.request, time, sys

OUT = "/home/heisenberg/CA/nuri-cl/analysis/childA-tokenlists.json"
raw = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childA-raw.json"))
fds = sorted(raw["fds"].keys())
out = {}
for i, fd in enumerate(fds):
    url = f"https://scrollscan.com/api/v2/addresses/{fd}/token-balances"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                data = json.loads(r.read().decode())
            break
        except Exception as e:
            if a == 3:
                data = {"error": str(e)}
            time.sleep(2 * (a + 1))
    out[fd] = data
    if (i + 1) % 10 == 0:
        print(f"{i+1}/{len(fds)}", file=sys.stderr)
    time.sleep(0.4)
json.dump({"block": raw["block"], "tokenlists": out}, open(OUT, "w"), indent=1)
print("saved", OUT, file=sys.stderr)
# summary
from collections import defaultdict
tot = defaultdict(int)
meta = {}
for fd, arr in out.items():
    if not isinstance(arr, list):
        print("ERR", fd, str(arr)[:100]); continue
    for x in arr:
        t = x["token"]
        addr = t["address_hash"].lower()
        val = int(x["value"])
        dec = int(t["decimals"] or 18)
        meta[addr] = {"symbol": t.get("symbol"), "decimals": dec, "name": t.get("name")}
        if val:
            tot[addr] += val
for a, v in sorted(tot.items(), key=lambda kv: -kv[1]):
    m = meta[a]
    print(f"{m['symbol']:>10} {a} {v / 10**m['decimals']:.6f}")
