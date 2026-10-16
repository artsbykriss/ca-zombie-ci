#!/usr/bin/env python3
"""Fetch representative txs per factory event type; maps events->selectors (evidence)."""
import json, urllib.request, collections

RPC = "https://rpc.mainnet.chain.robinhood.com"
def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 arcus-analysis/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.load(r)
    if "error" in d: raise RuntimeError(d["error"])
    return d["result"]

d = json.load(open('/home/heisenberg/CA/arcus/analysis/factory_beacon_logs.json'))
evs = collections.defaultdict(list)
for l in d['factory']:
    evs[l['topics'][0]].append(l)

cache = {}
def get_tx(h):
    if h not in cache:
        cache[h] = rpc("eth_getTransactionByHash", [h])
    return cache[h]

report = {}
for t, ls in evs.items():
    entries = []
    for l in ls:
        tx = get_tx(l['transactionHash'])
        entries.append({
            "block": int(l['blockNumber'], 16), "tx": l['transactionHash'],
            "from": tx['from'], "to": tx['to'], "selector": tx['input'][:10],
            "input": tx['input'], "topics": l['topics'], "data": l['data'],
        })
    sel_count = collections.Counter(e["selector"] for e in entries)
    print(f"{t[:14]} n={len(entries)} selectors={dict(sel_count)}")
    report[t] = entries
json.dump(report, open('/home/heisenberg/CA/arcus/analysis/event_txs.json','w'), indent=1)
print("saved event_txs.json")
