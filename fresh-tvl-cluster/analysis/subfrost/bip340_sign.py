#!/usr/bin/env python3
"""Precompute BIP340 signatures (test key) for the SubfrostH17Test fork demo.
The vault verifies keccak256(abi.encode(data, nonce, chainid, this)). We sign with a
TEST key; the test vm.store()s the test pubkey into defaultPublicKey slot on the fork.
No real keys involved. Outputs Solidity constants.
"""
import hashlib, subprocess, sys

P  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
N  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
TAG = bytes.fromhex("7bb52d7a9fef58323eb1bf7a407db382d2f3f2d81bb1224f49fe518f6d48d37c")

def inv(a, m=P): return pow(a, m-2, m)
def ec_add(p1, p2):
    if p1 is None: return p2
    if p2 is None: return p1
    x1,y1=p1; x2,y2=p2
    if x1==x2 and (y1+y2)%P==0: return None
    if p1==p2: lam = (3*x1*x1) * inv(2*y1) % P
    else: lam = (y2-y1) * inv(x2-x1) % P
    x3 = (lam*lam - x1 - x2) % P
    return (x3, (lam*(x1-x3) - y1) % P)
def ec_mul(k, pt):
    r=None
    while k:
        if k&1: r=ec_add(r,pt)
        pt=ec_add(pt,pt); k>>=1
    return r

def cast_keccak(hexstr):
    return subprocess.run(["cast","keccak",hexstr],capture_output=True,text=True).stdout.strip()

def cast_sig(sig):
    return subprocess.run(["cast","sig",sig],capture_output=True,text=True).stdout.strip()

def b32(x): return f"{x:064x}"

# --- inputs (must mirror the Solidity test) ---
VAULT   = "0x95779E7E1C943042255B8a78273fe6DE4823CF06"
ATTACKER= "0x000000000000000000000000000000000000A77A"
CHAINID = 1
NONCE   = 777000  # will be vm.store()d into slot 5
WITHDRAW_SEL = cast_sig("withdrawFromBridge(uint256,uint8,uint256,address,bytes)")

def enc_withdraw(bridge_nonce, asset_id, amount, target_addr):
    # head: bridgeNonce, assetId, amount, target, offset(0xa0); tail: script length 0
    return (WITHDRAW_SEL[2:]
            + b32(bridge_nonce) + b32(asset_id) + b32(amount) + b32(int(target_addr,16))
            + b32(0xa0) + b32(0))

def enc_call(data_hex, nonce):
    # abi.encode(bytes data, uint256 nonce, uint256 chainid, address vault)
    d = bytes.fromhex(data_hex)
    n = len(d)
    padded = d.hex() + "00"*((32 - n%32)%32)
    return (b32(0x80) + b32(nonce) + b32(CHAINID) + b32(int(VAULT,16))
            + b32(n) + padded)

def bip340_sign(d, px, msg32):
    e = int(hashlib.sha256(TAG+TAG+bytes.fromhex(b32(px))+b32(int.from_bytes(msg32,"big")).encode() if False else TAG+TAG+bytes.fromhex(b32(px))+msg32).hexdigest(),16) % N
    # deterministic k from message
    k = int(hashlib.sha256(b"H17SUBK" + msg32).hexdigest(),16) % N
    while True:
        R = ec_mul(k, (GX,GY))
        if R is not None:
            rx = R[0]
            if R[1] & 1: k2 = (N - k) % N
            else: k2 = k
            e = int(hashlib.sha256(TAG+TAG+bytes.fromhex(b32(px))+msg32).hexdigest(),16) % N
            s = (k2 + e*d) % N
            if s != 0 and rx < P:
                return rx, s, R
        k = (k+1) % N

# test key
d = 0x5EED10A17C0FFEE0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0 % N
Ppt = ec_mul(d,(GX,GY))
if Ppt[1] & 1:
    d = N - d; Ppt = ec_mul(d,(GX,GY))
px = Ppt[0]
assert Ppt[1] % 2 == 0
print("// TEST PRIVKEY (fork-only fake):", hex(d))
print("// test pubkey x:", hex(px))

cases = [
    ("W1", 0x51001, 0, 100_000_000, ATTACKER, NONCE),      # 100 USDC
    ("W2", 0x51002, 1, 900_000_000, ATTACKER, NONCE+1),    # 900 USDT
    ("REPLAY", 0x51001, 0, 100_000_000, ATTACKER, NONCE+2),# same bridgeNonce 0x51001 again
]
for name, bn, aid, amt, tgt, nonce in cases:
    data = enc_withdraw(bn, aid, amt, tgt)
    enc = enc_call(data, nonce)
    m = cast_keccak("0x"+enc)
    rx, s, R = bip340_sign(d, px, bytes.fromhex(m[2:]))
    print(f"// {name} bridgeNonce={hex(bn)} assetId={aid} amount={amt} nonce={nonce}")
    print(f"//   data={data}")
    print(f"//   msg={m}")
    print(f'    uint256 constant {name}_RX = 0x{b32(rx)};')
    print(f'    uint256 constant {name}_S  = 0x{b32(s)};')
