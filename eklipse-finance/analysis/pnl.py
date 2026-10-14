#!/usr/bin/env python3
"""Attack P&L using ON-CHAIN view functions only:
 base.calculateTokenAmount([kdai,0,0], true) -> LP minted
 meta.calculateSwap(0,1,lp) -> pUSD out
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18
BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

def enc(sig4, *args):
    d = sig4
    for a in args:
        if isinstance(a, int): d += hex(a)[2:].rjust(64, "0")
        else: raise ValueError(a)
    return d

def call(to, sig4, *args):
    for _ in range(6):
        r = eth_call(to, enc(sig4, *args), BH)
        if isinstance(r, str): return int(r, 16)
    raise RuntimeError("fail")

def call_arr(to, sig4, arr, flag):
    """for calculateTokenAmount(uint256[] amounts, bool deposit)"""
    d = sig4 + hex(0x40)[2:].rjust(64, "0") + hex(flag)[2:].rjust(64, "0")
    d += hex(len(arr))[2:].rjust(64, "0")
    for a in arr: d += hex(a)[2:].rjust(64, "0")
    for _ in range(6):
        r = eth_call(to, d, BH)
        if isinstance(r, str): return int(r, 16)
    raise RuntimeError("fail arr")

base = "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4"
meta = "0xe59234EeDC854b3b37D48EFd8a529069C3990F83"
baseLP = "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49"
KDAI = "0x5c74070fdea071359b86082bd9f9b3deaafbe32b"
oUSDT = "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167"
oUSDC = "0x754288077d0ff82af7a5317c7cb8c444d421d103"
pUSD = "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4"

base_vp = call(base, "0xe25aa5fa")
base_supply = call(baseLP, "0x18160ddd")
meta_vp = call(meta, "0xe25aa5fa")
print(f"base vp={base_vp/1e18:.9f} supply={base_supply/1e18:.3f}  meta vp={meta_vp/1e18:.9f}", flush=True)

prices = {"KDAI": 0.09635042744861741, "oUSDT": 0.10509040883124349, "oUSDC": 0.29619875144537683, "pUSD": 1.0001479453339572}

print("\n=== scenario A: deposit KDAI -> mint LP -> swap LP for pUSD (meta) ===")
print(f"{'KDAI in':>12} {'LP minted':>12} {'pUSD out':>12} {'KDAI cost$':>10} {'pUSD val$':>10} {'profit$':>10}")
for kdai in [100, 500, 1000, 2000, 5000, 8000, 10000, 15000, 20000, 30000, 50000]:
    dx = int(kdai * 1e18)
    lp = call_arr(base, "0xe6ab2806", [dx, 0, 0], 1)
    out = call(meta, "0xa95b089f", 0, 1, lp)
    cost = kdai * prices["KDAI"]
    val = out / 1e18 * prices["pUSD"]
    print(f"{kdai:>12} {lp/1e18:>12.3f} {out/1e18:>12.3f} {cost:>10.2f} {val:>10.2f} {val-cost:>10.2f}", flush=True)

print("\n=== scenario B: deposit oUSDC -> mint LP -> swap LP for pUSD (meta) ===")
for amt in [100, 500, 1000, 1700, 3000, 5000]:
    dx = int(amt * 1e6)
    lp = call_arr(base, "0xe6ab2806", [0, 0, dx], 1)
    out = call(meta, "0xa95b089f", 0, 1, lp)
    cost = amt * prices["oUSDC"]
    val = out / 1e18 * prices["pUSD"]
    print(f"{amt:>12} {lp/1e18:>12.3f} {out/1e18:>12.3f} {cost:>10.2f} {val:>10.2f} {val-cost:>10.2f}", flush=True)

print("\n=== scenario C: deposit oUSDT -> mint LP -> swap LP for pUSD (meta) ===")
for amt in [1000, 5000, 10000, 20000, 33000]:
    dx = int(amt * 1e6)
    lp = call_arr(base, "0xe6ab2806", [0, dx, 0], 1)
    out = call(meta, "0xa95b089f", 0, 1, lp)
    cost = amt * prices["oUSDT"]
    val = out / 1e18 * prices["pUSD"]
    print(f"{amt:>12} {lp/1e18:>12.3f} {out/1e18:>12.3f} {cost:>10.2f} {val:>10.2f} {val-cost:>10.2f}", flush=True)
