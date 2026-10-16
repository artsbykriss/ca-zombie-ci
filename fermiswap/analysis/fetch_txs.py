#!/usr/bin/env python3
"""Fetch and classify all txs to Fermi contracts via Etherscan V2. Read-only."""
import json, os, urllib.request, time

EK = None
for line in open('/home/heisenberg/CA/.env'):
    if line.startswith('ETHERSCANV2_API_KEY='):
        EK = line.split('=', 1)[1].strip().strip('"')

def fetch_txs(addr, page_size=1000):
    out = []
    page = 1
    while True:
        url = (f"https://api.etherscan.io/v2/api?chainid=1&module=account&action=txlist"
               f"&address={addr}&startblock=0&endblock=99999999&page={page}&offset={page_size}"
               f"&sort=asc&apikey={EK}")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        d = json.load(urllib.request.urlopen(req, timeout=30))
        r = d.get('result', [])
        if not isinstance(r, list) or not r:
            break
        out += r
        if len(r) < page_size:
            break
        page += 1
        time.sleep(0.3)
    return out

targets = {
    'swapper': '0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e',
    'vault': '0x585d44727129B9C69791B10238Ca605932938B4F',
    'engine': '0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f',
}
os.makedirs('analysis', exist_ok=True)
allc = {}
for name, addr in targets.items():
    txs = fetch_txs(addr)
    print(f"{name}: {len(txs)} txs")
    from collections import Counter
    c = Counter()
    for t in txs:
        sel = t['input'][:10] if t['input'] != '0x' else '0x(plain)'
        c[sel] += 1
    allc[name] = {'count': len(txs), 'selectors': dict(c.most_common())}
    if txs:
        print('  first:', txs[0]['blockNumber'], txs[0]['timeStamp'])
        print('  last :', txs[-1]['blockNumber'], txs[-1]['timeStamp'])
    for sel, n in c.most_common(12):
        print(f'    {sel} x{n}')
    json.dump(txs, open(f'analysis/{name}_txs_full.json', 'w'))
json.dump(allc, open('analysis/tx_classification.json', 'w'), indent=1)
