#!/usr/bin/env python3
"""Tiny JSON-RPC batch helper for opBNB reads. Keyless public RPC only."""
import json, sys, urllib.request

RPCS = ["https://opbnb-mainnet-rpc.bnbchain.org", "https://opbnb.publicnode.com"]

def rpc_batch(calls, url=None):
    """calls: list of (method, params). Returns list of results."""
    urls = [url] if url else RPCS
    payload = [{"jsonrpc": "2.0", "method": m, "params": p, "id": i} for i, (m, p) in enumerate(calls)]
    data = json.dumps(payload).encode()
    last = None
    for u in urls:
        try:
            req = urllib.request.Request(u, data=data, headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.load(r)
            res = {}
            for item in out:
                if "result" in item:
                    res[item["id"]] = item["result"]
                else:
                    res[item["id"]] = {"__error__": item.get("error")}
            return [res[i] for i in range(len(calls))]
        except Exception as e:
            last = e
    raise RuntimeError(f"all RPCs failed: {last}")

def eth_call(to, data, block="latest"):
    return rpc_batch([("eth_call", [{"to": to, "data": data}, block])])[0]

def block_number():
    return int(rpc_batch([("eth_blockNumber", [])])[0], 16)

if __name__ == "__main__":
    print("block", block_number())
