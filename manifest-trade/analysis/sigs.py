#!/usr/bin/env python3
"""List signatures touching a Solana account (upgrade history), keyless RPC."""
import json, sys, urllib.request, time

RPC = "https://api.mainnet-beta.solana.com"
addr = sys.argv[1]
before = None
seen = []
for page in range(4):
    params = [addr, {"limit": 200}]
    if before:
        params[1]["before"] = before
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "getSignaturesForAddress", "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
    try:
        r = json.load(urllib.request.urlopen(req, timeout=60))
    except Exception as e:
        print("err", e); break
    res = r.get("result") or []
    if not res:
        break
    seen.extend(res)
    before = res[-1]["signature"]
    if len(res) < 200:
        break
    time.sleep(0.5)
print(json.dumps(seen, indent=1))
