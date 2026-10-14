#!/usr/bin/env python3
"""Precise attack economics: base-pool LP mint cost vs meta-pool LP->pUSD payout.
All reads at one pinned block. Saddle invariant math validated on-chain."""
import json, sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18
BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

def enc(sig4, *args):
    d = sig4
    for a in args:
        d += hex(int(a))[2:].rjust(64, "0")
    return d

def call(to, sig4, *args):
    for _ in range(6):
        r = eth_call(to, enc(sig4, *args), BH)
        if isinstance(r, str): return r
    raise RuntimeError(f"call failed {to} {sig4}")

def u(r): return int(r, 16)

base = "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4"
meta = "0xe59234EeDC854b3b37D48EFd8a529069C3990F83"
baseLP = "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49"
metaLP = "0x63c7d72963ed6e0c255835b606bef55ebeb1b5f8"
pUSD = "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4"
KDAI = "0x5c74070fdea071359b86082bd9f9b3deaafbe32b"
oUSDT = "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167"
oUSDC = "0x754288077d0ff82af7a5317c7cb8c444d421d103"

# --- state ---
base_A = u(call(base, "0xd46300fd"))
base_vp = u(call(base, "0xe25aa5fa"))
base_supply = u(call(baseLP, "0x18160ddd"))
meta_A = u(call(meta, "0xd46300fd"))
meta_vp = u(call(meta, "0xe25aa5fa"))
meta_supply = u(call(metaLP, "0x18160ddd"))
def bal(tok, owner): return u(call(tok, "0x70a08231", int(owner, 16)))
base_bals = [bal(KDAI, base), bal(oUSDT, base), bal(oUSDC, base)]
meta_lp_res = bal(baseLP, meta)
meta_pusd_res = bal(pUSD, meta)
print(f"base: A={base_A} vp={base_vp/1e18:.9f} supply={base_supply/1e18:.3f}")
print(f"  bals: KDAI={base_bals[0]/1e18:.3f} oUSDT={base_bals[1]/1e6:.3f} oUSDC={base_bals[2]/1e6:.3f}")
print(f"meta: A={meta_A} vp={meta_vp/1e18:.9f} supply={meta_supply/1e18:.3f} LPres={meta_lp_res/1e18:.6f} pUSDres={meta_pusd_res/1e18:.3f}")

# --- math ---
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

# base xp (18-dec normalized)
base_xp = [base_bals[0], base_bals[1]*10**12, base_bals[2]*10**12]
D_base = getD(base_xp, base_A)
print(f"base D={D_base/1e18:.3f}  (vp*supply={base_vp*base_supply//PRECISION/1e18:.3f})")

# meta xp
meta_xp = [meta_lp_res * meta_vp // PRECISION, meta_pusd_res]
D_meta = getD(meta_xp, meta_A)
print(f"meta D={D_meta/1e18:.3f}")

# --- fee detection: tiny swap vs model (n=2 quadratic) ---
def meta_out_lp_to_pusd(dx_lp, xp=None, D=None):
    xp = xp or meta_xp; D = D or D_meta
    dxs = dx_lp * meta_vp // PRECISION
    x0 = xp[0] + dxs
    Ann = meta_A * 2
    Bq = Ann*x0 - (Ann-1)*D
    Cq = D**3 // (4*x0)
    y = (-Bq + math.isqrt(Bq*Bq + 4*Ann*Cq)) // (2*Ann)
    return xp[1] - y

for dx in [10**12, 10**15, 10**18]:
    model = meta_out_lp_to_pusd(dx)
    oc = u(call(meta, "0xa95b089f", 0, 1, dx))
    ratio = oc/model if model else 0
    print(f"  fee probe dx={dx/1e18}: model={model/1e18:.9f} onchain={oc/1e18:.9f} ratio={ratio:.9f}")

# --- base mint: dD per unit deposited, real cost per LP ---
prices = {KDAI: 0.09635042744861741, oUSDT: 0.10509040883124349, oUSDC: 0.29619875144537683}
names = {KDAI: "KDAI", oUSDT: "oUSDT", oUSDC: "oUSDC"}
print("\n-- base mint marginal rates (LP minted per 1.0 token deposited, real cost per LP) --")
for i, t in enumerate([KDAI, oUSDT, oUSDC]):
    unit = 10**18 if i == 0 else 10**6
    xp2 = list(base_xp); xp2[i] += unit
    D2 = getD(xp2, base_A)
    lp_per_token = (D2 - D_base) / 1e18  # LP (18dec) minted per 1 token
    # real cost per LP: price per token / lp_per_token
    cost = prices[t] / (lp_per_token) if lp_per_token else float('inf')
    print(f"  {names[t]:6s}: dD={lp_per_token:.6f} LP per token; token price=${prices[t]:.4f}; cost/LP=${cost:.4f}")

# --- meta payout curve + attack P&L ---
print("\n-- meta LP dump -> pUSD (marginal & cumulative) --")
prev_out = 0
prev_x = 0
for dx_lp in [0.001, 0.01, 0.1, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 8000, 10000]:
    dx = int(dx_lp * 1e18)
    out = meta_out_lp_to_pusd(dx)
    marg = (out - prev_out) / (dx_lp - prev_x) if dx_lp > prev_x else 0
    print(f"  dump {dx_lp:>8} LP -> {out/1e18:>12.3f} pUSD  (avg marginal {marg/1e18:>9.4f})")
    prev_out = out; prev_x = dx_lp
