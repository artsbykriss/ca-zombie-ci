#!/usr/bin/env python3
"""Minimal JSON-RPC helper for BTTC/Viction/Aurora reads. Read-only. No secrets."""
import json, sys, urllib.request, time

RPCS = {
    "bttc": "https://rpc.bt.io",
    "viction": "https://rpc.viction.xyz",
    "aurora": "https://mainnet.aurora.dev",
}

def rpc(chain, method, params, url=None, tries=3):
    url = url or RPCS[chain]
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for t in range(tries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if "result" in d:
                return d["result"]
            raise RuntimeError(d.get("error"))
        except Exception as e:
            if t == tries - 1:
                raise
            time.sleep(1.5 * (t + 1))

def batch(chain, calls, url=None):
    """calls: list of (method, params). Returns list of results (None on error)."""
    url = url or RPCS[chain]
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.load(r)
    out = [None] * len(calls)
    for item in d:
        out[item["id"]] = item.get("result", None)
    return out

def eth_call(chain, to, data, block="latest", url=None):
    return rpc(chain, "eth_call", [{"to": to, "data": data}, block], url=url)

def block_number(chain, url=None):
    return int(rpc(chain, "eth_blockNumber", [], url=url), 16)

def get_code(chain, addr, block="latest", url=None):
    return rpc(chain, "eth_getCode", [addr, block], url=url)

def get_balance(chain, addr, block="latest", url=None):
    return int(rpc(chain, "eth_getBalance", [addr, block], url=url), 16)

# minimal ABI enc/dec helpers
def pad32(x):
    if isinstance(x, int):
        return f"{x:064x}"
    x = x.lower().replace("0x", "")
    return x.rjust(64, "0")

def sel(sig):
    import hashlib
    return "0x" + hashlib.sha3_256(sig.encode()).hexdigest()[:8]  # placeholder, use keccak below

def addr_call_data(sig4, args=()):
    return sig4 + "".join(pad32(a) for a in args)

def dec_uint(h, idx=0):
    if h is None or h == "0x":
        return None
    h = h[2:]
    return int(h[idx*64:(idx+1)*64], 16)

def dec_addr(h, idx=0):
    if h is None or h == "0x":
        return None
    h = h[2:]
    return "0x" + h[idx*64+24:(idx+1)*64]

if __name__ == "__main__":
    print(json.dumps({"bttc": block_number("bttc"), "viction": block_number("viction"), "aurora": block_number("aurora")}, indent=2))
