#!/usr/bin/env python3
"""Independent RPC helpers for Archer verification. READ-ONLY."""
import json, urllib.request, base64, hashlib, time

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]

def rpc(method, params, endpoint=None, retries=4):
    eps = [endpoint] if endpoint else ENDPOINTS
    last = None
    for ep in eps:
        for attempt in range(retries):
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    out = json.loads(r.read().decode())
                if "error" in out:
                    last = out
                    time.sleep(1.0)
                    continue
                return out.get("result")
            except Exception as e:
                last = {"error": str(e)}
                time.sleep(1.0)
                continue
    return last

def b58encode(b: bytes) -> str:
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = alphabet[r] + s
    for c in b:
        if c == 0:
            s = "1" + s
        else:
            break
    return s or "1"

def b58decode(s: str) -> bytes:
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = 0
    for ch in s:
        n = n * 58 + alphabet.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = 0
    for ch in s:
        if ch == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b

def disc_b58(s: str) -> str:
    return b58encode(s.encode())

if __name__ == "__main__":
    print("ACHRMKR1 ->", disc_b58("ACHRMKR1"))
    print("ACHRMKT1 ->", disc_b58("ACHRMKT1"))
