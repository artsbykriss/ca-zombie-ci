#!/usr/bin/env python3
"""Scan recent Governor/Timelock logs over keyless public RPC in 8k-block chunks."""
import json, urllib.request, os, time

RPC = os.environ.get('OP_RPC_PUBLIC', 'https://mainnet.optimism.io')
GOV = '0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777'
TL = '0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899'
FROM = 158262010
TO = 158341121

TOPICS = {
    'ProposalCreated': '0x7d84a6263ae0d98d3329bd7b46bb4e8d6f98cd35a7adb45c274c8b7fd5ebd5e0',
    'VoteCast': '0xb8e138887d0aa13bab447e82de9d5c1777041ecd21ca36ba824ff1e6c07ddda4',
    'ProposalQueued': '0x9a2e42fd6722813d69113e7d0079d3d940171428df7373df9c7f7617cfda2892',
    'ProposalExecuted': '0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f',
    'CallExecuted': '0xc2617efa69bab66782fa219543714338489c4e9e178271560a91b82c3f612b58',
    'CallScheduled': '0x8df6186c52f5d6410d3fc41d01f19a1f1b05960144685cabb7c1e07d2e877620',
}

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(3):
        try:
            req = urllib.request.Request(RPC, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
            r = json.load(urllib.request.urlopen(req, timeout=60))
            if 'error' in r: raise RuntimeError(r['error'])
            return r['result']
        except Exception:
            if i == 2: raise
            time.sleep(2)

out = {k: [] for k in TOPICS}
for name, topic in TOPICS.items():
    addr = TL if name in ('CallExecuted', 'CallScheduled') else GOV
    b = FROM
    while b <= TO:
        e = min(b + 8000 - 1, TO)
        logs = rpc('eth_getLogs', [{"address": addr, "fromBlock": hex(b), "toBlock": hex(e), "topics": [topic]}])
        for lg in logs:
            lg['_event'] = name
        out[name].extend(logs)
        b = e + 1
    print(name, len(out[name]), flush=True)
json.dump(out, open('recent_logs.json', 'w'))
print('saved recent_logs.json')
