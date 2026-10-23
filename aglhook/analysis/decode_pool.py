#!/usr/bin/env python3
"""Independent cross-check of the AGL/ETH pool reserves.
Uses exact integer sqrt prices (Q96) so there is no float error in the
sqrt-price ratio; tick sqrt prices via 1.0001**tick computed with Decimal.
Pure math, no secrets."""
from decimal import Decimal, getcontext
getcontext().prec = 60

Q96 = Decimal(2 ** 96)
sqrtPriceX96 = Decimal(47729490862246211467375510809330)
L = Decimal(192469621223142870118663)
tickLower, tickUpper = -887156, 171120

def sqrt_at_tick(t):
    # sqrt(1.0001^t) = 1.0001^(t/2)
    return (Decimal("1.0001") ** (Decimal(t) / 2))

sp = sqrtPriceX96 / Q96
sa = sqrt_at_tick(tickLower)
sb = sqrt_at_tick(tickUpper)
print(f"sp={sp:.10e} sa={sa:.10e} sb={sb:.10e}")
assert sa < sp < sb

amount0 = L * (sb - sp) / (sp * sb)   # ETH wei
amount1 = L * (sp - sa)               # AGL wei
print(f"ETH reserve : {amount0 / Decimal(10**18):.6f} ETH")
print(f"AGL reserve : {amount1 / Decimal(10**18):.4f} AGL")
mid = sp * sp
print(f"mid price   : {mid:.2f} AGL per ETH")
ethusd = Decimal("2402.6542445714776")
aglusd = ethusd / mid
tvl = (amount0 / Decimal(10**18)) * ethusd + (amount1 / Decimal(10**18)) * aglusd
print(f"AGL price   : ${aglusd:.8f}")
print(f"pool TVL    : ${tvl:,.0f}")
