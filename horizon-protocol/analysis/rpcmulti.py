#!/usr/bin/env python3
"""Threaded single-call BSC JSON-RPC helper. Public endpoints only, no keys.
"""
import json, time, urllib.request, threading
from concurrent.futures import ThreadPoolExecutor

RPCS = [
    "https://bsc-dataseed2.defibit.io",
    "https://bsc-dataseed1.defibit.io",
    "https://bsc-mainnet.public.blastapi.io",
    "https://bsc-dataseed3.ninicoin.io",
    "https://bsc-rpc.publicnode.com",
]
_lock = threading.Lock()
_rr = {"i": 0}

def _next_rpc():
    with _lock:
        r = RPCS[_rr["i"] % len(RPCS)]
        _rr["i"] += 1
        return r

def _rpc_one(method, params, retries=5):
    last = None
    for i in range(retries):
        rpc = _next_rpc()
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        try:
            req = urllib.request.Request(rpc, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=12) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = str(e)
        time.sleep(0.3 * (i + 1))
    return {"error": str(last)}

def call(to, data):
    return _rpc_one("eth_call", [{"to": to, "data": data}, "latest"])

def native(addr):
    return _rpc_one("eth_getBalance", [addr, "latest"])

def block():
    return int(_rpc_one("eth_blockNumber", []), 16)

def multi(fns, workers=10):
    """fns: list of callables. Returns list of results in order."""
    with ThreadPoolExecutor(max_workers=workers) as ex:
        return list(ex.map(lambda f: f(), fns))

if __name__ == "__main__":
    print("block", block())
