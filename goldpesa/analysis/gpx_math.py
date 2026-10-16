#!/usr/bin/env python3
"""
Exact integer replication of the GoldPesa GPXHooks `checkRebalance` math.

Sources (verified deployed contract, Base):
  GPXHooks   0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8
  TickMath   v4-core src/libraries/TickMath.sol (constants from verified source bundle)
  LiquidityAmounts v4-core test/utils/LiquidityAmounts.sol
  FullMath   v4-core src/libraries/FullMath.sol

All values read on-chain at Base block 52,660,634 (2026-10-16) unless noted.
"""
import math

Q96 = 1 << 96
MAX_TICK = 887272
MIN_SQRT_PRICE = 4295128739

# --- exact getSqrtPriceAtTick (v4-core TickMath) ---
def get_sqrt_price_at_tick(tick: int) -> int:
    assert -MAX_TICK <= tick <= MAX_TICK
    abs_tick = abs(tick)
    price = 0xfffcb933bd6fad37aa2d162d1a594001 if (abs_tick & 0x1) else (1 << 128)
    consts = [
        (0x2, 0xfff97272373d413259a46990580e213a), (0x4, 0xfff2e50f5f656932ef12357cf3c7fdcc),
        (0x8, 0xffe5caca7e10e4e61c3624eaa0941cd0), (0x10, 0xffcb9843d60f6159c9db58835c926644),
        (0x20, 0xff973b41fa98c081472e6896dfb254c0), (0x40, 0xff2ea16466c96a3843ec78b326b52861),
        (0x80, 0xfe5dee046a99a2a811c461f1969c3053), (0x100, 0xfcbe86c7900a88aedcffc83b479aa3a4),
        (0x200, 0xf987a7253ac413176f2b074cf7815e54), (0x400, 0xf3392b0822b70005940c7a398e4b70f3),
        (0x800, 0xe7159475a2c29b7443b29c7fa6e889d9), (0x1000, 0xd097f3bdfd2022b8845ad8f792aa5825),
        (0x2000, 0xa9f746462d870fdf8a65dc1f90e061e5), (0x4000, 0x70d869a156d2a1b890bb3df62baf32f7),
        (0x8000, 0x31be135f97d08fd981231505542fcfa6), (0x10000, 0x9aa508b5b7a84e1c677de54f3e99bc9),
        (0x20000, 0x5d6af8dedb81196699c329225ee604), (0x40000, 0x2216e584f5fa1ea926041bedfe98),
        (0x80000, 0x48a170391f7dc42444e8fa2),
    ]
    for bit, c in consts:
        if abs_tick & bit:
            price = (price * c) >> 128
    if tick > 0:
        price = (2**256 - 1) // price
    return (price + 0xFFFFFFFF) >> 32

# --- exact getTickAtSqrtPrice (v4-core TickMath) ---
def _msb(x: int) -> int:
    return x.bit_length() - 1

