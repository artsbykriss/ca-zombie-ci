#!/usr/bin/env python3
"""Parse AZverse logs: roles, tokens, validators, withdrawals. Keyless."""
import json, os

D = os.path.dirname(os.path.abspath(__file__))
def load(n): return json.load(open(os.path.join(D, f"logs_{n}.json")))

ROLE_NAMES = {
    "0x0000000000000000000000000000000000000000000000000000000000000000": "DEFAULT_ADMIN",
    "0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929": "OPERATOR",
    "0x9ac8e1b1a9a1e0b2a1b6c9b83c1c8db0a56e5a63aa2b62ee12c1d2f2b1b2b2b2": None,
}
# compute names from known constants
import hashlib
from eth_utils import keccak  # may not exist; fallback below

def k(s): return "0x" + hashlib.new("sha3_256").hexdigest() if False else None

# Use plain keccak via pysha3-like: use web3? Not available. Use fixed known hashes computed with cast earlier? Compute here with pure python keccak if available.
try:
    from Crypto.Hash import keccak as _k
    def keccak256(b: bytes) -> str:
        h = _k.new(digest_bits=256); h.update(b); return "0x" + h.hexdigest()
except Exception:
    # minimal keccak implementation (from pyethereum, compact)
    def _keccak256(data: bytes) -> bytes:
        import struct
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
        out=b"".join(struct.pack("<Q",A[i%5][i//5]) for i in range(17))[:32]
        return out
    def keccak256(b: bytes) -> str:
        return "0x" + _keccak256(b).hex()

def role_name(r: str) -> str:
    mapping = {
        keccak256(b"DEFAULT_ADMIN_ROLE"): "DEFAULT_ADMIN_ROLE",
        keccak256(b"OPERATOR_ROLE"): "OPERATOR_ROLE",
        keccak256(b"VALIDATOR_ROLE"): "VALIDATOR_ROLE",
        keccak256(b"TOKEN_ROLE"): "TOKEN_ROLE",
        keccak256(b"ADMIN_ROLE"): "ADMIN_ROLE",
        keccak256(b"DEPOSIT_ROLE"): "DEPOSIT_ROLE",
        keccak256(b"PAUSE_ROLE"): "PAUSE_ROLE",
        keccak256(b"UPGRADE_ROLE"): "UPGRADE_ROLE",
    }
    return mapping.get(r, r)

def topic_addr(t): return "0x" + t[-40:]

def bn(x):
    v = x["blockNumber"]
    return int(v, 16) if isinstance(v, str) and v.startswith("0x") else int(v)

print("=== ROLE GRANTS (role, account, sender, block, tx) ===")
holders = {}
for l in sorted(load("RoleGranted"), key=lambda x: bn(x)):
    role = role_name(l["topics"][1]); acct = topic_addr(l["topics"][2]).lower()
    holders.setdefault(role, set()).add(acct)
    print(f"{l['blockNumber']:>10} {role:<20} {acct} sender={topic_addr(l['topics'][3])} tx={l['transactionHash'][:18]}")

print("\n=== ROLE REVOKES ===")
for l in sorted(load("RoleRevoked"), key=lambda x: bn(x)):
    role = role_name(l["topics"][1]); acct = topic_addr(l["topics"][2]).lower()
    holders.get(role, set()).discard(acct)
    print(f"{l['blockNumber']:>10} {role:<20} {acct} sender={topic_addr(l['topics'][3])} tx={l['transactionHash'][:18]}")

print("\n=== CURRENT ROLE HOLDERS (from events) ===")
for r, s in sorted(holders.items()):
    print(f"{r:<20} {sorted(s)}")

print("\n=== TOKENS ADDED ===")
for l in sorted(load("TokenAdded"), key=lambda x: bn(x)):
    d = l["data"][2:]
    token = topic_addr(l["topics"][1]) if len(l["topics"]) > 1 else "0x" + d[:64][24:]
    hardcap = int(d[64:128], 16); refill = int(d[128:192], 16)
    print(f"{l['blockNumber']:>10} token={token} hardCapRatioBps={hardcap} refillRateMps={refill}")

print("\n=== VALIDATORS ADDED ===")
for l in load("ValidatorsAdded"):
    d = l["data"][2:]
    print(f"block={l['blockNumber']} hash={l['topics'][1]}")
    print("  raw data:", d)
    # decode: bytes32 hash, address[] (offset), count, totalPower, requiredPower
    # non-indexed: bytes32 hash; address[] validatorAddresses; uint256 count; uint256 totalPower; uint256 requiredPower
    hashv = d[0:64]
    off = int(d[64:128], 16) * 2  # in hex chars, relative to data start
    count = int(d[128:192], 16)
    total_power = int(d[192:256], 16)
    req_power = int(d[256:320], 16)
    arrlen = int(d[off:off+64], 16)
    addrs = []
    for i in range(arrlen):
        w = d[off+64+i*64: off+128+i*64]
        addrs.append("0x" + w[24:])
    print(f"  hash={hashv} count={count} totalPower={total_power} requiredPower={req_power}")
    print(f"  validators({arrlen})={addrs}")

print("\n=== UPGRADED ===")
for l in load("Upgraded"):
    print(f"block={l['blockNumber']} impl={topic_addr(l['topics'][1])} tx={l['transactionHash']}")
