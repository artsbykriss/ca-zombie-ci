#!/usr/bin/env python3
"""Parallel Kaia RPC helper (read-only, keyless public endpoints)."""
import json, subprocess, concurrent.futures as cf

RPCS = [
    "https://public-en.node.kaia.io",
    "https://rpc.ankr.com/kaia",
    "https://kaia.drpc.org",
]

def _curl(url, payload, timeout=25):
    p = subprocess.run(
        ["curl", "-s", "-m", str(timeout), "-X", "POST", "-H", "Content-Type: application/json",
         "--data-binary", payload, url],
        capture_output=True, text=True, timeout=timeout + 10)
    return p.stdout

def rpc(method, params, rpc_url=None, retries=2):
    urls = [rpc_url] if rpc_url else RPCS
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    last_err = None
    for _ in range(retries):
        for u in urls:
            try:
                out = json.loads(_curl(u, payload))
                if "error" in out:
                    raise RuntimeError(out["error"])
                return out.get("result")
            except Exception as e:
                last_err = e
    raise RuntimeError(f"rpc failed: {last_err}")

def rpc_many(calls, workers=16, rpc_url=None):
    """calls: list of (method, params) -> list of results (None replaced by {'__error__':...})"""
    def one(i_c):
        i, (m, p) = i_c
        try:
            return i, rpc(m, p, rpc_url=rpc_url)
        except Exception as e:
            return i, {"__error__": str(e)[:200]}
    out = [None] * len(calls)
    with cf.ThreadPoolExecutor(max_workers=workers) as ex:
        for i, r in ex.map(one, list(enumerate(calls))):
            out[i] = r
    return out

def dec_uint(hexstr):
    if not hexstr or hexstr == "0x" or isinstance(hexstr, dict):
        return None
    return int(hexstr, 16)

def dec_str(hexstr):
    if not hexstr or hexstr == "0x" or isinstance(hexstr, dict):
        return None
    b = bytes.fromhex(hexstr[2:])
    if len(b) >= 64:
        off = int.from_bytes(b[0:32], "big")
        if off + 32 <= len(b):
            ln = int.from_bytes(b[off:off+32], "big")
            if off + 32 + ln <= len(b):
                return b[off+32:off+32+ln].decode("utf-8", "replace")
    return hexstr

def dec_addr(hexstr):
    if not hexstr or hexstr == "0x" or isinstance(hexstr, dict):
        return None
    return "0x" + hexstr[-40:]

def sel(sig):
    return subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()

if __name__ == "__main__":
    print(rpc("eth_blockNumber", []))
