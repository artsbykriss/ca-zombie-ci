#!/usr/bin/env python3
"""Minimal stdlib JSON-RPC client for read-only on-chain screens (no keys, public endpoints only)."""
import json, urllib.request, time

RPCS = {
    "ethereum": "https://ethereum-rpc.publicnode.com",
    "bsc": "https://bsc-rpc.publicnode.com",
    "aurora": "https://mainnet.aurora.dev",
    "viction": "https://rpc.viction.xyz",
    "opbnb": "https://opbnb-rpc.publicnode.com",
    "bttc": "https://rpc.bt.io",
    "hyperevm": "https://rpc.hyperliquid.xyz/evm",
    "sonic": "https://rpc.soniclabs.com",
    "base": "https://base-rpc.publicnode.com",
}

def rpc(chain, method, params, retries=3):
    url = RPCS[chain]
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (research; read-only)",
            })
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if "error" in d:
                return {"error": d["error"]}
            return d.get("result")
        except Exception as e:
            last = str(e)
            time.sleep(1 + i)
    return {"error": last}

def batch(chain, calls, chunk=10):
    """calls: list of (method, params). Returns list of results in order."""
    out = []
    for i in range(0, len(calls), chunk):
        sub = calls[i:i+chunk]
        payload = [{"jsonrpc": "2.0", "id": j, "method": m, "params": p} for j, (m, p) in enumerate(sub)]
        body = json.dumps(payload).encode()
        url = RPCS[chain]
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, data=body, headers={
                    "Content-Type": "application/json",
                    "User-Agent": "Mozilla/5.0 (research; read-only)",
                })
                with urllib.request.urlopen(req, timeout=40) as r:
                    d = json.load(r)
                res = {x["id"]: x.get("result", x.get("error")) for x in d}
                out.extend(res.get(j) for j in range(len(sub)))
                break
            except Exception as e:
                if attempt == 2:
                    out.extend(["ERR:" + str(e)] * len(sub))
                time.sleep(1 + attempt)
    return out

def blocknum(chain):
    return rpc(chain, "eth_blockNumber", [])

def getcode(chain, addr):
    return rpc(chain, "eth_getCode", [addr, "latest"])

def balance(chain, addr):
    return rpc(chain, "eth_getBalance", [addr, "latest"])

def call(chain, to, data):
    return rpc(chain, "eth_call", [{"to": to, "data": data}, "latest"])

def selector(sig):
    import hashlib
    return "0x" + hashlib.sha3_256(sig.encode()).hexdigest()[:8] if False else "0x" + __import__("hashlib").new("sha3_256", b"").hexdigest()[:0]

# --- minimal keccak (for selector computation) ---
_KECCAK_RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
_KECCAK_ROT = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]

def _keccak_f(A):
    for rnd in range(24):
        C = [A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4] for x in range(5)]
        D = [C[(x-1)%5]^(((C[(x+1)%5]<<1)|(C[(x+1)%5]>>63))&0xFFFFFFFFFFFFFFFF) for x in range(5)]
        for x in range(5):
            for y in range(5):
                A[x][y] ^= D[x]
        B = [[0]*5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                B[y][(2*x+3*y)%5] = ((A[x][y]<<_KECCAK_ROT[x][y])|(A[x][y]>>(64-_KECCAK_ROT[x][y])))&0xFFFFFFFFFFFFFFFF
        for x in range(5):
            for y in range(5):
                A[x][y] = B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])
        A[0][0] ^= _KECCAK_RC[rnd]
    return A

def keccak256(data: bytes) -> bytes:
    rate = 136
    P = bytearray(data)
    P.append(0x01)
    while len(P) % rate != 0:
        P.append(0x00)
    P[-1] |= 0x80
    A = [[0]*5 for _ in range(5)]
    for off in range(0, len(P), rate):
        blk = P[off:off+rate]
        for i in range(rate//8):
            lane = int.from_bytes(blk[i*8:(i+1)*8], "little")
            A[i%5][i//5] ^= lane
        A = _keccak_f(A)
    out = b""
    for i in range(4):
        out += A[i%5][i//5].to_bytes(8, "little")
    return out

def sel(sig: str) -> str:
    return "0x" + keccak256(sig.encode()).hex()[:8]

def enc_uint(v):
    return format(v, "064x")

def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

if __name__ == "__main__":
    print("sel transfer(address,uint256)", sel("transfer(address,uint256)"))
    print("sel balanceOf(address)", sel("balanceOf(address)"))
    print("sel skim(address)", sel("skim(address)"))
    print("sel totalSupply()", sel("totalSupply()"))
