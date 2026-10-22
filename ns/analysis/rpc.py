#!/usr/bin/env python3
"""Minimal JSON-RPC helper for BSC reads. Keyless public endpoint by default.
Usage: python3 rpc.py <method> <params-json>
"""
import json, os, sys, urllib.request

RPC = os.environ.get("BSC_PUBLIC_RPC", "https://bsc-rpc.publicnode.com")


def call(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 zombie-hunt-research",
    })
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def eth_call(to, data, block="latest"):
    return call("eth_call", [{"to": to, "data": data}, block])["result"]


def block_number():
    return int(call("eth_blockNumber", [])["result"], 16)


if __name__ == "__main__":
    m = sys.argv[1]
    p = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
    print(json.dumps(call(m, p)))
