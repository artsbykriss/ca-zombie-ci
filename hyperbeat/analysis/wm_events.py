#!/usr/bin/env python3
"""Fetch WithdrawManager queue/claim events via Etherscan V2 (chain 999) and
reconcile the manager's HYPE liability. Read-only. Key from env; never written.
"""
import json, os, urllib.request, time, sys

KEY = os.environ["ETHERSCANV2_API_KEY"]
WM = "0x9d0B0877b9f2204CF414Ca7862E4f03506822538"
QUEUED = "0xa2bc034e3400735d5038171f4a52ede4ca8a21acc010aab81996a18301cdf0a3"
CLAIMED = "0x2d43eb174787155132b52ddb6b346e2dca99302eac3df4466dbeff953d3c84d1"
FINAL = "0x" + "x"

def logs(topic0, start=0, end=99_999_999):
    out = []
    cur = start
    while cur <= end:
        url = (f"https://api.etherscan.io/v2/api?chainid=999&module=logs&action=getLogs"
               f"&address={WM}&fromBlock={cur}&toBlock={end}&topic0={topic0}&apikey={KEY}")
        for att in range(4):
            try:
                r = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "zh4"}), timeout=90))
                break
            except Exception as e:
                print("retry", e, file=sys.stderr); time.sleep(3); r = {}
        res = r.get("result") or []
        if not isinstance(res, list):
            print("ERR", res, file=sys.stderr); break
        out.extend(res)
        if len(res) < 1000:
            break
        cur = int(res[-1]["blockNumber"], 16) + 1
        time.sleep(0.3)
    return out

q = logs(QUEUED)
c = logs(CLAIMED)
print("queued events", len(q), "claimed events", len(c))
qi = []
for e in q:
    t = e["topics"]
    d = e["data"][2:]
    be = int(d[0:64], 16); hy = int(d[64:128], 16)
    qi.append({"id": int(t[2], 16), "user": "0x" + t[1][26:], "be": be, "hype": hy})
ci = []
for e in c:
    t = e["topics"]
    d = e["data"][2:]
    ci.append({"id": int(t[2], 16), "hype": int(d[0:64], 16)})
json.dump({"queued": qi, "claimed": ci}, open("wm_events.json", "w"))
print("max id", max(x["id"] for x in qi) if qi else None, "claims max id", max((x['id'] for x in ci), default=None))
print("sum queued hype", sum(x["hype"] for x in qi) / 1e18)
print("sum claimed hype", sum(x["hype"] for x in ci) / 1e18)
