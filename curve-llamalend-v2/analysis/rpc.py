#!/usr/bin/env python3
"""Minimal JSON-RPC helper. URLs are supplied via env vars (never embedded in files).
Usage: RPC_URL=... python3 rpc.py ...
"""
import json, os, sys, urllib.request

PUB = {
    "ethereum": "https://ethereum-rpc.publicnode.com",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
    "optimism": "https://mainnet.optimism.io",
    "base": "https://mainnet.base.org",
}

def url(chain):
    u = os.environ.get(chain.upper() + "_RPC_URL")
    if not u and chain == "ethereum":
        u = os.environ.get("BLOCKPI_RPC_URL") or os.environ.get("RPC_URL")
    return u or PUB[chain]

def batch(chain, calls, block="latest", chunk=10):
    res = [None] * len(calls)
    for off in range(0, len(calls), chunk):
        body = []
        for i, (to, data) in enumerate(calls[off:off+chunk]):
            body.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                         "params": [{"to": to, "data": data}, block if isinstance(block, str) else hex(block)]})
        req = urllib.request.Request(url(chain), data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
        try:
            out = json.load(urllib.request.urlopen(req, timeout=60))
        except urllib.error.HTTPError as e:
            if e.code in (413, 429) and len(body) > 1:
                return batch(chain, calls, block, max(1, chunk // 2))
            raise
        if isinstance(out, dict):
            out = [out]
        for r in out:
            res[off + r["id"]] = r.get("result") if "result" in r else {"error": r.get("error")}
    return res

def sel(sig):
    # keccak via eth_hash if present else subprocess cast
    try:
        from Crypto.Hash import keccak
        k = keccak.new(digest_bits=256); k.update(sig.encode()); return "0x" + k.hexdigest()[:8]
    except Exception:
        import subprocess
        return subprocess.check_output(["cast", "sig", sig]).decode().strip()

def block_number(chain):
    req = urllib.request.Request(url(chain), data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return int(json.load(urllib.request.urlopen(req, timeout=30))["result"], 16)

def uint(x):
    if not x or isinstance(x, dict): return None
    return int(x, 16)

def addr(x):
    if not x or isinstance(x, dict): return None
    return "0x" + x[-40:]

if __name__ == "__main__":
    print(block_number(sys.argv[1] if len(sys.argv) > 1 else "ethereum"))
