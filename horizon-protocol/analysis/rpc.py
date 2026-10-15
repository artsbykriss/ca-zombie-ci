#!/usr/bin/env python3
"""Minimal BSC JSON-RPC helper (public endpoint; no keys).
Usage:
  python3 rpc.py block
  python3 rpc.py call <to> <sig-or-data> [--from 0x..]
  python3 rpc.py code <addr>
  python3 rpc.py batch <file.json>   # [{"to":..,"data":..}, ...]
Env: BSC_RPC (default https://bsc-rpc.publicnode.com)
"""
import json, os, sys, urllib.request, time

RPC = os.environ.get("BSC_RPC", "https://bsc-rpc.publicnode.com")

def rpc(method, params, retries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                d = json.loads(r.read())
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = str(e)
        time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"rpc failed: {last}")

def selector(sig):
    # keccak via cast is easier; here we require raw data or use known selectors map
    return sig

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "block":
        print(int(rpc("eth_blockNumber", []), 16))
    elif cmd == "code":
        c = rpc("eth_getCode", [sys.argv[2], "latest"])
        print(len(c), c[:80])
    elif cmd == "call":
        to = sys.argv[2]
        data = sys.argv[3]
        params = [{"to": to, "data": data}, "latest"]
        if "--from" in sys.argv:
            params[0]["from"] = sys.argv[sys.argv.index("--from") + 1]
        print(rpc("eth_call", params))
    elif cmd == "batch":
        items = json.load(open(sys.argv[2]))
        reqs = []
        for i, it in enumerate(items):
            p = [{"to": it["to"], "data": it["data"]}, it.get("block", "latest")]
            reqs.append({"jsonrpc": "2.0", "id": i, "method": "eth_call", "params": p})
        body = json.dumps(reqs).encode()
        req = urllib.request.Request(RPC, data=body, headers={
            "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            out = json.loads(r.read())
        res = {}
        for d in out:
            res[d["id"]] = d.get("result") or d.get("error")
        print(json.dumps(res, indent=1))
