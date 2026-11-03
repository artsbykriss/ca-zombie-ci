#!/usr/bin/env python3
"""2026-11 escalation: live HL BBO-mid displacement cost (mech B, cross-and-rest),
fine book + nSigFigs 4/3/2 buckets, taker unwind. Read-only public API.
Writes escalation_cost.json. Companion to child3-cost-model (Oct-15) - does not
modify it."""
import json, os, math, time, urllib.request

COINS = ["BTC", "ETH"]
TICK = {"BTC": 1.0, "ETH": 0.1}
NS_STEP = {"BTC": {"ns4": 10.0, "ns3": 100.0, "ns2": 1000.0},
           "ETH": {"ns4": 1.0, "ns3": 10.0, "ns2": 100.0}}


def hl(body):
    r = urllib.request.Request("https://api.hyperliquid.xyz/info",
                               data=json.dumps(body).encode(),
                               headers={"Content-Type": "application/json",
                                        "User-Agent": "Mozilla/5.0"})
    return json.loads(urllib.request.urlopen(r, timeout=25).read())


def levels(rec, side):
    return [(float(l["px"]), float(l["sz"])) for l in rec["levels"][0 if side == "bid" else 1]]


def ladder(coin, side, books):
    """Rungs (lo, hi, size) in sweep order; fine then ns4/ns3/ns2, de-overlapped."""
    rungs = []
    fine = sorted(levels(books[f"{coin}_fine"], side), reverse=(side == "bid"))
    for px, sz in fine:
        rungs.append((px, px, sz, "fine"))
    edge = fine[-1][0] if fine else 0.0
    for tag in ("ns4", "ns3", "ns2"):
        step = NS_STEP[coin][tag]
        lv = sorted(levels(books[f"{coin}_{tag}"], side), reverse=(side == "bid"))
        for px, sz in lv:
            lo, hi = px - step / 2, px + step / 2
            if side == "ask":
                lo = max(lo, edge)
                if hi <= edge + 1e-9:
                    continue
            else:
                hi = min(hi, edge)
                if lo >= edge - 1e-9:
                    continue
            size = sz * (hi - lo) / step if step else sz
            if size <= 0:
                continue
            rungs.append((lo, hi, size, tag))
        edge = (min(x[0] for x in lv) - step / 2) if side == "bid" and lv else edge
        if side == "ask" and lv:
            edge = max(x[0] for x in lv) + step / 2
    return rungs


def consume(rungs, limit, side):
    """Consume rungs until price limit. Returns (notional, size, vwap, filled)."""
    notional = size = 0.0
    for lo, hi, sz, src in rungs:
        if side == "ask":
            if lo > limit:
                break
            if hi <= limit:
                take = sz
            else:
                take = sz * max(0.0, (limit - lo) / (hi - lo)) if hi > lo else 0.0
        else:
            if hi < limit:
                break
            if lo >= limit:
                take = sz
            else:
                take = sz * max(0.0, (hi - limit) / (hi - lo)) if hi > lo else 0.0
        if take <= 0:
            continue
        px = (lo + hi) / 2 if hi > lo else lo
        notional += take * px
        size += take
        if take < sz - 1e-12:
            break
    return notional, size, (notional / size if size else 0.0), size > 0


books = {}
meta = {}
for c in COINS:
    books[f"{c}_fine"] = hl({"type": "l2Book", "coin": c})
    for ns in (4, 3, 2):
        books[f"{c}_ns{ns}"] = hl({"type": "l2Book", "coin": c, "nSigFigs": ns})
        time.sleep(0.25)
    bid = levels(books[f"{c}_fine"], "bid")[0][0]
    ask = levels(books[f"{c}_fine"], "ask")[0][0]
    meta[c] = {"bid": bid, "ask": ask, "mid": (bid + ask) / 2,
               "spread_bp": (ask - bid) / ((bid + ask) / 2) * 10000}

out = {"generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
       "source": "api.hyperliquid.xyz/info l2Book", "meta": meta, "cost": {}}
FEE_BP = 4.5
for c in COINS:
    mid = meta[c]["mid"]
    tick = TICK[c]
    out["cost"][c] = {}
    for bp in (5, 10, 15, 30, 60, 100):
        out["cost"][c][str(bp)] = {}
        for direction in ("up", "down"):
            target = mid * (1 + bp / 1e4) if direction == "up" else mid * (1 - bp / 1e4)
            if direction == "up":
                P = target - tick / 2
                notional, size, vwap, ok = consume(ladder(c, "ask", books), P, "ask")
                back_n, back_sz, back_vwap, _ = consume(ladder(c, "bid", books), 0.0, "bid")
                # unwind the acquired size against the untouched bid ladder
                rem = size
                proceeds = 0.0
                for lo, hi, sz, src in ladder(c, "bid", books):
                    take = min(rem, sz)
                    px = (lo + hi) / 2 if hi > lo else lo
                    proceeds += take * px
                    rem -= take
                    if rem <= 1e-12:
                        break
                slip = notional - proceeds
            else:
                P = target + tick / 2
                notional, size, vwap, ok = consume(ladder(c, "bid", books), P, "bid")
                proceeds = 0.0
                rem = size
                for lo, hi, sz, src in ladder(c, "ask", books):
                    take = min(rem, sz)
                    px = (lo + hi) / 2 if hi > lo else lo
                    proceeds += take * px
                    rem -= take
                    if rem <= 1e-12:
                        break
                slip = proceeds - notional
            fees = (notional + proceeds) * FEE_BP / 1e4
            out["cost"][c][str(bp)][direction] = {
                "target_mid": round(target, 4),
                "sweep_limit": round(P, 4),
                "sweep_notional_usd": round(notional, 0),
                "size": round(size, 4),
                "sweep_vwap": round(vwap, 4),
                "unwind_proceeds_usd": round(proceeds, 0),
                "roundtrip_slippage_usd": round(slip, 0),
                "fees_4.5bp_usd": round(fees, 0),
                "total_roundtrip_cost_usd": round(slip + fees, 0),
                "full_fill": bool(ok),
            }
OUTDIR = os.environ.get("ESCALATION_OUT", "/home/heisenberg/CA/papertrade/analysis")
json.dump(out, open(os.path.join(OUTDIR, "escalation_cost.json"), "w"), indent=1)
print(json.dumps(out["meta"], indent=1))
for c in COINS:
    for bp in ("10", "15", "30"):
        for d in ("up", "down"):
            r = out["cost"][c][bp][d]
            print(c, bp + "bp", d, "sweep $%.1fM" % (r["sweep_notional_usd"] / 1e6),
                  "cost $%s" % format(r["total_roundtrip_cost_usd"], ","),
                  "slip $%s" % format(r["roundtrip_slippage_usd"], ","))
