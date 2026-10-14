#!/usr/bin/env python3
"""Fit contract A convention + full attack P&L (correct decimal scaling)."""
import json, sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18
BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

def enc(sig4, *args):
    d = sig4
    for a in args: d += hex(int(a))[2:].rjust(64, "0")
    return d
def call(to, sig4, *args):
    for _ in range(6):
        r = eth_call(to, enc(sig4, *args), BH)
        if isinstance(r, str): return r
    raise RuntimeError("fail")
def u(r): return int(r, 16)

base = "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4"
meta = "0xe59234EeDC854b3b37D48EFd8a529069C3990F83"
baseLP = "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49"
KDAI = "0x5c74070fdea071359b86082bd9f9b3deaafbe32b"
oUSDT = "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167"
oUSDC = "0x754288077d0ff82af7a5317c7cb8c444d421d103"
pUSD = "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4"

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

base_A = u(call(base, "0xd46300fd")); base_vp = u(call(base, "0xe25aa5fa")); base_supply = u(call(baseLP, "0x18160ddd"))
meta_A = u(call(meta, "0xd46300fd")); meta_vp = u(call(meta, "0xe25aa5fa"))
def bal(tok, owner): return u(call(tok, "0x70a08231", int(owner, 16)))
bb = [bal(KDAI, base), bal(oUSDT, base), bal(oUSDC, base)]
mlp = bal(baseLP, meta); mp = bal(pUSD, meta)
base_xp = [bb[0], bb[1]*10**12, bb[2]*10**12]
meta_xp = [mlp * meta_vp // PRECISION, mp]
target_base = base_vp * base_supply // PRECISION
target_meta = meta_vp * u(call("0x63c7d72963ed6e0c255835b606bef55ebeb1b5f8", "0x18160ddd")) // PRECISION
print(f"base: getA={base_A} target D={target_base/1e18:.4f}")
print(f"meta: getA={meta_A} target D={target_meta/1e18:.4f}")
for a in [base_A, base_A//10, base_A//100, base_A*100]:
    print(f"  base getD(a={a}) = {getD(base_xp, a)/1e18:.4f}")
for a in [meta_A, meta_A//10, meta_A//100, meta_A*100]:
    print(f"  meta getD(a={a}) = {getD(meta_xp, a)/1e18:.4f}")

# --- find best-fit A by bisection ---
def fit_A(xp, target):
    lo, hi = 1, 10**7
    for _ in range(60):
        mid = (lo + hi) // 2
        if getD(xp, mid) > target: lo = mid
        else: hi = mid
    return lo
print("fitted base A:", fit_A(base_xp, target_base), " (getA=", base_A, ")")
print("fitted meta A:", fit_A(meta_xp, target_meta), " (getA=", meta_A, ")")

# --- validate calculateSwap with fitted A ---
A_b = fit_A(base_xp, target_base)
def meta_model_out(dx_lp, A):
    dxs = dx_lp * meta_vp // PRECISION
    x0 = meta_xp[0] + dxs
    Ann = A * 2
    Bq = Ann*x0 - (Ann-1)*target_meta
    Cq = target_meta**3 // (4*x0)
    y = (-Bq + math.isqrt(Bq*Bq + 4*Ann*Cq)) // (2*Ann)
    return meta_xp[1] - y
A_m = fit_A(meta_xp, target_meta)
for dx in [10**15, 10**18, 5*10**18]:
    m = meta_model_out(dx, A_m)
    oc = u(call(meta, "0xa95b089f", 0, 1, dx))
    print(f"  meta validate dx={dx/1e18}LP: model={m/1e18:.6f} onchain={oc/1e18:.6f} ratio={oc/m:.6f}")

# --- base mint curve with fitted A ---
print("\n-- base mint: LP minted per token deposited (marginal) --")
toks = [(KDAI, 10**18, 1), (oUSDT, 10**6, 10**12), (oUSDC, 10**6, 10**12)]
prices = {KDAI: 0.09635042744861741, oUSDT: 0.10509040883124349, oUSDC: 0.29619875144537683}
names = {KDAI: "KDAI", oUSDT: "oUSDT", oUSDC: "oUSDC"}
D0 = getD(base_xp, A_b)
for t, unit, mult in toks:
    xp2 = list(base_xp); xp2[base_xp.index(base_xp[0]) if False else toks.index((t,unit,mult))] += unit * mult
    D2 = getD(xp2, A_b)
    lp = (D2 - D0) / 1e18
    cost = prices[t] / lp if lp else float("inf")
    print(f"  {names[t]:6s}: {lp:.6f} LP per token, cost/LP = ${cost:.5f}")
