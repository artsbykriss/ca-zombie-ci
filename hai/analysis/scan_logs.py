#!/usr/bin/env python3
"""Chunked eth_getLogs scanner for Optimism (10k-block chunks). RPC from env OP_RPC (never saved)."""
import os, json, sys, time, urllib.request
RPC = os.environ['OP_RPC']
CHUNK = 10000
def rpc(method, params, retries=4):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={'Content-Type':'application/json'})
            r = json.load(urllib.request.urlopen(req, timeout=45))
            if 'error' in r:
                raise RuntimeError(r['error'])
            return r['result']
        except Exception as e:
            if i == retries-1: raise
            time.sleep(1.5*(i+1))
def scan(address, topics, from_block, to_block, label):
    logs = []
    b = from_block
    while b <= to_block:
        end = min(b+CHUNK-1, to_block)
        r = rpc('eth_getLogs', [{"address": address, "fromBlock": hex(b), "toBlock": hex(end), "topics": [topics]}])
        logs.extend(r)
        b = end+1
    print(f"{label}: {len(logs)} logs in [{from_block},{to_block}]", flush=True)
    return logs
if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--address', required=True)
    p.add_argument('--topics', required=True, help='comma-separated topic0 list')
    p.add_argument('--from-block', type=int, required=True)
    p.add_argument('--to', type=int, required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--label', default='scan')
    a = p.parse_args()
    topics = [t.strip() for t in a.topics.split(',') if t.strip()]
    logs = scan(a.address, topics, a.from_block, a.to, a.label)
    json.dump(logs, open(a.out,'w'))
    print('saved', a.out)
