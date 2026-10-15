#!/usr/bin/env python3
"""Tiny keyless JSON-RPC helper for Kava EVM (batch eth_call). Read-only."""
import json, sys, urllib.request

RPCS = ["https://evm.kava.io", "https://kava-evm-rpc.publicnode.com"]

def rpc(method, params, url=None, timeout=30):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for u in ([url] if url else RPCS):
        try:
            req = urllib.request.Request(u, data=body, headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            last = out
        except Exception as e:
            last = e
    raise RuntimeError(f"rpc {method} failed: {last}")

def batch(calls, block="latest", url=None, chunk=40):
    """calls: list of (to, data). returns list of hex results."""
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i+chunk]
        body = [{"jsonrpc": "2.0", "id": j, "method": "eth_call",
                 "params": [{"to": to, "data": data}, block]} for j, (to, data) in enumerate(part)]
        payload = json.dumps(body).encode()
        got = None
        for u in ([url] if url else RPCS):
            try:
                req = urllib.request.Request(u, data=payload, headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
                with urllib.request.urlopen(req, timeout=60) as r:
                    got = json.loads(r.read())
                break
            except Exception as e:
                got = None
        if got is None:
            raise RuntimeError("batch failed")
        byid = {x["id"]: x for x in got}
        for j in range(len(part)):
            x = byid[j]
            out.append(x.get("result") if "result" in x else {"error": x.get("error")})
    return out

def sel(sig):
    """4-byte selector from signature, keccak via eth_hash if available else known map."""
    import hashlib
    # minimal keccak-256 implementation (pure python)
    RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
          0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
          0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
          0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
          0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
          0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
    def rol(x, n): return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF
    def keccak_f(st):
        for rnd in range(24):
            C = [st[x][0]^st[x][1]^st[x][2]^st[x][3]^st[x][4] for x in range(5)]
            D = [C[(x+4)%5]^rol(C[(x+1)%5],1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    st[x][y] ^= D[x]
            B = [[0]*5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    B[y][(2*x+3*y)%5] = rol(st[x][y], [(0,36,3,41,18),(1,44,10,45,2),(62,6,43,15,61),(28,55,25,21,56),(27,20,39,8,14)][x][y])
            for x in range(5):
                for y in range(5):
                    st[x][y] = B[x][y] ^ ((~B[(x+1)%5][y]) & B[(x+2)%5][y])
            st[0][0] ^= RC[rnd]
        return st
    rate = 136
    msg = sig.encode()
    padlen = rate - (len(msg) % rate)
    msg = msg + b'\x01' + b'\x00'*(padlen-2) + b'\x80'
    st = [[0]*5 for _ in range(5)]
    for off in range(0, len(msg), rate):
        blk = msg[off:off+rate]
        for i in range(rate//8):
            x, y = i % 5, i // 5
            st[x][y] ^= int.from_bytes(blk[i*8:i*8+8], 'little')
        st = keccak_f(st)
    h = b''.join(st[x][y].to_bytes(8,'little') for y in range(5) for x in range(5))
    return "0x" + h[:4].hex()

def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")[:64]
def enc_u256(n): return hex(n)[2:].rjust(64,"0")

if __name__ == "__main__":
    print(rpc("eth_blockNumber", []))
    for s in ["underlying()","exchangeRateStored()","exchangeRateCurrent()","totalSupply()","totalBorrows()","totalReserves()","reserveFactorMantissa()","getCash()","comptroller()","interestRateModel()","admin()","accrualBlockNumber()","borrowRatePerBlock()","supplyRatePerBlock()","implementation()"]:
        print(s, sel(s))
