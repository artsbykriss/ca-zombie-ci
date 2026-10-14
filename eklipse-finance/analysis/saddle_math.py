#!/usr/bin/env python3
"""Saddle Swap math model (getD/getY) + validation against on-chain calculateSwap."""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18

def getD(xp, a):
    """Saddle getD: a = A_PRECISE (e.g. 200000). xp = list of normalized balances (int)."""
    n = len(xp)
    S = sum(xp)
    if S == 0: return 0
    D = S
    Ann = a * n
    for _ in range(255):
        P = D
        for x in xp:
            P = P * D // x // n
        Dprev = D
        D = (Ann * S + P * n) * D // ((Ann - 1) * D + (n + 1) * P)
        if abs(D - Dprev) <= 1:
            return D
    return D

def getY(xp, a, D, i, j, x_new_i):
    """Solve for new x_j given x_i -> x_new_i, invariant D, A a (raw). i,j indices."""
    n = len(xp)
    Ann = a * n
    _xp = list(xp)
    _xp[i] = x_new_i
    S_ = sum(_xp)
    c = D
    for x in _xp:
        c = c * D // (x * n)
    c = c * D // (Ann * n)
    b = S_ + D // Ann
    y = D
    for _ in range(255):
        yprev = y
        y = (y*y + c) // (2*y + b - D)
        if abs(y - yprev) <= 1:
            return y
    return y

if __name__ == "__main__":
    # on-chain values (block ~229748126)
    meta = {
        "tokens": ["0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49", "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4"],
        "balances": [9131924991930958710, 10403963277985893319479],
        "precMul": [1041310458456201923, 10**18],
        "A": 200,
        "vp": 1057825367022704401,
        "lpSupply": 7211285526382630745754,
    }
    xp = [b * m // PRECISION for b, m in zip(meta["balances"], meta["precMul"])]
    print("meta xp:", xp)
    D = getD(xp, meta["A"])
    print("computed D:", D, " vp*supply:", meta["vp"] * meta["lpSupply"] // PRECISION)
    # validate calculateSwap(0,1,1e18): LP -> pUSD
    for dx in [10**17, 10**18, 5*10**18]:
        x_new = xp[0] + dx * meta["precMul"][0] // PRECISION
        y = getY(xp, meta["A"], D, 0, 1, x_new)
        dy = (xp[1] - y) // meta["precMul"][1] * PRECISION
        print(f"  model LP->pUSD dx={dx/1e18}: dy={dy/1e18}")
    for dx in [10**18, 1000*10**18]:
        x_new = xp[1] + dx * meta["precMul"][1] // PRECISION
        y = getY(xp, meta["A"], D, 1, 0, x_new)
        dy = (xp[0] - y) * PRECISION // meta["precMul"][0]
        print(f"  model pUSD->LP dx={dx/1e18}: dy={dy/1e18}")

    # compare to on-chain
    def enc(sig4, *args):
        d = sig4
        for a in args:
            d += hex(int(a))[2:].rjust(64, "0")
        return d
    mp = "0xe59234EeDC854b3b37D48EFd8a529069C3990F83"
    for (frm, to, amt, lbl) in [(0,1,10**17,"LP->pUSD 0.1"), (0,1,10**18,"LP->pUSD 1"), (0,1,5*10**18,"LP->pUSD 5"),
                                (1,0,10**18,"pUSD->LP 1"), (1,0,1000*10**18,"pUSD->LP 1000")]:
        r = eth_call(mp, enc("0xa95b089f", frm, to, amt))
        try: v = int(r, 16)/1e18
        except Exception: v = r
        print(f"  onchain calculateSwap {lbl}: {v}")
