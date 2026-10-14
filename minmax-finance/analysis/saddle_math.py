#!/usr/bin/env python3
"""Exact Saddle v1 (SwapUtils) math in Python — verified against on-chain calculateSwap.

All functions mirror saddle-finance/saddle-contract contracts/SwapUtils.sol exactly.
Amounts are integers; xp arrays are already precision-scaled (18 dec).
"""
from fractions import Fraction

A_PRECISION = 100
FEE_DENOMINATOR = 10**10
MAX_ITERATIONS = 255


def within1(a, b):
    if a > b:
        return a - b <= 1
    return b - a <= 1


def getD(xp, a):
    n = len(xp)
    s = sum(xp)
    if s == 0:
        return 0
    d = s
    nA = a * n
    for _ in range(MAX_ITERATIONS):
        dP = d
        for j in range(n):
            dP = dP * d // (xp[j] * n)
        prevD = d
        num = (nA * s // A_PRECISION + dP * n) * d
        den = (nA - A_PRECISION) * d // A_PRECISION + (n + 1) * dP
        d = num // den
        if within1(d, prevD):
            return d
    raise RuntimeError("D does not converge")


def getY(a, i, j, x, xp):
    n = len(xp)
    d = getD(xp, a)
    c = d
    s = 0
    nA = n * a
    for k in range(n):
        if k == i:
            _x = x
        elif k != j:
            _x = xp[k]
        else:
            continue
        s += _x
        c = c * d // (_x * n)
    c = c * d * A_PRECISION // (nA * n)
    b = s + d * A_PRECISION // nA
    y = d
    for _ in range(MAX_ITERATIONS):
        yPrev = y
        y = (y * y + c) // (2 * y + b - d)
        if within1(y, yPrev):
            return y
    raise RuntimeError("y does not converge")


def calculate_swap(balances, multipliers, a_precise, swap_fee, i, j, dx):
    """Returns (dy, dy_fee) in native decimals, exactly as the contract does."""
    xp = [b * m for b, m in zip(balances, multipliers)]
    x = dx * multipliers[i] + xp[i]
    y = getY(a_precise, i, j, x, xp)
    dy = xp[j] - y - 1
    dy_fee = dy * swap_fee // FEE_DENOMINATOR
    dy = (dy - dy_fee) // multipliers[j]
    return dy, dy_fee


def spot_price(balances, multipliers, a_precise, swap_fee, i, j, eps=10**6):
    """Marginal price of token i in units of token j (native), via tiny dx."""
    xp = [b * m for b, m in zip(balances, multipliers)]
    # tiny dx in xp units
    dx_native = max(1, eps // multipliers[i])
    x = dx_native * multipliers[i] + xp[i]
    y = getY(a_precise, i, j, x, xp)
    dy = xp[j] - y - 1
    dy_fee = dy * swap_fee // FEE_DENOMINATOR
    dy_native = (dy - dy_fee) / multipliers[j]
    return dy_native / dx_native


if __name__ == "__main__":
    # Self-test against known on-chain values (P1 ioBUSD->ioUSDT 100e18 -> 100.4006e6)
    # P1 balances: [9320188370178109263770, 7922037782, 18426612012, 18052329356217916330044]
    # multipliers: [1, 1e12, 1e12, 1]
    b = [9320188370178109263770, 7922037782, 18426612012, 18052329356217916330044]
    m = [1, 10**12, 10**12, 1]
    a = 20000
    fee = 6000000
    dy, f = calculate_swap(b, m, a, fee, 0, 2, 100 * 10**18)
    print("P1 ioBUSD->ioUSDT 100e18:", dy, "expected 100400600 (on-chain 100.4006e6)")
    dy, f = calculate_swap(b, m, a, fee, 1, 2, 100 * 10**6)
    print("P1 ioUSDC->ioUSDT 100e6:", dy, "expected 1005649")
    # P2 XIM(0)->ioUSDC(2)
    b2 = [189667906146848584313, 3358120338170806054, 2926443, 3219153]
    m2 = [1, 1, 10**12, 10**12]
    dy, f = calculate_swap(b2, m2, a, fee, 2, 0, 10**5)  # 0.1 ioUSDC
    print("P2 ioUSDC->XIM 0.1e6:", dy, "expected ~1.4657e18")
    dy, f = calculate_swap(b2, m2, a, fee, 0, 2, 10**18)  # 1 XIM
    print("P2 XIM->ioUSDC 1e18:", dy, "expected ~65228")
    # spot rates
    print("P2 spot ioUSDC->XIM:", spot_price(b2, m2, a, fee, 2, 0))
    print("P2 spot XIM->ioUSDC:", spot_price(b2, m2, a, fee, 0, 2))
