#!/usr/bin/env python3
"""
Serum Swap live-value analysis: prices the on-chain pool state and quantifies
(a) TVL under DefiLlama prices, (b) TVL under realizable (live-DEX) prices,
(c) the maximum unprivileged *arbitrage* profit available at the pools' curve
    prices (normal AMM trading, reported separately -- NOT a bug),
(d) value classifications: H-O (LP holders), P (fee-account key), S (stuck).

Read-only, public data only.
"""
import json
import math
import os

OUT = os.path.dirname(os.path.abspath(__file__))
raw = json.load(open(os.path.join(OUT, "pools-raw.json")))
llama = {k.replace("solana:", ""): v["price"] for k, v in json.load(open("/tmp/opencode/llama_prices.json")).items()}
ds = json.load(open("/tmp/opencode/dexscreener_full.json"))

DEEP_OK = {
    "So11111111111111111111111111111111111111112",
    "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
}

# realizable price: live DEX price if a pair has >= $1k liquidity, else deep-token llama, else 0
real = {}
for m, v in ds.items():
    b = v.get("best")
    if b and (b.get("liq") or 0) >= 1000 and b.get("px"):
        real[m] = b["px"]
    elif m in DEEP_OK and m in llama:
        real[m] = llama[m]
    else:
        real[m] = 0.0
for m in llama:
    real.setdefault(m, 0.0)

PROGRAM = raw["program_id"]
pools = [p for p in raw["pools"] if p.get("is_initialized")]
FEE_NUM, FEE_DEN = 25, 10000
OWNER_NUM, OWNER_DEN = 5, 10000


def calc_fee(x, n, d):
    if n == 0 or x == 0:
        return 0
    f = (x * n) // d
    return f if f > 0 else 1


def cp_out(xin, src, dst):
    """deployed constant-product output for xin after fees (exact integer math)."""
    tf = calc_fee(xin, FEE_NUM, FEE_DEN)
    of = calc_fee(xin, OWNER_NUM, OWNER_DEN)
    tot = tf + of
    if tot >= xin or xin == 0:
        return None
    xin2 = xin - tot
    inv = src * dst
    newsrc = src + xin2
    newdst = (inv + newsrc - 1) // newsrc  # checked_ceil_div
    out = dst - newdst
    return out if out > 0 else None


def arb_cp(A, B, pa, pb, cap=10**19):
    """max profit over both directions; returns (profit_usd, detail)."""
    best = (0.0, None)
    for give, recv, p_give, p_recv, s, d, tag in (
        (B, A, pb, pa, B, A, "giveB"),
        (A, B, pa, pb, A, B, "giveA"),
    ):
        if s <= 0 or d <= 0 or p_give <= 0 or p_recv <= 0:
            continue
        # analytic optimum without fees as a starting bracket
        k = s * d
        if p_recv * k <= 0:
            continue
        x_opt = math.sqrt(k * p_recv / p_give) - s
        if x_opt <= 1:
            continue
        lo, hi = 1, min(int(x_opt * 3) + 1000, cap)
        # golden section on profit
        def profit(x):
            out = cp_out(x, s, d)
            if out is None:
                return -1
            return out * p_recv - x * p_give
        gr = (math.sqrt(5) - 1) / 2
        a, b = lo, hi
        c, dd = b - gr * (b - a), a + gr * (b - a)
        fc, fd = profit(c), profit(dd)
        for _ in range(160):
            if fc > fd:
                b, dd, fd = dd, c, fc
                c = b - gr * (b - a)
                fc = profit(c)
            else:
                a, c, fc = c, dd, fd
                dd = a + gr * (b - a)
                fd = profit(dd)
            if b - a < 2:
                break
        xbest = int(a)
        for x in range(max(1, xbest - 3), xbest + 4):
            pf = profit(x)
            if pf > best[0]:
                best = (float(pf), {"direction": tag, "amount_in_raw": x,
                                    "amount_out_raw": cp_out(x, s, d)})
    return best


def price_of(mint, table):
    return table.get(mint, 0.0)


