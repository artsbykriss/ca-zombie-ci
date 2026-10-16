#!/usr/bin/env python3
"""Fetch registry txs in recent blocks, decode updateState for engine3. Read-only."""
import json, urllib.request
from datetime import datetime, timezone

EK = None
for line in open('/home/heisenberg/CA/.env'):
    if line.startswith('ETHERSCANV2_API_KEY='):
        EK = line.split('=', 1)[1].strip().strip('"')

REG = '0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F'
ENGINE = '0x90f73fea1ee2dc514d4dbac0bff7ff04b933767f'

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=40))

# recent: last ~90k blocks (~12 days)
latest = 26202357
start = latest - 90000
txs = []
page = 1
while True:
    d = get(f"https://api.etherscan.io/v2/api?chainid=1&module=account&action=txlist&address={REG}&startblock={start}&endblock=latest&page={page}&offset=1000&sort=asc&apikey={EK}")
    r = d.get('result', [])
    if not isinstance(r, list) or not r:
        break
    txs += r
    if len(r) < 1000:
        break
    page += 1
    if page > 15:
        print("cap reached"); break
print(f"recent registry txs since block {start}: {len(txs)}")

# classify: updateState(0xa9114b0f) with target=ENGINE
eng_updates = []
for t in txs:
    if t['input'].startswith('0xa9114b0f'):
        data = t['input'][10:]
        words = [data[i:i+64] for i in range(0, len(data), 64)]
        target = '0x'+words[0][-40:]
        if target.lower() == ENGINE:
            eng_updates.append(t)

print(f"engine3 updateState txs: {len(eng_updates)}")
for t in eng_updates[-15:]:
    d = t['input'][10:]
    words = [d[i:i+64] for i in range(0, len(d), 64)]
    ts = datetime.fromtimestamp(int(t['timeStamp']), tz=timezone.utc).strftime('%Y-%m-%d %H:%M')
    lane = words[1]
    uts = int(words[2],16)
    nslots = int(words[3],16)
    slots = [int(words[4+i],16) for i in range(min(nslots,4))]
    print(f"  blk {t['blockNumber']} {ts} from={t['from'][:12]} lane={lane[:20]}.. uts={uts} slots={nslots} {slots[:3]}")
json.dump(txs, open('analysis/registry_txs_recent.json','w'))
json.dump(eng_updates, open('analysis/engine3_updates.json','w'))
