#!/usr/bin/env python3
"""FourPool vs UniV2 cross-pool arb (corrected raw reserves from pairs_live.json).
State at ZetaChain block ~19473564 (2026-10-14)."""
from decimal import Decimal, getcontext
getcontext().prec = 80
FEE_DENOM = Decimal(10)**10

class Curve4:
    def __init__(self, balances, A, fee):
        self.b = [Decimal(x) for x in balances]
        self.A = Decimal(A); self.fee = Decimal(fee)
        self.rates = [Decimal(10)**18, Decimal(10)**30, Decimal(10)**30, Decimal(10)**18]
    def xp(self): return [self.rates[i]*self.b[i]/Decimal(10)**18 for i in range(4)]
    def get_D(self, xp, amp):
        S = sum(xp)
        if S == 0: return Decimal(0)
        D = S; Ann = amp*4
        for _ in range(255):
            D_P = D
            for x in xp: D_P = D_P*D/(x*4)
            Dprev = D
            D = (Ann*S + D_P*4)*D/((Ann-1)*D + 5*D_P)
            if abs(D-Dprev) <= 1: break
        return D
    def get_y(self, i, j, x, xp, amp):
        D = self.get_D(xp, amp); c = D; S_ = Decimal(0); Ann = amp*4
        for k in range(4):
            if k == i: _x = x
            elif k != j: _x = xp[k]
            else: continue
            S_ += _x; c = c*D/(_x*4)
        c = c*D/(Ann*4); b = S_ + D/Ann; y = D
        for _ in range(255):
            y_prev = y; y = (y*y+c)/(2*y+b-D)
            if abs(y-y_prev) <= 1: break
        return y
    def get_dy(self, i, j, dx):
        xp = self.xp()
        x = xp[i] + dx*self.rates[i]/Decimal(10)**18
        y = self.get_y(i, j, x, xp, self.A)
        dy = (xp[j]-y-1)*Decimal(10)**18/self.rates[j]
        fee = self.fee*dy/FEE_DENOM
        return dy-fee

def u2(dx, r_in, r_out):
    dxf = dx*997
    return dxf*r_out/(r_in*1000+dxf)

pool = Curve4([111291259963189387503, 331828189, 10156441, 9917326817617350502], A=2000, fee=10**6)
# exact raw reserves
bf = (Decimal(1400845253), Decimal(11419161620252894395983))          # USDC.ETH, WZETA
p3f = (Decimal(13619641925918158802996), Decimal(1337871716))         # WZETA, USDT.ETH
p10 = (Decimal(876084855984269493623), Decimal(7207963697017175043476))# USDC.BSC, WZETA
pc9 = (Decimal(8438512843584760958599), Decimal(822995730336982853391))# WZETA, USDT.BSC

E18 = Decimal(10)**18
print("=== marginal rates ===")
print("market USDT.ETH per USDC.ETH:", float((p3f[0]/p3f[1])/(bf[1]/bf[0])))
print("FourPool 1 USDT.ETH ->", float(pool.get_dy(2,1,Decimal(10**6)))/1e6, "USDC.ETH")
print("market USDT.BSC per USDC.BSC:", float((pc9[0]/pc9[1])/(p10[1]/p10[0])))
print("FourPool 1 USDT.BSC ->", float(pool.get_dy(3,0,Decimal(10**18)))/1e18, "USDC.BSC")
print()
print("=== Path A: WZETA -> USDC.ETH(0xbfff) -> USDT.ETH(FourPool) -> WZETA(0x3f2f) ===")
best=None
for x_wz in [0.1,0.5,1,2,3,5,8,10,15,20]:
    x = Decimal(str(x_wz))*E18
    ue = u2(x, bf[1], bf[0])                 # WZETA -> USDC.ETH (6dec)
    ut = pool.get_dy(1,2, ue)                # USDC.ETH -> USDT.ETH
    out = u2(ut, p3f[1], p3f[0])             # USDT.ETH -> WZETA
    p = out-x
    print(f"  X={x_wz:5} -> {float(ue)/1e6:8.4f} USDC.ETH -> {float(ut)/1e6:8.4f} USDT.ETH -> {float(out)/1e18:8.4f} WZETA | profit {float(p)/1e18:8.5f} ({100*float(p/x):7.3f}%)")
    if best is None or p>best[1]: best=(x_wz,p)
print("  BEST:", best[0], "profit", float(best[1])/1e18)
print()
print("=== Path B: WZETA -> USDC.BSC(0x10b4) -> USDT.BSC(FourPool) -> WZETA(0xc9d3) ===")
best=None
for x_wz in [0.1,0.5,1,2,3,5,8,10,15,20]:
    x = Decimal(str(x_wz))*E18
    ub = u2(x, p10[1], p10[0])               # WZETA -> USDC.BSC
    ut = pool.get_dy(0,3, ub)                # USDC.BSC -> USDT.BSC
    out = u2(ut, pc9[1], pc9[0])             # USDT.BSC -> WZETA
    p = out-x
    print(f"  X={x_wz:5} -> {float(ub)/1e18:8.4f} USDC.BSC -> {float(ut)/1e18:8.4f} USDT.BSC -> {float(out)/1e18:8.4f} WZETA | profit {float(p)/1e18:8.5f} ({100*float(p/x):7.3f}%)")
    if best is None or p>best[1]: best=(x_wz,p)
print("  BEST:", best[0], "profit", float(best[1])/1e18)
print()
print("=== Reverse: WZETA -> USDT.ETH(0x3f2f) -> USDC.ETH(FourPool) -> WZETA(0xbfff) ===")
for x_wz in [0.1,1,5,10]:
    x = Decimal(str(x_wz))*E18
    ut = u2(x, p3f[1], p3f[0])
    ue = pool.get_dy(2,1, ut)
    out = u2(ue, bf[1], bf[0])
    print(f"  X={x_wz:5} profit {float(out-x)/1e18:8.5f} ({100*float((out-x)/x):7.3f}%)")