rows = []
tot_llama = tot_real = 0.0
arb_llama_total = arb_real_total = 0.0
cp_extra_real = 0.0
for p in pools:
    da, db = p["decimals_a"], p["decimals_b"]
    ra, rb = p["reserve_a"] or 0, p["reserve_b"] or 0
    pa_l, pb_l = price_of(p["token_a_mint"], llama), price_of(p["token_b_mint"], llama)
    pa_r, pb_r = price_of(p["token_a_mint"], real), price_of(p["token_b_mint"], real)
    va_l, vb_l = ra / 10**da * pa_l, rb / 10**db * pb_l
    va_r, vb_r = ra / 10**da * pa_r, rb / 10**db * pb_r
    tot_llama += va_l + vb_l
    tot_real += va_r + vb_r
    row = {
        "pool": p["pool"], "curve": p["curve_type"], "authority_pda": p["authority_pda"],
        "token_program_id": p["token_program_id"],
        "token_a_mint": p["token_a_mint"], "token_b_mint": p["token_b_mint"],
        "decimals_a": da, "decimals_b": db,
        "vault_a": p["token_a"], "vault_b": p["token_b"],
        "reserve_a_raw": ra, "reserve_b_raw": rb,
        "reserve_a_ui": ra / 10**da, "reserve_b_ui": rb / 10**db,
        "vault_a_owner_is_pda": p["vault_a_owner_is_pda"], "vault_b_owner_is_pda": p["vault_b_owner_is_pda"],
        "pool_mint": p["pool_mint"], "lp_supply": p["lp_supply"],
        "pool_fee_account": p["pool_fee_account"],
        "fee_account_lp_balance": p["fee_account_amount"],
        "fee_account_owner": (p["refs"]["pool_fee_account"] or {}).get("owner"),
        "fees": p["fees"],
        "usd_llama": {"a": va_l, "b": vb_l, "total": va_l + vb_l},
        "usd_realizable": {"a": va_r, "b": vb_r, "total": va_r + vb_r},
        "price_llama": {"a": pa_l, "b": pb_l},
        "price_realizable": {"a": pa_r, "b": pb_r},
    }
    # arbitrage estimates (normal AMM trading)
    if p["curve_type"] == "ConstantProduct":
        pl, det_l = arb_cp(ra, rb, pa_l / 10**da, pb_l / 10**db)
        pr, det_r = arb_cp(ra, rb, pa_r / 10**da, pb_r / 10**db)
        row["arb_profit_llama_usd"] = round(pl, 2)
        row["arb_profit_realizable_usd"] = round(pr, 2)
        arb_llama_total += pl
        arb_real_total += pr
    else:
        # ConstantPrice: fixed exchange rate, raw-unit based
        price_param = p["curve_param_u64"]
        prof_r = 0.0
        detail = None
        if price_param > 0 and ra > 0 and rb > 0:
            for give_side in ("a", "b"):
                if give_side == "a":  # AtoB: dest = src/price
                    out_max = rb
                    x_needed = out_max * price_param
                    if x_needed <= ra:
                        prof = out_max / 10**db * pb_r - x_needed / 10**da * pa_r
                        if prof > prof_r:
                            prof_r, detail = prof, {"direction": "giveA", "out_raw": out_max}
                else:  # BtoA: dest = src*price
                    out_max = ra
                    x_needed = out_max // price_param + (1 if out_max % price_param else 0)
                    if x_needed <= rb:
                        prof = out_max / 10**da * pa_r - x_needed / 10**db * pb_r
                        if prof > prof_r:
                            prof_r, detail = prof, {"direction": "giveB", "out_raw": out_max}
        row["arb_profit_realizable_usd"] = round(prof_r, 2)
        row["arb_profit_llama_usd"] = round(prof_r, 2)
        row["arb_detail"] = detail
        cp_extra_real += prof_r
        arb_real_total += prof_r
        arb_llama_total += prof_r
    rows.append(row)

rows.sort(key=lambda r: -r["usd_llama"]["total"])
out = {
    "generated_at": None,
    "program_id": PROGRAM,
    "programdata": raw["programdata"],
    "slot": raw["slot"],
    "n_accounts_owned": raw["total_accounts"],
    "n_initialized_pools": raw["initialized_pools"],
    "price_source_llama": "https://coins.llama.fi/prices/current (2026-10-15)",
    "price_source_realizable": "DexScreener best pair with >= $1000 liquidity; deep tokens fall back to DefiLlama; otherwise 0",
    "totals": {
        "tvl_usd_llama_prices": round(tot_llama, 2),
        "tvl_usd_realizable_prices": round(tot_real, 2),
        "arb_profit_usd_llama_prices": round(arb_llama_total, 2),
        "arb_profit_usd_realizable_prices": round(arb_real_total, 2),
    },
    "pools": rows,
}
json.dump(out, open(os.path.join(OUT, "pools.json"), "w"), indent=1)
print(json.dumps(out["totals"], indent=1))
print("top 12 pools by llama USD:")
for r in rows[:12]:
    print(f"  {r['pool']} {r['curve']} llama=${r['usd_llama']['total']:,.2f} real=${r['usd_realizable']['total']:,.2f} arb_llama=${r['arb_profit_llama_usd']:,.2f} arb_real=${r['arb_profit_realizable_usd']:,.2f}")
print("top 12 by arb_real:")
for r in sorted(rows, key=lambda x: -(x.get('arb_profit_realizable_usd') or 0))[:12]:
    print(f"  {r['pool']} {r['curve']} arb_real=${r['arb_profit_realizable_usd']:,.2f} ({r.get('arb_detail')}) resA={r['reserve_a_ui']:.4f} resB={r['reserve_b_ui']:.4f}")
