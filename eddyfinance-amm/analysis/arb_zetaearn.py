#!/usr/bin/env python3
"""ZetaEarn stZETA discount arb on Eddy's UniV2 pair 0x6b3ee329 (correct token 0x45334a5b).
Buy stZETA from Eddy pair with WZETA, redeem via ZetaEarn vault at convertStZETAToZETA rate.
State @ ZetaChain block 19473839. Redemption rate read live from vault proxy (1.159644709 ZETA/stZETA)."""
from decimal import Decimal, getcontext
getcontext().prec = 60
E18 = Decimal(10)**18

R0 = Decimal("36280721922084910366691")   # stZETA reserve
R1 = Decimal("38057853626162811115184")   # WZETA reserve
RATE = Decimal("1159644709233493232")/E18  # ZetaEarn convertStZETAToZETA(1e18) = 1.159644709

def u2(dx, r_in, r_out):
    dxf = dx*997
    return dxf*r_out/(r_in*1000+dxf)

print(f"ZetaEarn redemption rate: {RATE} ZETA/stZETA")
print(f"Eddy pair marginal price : {float(R1/R0):.6f} WZETA/stZETA")
print(f"discount                 : {100*(1-float(R1/R0)/float(RATE)):.2f}%")
print()
print("=== buy stZETA from Eddy pair with WZETA, redeem at vault rate ===")
best=None
for x_wz in [10,50,100,250,500,750,1000,1500,1900,2000,2500,3000,4000,5000,7000,9000,12000]:
    x = Decimal(x_wz)*E18
    stz = u2(x, R1, R0)
    redeemed = stz*RATE
    profit = redeemed - x
    print(f"X={x_wz:6} WZETA -> {float(stz)/1e18:10.3f} stZETA -> redeem {float(redeemed)/1e18:10.3f} ZETA | profit {float(profit)/1e18:9.4f} ZETA ({100*float(profit/x):7.3f}%)")
    if best is None or profit>best[1]: best=(x_wz,profit,stz)
print()
print(f"OPTIMUM: x={best[0]} WZETA -> {float(best[2])/1e18:.3f} stZETA -> profit {float(best[1])/1e18:.4f} ZETA")
# full-reserve sanity: buy until price reaches redemption rate
import math
xmax = (math.sqrt(float(RATE)*0.997*float(R0)*float(R1)) - float(R1))/0.997
print(f"marginal-equalizing size: {xmax:.1f} WZETA (pool WZETA reserve {float(R1)/1e18:.0f})")
