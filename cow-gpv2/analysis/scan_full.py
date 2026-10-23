#!/usr/bin/env python3
"""Incremental, resumable full enumeration of Approval(owner=GPv2Settlement) via Etherscan V2.
Bisects on the 1000-result cap. Appends rows to analysis/approvals_raw.jsonl. Read-only."""
import json, os, sys, urllib.request, time

KEY = os.environ["ETHERSCANV2_API_KEY"]
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T1 = "0x0000000000000000000000009008d19f58aabd9ed0d60971565aa8510560ab41"
HEAD = int(os.environ.get("HEAD_BLOCK", "26253553"))
CAP = 1000
OUT = "/home/heisenberg/CA/cow-gpv2/analysis/approvals_raw.jsonl"
DONE = "/home/heisenberg/CA/cow-gpv2/analysis/approvals_done.json"

def get(frm, to):
    url = ("https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
           f"&fromBlock={frm}&toBlock={to}&topic0={APPROVAL}&topic1={T1}&topic0_1_opr=and&apikey={KEY}")
    for a in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"research/1.0"}), timeout=60) as r:
                j = json.load(r)
            if j.get("status") == "0" and "No" in str(j.get("message","")):
                return []
            if not isinstance(j.get("result"), list):
                raise RuntimeError(j)
            return j["result"]
        except Exception:
            if a == 5: raise
            time.sleep(1.5*(a+1))

fh = open(OUT, "a")
n_new = 0
def emit(rows):
    global n_new
    for x in rows:
        fh.write(json.dumps({"b":int(x["blockNumber"],16),"tx":x["transactionHash"],
                             "li":x["logIndex"],"token":x["address"],
                             "spender":"0x"+x["topics"][2][-40:],"value":x["data"]})+"\n")
    n_new += len(rows)
    fh.flush()

def scan(frm, to, depth=0):
    res = get(frm, to)
    if len(res) < CAP or frm >= to:
        emit(res); return
    mid = (frm+to)//2
    scan(frm, mid, depth+1); scan(mid+1, to, depth+1)

CH = 500_000
b = 0
while b <= HEAD:
    e = min(b+CH-1, HEAD)
    scan(b, e)
    print(f"{b}..{e} done cumulative={n_new}", flush=True)
    b = e+1
fh.close()
print("WROTE", n_new)
