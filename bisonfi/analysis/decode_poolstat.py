#!/usr/bin/env python3
"""Decode BisonFi POOLSTAT layout: locate pubkeys, u64s, vaults (read-only)."""
import base64, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''
def b58e(b):
    n=int.from_bytes(b,'big'); out=''
    while n: n,r2=divmod(n,58); out=ALPHA[r2]+out
    for c in b:
        if c==0: out='1'+out
        else: break
    return out

states={s["pubkey"]:base64.b64decode(s["data_b64"]) for s in json.load(open(os.path.join(OUT,"pool-states-2048.json")))}

CUR="8FnX3xo2yYw3EUE6w3nQA4GfXGS9wpK6oj3veJpbFzLo"
OLD="51FQwjrvo8J8zXUaKyAznJ5NYpoiTCuqAqCu3HAMB9NZ"
KNOWN={
 "FxGiN5NkigicwrnFshZEAUH9C13yrBALmgYxA9x8sfnQ":"old vault WSOL",
 "6DMF4t6Ks8yXhG8K3rrTAeNYrqNrr1DwewHvBmH3a3FX":"old vault USDC",
 "ATRsNGv2nDw7hSMfkUTBoVUDsFDwN7po7KbecyiGWNB4":"recent tx acct10",
 "2Y7HATmn9aJBcxCskE5V2U2epmjvkZmB51zTJBbhj4cU":"recent tx acct2",
 "BgWUvrBhWHV1AALA6Bkk65bLzMRMLVFXGjdGeTaQx4VM":"recent tx acct11",
 "7Pp2nxw9tMT7cZQideXQrHs9dBK9hNKzLbG7zj4fjhWo":"recent tx acct7",
 "J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv":"recent extra acct30",
 "6b5LxeDVxqCGAhZjjjgieGP71c5GBt2cBwiafCFX6NMU":"quote-signer poolstate?",
 "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":"USDC mint",
 "So11111111111111111111111111111111111111112":"WSOL mint",
}
def find(big, needle):
    out=[]; i=0
    while True:
        i=big.find(needle,i)
        if i<0: return out
        out.append(i); i+=1

for name in (CUR, OLD):
    d=states[name]
    print("=====",name, "name_field:", d[256:272])
    for a,label in KNOWN.items():
        nb=b58d(a)
        hits=find(d,nb)
        if hits: print(f"   pubkey {a} ({label}) at offsets {hits}")
    # u64 fields in first 200 bytes
    import struct
    for off in range(12, 200, 4):
        v=struct.unpack_from("<I", d, off)[0]
        v8=struct.unpack_from("<Q", d, off)[0] if off+8<=len(d) else 0
        if v not in (0,):
            pass
    # print 8-byte aligned-ish dump with u64 interpretation
    print("   u64 fields (offset: value):")
    for off in range(8, 192, 8):
        v=struct.unpack_from("<Q", d, off)[0]
        print(f"     {off:4d}: {v:20d} 0x{v:016x}")

# vault enumeration for both pool states
for ps in (CUR, OLD):
    r=rpc("getTokenAccountsByOwner",[ps,{"programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},{"encoding":"jsonParsed","commitment":"confirmed"}])
    res=r.get("result")
    if res is None:
        print("getTokenAccountsByOwner", ps, "ERR", r.get("error")); continue
    print(f"\n=== vaults owned by {ps}: {len(res['value'])}")
    for v in res["value"]:
        info=v["account"]["data"]["parsed"]["info"]
        print("   ", v["pubkey"], info["mint"], info["tokenAmount"]["uiAmountString"])
