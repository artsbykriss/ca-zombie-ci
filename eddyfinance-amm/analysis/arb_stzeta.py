#!/usr/bin/env python3
"""stZETA cross-pool arb simulation: Eddy stableswap 0x01a9cd vs Eddy UniV2 pair 0x6b3ee329.
Pure local math from verified sources (Curve 2-coin stableswap + UniV2).
State read at ZetaChain block 19473839 (2026-10-14).
"""
from decimal import Decimal, getcontext
getcontext().prec = 60

A_PRECISION = 100
FEE_DENOMINATOR = 10**10

# --- Curve 2-coin stableswap (Vyper 0.3.7) ---
class Curve2:
    def __init__(self, b0, b1, A, fee):
        self.b0, self.b1 = Decimal(b0), Decimal(b1)
        self.A = Decimal(A) * A_PRECISION   # A_precise
        self.fee = Decimal(fee)
    def get_D(self, xp0, xp1):
        S = xp0 + xp1
        if S == 0: return Decimal(0)
        D = S
        Ann = self.A * 2
        for _ in range(255):
            D_P = D * D / (xp0 * 2) * D / (xp1 * 2)
            Dprev = D
            D = (Ann * S / A_PRECISION + D_P * 2) * D / ((Ann - A_PRECISION) * D / A_PRECISION + 3 * D_P)
            if abs(D - Dprev) <= 1:
                break
        return D
    def get_y(self, i, j, x, xp):
        D = self.get_D(xp[0], xp[1])
        Ann = self.A * 2
        c = D
        S_ = Decimal(0)
        for k in range(2):
            if k == i: _x = x
            elif k != j: _x = xp[k]
            else: continue
            S_ += _x
            c = c * D / (_x * 2)
        c = c * D * A_PRECISION / (Ann * 2)
        b = S_ + D * A_PRECISION / Ann
        y = D
        for _ in range(255):
            y_prev = y
            y = (y * y + c) / (2 * y + b - D)
            if abs(y - y_prev) <= 1: break
        return y
    def get_dy(self, i, j, dx):
        xp = [self.b0, self.b1]
        x = xp[i] + dx
        y = self.get_y(i, j, x, xp)
        dy = xp[j] - y - 1
        fee = dy * self.fee / FEE_DENOMINATOR
        return dy - fee

def univ2_out(dx, r_in, r_out):
    dxf = dx * 997
    return dxf * r_out / (r_in * 1000 + dxf)

# --- live state (block 19473839) ---
E18 = Decimal(10)**18
pool = Curve2(Decimal("83862609772327573591"), Decimal("377377613740253279659"), A=50, fee=3*10**7)
pair_stz = Decimal("36280721922084910366691")   # stZETA reserve
pair_wz  = Decimal("38057853626162811115184")   # WZETA reserve

# sanity: get_dy(0,1,1 ZETA)
print("sanity get_dy(0->1, 1 ZETA):", float(pool.get_dy(0,1,1*E18))/1e18, "stZETA")
print("sanity get_dy(1->0, 100 stZETA):", float(pool.get_dy(1,0,100*E18))/1e18, "ZETA")
print("pair marginal stZETA price:", float(pair_wz/pair_stz), "WZETA/stZETA")
print()
# direction A: buy stZETA in Curve with ZETA, sell into UniV2
print("=== Direction A: ZETA -> stableswap -> stZETA -> UniV2 -> WZETA ===")
best = None
for x_zeta in [1,2,5,10,20,30,40,50,60,70,80,90,100,120,150,200,250,300,350,400,500,600,800,1000]:
    x = Decimal(x_zeta)*E18
    dy = pool.get_dy(0,1,x)
    out = univ2_out(dy, pair_stz, pair_wz)
    profit = out - x
    print(f"X={x_zeta:6} ZETA -> {float(dy)/1e18:10.3f} stZETA -> {float(out)/1e18:10.3f} WZETA | profit={float(profit)/1e18:8.4f} ZETA ({100*float(profit/x):7.3f}%)")
    if best is None or profit > best[1]:
        best = (x_zeta, profit)
print("BEST:", best[0], "ZETA in, profit", float(best[1])/1e18, "ZETA")
print()
# direction B: buy stZETA in UniV2 with WZETA, sell into Curve
print("=== Direction B: WZETA -> UniV2 -> stZETA -> stableswap -> ZETA ===")
for x_wz in [1,5,10,20,40,60,80,100]:
    x = Decimal(x_wz)*E18
    dy = univ2_out(x, pair_wz, pair_stz)
    out = pool.get_dy(1,0,dy)
    print(f"X={x_wz:6} WZETA -> {float(dy)/1e18:10.3f} stZETA -> {float(out)/1e18:10.3f} ZETA | profit={float(out-x)/1e18:8.4f} ({100*float((out-x)/x):7.3f}%)")
