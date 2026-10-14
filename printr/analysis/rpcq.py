#!/usr/bin/env python3
"""Tiny JSON-RPC helper for Printr L2-phase2 analysis.

Endpoints: prefers env override (RPC_URL_<CHAIN>) then public fallbacks.
NEVER hardcode keyed URLs here (this folder is synced to a public CI repo).
"""
import json, os, sys, time, urllib.request

PUBLIC = {
    "ethereum": "https://ethereum-rpc.publicnode.com",
    "base": "https://mainnet.base.org",
    "mantle": "https://rpc.mantle.xyz",
    "arbitrum": "https://arb1.arbitrum.io/rpc",
    "bsc": "https://bsc-rpc.publicnode.com",
    "avalanche": "https://api.avax.network/ext/bc/C/rpc",
    "monad": "https://rpc.monad.xyz",
}

def endpoint(chain: str) -> str:
    return os.environ.get(f"RPC_URL_{chain.upper()}") or PUBLIC[chain]

def rpc(chain: str, method: str, params: list, retries: int = 4, timeout: int = 30):
    url = endpoint(chain)
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0",
            })
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            last = out
        except Exception as e:  # noqa
            last = str(e)
        time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"{chain} {method} failed: {last}")

def batch(chain: str, calls: list, timeout: int = 40):
    """calls = [(method, params), ...]; returns list of results/errors in order."""
    url = endpoint(chain)
    body = json.dumps([
        {"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)
    ]).encode()
    for i in range(4):
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            res = [None] * len(calls)
            for item in out:
                res[item["id"]] = item.get("result", {"error": item.get("error")})
            return res
        except Exception as e:  # noqa
            if i == 3:
                raise
            time.sleep(1.5 * (i + 1))

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "block":
        for chain in sys.argv[2:] or PUBLIC:
            b = rpc(chain, "eth_blockNumber", [])
            print(chain, int(b, 16))
    elif cmd == "call":
        # call <chain> <to> <data>
        chain, to, data = sys.argv[2], sys.argv[3], sys.argv[4]
        print(rpc(chain, "eth_call", [{"to": to, "data": data}, "latest"]))
