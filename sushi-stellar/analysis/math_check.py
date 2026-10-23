#!/usr/bin/env python3
"""Independent check of the deployed pool's exact-input quote against the reference UniV3
single-step formula (getNextSqrtPriceFromAmount0RoundingUp + getAmount1Delta).

Read-only: uses pool.quote_exact_input via simulateTransaction.
"""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/sushi-stellar/analysis")
from state import sim, val
from sval import py
from stellar_sdk import scval, Address, xdr

Q96 = 1 << 96
MIN_SQRT = 4295128739
MAX_SQRT = 1461446703485210103287273052203988822378723970342

def next_sqrt_from_amount0(sqrtP, L, amount, add=True):
    """UniV3 getNextSqrtPriceFromAmount0RoundingUp"""
    if amount == 0: return sqrtP
    num1 = L << 96
    if add:
        denom = num1 + amount * sqrtP
        return -(-(num1 * sqrtP) // denom)  # ceil
    else:
        denom = num1 - amount * sqrtP
        return -(-(num1 * sqrtP) // denom)

def next_sqrt_from_amount1(sqrtP, L, amount, add=True):
    """UniV3 getNextSqrtPriceFromAmount1RoundingDown"""
    if add:
        return sqrtP + ((amount << 96) // L)
    else:
        return sqrtP - ((amount << 96) // L)

def amount0_delta(sqrtA, sqrtB, L, round_up):
    if sqrtA > sqrtB: sqrtA, sqrtB = sqrtB, sqrtA
    num = L << 96
    if round_up:
        return -(-(num * (sqrtB - sqrtA)) // (sqrtB * sqrtA))
    return (num * (sqrtB - sqrtA)) // (sqrtB * sqrtA)

def amount1_delta(sqrtA, sqrtB, L, round_up):
    if sqrtA > sqrtB: sqrtA, sqrtB = sqrtB, sqrtA
    num = L * (sqrtB - sqrtA)
    if round_up:
        return -(-num // Q96)
    return num // Q96

def ref_quote(sqrtP, L, fee, zero_for_one, amount_in, limit):
    # exact input, single step (assumes no tick crossing within the range)
    fee_den = 1_000_000
    amount_less_fee = amount_in * (fee_den - fee) // fee_den
    if zero_for_one:
        nxt = next_sqrt_from_amount0(sqrtP, L, amount_less_fee, add=True)
        if nxt < limit: nxt = limit
        out = amount1_delta(nxt, sqrtP, L, round_up=False)
    else:
        nxt = next_sqrt_from_amount1(sqrtP, L, amount_less_fee, add=True)
        if nxt > limit: nxt = limit
        out = amount0_delta(sqrtP, nxt, L, round_up=False)
    return out, nxt

if __name__ == "__main__":
    POOL = sys.argv[1] if len(sys.argv) > 1 else "CBVHBZSZOS6KRDJ4D44FU2YLIENOVSSLM3UGKW6XQMVIFUAMWIWCVH2U"
    s0 = py(val(sim(POOL, "slot0")))
    L = py(val(sim(POOL, "liquidity")))
    fee = py(val(sim(POOL, "fee")))
    t0 = py(val(sim(POOL, "token0"))); t1 = py(val(sim(POOL, "token1")))
    print("pool", POOL, "fee", fee, "L", L, "sqrtP", s0["sqrt_price_x96"], "tick", s0["tick"])
    print("token0", t0, "token1", t1)
    ok = 0; tot = 0
    for zfo, lim, amts in [(True, MIN_SQRT, [10, 10**4, 10**6, 10**8]),
                           (False, MAX_SQRT, [10, 10**4, 10**6, 10**8])]:
        for amt in amts:
            params = [scval.to_bool(zfo), scval.to_int128(amt), scval.to_uint256(lim)]
            r = sim(POOL, "quote_exact_input", params)
            if r.error:
                print(f"  zfo={zfo} amt={amt}: quote err {(r.error).splitlines()[0][:60]}"); continue
            got = py(val(r))
            exp, nxt = ref_quote(s0["sqrt_price_x96"], L, fee, zfo, amt, lim)
            tot += 1
            match = (isinstance(got, dict) and (got.get("amount_out") == exp or got.get("amount1") == exp or got.get("amount0") == exp))
            # try to extract whichever amount is the output
            gv = None
            if isinstance(got, dict):
                gv = got.get("amount_out")
                if gv is None:
                    gv = got.get("amount1") if zfo else got.get("amount0")
            ok += 1 if (gv == exp) else 0
            print(f"  zfo={zfo} amt={amt}: quote={gv} ref={exp} {'MATCH' if gv==exp else ('n/a' if gv is None else 'DIFF')}  raw={got}")
    print(f"matches: {ok}/{tot}")
