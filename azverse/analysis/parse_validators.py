#!/usr/bin/env python3
"""Decode ValidatorsAdded + brute-force validator powers against the on-chain hash. Keyless."""
import json, os
D = os.path.dirname(os.path.abspath(__file__))

# keccak256 (pure python fallback, same as parse_roles)
try:
    from Crypto.Hash import keccak as _k
    def keccak256(b: bytes) -> bytes:
        h = _k.new(digest_bits=256); h.update(b); return h.digest()
except Exception:
    import struct
    def _keccak256(data: bytes) -> bytes:
        RC = [0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,
              0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,
              0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,
              0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,
              0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,
              0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008]
        R = [[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]]
        def rol(x,n): return ((x<<n)|(x>>(64-n)))&0xFFFFFFFFFFFFFFFF
        def f(A):
            for rnd in range(24):
                C=[A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4] for x in range(5)]
                D=[C[(x-1)%5]^rol(C[(x+1)%5],1) for x in range(5)]
                for x in range(5):
                    for y in range(5): A[x][y]^=D[x]
                B=[[0]*5 for _ in range(5)]
                for x in range(5):
                    for y in range(5): B[y][(2*x+3*y)%5]=rol(A[x][y],R[x][y])
                for x in range(5):
                    for y in range(5): A[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y])
                A[0][0]^=RC[rnd]
            return A
        rate=136
        data=bytearray(data); data.append(1)
        while len(data)%rate!=0: data.append(0)
        data[-1]|=0x80
        A=[[0]*5 for _ in range(5)]
        for off in range(0,len(data),rate):
            blk=data[off:off+rate]
            for i in range(rate//8):
                x,y=i%5,i//5
                A[x][y]^=struct.unpack("<Q",blk[i*8:i*8+8])[0]
            A=f(A)
        return b"".join(struct.pack("<Q",A[i%5][i//5]) for i in range(17))[:32]
    def keccak256(b: bytes) -> bytes:
        return _keccak256(b)

def enc_array(vals):
    """abi.encode(ValidatorInfo[] validators) where ValidatorInfo=(address,uint256).
    Dynamic array encoding: offset(32) | len(32) | tuples..."""
    n = len(vals)
    out = (32).to_bytes(32, "big") + n.to_bytes(32, "big")
    for (a, p) in vals:
        out += bytes(12) + bytes.fromhex(a[2:]) + p.to_bytes(32, "big")
    return out

logs = json.load(open(os.path.join(D, "logs_ValidatorsAdded.json")))
for l in logs:
    d = l["data"][2:]
    hashv = d[0:64]
    off = int(d[64:128], 16) * 2  # hex-string index
    count = int(d[128:192], 16)
    total_power = int(d[192:256], 16)
    req_power = int(d[256:320], 16)
    arrlen = int(d[off:off+64], 16)
    addrs = []
    for i in range(arrlen):
        w = d[off+64+i*64: off+128+i*64]
        addrs.append("0x" + w[24:])
    print(f"block={l['blockNumber']} tx={l['transactionHash']}")
    print(f"  hash={hashv}")
    print(f"  count={count} totalPower={total_power} requiredPower={req_power}")
    print(f"  validators({arrlen})={addrs}")
    # brute force powers summing to total_power
    found = []
    import itertools
    n = len(addrs)
    def rec(prefix, rem):
        if len(prefix) == n - 1:
            p = prefix + [rem]
            if all(x > 0 for x in p):
                h = keccak256(enc_array(list(zip(addrs, p))))
                if h.hex() == hashv:
                    found.append(p)
            return
        for x in range(1, rem - (n - len(prefix) - 1)):
            rec(prefix + [x], rem - x)
    if n <= 5 and total_power <= 200:
        rec([], total_power)
    print(f"  POWER CANDIDATES: {found}")
