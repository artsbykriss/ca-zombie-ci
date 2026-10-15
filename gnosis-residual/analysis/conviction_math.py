#!/usr/bin/env python3
"""Exact (integer) reproduction of Gardens v2 conviction + threshold math.
Validates against live on-chain values, then simulates the attacker path:
buy S HNY -> register -> activate -> propose X -> support -> wait t -> execute.
"""
import json

D = 10_000_000
TWO_128 = 1 << 128
TWO_127 = 1 << 127

# live cvParams (block 48,767,221)
weight        = 998_926        # 0x0f3e0e
decay         = 9_999_958      # 0x989656
maxRatio      = 8_160_578      # 0x7c8542
minThreshold  = 100 * 10**18   # 0x56bc75e2d63100000

# live pool state
F        = int("129f5d8685132a4d06c", 16)   # getPoolAmount()
hny_bal  = int("129f3ed3321d4e0f844", 16)   # balanceOf(strategy)
T0       = int("112d3380119bad2dc68", 16)   # totalPointsActivated
TP0      = int("11304a99d88553a0754", 16)   # getPoolThresholdPoints()
totalStaked = int("2eb277170de13e0000", 16)

def _mul(a,b):
    assert a <= TWO_128 and b < TWO_128
    return ((a*b) + TWO_127) >> 128
def _pow(a,b):
    r = TWO_128
    while b > 0:
        if b & 1 == 0:
            a = _mul(a,a); b >>= 1
        else:
            r = _mul(r,a); b -= 1
    return r
def muldiv(a,b,c,roundup=False):
    p = a*b
    q = p//c
    if roundup and p % c: q += 1
    return q
def calculate_conviction(t, last_conv, old_amount, decay_=decay):
    at = _pow((decay_ << 128)//D, t)
    return (((at*last_conv) + ((old_amount*D*(TWO_128-at))//(D-decay_))) + TWO_127) >> 128
def weighted_average(snap, current, elapsed, decay_=decay):
    decay_factor = _pow((decay_ << 128)//D, elapsed)
    if current >= snap:
        wd = muldiv(current-snap, decay_factor, TWO_128, True)
        return current - wd
    else:
        wd = muldiv(snap-current, decay_factor, TWO_128, True)
        return current + wd
def calculate_threshold(req, pool_amt, total_points, decay_=decay):
    if pool_amt > 0 and maxRatio*pool_amt <= req*D:
        return (1<<256)-1
    ratio_term_req = 0 if pool_amt==0 else (req << 64)//pool_amt
    denom = (maxRatio << 64)//D - ratio_term_req
    weight_scaled = (weight << 128)//D
    ratio_term = muldiv(weight_scaled, D, (denom*denom) >> 64)
    decay_adjusted = ratio_term // (D - decay_)
    thr = muldiv(decay_adjusted, total_points, 1 << 64)
    override = muldiv(minThreshold, D, D - decay_)
    return max(thr, override)

# ---- validation against live proposal 4 (storage read at blk 48,767,221)
p4_staked = int("2eb277170de13e0000",16)
p4_convlast = int("a4f9e574f3eef58c740e6",16)
p4_blocklast = int("2824cf2",16)
p4_tsnap = int("115f032833b58a441f6",16)
p4_tsnapblk = int("2d84659",16)
blk_now = 48767221
conv_now = calculate_conviction(blk_now - p4_blocklast, p4_convlast, p4_staked)
print("VALIDATION p4 conviction:")
print("  simulated:", conv_now)
print("  on-chain :", int("a9a71c35076e32792c8157",16))
print("  match:", conv_now == int("a9a71c35076e32792c8157",16))
tp_p4 = p4_tsnap
if p4_tsnap > T0:
    tp_p4 = weighted_average(p4_tsnap, T0, blk_now - p4_tsnapblk)
# pool threshold points now
TP_now = TP0
print("  p4 threshold points sim:", tp_p4, " pool TP now:", TP_now)
thr_p4 = calculate_threshold(int("3635c9adc5dea00000",16), F, max(tp_p4, TP_now))
print("  p4 threshold for X=1000:", thr_p4, "(conviction >> threshold:", conv_now > thr_p4, ")")
print()
print("LIVE:", f"F={F/1e18:,.6f} HNY  balance={hny_bal/1e18:,.6f}  T0={T0/1e18:,.6f} pts  TP0={TP0/1e18:,.6f}")
print("min threshold override:", muldiv(minThreshold, D, D-decay))

json.dump({"F":str(F),"hny_bal":str(hny_bal),"T0":str(T0),"TP0":str(TP0)}, open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-math-constants.json","w"), indent=1)
