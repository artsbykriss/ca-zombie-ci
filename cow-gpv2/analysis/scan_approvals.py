#!/usr/bin/env python3
"""Scan Approval(owner=settlement, spender, value) events in chunks. Read-only."""
import json, os, sys, urllib.request, time

RPC = os.environ.get("NODEREAL_ETH_RPC_URL") or os.environ.get("RPC_URL")
SETTLEMENT = "0x9008d19f58aabd9ed0d60971565aa8510560ab41"
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
owner_topic = "0x" + "0"*24 + SETTLEMENT[2:]

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                j = json.load(r)
            if "error" in j:
                raise RuntimeError(j["error"])
            return j["result"]
        except Exception as e:
            if attempt == 3: raise
            time.sleep(1.5*(attempt+1))

head = int(rpc("eth_blockNumber", []), 16)
start = int(sys.argv[1]) if len(sys.argv) > 1 else head - 2_000_000
CH = 50_000
hits = []
b = start
while b <= head:
    to = min(b+CH-1, head)
    logs = rpc("eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(to),
                                "topics": [APPROVAL, owner_topic]}])
    for lg in logs:
        tok = lg["address"]
        spender = "0x" + lg["topics"][2][-40:]
        val = int(lg["data"], 16)
        hits.append({"block": int(lg["blockNumber"],16), "tx": lg["transactionHash"],
                     "token": tok, "spender": spender, "value": val})
    b = to+1
print(json.dumps({"head": head, "from": start, "count": len(hits), "hits": hits}, indent=1))