def get_tick_at_sqrt_price(sqrt_price_x96: int) -> int:
    if sqrt_price_x96 < MIN_SQRT_PRICE or sqrt_price_x96 >= 1461446703485210103287273052203988822378723970342:
        raise ValueError("InvalidSqrtPrice")
    price = sqrt_price_x96 << 32
    msb = _msb(price)
    r = price >> (msb - 127) if msb >= 128 else price << (127 - msb)
    log_2 = (msb - 128) << 64
    for i in range(63, 49, -1):
        r = (r * r) >> 127
        f = r >> 128
        log_2 |= f << i
        r >>= f
    log_sqrt10001 = log_2 * 255738958999603826347141
    tick_low = (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
    tick_hi = (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
    def to_int24(v):
        v &= (1 << 256) - 1
        return v - (1 << 256) if v >= (1 << 255) else v
    tick_low = to_int24(tick_low)
    tick_hi = to_int24(tick_hi)
    if tick_low == tick_hi:
        return tick_low
    return tick_hi if get_sqrt_price_at_tick(tick_hi) <= sqrt_price_x96 else tick_low

# --- LiquidityAmounts (v4-core test utils) ---
def get_amount0_for_liquidity(sp_a: int, sp_b: int, liquidity: int) -> int:
    if sp_a > sp_b:
        sp_a, sp_b = sp_b, sp_a
    # FullMath.mulDivRoundingUp(liquidity << 96, sp_b - sp_a, sp_b) / sp_a
    num = liquidity << 96
    prod = num * (sp_b - sp_a)
    den = sp_b
    # mulDivRoundingUp
    result = (prod + den - 1) // den
    return result // sp_a

def get_amount1_for_liquidity(sp_a: int, sp_b: int, liquidity: int) -> int:
    if sp_a > sp_b:
        sp_a, sp_b = sp_b, sp_a
    return (liquidity * (sp_b - sp_a)) // Q96

# --- FullMath.mulDiv (floor) ---
def mul_div(a: int, b: int, den: int) -> int:
    return (a * b) // den

# ============ LIVE STATE (Base block 52,660,634, 2026-10-16) ============
TOTAL_SUPPLY = 100_000_000 * 10**18
GPX_RESERVES = 99930888384260767462321773       # hook gpxReserves()
TREASURY_GPX = 971776010345558154699            # GPX.balanceOf(treasury)
L = 23063189219641299                            # pool liquidity == position 3106206 liquidity
SQRT_PRICE_X96 = 180051204617000423516900        # PoolManager slot0
TICK = -259906
LOWER_TICK = -275982                             # position tickLower (state lowerTick)
UPPER_TICK = 887272                              # MAX_TICK
MIN_SPREAD = 9624

def current_state(usdc=None, reserves=GPX_RESERVES, treasury=TREASURY_GPX, sp=SQRT_PRICE_X96, liq=L):
    sp_lo = get_sqrt_price_at_tick(LOWER_TICK)
    sp_hi = get_sqrt_price_at_tick(UPPER_TICK)
    gpx_in = get_amount0_for_liquidity(sp, sp_hi, liq)
    usdc_in = get_amount1_for_liquidity(sp_lo, sp, liq)
    circ = TOTAL_SUPPLY - reserves - gpx_in - treasury
    return gpx_in, usdc_in, circ

def check_rebalance(usdc_in, circ, sp=SQRT_PRICE_X96, tick=TICK, lower=LOWER_TICK, gpx_in=None, reserves=GPX_RESERVES):
    if circ == 0 or usdc_in == 0:
        return False, None
    a_x96 = mul_div(usdc_in << 192, 1, circ * sp)
    if a_x96 >= (1 << 160):
        return False, None
    sim = get_tick_at_sqrt_price(a_x96)
    ok1 = not (sim <= lower or sim >= tick)
    proposed = lower + 1
    ok2 = not (proposed + MIN_SPREAD > tick)
    if not (ok1 and ok2):
        return False, sim
    sp_a = get_sqrt_price_at_tick(proposed)
    liq_new = get_amount1_for_liquidity(sp_a, sp, usdc_in)
    gpx_needed = get_amount0_for_liquidity(sp, get_sqrt_price_at_tick(UPPER_TICK), liq_new)
    total_avail = reserves + (gpx_in if gpx_in is not None else 0)
    return (gpx_needed <= total_avail), sim

if __name__ == "__main__":
    gpx_in, usdc_in, circ = current_state()
    print(f"gpxInsideUniswap  = {gpx_in/1e18:,.6f} GPX")
    print(f"usdcInsideUniswap = {usdc_in/1e6:,.6f} USDC")
    print(f"gpxCirculating    = {circ/1e18:,.6f} GPX")
    ok, sim = check_rebalance(usdc_in, circ, gpx_in=gpx_in)
    print(f"simulatedTick     = {sim}")
    print(f"band              = ({LOWER_TICK}, {TICK})  (proposed+MIN_SPREAD <= tick: {LOWER_TICK+1+MIN_SPREAD} <= {TICK} -> {LOWER_TICK+1+MIN_SPREAD <= TICK})")
    print(f"checkRebalance    = {ok}")
    sp_lo = get_sqrt_price_at_tick(LOWER_TICK)
    sp = SQRT_PRICE_X96
    # exact trigger condition: C < L/sp_lo - L/sp  (derived: L(sp-sp_lo)/(C*sp) > sp_lo)
    # in Q96 integer terms: C < (L*Q96)/sp_lo - (L*Q96)/sp
    thr_c = (L * Q96) // sp_lo - (L * Q96) // sp
    print(f"trigger needs gpxCirculating < {thr_c/1e18:,.4f} GPX (at current price)")
    thr_c_priceinf = (L * Q96) // sp_lo
    print(f"trigger needs gpxCirculating < {thr_c_priceinf/1e18:,.4f} GPX (absolute, price->inf)")
    # price-independent form: trigger <=> treasury > N' - L/sp_lo + L/sp,  N' = C + x_pool + treasury
    N = circ + gpx_in + TREASURY_GPX
    thr_t = N - ((L * Q96) // sp_lo - (L * Q96) // sp) - gpx_in + gpx_in  # = N - thr_c - x_pool + x_pool ... simplify:
    thr_t = N - gpx_in - thr_c
    print(f"N' (non-reserve GPX) = {N/1e18:,.4f}")
    print(f"TRIGGER <=> treasuryGPX > {thr_t/1e18:,.4f} GPX  (price-independent, given currentTick>= -266357)")
    print(f"treasury today = {TREASURY_GPX/1e18:,.4f} GPX -> needs +{(thr_t-TREASURY_GPX)/1e18:,.4f} GPX more")
    print(f"theoretical max treasury = N' = {N/1e18:,.4f} GPX (full recursive fee-cycling of all non-reserve GPX)")
    print(f"=> needs {(thr_t-TREASURY_GPX)/N*100:,.1f}% of ALL non-reserve GPX absorbed into the treasury")
    print(f"payers must lose >= 2x treasury gain in fees = ~{2*(thr_t-TREASURY_GPX)/1e18:,.0f} GPX (>= ~${2*(thr_t-TREASURY_GPX)/1e18*5.1646:,.0f} nominal) for <= $28,951 extraction")
