#!/usr/bin/env python3
"""Quantify: meta-pool LP->pUSD extraction curve vs cost of minting base LP.
Uses exact Saddle invariant math validated against on-chain calculateSwap."""
import json, sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18

def getD(xp, a):
    n = len(xp); S = sum(xp)
    if S == 0: return 0
    D = S; Ann = a * n
    for _ in range(256):
        P = D
        for x in xp: P = P * D // x // n
        Dprev = D
        D = (Ann * S + P * n) * D // ((Ann - 1) * D + (n + 1) * P)
        if abs(D - Dprev) <= 1: return D
    return D

def getY_general(xp, a, D, i, x_new_i):
    """Newton for new y at index j != i (n arbitrary, 2-target). Returns new x_j."""
    n = len(xp)
    Ann = a * n
    xs = list(xp); xs[i] = x_new_i
    S_ = sum(xs)
    # solve: Ann*S + D = Ann*D + D^(n+1)/(n^n * prod) for unknown y = x_j
    # => Ann*(S_ + y) + D = Ann*D + D^(n+1)/(n^n * P_other * y)
    # multiply by y: Ann*S_*y + Ann*y^2 + D*y = Ann*D*y + D^(n+1)/(n^n*P_other)
    # => Ann*y^2 + y*(Ann*S_ + D - Ann*D) - D^(n+1)/(n^n*P_other) = 0
    P_other = 1
    for k in range(n):
        if k != i: P_other *= xs[k]
    # note: S_ includes x_new_i but not y; P_other = prod of all except i (i already replaced)
    C = D**(n+1) // (n**n * P_other)
    B = Ann*S_ + D - Ann*D
    # Newton: y^2 + (B/Ann) y - C/Ann = 0
    b = B / Ann; c = C / Ann
    y = D / 1.0
    for _ in range(256):
        yprev = y
        y = (y*y + c) / (2*y + b)
        if abs(y - yprev) <= 1: break
    return y

def solve_meta(n=2):
    pass

def enc(sig4, *args):
    d = sig4
    for a in args:
        d += hex(int(a))[2:].rjust(64, "0")
    return d

BLOCK = int(rpc("eth_blockNumber", []), 16)
print("block", BLOCK, flush=True)

# ---- live state ----
meta = "0xe59234EeDC854b3b37D48EFd8a529069C3990F83"
base = "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4"
def rd(to, sig, *args):
    for _ in range(5):
        r = eth_call(to, enc(sig, *args), hex(BLOCK))
        if isinstance(r, str): return int(r, 16)
    raise RuntimeError(f"rd failed {to} {sig}")
# read balances
def bal(tok, owner):
    for _ in range(5):
        r = eth_call(tok, enc("0x70a08231", int(owner, 16)), hex(BLOCK))
        if isinstance(r, str): return int(r, 16)
    raise RuntimeError(f"bal failed {tok} {owner}")

baseLP = "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49"
pUSD = "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4"
meta_lp_res = bal(baseLP, meta)
meta_pusd_res = bal(pUSD, meta)
meta_vp = rd(meta, "0xe25aa5fa")
meta_A = rd(meta, "0xd46300fd")
meta_supply = rd("0x63c7d72963ed6e0c255835b606bef55ebeb1b5f8", "0x18160ddd")
print(f"meta: LP_res={meta_lp_res/1e18:.6f} pUSD_res={meta_pusd_res/1e18:.6f} vp={meta_vp/1e18:.9f} A={meta_A} metaLP_supply={meta_supply/1e18:.6f}")

KDAI = "0x5c74070fdea071359b86082bd9b3fbdeaafbe32b".replace("fbde","fde0")
KDAI = "0x5c74070fdea071359b86082bd9f9b3deaafbe32b"
oUSDT = "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167"
oUSDC = "0x754288077d0ff82af7a5317c7cb8c444d421d103"
base_toks = [KDAI, oUSDT, oUSDC]
base_bals = [bal(t, base) for t in base_toks]
base_A = rd(base, "0xd46300fd")
base_vp = rd(base, "0xe25aa5fa")
base_supply = rd("0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49", "0x18160ddd")
print(f"base: bals={[b/1e18 for b in base_bals]} A={base_A} vp={base_vp/1e18:.9f} supply={base_supply/1e18:.3f}")

# prices (DefiLlama, USD)
prices = {"KDAI": 0.09635042744861741, "oUSDT": 0.10509040883124349, "oUSDC": 0.29619875144537683, "pUSD": 1.0001479453339572}

# ---- meta extraction curve: dump LP -> pUSD ----
xp = [meta_lp_res * meta_vp // PRECISION, meta_pusd_res]  # scaled LP reserve uses base vp
D = getD(xp, meta_A)
print(f"meta D={D/1e18:.3f} (vp*supply={meta_vp*meta_supply//10**18/1e18:.3f})")

# quadratic solve for n=2
def dy_lp_to_pusd(dx_lp):
    dx_scaled = dx_lp * meta_vp // PRECISION
    x0 = xp[0] + dx_scaled
    x1 = xp[1]
    Ann = meta_A * 2
    # 400y^2 + y(400 x0 - 399D) - D^3/(4 x0) = 0
    Bq = Ann*x0 - (Ann-1)*D
    Cq = D**3 // (4*x0)
    y = (-Bq + math.isqrt(Bq*Bq + 4*Ann*Cq)) // (2*Ann)
    return x1 - y

# validate against on-chain
for dx in [10**17, 10**18, 5*10**18]:
    model = dy_lp_to_pusd(dx)
    onchain = int(eth_call(meta, enc("0xa95b089f", 0, 1, dx), hex(BLOCK)), 16)
    print(f"  validate dx={dx/1e18} LP: model={model/1e18:.6f} onchain={onchain/1e18:.6f}")

# total pUSD out for increasing LP dumps
print("\n-- LP dump curve (meta) --")
for dx_lp in [0.1, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]:
    dx = int(dx_lp * 1e18)
    out = dy_lp_to_pusd(dx)
    marginal = (dy_lp_to_pusd(dx + 10**17) - out) * 10 // 10**18
    print(f"  dump {dx_lp:>8} LP -> {out/1e18:>12.2f} pUSD   marginal={marginal/1e18:.4f} pUSD/LP")
