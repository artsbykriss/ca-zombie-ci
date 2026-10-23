#!/usr/bin/env python3
"""Verify the BulbaSwap V3 factory embeds the CANONICAL Uniswap v3-core v1.0.0
pool init code, by extracting it from the verified creation bytecode and
hashing it (pure-python keccak-256, no third-party deps).
Keyless public endpoints only."""
import json, subprocess, sys

EXPLORER = "https://explorer-api.morphl2.io/api"
FACTORY = "0xff8578c2949148a6f19b7958ae86caab2779cddd"
CANONICAL = "0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54"
MARKER = "6158c8806107038339019056fe"   # PUSH2 len; DUP1; PUSH2 off; DUP4; CODECOPY; ...; JUMP; INVALID
POOL_INIT_LEN = 0x58C8                   # 22728 bytes

# ---------------- pure-python keccak-256 ----------------
_RC = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
]
_R = [
    [0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61],
    [28, 55, 25, 21, 56], [27, 20, 39, 8, 14],
]
_M = (1 << 64) - 1

def _rot(x, n):
    n %= 64
    return ((x << n) | (x >> (64 - n))) & _M

def _keccak_f(a):
    for rnd in range(24):
        c = [a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4] for x in range(5)]
        d = [c[(x - 1) % 5] ^ _rot(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(5):
                a[x][y] ^= d[x]
        b = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                b[y][(2 * x + 3 * y) % 5] = _rot(a[x][y], _R[x][y])
        for x in range(5):
            for y in range(5):
                a[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y])
        a[0][0] ^= _RC[rnd]
    return a

def keccak256(data: bytes) -> bytes:
    rate = 136
    a = [[0] * 5 for _ in range(5)]
    data = bytearray(data)
    data.append(0x01)
    while len(data) % rate != 0:
        data.append(0x00)
    data[-1] ^= 0x80
    for off in range(0, len(data), rate):
        block = data[off:off + rate]
        for i in range(rate // 8):
            lane = int.from_bytes(block[i * 8:i * 8 + 8], "little")
            a[i % 5][i // 5] ^= lane
        a = _keccak_f(a)
    out = b""
    for i in range(4):
        out += a[i % 5][i // 5].to_bytes(8, "little")
    return out[:32]
# ---------------------------------------------------------

def curl(url):
    return subprocess.run(["curl", "-s", url], capture_output=True, text=True, timeout=90).stdout

def main():
    d = json.loads(curl(f"{EXPLORER}?module=contract&action=getcontractcreation&contractaddresses={FACTORY}"))
    rec = d["result"][0]
    cb = rec["creationBytecode"][2:]
    i = cb.find(MARKER)
    assert i >= 0, "pool init-code marker not found"
    start = i + len(MARKER)
    init = cb[start:start + 2 * POOL_INIT_LEN]
    assert len(init) == 2 * POOL_INIT_LEN, "truncated pool init code"
    kh = "0x" + keccak256(bytes.fromhex(init)).hex()
    print("factory            :", FACTORY)
    print("deployer           :", rec["contractCreator"])
    print("pool init-code len :", POOL_INIT_LEN, "bytes")
    print("extracted hash     :", kh)
    print("canonical v1.0.0   :", CANONICAL)
    print("MATCH" if kh.lower() == CANONICAL else "MISMATCH")
    if kh.lower() != CANONICAL:
        sys.exit(1)

if __name__ == "__main__":
    main()
