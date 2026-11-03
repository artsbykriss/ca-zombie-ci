#!/usr/bin/env python3
"""2026-11 escalation economics: payout at the live OI caps vs live manipulation cost.
Reads escalation_snapshot.json, escalation_state_trading.json, escalation_cost.json.
Writes escalation_econ.json. Pure arithmetic on live reads; no transactions."""
import json, os

A = os.environ.get("ESCALATION_OUT", os.path.dirname(os.path.abspath(__file__)))
S = json.load(open(f"{A}/escalation_snapshot.json"))
T = json.load(open(f"{A}/escalation_state_trading.json"))
C = json.load(open(f"{A}/escalation_cost.json"))

INST = {r[1]: r for r in T["instruments"]}
LP = S["views"]["lpBankrollAvailable_usd"]
MOVES = [5, 10, 15, 30, 60, 100]


def holdback(px_bp, off_hours=True):
    if off_hours:
        lo, hi, k, p = 0.3, 10.0, 6.085, 3
    else:
        lo, hi, k, p = 0.75, 6.0, 3.597, 2
    if px_bp <= lo or px_bp >= hi:
        return 0.0
    w = hi - lo
    u = (px_bp - lo) / w
    return k * w * (u ** 2) * ((1 - u) ** p)


def payout_factor(px_bp, mult, off_hours=True):
    """USD payout per $1 of notional."""
    hb = holdback(px_bp, off_hours)
    me = max(px_bp - 0.2 - hb, 0.0) / 1e4
    if me <= 0:
        return 0.0, hb
    scale = 0.9 / (1 + 1 / (me * 15000) + 100000 / (1e6 * me * mult))
    return me * scale * 0.98, hb


out = {"block": S["block"], "lp_bankroll_usd": round(LP, 2), "generated_from": "latest-block reads",
       "note": "offHours=true at read time; holdback uses the off-hours band (0.3-10bp). Above 10bp holdback = 0.",
       "caps": {}, "full_cap_sweep": {}, "bankroll_notional_needed": {}, "max_net": None}

for sym in ("BTC", "ETH"):
    m = S["markets"][sym]
    out["caps"][sym] = {"mid": m["mid"], "longCap": m["longCap"], "shortCap": m["shortCap"],
                        "longCap_usd": round(m["longCap"] * m["mid"], 2),
                        "shortCap_usd": round(m["shortCap"] * m["mid"], 2),
                        "longHeadroom_usd": round(m["longHeadroom_usd"], 2),
                        "shortHeadroom_usd": round(m["shortHeadroom_usd"], 2)}

best = None
for sym in ("BTC", "ETH"):
    mult = int(INST[sym][13]) / 1e18
    m = S["markets"][sym]
    mid = m["mid"]
    out["full_cap_sweep"][sym] = {}
    for side, cap in (("long", m["longCap"]), ("short", m["shortCap"])):
        N = cap * mid
        out["full_cap_sweep"][sym][side] = {"N_usd": round(N, 0), "moves": {}}
        for bp in MOVES:
            f, hb = payout_factor(bp, mult)
            pay = N * f
            direction = "up" if side == "long" else "down"
            cost = C["cost"][sym][str(bp)][direction]["total_roundtrip_cost_usd"] if str(bp) in C["cost"][sym] else None
            row = {"payout_usd": round(pay, 0), "cost_usd": cost,
                   "net_usd": round(pay - cost, 0) if cost else None,
                   "payout_per_1M": round(f * 1e6, 0), "holdback_bp": round(hb, 3)}
            out["full_cap_sweep"][sym][side]["moves"][str(bp)] = row
            if cost and (best is None or row["net_usd"] > best["net_usd"]):
                best = {"market": sym, "side": side, "move_bp": bp, **row}
out["max_net"] = best

for sym in ("BTC", "ETH"):
    mult = int(INST[sym][13]) / 1e18
    out["bankroll_notional_needed"][sym] = {}
    for bp in MOVES:
        f, _ = payout_factor(bp, mult)
        out["bankroll_notional_needed"][sym][str(bp)] = round(LP / f, 0) if f else None

json.dump(out, open(f"{A}/escalation_econ.json", "w"), indent=1)

print("LP bankroll", f"${LP:,.2f}")
for sym in ("BTC", "ETH"):
    for side in ("long", "short"):
        r = out["full_cap_sweep"][sym][side]
        print(f"\n{sym} {side} cap N=${r['N_usd']:,.0f}")
        for bp in MOVES:
            x = r["moves"][str(bp)]
            print(f"  {bp:>3}bp payout ${x['payout_usd']:>10,.0f} cost ${x['cost_usd']:>10,.0f} net ${x['net_usd']:>10,.0f}")
print("\nmax net across all full-cap single-market sweeps:", best)
print("\nnotional needed to drain LP bankroll:")
for sym in ("BTC", "ETH"):
    print(" ", sym, {k: f"${v/1e6:,.1f}M" for k, v in out["bankroll_notional_needed"][sym].items()})
