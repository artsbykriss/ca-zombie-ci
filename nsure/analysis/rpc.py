#!/usr/bin/env python3
"""Batch JSON-RPC helper. Reads endpoint from env vars (never hardcodes/prints keyed URLs).
Usage: from rpc import rpc_batch, eth_call, balance_of ...
"""
import os, json, time, urllib.request

def _endpoints():
    out = []
    for k in ("NODEREAL_ETH_RPC_URL", "DRPC_RPC_URL", "RPC_URL"):
        v = os.environ.get(k)
        if v:
            out.append(v)
    out += ["https://eth.drpc.org", "https://ethereum-rpc.publicnode.com", "https://1rpc.io/eth"]
    # dedupe preserving order
    seen, res = set(), []
    for u in out:
        if u not in seen:
            seen.add(u); res.append(u)
    return res

def _post(url, payload, timeout=10):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 research"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc_batch(calls, batch_size=10, retries=4):
    """calls: list of (method, params). Returns list of results (or {'error':...})."""
    eps = _endpoints()
    results = [None] * len(calls)
    for start in range(0, len(calls), batch_size):
        chunk = calls[start:start + batch_size]
        payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
                   for i, (m, p) in enumerate(chunk)]
        ok = False
        for attempt in range(retries):
            url = eps[min(attempt, len(eps) - 1)]
            try:
                resp = _post(url, payload)
                by_id = {r.get("id"): r for r in resp}
                for i in range(len(chunk)):
                    r = by_id.get(i, {})
                    results[start + i] = r.get("result", {"error": r.get("error")})
                ok = True
                break
            except Exception as e:
                time.sleep(0.6 * (attempt + 1))
        if not ok:
            for i in range(len(chunk)):
                results[start + i] = {"error": "rpc_failed"}
    return results

def block_number():
    r = rpc_batch([("eth_blockNumber", [])])[0]
    return int(r, 16)

def get_code(addr, block="latest"):
    return rpc_batch([("eth_getCode", [addr, hex(block) if isinstance(block, int) else block])])[0]

def get_balance(addr, block="latest"):
    r = rpc_batch([("eth_getBalance", [addr, hex(block) if isinstance(block, int) else block])])[0]
    return int(r, 16)

def eth_call(to, data, block="latest"):
    r = rpc_batch([("eth_call", [{"to": to, "data": data},
                                 hex(block) if isinstance(block, int) else block])])[0]
    return r

def word(v):  # 32-byte hex int
    return "0x" + format(v, "064x")

def addr_word(a):
    return "0x" + a.lower().replace("0x", "").rjust(64, "0")

def sel(sig):
    import hashlib
    return "0x" + hashlib.sha3_256(b"").hexdigest()[:0]  # placeholder

def topic0(sig):
    """Full 32-byte keccak hash of an event signature."""
    try:
        from Crypto.Hash import keccak as _k
        h = _k.new(digest_bits=256); h.update(sig.encode()); return "0x" + h.hexdigest()
    except Exception:
        pass
    try:
        import sha3
        k = sha3.keccak_256(); k.update(sig.encode()); return "0x" + k.hexdigest()
    except Exception:
        pass
    return "0x" + _keccak256(sig.encode()).hex()

def selector(sig):
    # keccak via eth_hash if available else pure-python fallback
    try:
        from Crypto.Hash import keccak as _k  # pycryptodome
        h = _k.new(digest_bits=256); h.update(sig.encode()); return "0x" + h.hexdigest()[:8]
    except Exception:
        pass
    try:
        import sha3  # pysha3
        k = sha3.keccak_256(); k.update(sig.encode()); return "0x" + k.hexdigest()[:8]
    except Exception:
        pass
    # minimal keccak-256 implementation
    return "0x" + _keccak256(sig.encode()).hex()[:8]

def _keccak256(data: bytes) -> bytes:
    # compact pure-python keccak-f[1600]
    RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
          0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
          0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
          0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
          0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
          0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
    R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
    rate = 136
    M = bytearray(data)
    M.append(0x01)
    while len(M) % rate != 0: M.append(0)
    M[-1] ^= 0x80
    S = [0]*25
    def rol(x,n): return ((x << n) | (x >> (64-n))) & 0xFFFFFFFFFFFFFFFF
    for off in range(0, len(M), rate):
        blk = M[off:off+rate]
        for i in range(rate//8):
            S[i] ^= int.from_bytes(blk[i*8:i*8+8], 'little')
        for rnd in range(24):
            C = [S[x] ^ S[x+5] ^ S[x+10] ^ S[x+15] ^ S[x+20] for x in range(5)]
            D = [C[(x-1) % 5] ^ rol(C[(x+1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5): S[x+5*y] ^= D[x]
            B = [0]*25
            for x in range(5):
                for y in range(5):
                    B[y + 5*((2*x+3*y) % 5)] = rol(S[x+5*y], R[x][y])
            for x in range(5):
                for y in range(5):
                    S[x+5*y] = B[x+5*y] ^ ((~B[(x+1) % 5 + 5*y]) & B[(x+2) % 5 + 5*y])
            S[0] ^= RC[rnd]
    return b''.join(s.to_bytes(8,'little') for s in S)[:32]
