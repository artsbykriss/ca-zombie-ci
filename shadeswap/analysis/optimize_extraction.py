#!/usr/bin/env python3
"""Extraction optimizer: mint stkd-SCRT (SCRT input) -> SILK/SHD -> destination pools.

Constant-product approximation (conservative for stable pools), 0.3% fee on all pools.
External prices from CoinGecko (2026-10-15).
"""
import json

FEE = 0.997
COST_STKD = 0.018445  # USD per stkd-SCRT (mint incl 2% fee; SCRT $0.00731912 * 2.4694 / 0.98)

# intermediate pools: (x=out-token reserve, y=in-token reserve)
P_SILK = (120520.1828, 310524.808987)   # SILK/stkd-SCRT: SILK out, stkd-SCRT in
P_SHD = (86499.57832691, 199935.564540)  # SHD/stkd-SCRT: SHD out, stkd-SCRT in

# destination pools: (x=in-token reserve [SILK or SHD], y=out reserve, price of out token)
SILK_DESTS = [
    ("saUSDC", 5345.5712, 3013.269132, 1.0),
    ("saUSDT", 9219.8244, 5083.273673, 1.0),
    ("saWBTC", 4574.3095, 0.067047, 81213.0),
    ("saWETH", 131.6669, 0.071185, 2369.61),
    ("sCMST", 387.8675, 13009.617113, 0.05105),
    ("sqATOM", 1059.0167, 96.139764, 1.678),
    ("sUSK", 711.1491, 355.711210, 0.314985),
    ("sstOSMO", 8003.0212, 5158.589714, 0.061014),
    ("sstINJ", 4891.1286, 15.896120, 7.28),
    ("sstATOM", 10762.4785, 116.626682, 1.76),
    ("sstkATOM", 1462.4365, 19.329542, 1.76),
]
SHD_DESTS = [
    ("saWBTC", 1213.7680, 0.017177, 81213.0),
    ("SIENNA", 661.1410, 48446.619794, 0.01574366),
]


def waterfill(k, dests):
    """Maximize sum p*y*k_i/(x+k_i) s.t. sum k_i = k. Returns value."""
    if k <= 0:
        return 0.0
    lo, hi = 0.0, max(d[3] for d in dests)  # lambda
    for _ in range(80):
        lam = (lo + hi) / 2
        tot = 0.0
        for _, x, y, p in dests:
            # marginal value = p*y*x/(x+k)^2 = lam -> (x+k) = sqrt(p*y*x/lam)
            if lam <= 0:
                ki = k
            else:
                xi = (p * y * x / lam) ** 0.5
                ki = max(0.0, xi - x)
            tot += ki
        if tot > k:
            lo = lam
        else:
            hi = lam
    # allocate
    lam = (lo + hi) / 2
    val = 0.0
    for _, x, y, p in dests:
        if lam <= 0:
            ki = k
        else:
            xi = (p * y * x / lam) ** 0.5
            ki = max(0.0, xi - x)
        val += p * y * ki / (x + ki)
    return val


def profit(sA, sB):
    silk = P_SILK[0] * sA / (P_SILK[1] + sA) * FEE if sA > 0 else 0
    shd = P_SHD[0] * sB / (P_SHD[1] + sB) * FEE if sB > 0 else 0
    val = waterfill(silk, SILK_DESTS) + waterfill(shd, SHD_DESTS)
    return val - COST_STKD * (sA + sB)


# coarse-to-fine search
best = (0, 0, 0.0)
step = 5000.0
sA, sB = 0.0, 0.0
for _ in range(6):
    improved = True
    while improved:
        improved = False
        for dA, dB in ((step, 0), (-step, 0), (0, step), (0, -step)):
            nA, nB = max(0.0, sA + dA), max(0.0, sB + dB)
            p = profit(nA, nB)
            if p > best[2] + 1e-9:
                best = (nA, nB, p)
                sA, sB = nA, nB
                improved = True
    step /= 5

sA, sB, p = best
silk = P_SILK[0] * sA / (P_SILK[1] + sA) * FEE if sA > 0 else 0
shd = P_SHD[0] * sB / (P_SHD[1] + sB) * FEE if sB > 0 else 0
print(f"OPTIMAL: stkd-SCRT in A->SILK: {sA:,.0f}  in B->SHD: {sB:,.0f}  total {sA+sB:,.0f}")
print(f"  SILK produced: {silk:,.1f}   SHD produced: {shd:,.1f}")
print(f"  gross output value: ${waterfill(silk, SILK_DESTS) + waterfill(shd, SHD_DESTS):,.2f}")
print(f"  input cost: ${COST_STKD*(sA+sB):,.2f}")
print(f"  NET PROFIT: ${p:,.2f}")
print()
# breakdown: marginal allocations
for name, x, y, pr in SILK_DESTS + SHD_DESTS:
    pass

# sanity: value of a few naive strategies
for label, (a, b) in {"all->SILK 100k": (100000, 0), "all->SHD 100k": (0, 100000),
                      "split 100k/100k": (100000, 100000), "50k/50k": (50000, 50000)}.items():
    print(f"{label}: net ${profit(a, b):,.2f}")
json.dump({"best": {"stkd_to_silk": sA, "stkd_to_shd": sB, "silk": silk, "shd": shd, "net_usd": p},
           "cost_per_stkd": COST_STKD}, open("/home/heisenberg/CA/shadeswap/analysis/extraction-opt.json", "w"), indent=1)
