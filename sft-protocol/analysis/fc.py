#!/usr/bin/env python3
"""fc.py — Filecoin FEVM JSON-RPC helper: endpoint rotation, retries, disk cache.

Usage:
  python3 fc.py call <to> <data> [block]        # eth_call
  python3 fc.py code <addr>                     # eth_getCode (len)
  python3 fc.py bal <addr>                      # eth_getBalance (wei)
  python3 fc.py slot <addr> <slot>              # eth_getStorageAt
  python3 fc.py raw <method> <params-json>      # any method
Caches results in rpc_cache.json (public data only).
"""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, 'rpc_cache.json')
ENDPOINTS = [
    "https://filecoin.drpc.org",
    "https://api.node.glif.io/rpc/v1",
]

def load_cache():
    if os.path.exists(CACHE):
        try: return json.load(open(CACHE))
        except Exception: return {}
    return {}

def save_cache(c):
    json.dump(c, open(CACHE, 'w'))

def rpc(method, params, cache, use_cache=True):
    key = method + '|' + json.dumps(params, sort_keys=True)
    if use_cache and key in cache:
        return cache[key]
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(3):
        ep = ENDPOINTS[attempt % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=15) as r:
                d = json.load(r)
            if 'result' in d:
                cache[key] = d['result']
                save_cache(cache)
                return d['result']
            # A JSON-RPC error (e.g. VM revert) is a definitive answer, not transport failure.
            err = d.get('error') or {}
            msg = str(err.get('message') or err)
            if 'revert' in msg or 'message execution failed' in msg or 'execution reverted' in msg or err.get('code') == 3:
                return '__REVERT__:' + msg[:160]
            last = d
        except Exception as e:
            last = str(e)
        time.sleep(1 + attempt)
    raise RuntimeError(f"rpc failed: {method} {params}: {last}")

def main():
    cache = load_cache()
    cmd = sys.argv[1]
    if cmd == 'call':
        to, data = sys.argv[2], sys.argv[3]
        block = sys.argv[4] if len(sys.argv) > 4 else 'latest'
        print(rpc('eth_call', [{'to': to, 'data': data}, block], cache))
    elif cmd == 'code':
        r = rpc('eth_getCode', [sys.argv[2], 'latest'], cache)
        print(len(r)//2 - 1)
    elif cmd == 'bal':
        r = rpc('eth_getBalance', [sys.argv[2], 'latest'], cache)
        print(int(r, 16))
    elif cmd == 'slot':
        print(rpc('eth_getStorageAt', [sys.argv[2], sys.argv[3], 'latest'], cache))
    elif cmd == 'raw':
        print(json.dumps(rpc(sys.argv[2], json.loads(sys.argv[3]), cache, use_cache=False), indent=1))
    else:
        print(__doc__); sys.exit(1)

if __name__ == '__main__':
    main()
