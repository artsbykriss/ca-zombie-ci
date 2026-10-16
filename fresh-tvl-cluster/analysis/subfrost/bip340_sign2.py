#!/usr/bin/env python3
"""Clean BIP340 signer with inline verification. Fork-only TEST key."""
import hashlib, subprocess

P  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
N  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
TAG = bytes.fromhex("7bb52d7a9fef58323eb1bf7a407db382d2f3f2d81bb1224f49fe518f6d48d37c")

def inv(a, m=P): return pow(a, m-2, m)
def ec_add(p1, p2):
    if p1 is None: return p2
    if p2 is None: return p1
    x1,y1 = p1; x2,y2 = p2
    if x1==x2 and (y1+y2) % P == 0: return None
    lam = (3*x1*x1)*inv(2*y1) % P if p1 == p2 else (y2-y1)*inv(x2-x1) % P
    x3 = (lam*lam - x1 - x2) % P
    return (x3, (lam*(x1-x3) - y1) % P)
def mul(k, pt):
    r = None
    while k:
        if k & 1: r = ec_add(r, pt)
        pt = ec_add(pt, pt); k >>= 1
    return r

def challenge(rx, px, m):  # bytes m32
    return int(hashlib.sha256(TAG+TAG+rx.to_bytes(32,'big')+px.to_bytes(32,'big')+m).hexdigest(),16) % N

def sign(d, px, m, kseed):
    k = int(hashlib.sha256(b"H17SUBK2"+kseed).hexdigest(),16) % N
    while True:
        R = mul(k, (GX,GY))
        if R is not None:
            k2 = k if R[1] % 2 == 0 else (N-k)
            rx = R[0]
            e = challenge(rx, px, m)
            s = (k2 + e*d) % N
            if s != 0:
                return rx, s
        k = (k+1) % N

def verify(px, Rx, s, m):
    Rm = (px, pow((px**3+7) % P, (P+1)//4, P))
    if Rm[1] & 1: Rm = (Rm[0], P - Rm[1])
    e = challenge(Rx, px, m)
    R = ec_add(mul(s, (GX,GY)), mul((N-e) % N, Rm))
    return R is not None and R[1] % 2 == 0 and R[0] == Rx

def cast_keccak(h): return subprocess.run(["cast","keccak",h],capture_output=True,text=True).stdout.strip()
def b32(x): return f"{x:064x}"

VAULT    = "0x95779E7E1C943042255B8a78273fe6DE4823CF06"
ATTACKER = "0x000000000000000000000000000000000000A77A"
CHAINID  = 1
NONCE    = 777000
SEL      = "40deaa6d"  # withdrawFromBridge(uint256,uint8,uint256,address,bytes)

# key: derive from a fixed seed string, then normalize to even-y
d = int(hashlib.sha256(b"H17-SUBFROST-TESTKEY").hexdigest(),16) % N
Pp = mul(d,(GX,GY))
if Pp[1] & 1: d = N - d; Pp = mul(d,(GX,GY))
px = Pp[0]
assert Pp[1] % 2 == 0, "pubkey must have even y"

def enc_withdraw(bn, aid, amt):
    return SEL + b32(bn) + b32(aid) + b32(amt) + b32(int(ATTACKER,16)) + b32(0xa0) + b32(0)
def enc_msg(data_hex, nonce):
    dbytes = bytes.fromhex(data_hex); padd = dbytes.hex() + "00"*((32-len(dbytes)%32)%32)
    return b32(0x80) + b32(nonce) + b32(CHAINID) + b32(int(VAULT,16)) + b32(len(dbytes)) + padd

print("// d(fake):", hex(d))
print("// px     :", hex(px))
cases = [("W1",0x51001,0,100_000_000,NONCE),
         ("W2",0x51002,1,900_000_000,NONCE+1),
         ("REPLAY",0x51001,0,100_000_000,NONCE+2)]
data_hexes = {}
for name,bn,aid,amt,nonce in cases:
    data = enc_withdraw(bn,aid,amt)
    m = cast_keccak("0x"+enc_msg(data,nonce))
    mbytes = bytes.fromhex(m[2:])
    rx, s = sign(d, px, mbytes, mbytes)
    assert verify(px, rx, s, mbytes), "SELF-VERIFY FAILED"
    data_hexes[name] = (data, nonce)
    print(f"// {name}: nonce={nonce} bridgeNonce={hex(bn)} assetId={aid} amount={amt} msg={m} verify=OK")
    print(f'    uint256 internal constant {name}_RX = 0x{b32(rx)};')
    print(f'    uint256 internal constant {name}_S  = 0x{b32(s)};')
import json
json.dump({k:{"data":"0x"+v[0],"nonce":v[1]} for k,v in data_hexes.items()}, open("bip340_testvectors.json","w"), indent=1)
