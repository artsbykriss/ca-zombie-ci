#!/usr/bin/env python3
"""Fetch registry txs + logs. Read-only."""
import json, urllib.request, time
from datetime import datetime, timezone

EK = None
for line in open('/home/heisenberg/CA/.env'):
    if line.startswith('ETHERSCANV2_API_KEY='):
        EK = line.split('=', 1)[1].strip().strip('"')

REG = '0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F'

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=30))

# txs
txs = []
page = 1
while True:
    d = get(f"https://api.etherscan.io/v2/api?chainid=1&module=account&action=txlist&address={REG}&startblock=0&endblock=99999999&page={page}&offset=1000&sort=asc&apikey={EK}")
    r = d.get('result', [])
    if not isinstance(r, list) or not r: break
    txs += r
    if len(r) < 1000: break
    page += 1
print(f"registry txs: {len(txs)}")
for t in txs:
    ts = datetime.fromtimestamp(int(t['timeStamp']), tz=timezone.utc).strftime('%Y-%m-%d %H:%M')
    print(f"  {t['blockNumber']} {ts} from={t['from'][:12]} sel={t['input'][:10]} inlen={len(t['input'])}")
json.dump(txs, open('analysis/registry_txs.json','w'))

# events (logs)
logs = []
page = 1
while True:
    d = get(f"https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs&address={REG}&fromBlock=0&toBlock=latest&page={page}&offset=1000&apikey={EK}")
    r = d.get('result', [])
    if not isinstance(r, list) or not r: break
    logs += r
    if len(r) < 1000: break
    page += 1
print(f"registry logs: {len(logs)}")
from collections import Counter
c = Counter(l['topics'][0] for l in logs)
for topic, n in c.most_common():
    print(' ', topic, n)
json.dump(logs, open('analysis/registry_logs.json','w'))
