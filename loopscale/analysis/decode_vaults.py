#!/usr/bin/env python3
"""Decode Exponent StrategyVault accounts (mirrors DefiLlama loopscale-curation adapter decoder)
and isolate the Loopscale-curated vaults + their AUM. Read-only.
"""
import json, base64, struct, urllib.request, sys

RPC = "https://api.mainnet-beta.solana.com"
CURATOR = "bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN"
CURATOR_BYTES = None  # set below

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n = 0
    for ch in s:
        n = n * 58 + ALPH.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + b

CURATOR_BYTES = b58d(CURATOR)

def b58e(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = ALPH[r] + out
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + out

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "research"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r)

class C:
    def __init__(self, d):
        self.d = d; self.o = 0
    def u8(self):
        v = self.d[self.o]; self.o += 1; return v
    def u32(self):
        v = struct.unpack_from("<I", self.d, self.o)[0]; self.o += 4; return v
    def u64(self):
        v = struct.unpack_from("<Q", self.d, self.o)[0]; self.o += 8; return v
    def skip(self, n):
        self.o += n
    def pk(self):
        v = b58e(self.d[self.o:self.o+32]); self.o += 32; return v
    def vec(self, fn):
        return [fn() for _ in range(self.u32())]

def price_id(c):
    k = c.u8()
    if k == 0: c.skip(8)
    elif k == 1: c.skip(c.u32() * 8)
    else: raise ValueError(f"PriceId {k}")

def strat_pos(c):
    k = c.u8()
    if k == 0: c.skip(32+4+32); c.skip(c.u32()*4); price_id(c); price_id(c); c.skip(32)
    elif k == 1: c.skip(32); c.vec(lambda: (c.skip(32), price_id(c), c.skip(8)))
    elif k == 2:
        if c.u8() != 0: raise ValueError("obl")
        c.skip(32+32); price_id(c); c.vec(lambda: (c.skip(32), price_id(c))); c.skip(c.u32()*65); c.skip(1)
    elif k in (3,4): c.skip(32+32); price_id(c); price_id(c)
    elif k in (5,6,8): c.skip(32)
    elif k == 7: c.skip(32+32)
    elif k == 9: c.skip(32+8)
    else: raise ValueError(f"StrategyPosition {k}")
    return k

def decode(data):
    c = C(data)
    assert data[:8] == bytes([98,228,39,201,116,210,39,11]), "disc"
    c.o = 8
    c.skip(32+32+32)  # navAumCircuitBreakerState, squadsSettings, squadsVault
    c.vec(lambda: (c.skip(32), price_id(c), c.skip(32+32+8), c.skip(c.u32()*8)))
    underlying = c.pk()
    c.skip(32+32+2+32+32+1)
    status = c.u8()
    c.skip(8)
    aum = c.u64() + c.u64()
    c.skip(72)
    positions = c.vec(lambda: strat_pos(c))
    c.skip(8+8)
    managers = c.vec(lambda: c.pk())
    curators = c.vec(lambda: c.pk())
    return dict(underlying=underlying, status=status, aum=aum, positions=positions,
                managers=managers, curators=curators)

if __name__ == "__main__":
    accs = rpc("getProgramAccounts", ["sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD", {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58e(bytes([98,228,39,201,116,210,39,11]))}}],
    }])["result"]
    rows = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        if CURATOR_BYTES not in raw:
            continue
        try:
            d = decode(raw)
        except Exception as e:
            rows.append(dict(pubkey=a["pubkey"], error=str(e))); continue
        if CURATOR not in d["curators"]:
            continue
        rows.append(dict(pubkey=a["pubkey"], **d))
    print(json.dumps(rows, indent=1))
    print("loopscale-curated vaults:", len(rows))
    json.dump(rows, open("/home/heisenberg/CA/loopscale/analysis/loopscale_vaults.json","w"), indent=1)
