#!/usr/bin/env python3
"""Scan Approval(owner=settlement) over the post-2021 gap in 1M chunks (no full bisection).
Read-only."""
import json, os, sys, urllib.request, time

KEY = os.environ["ETHERSCANV2_API_KEY"]
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T1 = "0x0000000000000000000000009008d19f58aabd9ed0d60971565aa8510560ab41"

def get(frm, to):
    url = ("https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
           f"&fromBlock={frm}&toBlock={to}&topic0={APPROVAL}&topic1={T1}&topic0_1_opr=and&apikey={KEY}")
    for a in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"research/1.0"}), timeout=60) as r:
                j = json.load(r)
            if j.get("status") == "0" and "No" in str(j.get("message","")):
                return []
            if not isinstance(j.get("result"), list): raise RuntimeError(j)
            return j["result"]
        except Exception:
            if a == 5: raise
            time.sleep(2*(a+1))

frm = int(sys.argv[1]); to = int(sys.argv[2])
b = frm
hits = 0
while b <= to:
    e = min(b+1_000_000-1, to)
    res = get(b, e)
    n = len(res)
    hits += n
    print(f"{b}..{e}: {n}", flush=True)
    if n:
        for x in res[:5]:
            print("   ", x["address"], "->", "0x"+x["topics"][2][-40:], "blk", int(x["blockNumber"],16), x["transactionHash"])
    b = e+1
print("TOTAL HITS:", hits)
