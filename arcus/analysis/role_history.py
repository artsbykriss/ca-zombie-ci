#!/usr/bin/env python3
"""Role history + factory upgrade history + fetch all txs to factory in event blocks."""
import json, urllib.request, collections, time

RPC = "https://rpc.mainnet.chain.robinhood.com"
def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 arcus-analysis/1.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                d = json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            if attempt == 3: raise
            time.sleep(1.5)

d = json.load(open('/home/heisenberg/CA/arcus/analysis/factory_beacon_logs.json'))
FACT = "0x9c3663fa9ab976e67b42939486ec4966cb41a0bb"

print("=== FACTORY Upgraded (0xbc7cd75a) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b':
        print(" block", int(l['blockNumber'],16), "impl", "0x"+l['topics'][1][-40:], "tx", l['transactionHash'])

print("\n=== RoleGranted (0x2f878811) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d':
        print(" block", int(l['blockNumber'],16), "role", l['topics'][1][:18], "account", "0x"+l['topics'][2][-40:], "by", "0x"+l['data'][-40:])

print("\n=== RoleRevoked (0xf6391f5c) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b':
        print(" block", int(l['blockNumber'],16), "role", l['topics'][1][:18], "account", "0x"+l['topics'][2][-40:], "by", "0x"+l['data'][-40:])

print("\n=== RoleAdminChanged (0xbd79b86f) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff':
        print(" block", int(l['blockNumber'],16), "role", l['topics'][1][:18], "prevAdmin", l['topics'][2][:18], "newAdmin", l['topics'][3][:18])

print("\n=== ManagerUpdated (0x8df26d30) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0x8df26d30992ecfde135bbe59c1f267d82e2aae9d32fdae41551a38fe8b7bda87':
        print(" block", int(l['blockNumber'],16), "t1", "0x"+l['topics'][1][-40:], "t2", "0x"+l['topics'][2][-40:], "t3", "0x"+l['topics'][3][-40:])

print("\n=== BridgeVaultUpdated (0x86cafad4) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0x86cafad4e48ec1edd3bf1bb4b05fbe08a979cc3a0bfceb82a841aa502c5e666b':
        print(" block", int(l['blockNumber'],16), l['topics'][1], l['topics'][2])

print("\n=== BeaconUpdated (0x46a98d58) ===")
for l in sorted(d['factory'], key=lambda x: int(x['blockNumber'],16)):
    if l['topics'][0] == '0x46a98d582ba4c3ce698945c0010d1e6e1ba1c4a413ee1dfb18c0b31076be79e9':
        print(" block", int(l['blockNumber'],16), "t1", "0x"+l['topics'][1][-40:], "t2", "0x"+l['topics'][2][-40:])

# fetch blocks for all txs to factory
blocks_needed = sorted(set(int(l['blockNumber'],16) for l in d['factory']))
print(f"\n=== fetching {len(blocks_needed)} blocks for factory txs ===")
txs = {}
for i, bn in enumerate(blocks_needed):
    blk = rpc("eth_getBlockByNumber", [hex(bn), True])
    for tx in blk['transactions']:
        if tx['to'] and tx['to'].lower() == FACT:
            txs[tx['hash']] = {"block": bn, "from": tx['from'], "input": tx['input'],
                               "selector": tx['input'][:10], "status": None}
    if i % 25 == 0:
        print(f"  {i}/{len(blocks_needed)}...", flush=True)
        time.sleep(0.3)
json.dump(txs, open('/home/heisenberg/CA/arcus/analysis/factory_txs_events.json','w'), indent=1)
print("total factory txs found:", len(txs))
sc = collections.Counter(t['selector'] for t in txs.values())
for sel, n in sc.most_common():
    print(f"  {sel} {n}")
