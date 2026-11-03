#!/usr/bin/env python3
"""Papertrade Z3-C3 economics model.
Payout formula from the protocol's own docs (QueueLib.applyMarketImpact):
  adjustedPnl = rawPnl * scale ; scale = (1-baseRate)/(1 + term1 + term2)
  term1 = 1/(move_eff*rateMultiplier) ; term2 = referenceNotional/(1e6*move_eff*positionMultiplier)
  move_eff = move - deadband (deadband = entryPrice/50000 = 0.2bp)
  win fee 2% applied to the scaled gain.
Manipulation cost from child3 (live HL L2 books, 2026-10-15 23:10 UTC):
  round-trip cost (taker sweep + taker unwind, no refill) + fee variants.
Outputs analysis/economics.json + printed tables."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
C3 = json.load(open(os.path.join(HERE, "child3-cost-model.json")))
SNAP = json.load(open(os.path.join(HERE, "final_snapshot.json")))

INSTR = {
    "BTC": {"rateMultiplier": 15000.0, "positionMultiplier": 814.598, "baseRate": 0.10, "referenceNotional": 100000.0},
    "ETH": {"rateMultiplier": 15000.0, "positionMultiplier": 483.979, "baseRate": 0.10, "referenceNotional": 100000.0},
}
DEADBAND = 0.00002  # 0.2 bp
WIN_FEE = 0.98

def scale(move_eff, mult):
    t1 = 1.0 / (move_eff * 15000.0)
    t2 = 100000.0 / (1e6 * move_eff * mult)
    return (1 - 0.10) / (1 + t1 + t2)

def payout(N, move_bp, market):
    p = INSTR[market]
    me = max(move_bp/1e4 - DEADBAND, 0.0)
    if me <= 0: return 0.0
    return N * me * scale(me, p["positionMultiplier"]) * WIN_FEE

def cost(market, direction, move_bp, fee_variant):
    """child3 mechB roundtrip total (taker unwind)"""
    m = C3["cost_model"][market]["moves"][str(move_bp)][direction]["roundtrip_mechB"]
    return m["total_roundtrip_cost_usd"][fee_variant], m

def cost_slow_unwind(market, direction, move_bp, fee_bp=2.25):
    """sweep slip + 2bp unwind (book partially refilled) + fees both legs at fee_bp"""
    m = C3["cost_model"][market]["moves"][str(move_bp)][direction]["roundtrip_mechB"]
    slip = m["sweep_notional_usd"] * (m["sweep_slippage_bp"] + 2.0) / 1e4
    fees = (m["sweep_notional_usd"] + m["unwind_notional_usd"]) * fee_bp / 1e4
    return slip + fees, m

def cost_fees_only(market, direction, move_bp, fee_bp=2.25):
    m = C3["cost_model"][market]["moves"][str(move_bp)][direction]["roundtrip_mechB"]
    return (m["sweep_notional_usd"] + m["unwind_notional_usd"]) * fee_bp / 1e4, m

out = {"generated": "2026-10-16 (UTC)", "payout_factors_per_1M": {}, "instant_headroom": {}, "tables": {}, "breakeven": {}, "scenarios": {}, "envelope": {}}

MOVES = [5, 10, 15, 30]
VARIANTS = ["incident_implied_2.25bp", "diamond_2.7bp", "base_4.5bp"]

# 1) payout factor per $1M of deployable notional
for mk in ("BTC", "ETH"):
    out["payout_factors_per_1M"][mk] = {}
    for m in MOVES + [60]:
        out["payout_factors_per_1M"][mk][str(m)] = round(payout(1e6, m, mk), 2)

# 2) instant-headroom tables (from final snapshot)
hr = {
    "BTC": {"up": SNAP["markets"]["BTC"]["longHeadroom_usd"], "down": SNAP["markets"]["BTC"]["shortHeadroom_usd"]},
    "ETH": {"up": SNAP["markets"]["ETH"]["longHeadroom_usd"], "down": SNAP["markets"]["ETH"]["shortHeadroom_usd"]},
}
out["instant_headroom"] = hr
for mk in ("BTC", "ETH"):
    for d in ("up", "down"):
        N = hr[mk][d]
        for m in MOVES:
            pay = payout(N, m, mk)
            row = {"N_usd": round(N,0), "move_bp": m, "payout_usd": round(pay,0)}
            for v in VARIANTS:
                c, _ = cost(mk, d, m, v)
                row[v] = {"cost": round(c,0), "net": round(pay - c,0)}
            c_slow, _ = cost_slow_unwind(mk, d, m)
            c_floor, _ = cost_fees_only(mk, d, m)
            row["slow_unwind_2.25bp"] = {"cost": round(c_slow,0), "net": round(pay - c_slow,0)}
            row["fees_only_floor_2.25bp"] = {"cost": round(c_floor,0), "net": round(pay - c_floor,0)}
            out["tables"].setdefault(mk, {}).setdefault(d, {})[str(m)] = row

# 3) break-even N
for mk in ("BTC","ETH"):
    for d in ("up","down"):
        for m in MOVES:
            pay1 = payout(1e6, m, mk)  # per $1M
            be = {}
            for v in VARIANTS:
                c,_ = cost(mk,d,m,v); be[v] = round(c / pay1 * 1e6, 0)
            c,_ = cost_slow_unwind(mk,d,m); be["slow_unwind_2.25bp"] = round(c/pay1*1e6,0)
            c,_ = cost_fees_only(mk,d,m); be["fees_only_floor_2.25bp"] = round(c/pay1*1e6,0)
            out["breakeven"].setdefault(mk,{}).setdefault(d,{})[str(m)] = be

# 4) accumulation scenarios (N = 25/50/100/200M), ETH up, costs at 2.25bp / slow unwind; hedge 3-9bp of N
for mk in ("ETH","BTC"):
    for d in ("up",):
        for m in (15,30):
            for N in (25e6, 50e6, 100e6, 200e6):
                pay = payout(N, m, mk)
                rows = {"N": N, "move_bp": m, "payout": round(pay,0)}
                c_fast,_ = cost(mk,d,m,"incident_implied_2.25bp")
                c_slow,_ = cost_slow_unwind(mk,d,m)
                rows["cost_fast_2.25bp"] = round(c_fast,0)
                rows["net_nohedge_fast"] = round(pay-c_fast,0)
                rows["cost_slow_2.25bp"] = round(c_slow,0)
                rows["net_nohedge_slow"] = round(pay-c_slow,0)
                for hbp in (3,9):
                    hedge = N*hbp/1e4
                    rows[f"net_hedge{hbp}bp_slow"] = round(pay-c_slow-hedge,0)
                out["scenarios"].setdefault(mk,{}).setdefault(d,{}).setdefault(str(m),{})[str(int(N))] = rows

# 5) envelope
bank = SNAP["views"]["lpBankrollAvailable_usd"]
out["envelope"] = {
    "lp_bankroll_usd": round(bank,2),
    "instant_headroom_net_typical_usd": "negative at all moves tested (see tables)",
    "conditional_per_cycle_usd": "approx +9k..+62k (N=50M, 30bp, no hedge) / +40k..+145k (N=100M, 30bp)",
    "cycles_per_day": "accumulation ~4-6 min (keeper refills ~$9M every 15-30s) + manipulation/close/unwind ~2-5 min -> ~5-10 cycles/h theoretically; response-limited in practice",
    "hard_ceiling_usd": round(bank,2),
    "realistic_total_before_response_usd": "0.1M-2M (wide uncertainty; relayer policy + guardian response are the gating unknowns)",
}

json.dump(out, open(os.path.join(HERE,"economics.json"),"w"), indent=1)

# print key tables
print("== payout per $1M notional ==")
for mk in ("BTC","ETH"):
    print(mk, {k: "%.2f" % v for k,v in out["payout_factors_per_1M"][mk].items()})
print("\n== instant headroom (USD) ==", {k: {d: round(v) for d,v in x.items()} for k,x in hr.items()})
print("\n== net per cycle at instant headroom (2.25bp fees, taker unwind) ==")
for mk in ("BTC","ETH"):
    for d in ("up","down"):
        for m in MOVES:
            r=out["tables"][mk][d][str(m)]
            print(f"{mk:3s} {d:4s} {m:2d}bp: N=${r['N_usd']:>10,.0f} payout=${r['payout_usd']:>8,.0f} cost=${r['incident_implied_2.25bp']['cost']:>9,.0f} net=${r['incident_implied_2.25bp']['net']:>9,.0f} | slow-unwind net=${r['slow_unwind_2.25bp']['net']:>9,.0f} | fees-only net=${r['fees_only_floor_2.25bp']['net']:>9,.0f}")
print("\n== break-even N (USD) ==")
for mk in ("BTC","ETH"):
    for d in ("up","down"):
        for m in MOVES:
            print(mk,d,m,"bp:", {k: "${:,.0f}".format(v) for k,v in out["breakeven"][mk][d][str(m)].items()})
print("\n== accumulation scenarios (ETH up) ==")
for m in ("15","30"):
    for N,r in out["scenarios"]["ETH"]["up"][m].items():
        print(f"ETH up {m}bp N=${int(N)/1e6:>4.0f}M payout=${r['payout']:>9,.0f} net_fast=${r['net_nohedge_fast']:>9,.0f} net_slow=${r['net_nohedge_slow']:>9,.0f} net_hedge3bp=${r['net_hedge3bp_slow']:>9,.0f} net_hedge9bp=${r['net_hedge9bp_slow']:>9,.0f}")
