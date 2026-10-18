#!/usr/bin/env python3
"""Shared read-only JSON-RPC helper for Xphere mainnet (chainId 20250217).
Public keyless endpoints only. Never log or persist keyed URLs."""
import json, time, requests

RPCS = [
    "https://rpc.x-phere.com",
    "https://en-bkk.x-phere.com",
    "https://rpc.ankr.com/xphere_mainnet",
]
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) research"}

_sess = requests.Session()
_sess.headers.update(UA)

def rpc(method, params, rpc_url=None, timeout=25, retries=4):
    urls = [rpc_url] if rpc_url else RPCS
    last = None
    for attempt in range(retries):
        for u in urls:
            if not u:
                continue
            try:
                r = _sess.post(u, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params},
                               timeout=timeout)
                j = r.json()
                if "result" in j:
                    return j["result"]
                last = j.get("error")
            except Exception as e:
                last = str(e)
        time.sleep(1.0 * (attempt + 1))
    raise RuntimeError(f"rpc {method} failed: {last}")

def batch(calls, rpc_url=None, timeout=40):
    """calls: list of (method, params). Returns list of results (None on per-call error)."""
    urls = [rpc_url] if rpc_url else RPCS
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    last = None
    for attempt in range(4):
        for u in urls:
            if not u:
                continue
            try:
                r = _sess.post(u, json=payload, timeout=timeout)
                j = r.json()
                if isinstance(j, list):
                    out = [None] * len(calls)
                    for item in j:
                        i = item.get("id")
                        if i is not None:
                            out[i] = item.get("result")
                    return out
                last = j
            except Exception as e:
                last = str(e)
        time.sleep(1.0 * (attempt + 1))
    raise RuntimeError(f"batch failed: {last}")

def call(to, data, block="latest", rpc_url=None):
    return rpc("eth_call", [{"to": to, "data": data}, block], rpc_url=rpc_url)

def block_number(rpc_url=None):
    return int(rpc("eth_blockNumber", [], rpc_url=rpc_url), 16)

def get_code(addr, block="latest", rpc_url=None):
    return rpc("eth_getCode", [addr, block], rpc_url=rpc_url)

def get_logs(address=None, topics=None, from_block="0x0", to_block="latest", rpc_url=None):
    p = {"fromBlock": from_block, "toBlock": to_block}
    if address:
        p["address"] = address
    if topics:
        p["topics"] = topics
    return rpc("eth_getLogs", [p], rpc_url=rpc_url)

def hexword(x):
    if isinstance(x, str):
        x = int(x, 16) if x.startswith("0x") else int(x)
    return f"{x:064x}"

def enc_addr(a):
    """ABI word for an address to APPEND to a selector (no 0x prefix)."""
    return hexword(int(a, 16))

def enc_uint(x):
    """ABI word for a uint to APPEND to a selector (no 0x prefix)."""
    return hexword(x)

def dec_uint(h):
    if h is None:
        return None
    return int(h, 16)

def dec_addr(h):
    if h is None:
        return None
    return "0x" + h[-40:]

def dec_bool(h):
    return dec_uint(h) != 0

def to_bytes32_words(h):
    if h is None:
        return None
    h = h[2:] if h.startswith("0x") else h
    return [h[i:i+64] for i in range(0, len(h), 64)]

if __name__ == "__main__":
    bn = block_number()
    print("latest block:", bn)
    print("chainId:", rpc("eth_chainId", []))
