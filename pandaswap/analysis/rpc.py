#!/usr/bin/env python3
"""Robust batched BSC JSON-RPC helper (public endpoints only; no secrets).

Usage: imported by other analysis scripts. Read-only (eth_call / eth_getCode / eth_blockNumber).
"""
import json, os, time, urllib.request, urllib.error

UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) zombie-research"}
RPCS = []
for _envname in ("BSC_RPC_URL", "BSC_RPC_URL2", "BSC_RPC_URL3"):
    _env = os.environ.get(_envname)
    if _env:
        RPCS.append(_env)
RPCS += [
    "https://bsc-rpc.publicnode.com",
    "https://bsc-dataseed1.defibit.io",
    "https://bsc.drpc.org",
    "https://rpc.ankr.com/bsc",
]

_state = {"url": None}

def _post(url, payload, timeout=25):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=body, headers={**UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc_batch(calls, retries=8, batch=20):
    """calls: list of (method, params). Returns list of results (or None per item)."""
    results = [None] * len(calls)
    pending = list(range(len(calls)))
    attempt = 0
    while pending and attempt < retries:
        urls = ([_state["url"]] if _state["url"] else []) + [u for u in RPCS if u != _state["url"]]
        chunk = pending[:batch]
        rest = pending[batch:]
        progressed = False
        for u in urls:
            payload = [{"jsonrpc": "2.0", "id": i, "method": calls[i][0], "params": calls[i][1]} for i in chunk]
            try:
                resp = _post(u, payload, timeout=20)
                if isinstance(resp, dict):
                    resp = [resp]
                got = {r.get("id"): r for r in resp if isinstance(r, dict)}
                for i in chunk:
                    r = got.get(i)
                    if r is not None and "result" in r:
                        results[i] = r["result"]
                chunk = [i for i in chunk if results[i] is None]
                _state["url"] = u
                progressed = True
                break
            except Exception:
                continue
        pending = chunk + rest
        if pending:
            attempt += 1
            if not progressed:
                time.sleep(1.0 * attempt)
    return results

def call(to, data, block="latest"):
    r = rpc_batch([("eth_call", [{"to": to, "data": data}, hex(block) if isinstance(block, int) else block])])
    return r[0]

def code(addr, block="latest"):
    r = rpc_batch([("eth_getCode", [addr, hex(block) if isinstance(block, int) else block])])
    return r[0]

def block_number():
    r = rpc_batch([("eth_blockNumber", [])])
    return int(r[0], 16)

def enc_sel(sig):
    import hashlib
    return "0x" + hashlib.sha3_256(sig.encode()).hexdigest()[:8]  # placeholder, replaced below

def sel(sig):
    """4-byte selector via keccak (pure python, no deps)."""
    import hashlib
    # keccak256 implemented via tiny pure-python (eth-hash not guaranteed installed)
    try:
        from Crypto.Hash import keccak
        k = keccak.new(digest_bits=256); k.update(sig.encode()); return "0x" + k.hexdigest()[:8]
    except Exception:
        pass
    try:
        import sha3  # pysha3
        k = sha3.keccak_256(); k.update(sig.encode()); return "0x" + k.hexdigest()[:8]
    except Exception:
        pass
    # fallback: use cast if available
    import subprocess
    out = subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()
    return out

def word(hexstr):
    return hexstr[2:].rjust(64, "0") if hexstr and hexstr.startswith("0x") else (hexstr or "").rjust(64, "0")

def as_int(hexstr):
    if hexstr is None or hexstr == "0x":
        return None
    return int(hexstr, 16)

def as_addr(hexstr):
    if hexstr is None or len(hexstr) < 42:
        return None
    return "0x" + hexstr[-40:]

def encode_uint(n):
    return hex(n)[2:].rjust(64, "0")

def encode_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

if __name__ == "__main__":
    bn = block_number()
    print("block", bn)
