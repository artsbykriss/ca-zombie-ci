#!/usr/bin/env python3
"""Paginated Etherscan V2 getLogs for Approval(owner=settlement), recursive bisection on the 1000 cap.
Read-only. No secrets printed."""
import json, os, urllib.request, time

KEY = os.environ["ETHERSCANV2_API_KEY"]
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T1 = "0x0000000000000000000000009008d19f58aabd9ed0d60971565aa8510560ab41"
HEAD = 26253553
CAP = 1000

def get(frm, to):
    url = ("https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
           f"&fromBlock={frm}&toBlock={to}&topic0={APPROVAL}&topic1={T1}&topic0_1_opr=and&apikey={KEY}")
    for a in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"research/1.0"}), timeout=90) as r:
                j = json.load(r)
            if j.get("status") == "0" and "No" in str(j.get("message","")):
                return []
            if not isinstance(j.get("result"), list):
                raise RuntimeError(j)
            return j["result"]
        except Exception as e:
            if a == 5: raise
            time.sleep(2*(a+1))

rows = []
def scan(frm, to, depth=0):
    res = get(frm, to)
    if len(res) < CAP:
        rows.extend(res); return
    if frm >= to:
        rows.extend(res); return
    mid = (frm+to)//2
    scan(frm, mid, depth+1); scan(mid+1, to, depth+1)

# coarse sweep in 1M chunks
b = 0
while b <= HEAD:
    to = min(b+1_000_000-1, HEAD)
    scan(b, to)
    b = to+1

seen = {}
for x in rows:
    seen[(x["transactionHash"], x["logIndex"])] = x
rows = list(seen.values())
spenders = {}
for x in rows:
    spenders.setdefault("0x"+x["topics"][2][-40:], []).append(x)
blocks = sorted(int(x["blockNumber"],16) for x in rows)
print("total approval logs (owner=settlement):", len(rows))
print("distinct spenders:", len(spenders))
if blocks: print("block range:", blocks[0], "->", blocks[-1])
for sp, xs in sorted(spenders.items(), key=lambda kv: -len(kv[1])):
    bs = [int(x["blockNumber"],16) for x in xs]
    print(f"  {sp}  n={len(xs)}  blk {min(bs)}..{max(bs)}")
json.dump({"total":len(rows),"spenders":{k:len(v) for k,v in spenders.items()},
           "rows":[{"b":int(x["blockNumber"],16),"tx":x["transactionHash"],"token":x["address"],
                    "spender":"0x"+x["topics"][2][-40:],"value":x["data"]} for x in rows]},
          open("/home/heisenberg/CA/cow-gpv2/analysis/settlement_approvals.json","w"), indent=1)
print("wrote analysis/settlement_approvals.json")
