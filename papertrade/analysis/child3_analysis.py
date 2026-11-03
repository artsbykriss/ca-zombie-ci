#!/usr/bin/env python3
"""Child 3 cost model v2: HL BBO-mid displacement cost from LIVE order-book depth.

Fixes vs v1: partial-bucket-aware continuous depth integration; mechB accounts
for partial consumption of the bucket containing the limit price; new best
quote after a sweep estimated at P +/- tick (uniform-density central estimate)
with a next-label variant reported; unwind coverage flags.

Mechanisms
----------
A (pure sweep): sweep asks up to P*, next best ask ~ P*+tick, best bid static.
B (limit-cross + residual): marketable limit at P*, residual rests at P* so the
   attacker's own quote becomes best bid; next ask ~ P*+tick; new mid = P*+tick/2.
Cost = consumed notional for both.

Depth model: fine 20-level book, then nSigFigs 4/3/2 aggregated buckets
(asks round UP to grid, bids round DOWN -- verified). Bucket depth uniform in
its price range; bucket notional avg = (lo+hi)/2 of the integrated range.
"""
import json, math, statistics, datetime

A = "/home/heisenberg/CA/papertrade/analysis"
GEN = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

variants = json.load(open(f"{A}/child3-depthvariants.json"))
candles = json.load(open(f"{A}/child3-candles.json"))
churn = None
try:
    churn = json.load(open(f"{A}/child3-churn.json"))
except Exception:
    pass

TICK = {"BTC": 1.0, "ETH": 0.1}
NS_STEP = {"BTC": {"ns4": 10.0, "ns3": 100.0, "ns2": 1000.0},
           "ETH": {"ns4": 1.0, "ns3": 10.0, "ns2": 100.0}}
TARGETS_BP = [5, 10, 15, 30, 60]

def ceil_tick(p, t): return math.ceil(round(p / t, 6)) * t
def floor_tick(p, t): return math.floor(round(p / t, 6)) * t

def levels_of(rec, side):
    idx = {"bid": 0, "ask": 1}.get(side, side)
    return [(float(l["px"]), float(l["sz"])) for l in rec["response"]["levels"][idx]]

def build_ladder(coin, side):
    """Rungs in sweep order with integration geometry.
    ask rung: consumes range (lo, hi], full notional = size*(lo+hi)/2
    bid rung: consumes range [lo, hi), full notional = size*(lo+hi)/2
    fine rungs are point masses: lo==hi==px, notional=px*size
    """
    rungs = []
    fine = levels_of(variants["variants"][f"{coin}_fine"], side)
    if side == "ask":
        fine = sorted(fine)
        for px, sz in fine:
            rungs.append(dict(kind="fine", lo=px, hi=px, px=px, size=sz, src="fine"))
        edge = rungs[-1]["px"] if rungs else 0.0
        for tag in ("ns4", "ns3", "ns2"):
            s = NS_STEP[coin][tag]
            for L, sz in sorted(levels_of(variants["variants"][f"{coin}_{tag}"], side)):
                if L <= edge:
                    continue
                lo, hi = L - s, L
                if lo < edge < hi:
                    frac = (hi - edge) / s
                    sz = sz * frac
                    lo = edge
                if sz <= 0 or hi <= lo:
                    continue
                rungs.append(dict(kind="bucket", lo=lo, hi=hi, px=hi, size=sz, src=tag))
            edge = max(edge, max((L for L, _ in levels_of(variants["variants"][f"{coin}_{tag}"], side)), default=edge))
        return rungs
    else:
        fine = sorted(fine, reverse=True)
        for px, sz in fine:
            rungs.append(dict(kind="fine", lo=px, hi=px, px=px, size=sz, src="fine"))
        edge = rungs[-1]["px"] if rungs else math.inf
        for tag in ("ns4", "ns3", "ns2"):
            s = NS_STEP[coin][tag]
            for L, sz in sorted(levels_of(variants["variants"][f"{coin}_{tag}"], side), reverse=True):
                if L >= edge:
                    continue
                lo, hi = L, L + s
                if lo < edge < hi:
                    frac = (edge - lo) / s
                    sz = sz * frac
                    hi = edge
                if sz <= 0 or hi <= lo:
                    continue
                rungs.append(dict(kind="bucket", lo=lo, hi=hi, px=lo, size=sz, src=tag))
            edge = min(edge, min((L for L, _ in levels_of(variants["variants"][f"{coin}_{tag}"], side)), default=edge))
        return rungs

def cost_ask_up_to(rungs, P):
    """Notional + size consumed buying all asks with px <= P."""
    tot = sz_tot = 0.0
    for r in rungs:
        if r["kind"] == "fine":
            if r["px"] <= P:
                tot += r["px"] * r["size"]; sz_tot += r["size"]
        else:
            if P >= r["hi"]:
                tot += r["size"] * (r["lo"] + r["hi"]) / 2; sz_tot += r["size"]
            elif P > r["lo"]:
                frac = (P - r["lo"]) / (r["hi"] - r["lo"])
                tot += r["size"] * frac * (r["lo"] + P) / 2
                sz_tot += r["size"] * frac
    return tot, sz_tot

def cost_bid_down_to(rungs, P):
    """Notional + size obtained selling all bids with px >= P."""
    tot = sz_tot = 0.0
    for r in rungs:
        if r["kind"] == "fine":
            if r["px"] >= P:
                tot += r["px"] * r["size"]; sz_tot += r["size"]
        else:
            if P <= r["lo"]:
                tot += r["size"] * (r["lo"] + r["hi"]) / 2; sz_tot += r["size"]
            elif P < r["hi"]:
                frac = (r["hi"] - P) / (r["hi"] - r["lo"])
                tot += r["size"] * frac * (P + r["hi"]) / 2
                sz_tot += r["size"] * frac
    return tot, sz_tot

def consume_size(ladder, size_want):
    """Consume a size from the ladder (in sweep order). Returns (notional, avg, used, covered)."""
    tot = used = 0.0
    for r in ladder:
        if used >= size_want - 1e-12:
            break
        if r["kind"] == "fine":
            take = min(r["size"], size_want - used)
            tot += take * r["px"]; used += take
        else:
            take = min(r["size"], size_want - used)
            frac = take / r["size"]
            if r["hi"] >= r["lo"]:  # ask rung lo..hi ; bid rung lo..hi
                avg = (r["lo"] + (r["lo"] + frac * (r["hi"] - r["lo"]))) / 2
            tot += take * avg; used += take
    covered = used >= size_want - 1e-9
    return tot, (tot / used if used else None), used, covered

def next_label_above(ladder, P):
    for r in ladder:
        if r["px"] > P:
            return r["px"]
    return None

def next_label_below(ladder, P):
    for r in ladder:
        if r["px"] < P:
            return r["px"]
    return None

def depth_within(rungs, bp, side, mid):
    if side == "ask":
        return cost_ask_up_to(rungs, mid * (1 + bp / 1e4))[0]
    return cost_bid_down_to(rungs, mid * (1 - bp / 1e4))[0]

# ---------------- book summary ----------------
books = {}
for coin in ("BTC", "ETH"):
    fr = variants["variants"][f"{coin}_fine"]
    bids = sorted(levels_of(fr, 0), reverse=True)
    asks = sorted(levels_of(fr, 1))
    bb, ba = bids[0][0], asks[0][0]
    mid = (bb + ba) / 2
    books[coin] = dict(
        fetched_at_utc=fr["fetched_at_utc"], api_time_ms=fr["api_time_ms"],
        best_bid=bb, best_ask=ba, mid=mid, spread=ba - bb, spread_bp=(ba - bb) / mid * 1e4,
        tick=TICK[coin], top_bid_sz=bids[0][1], top_ask_sz=asks[0][1],
        fine_reach_ask_bp=(asks[-1][0] / mid - 1) * 1e4,
        fine_reach_bid_bp=(1 - bids[-1][0] / mid) * 1e4)

lad = {coin: dict(ask=build_ladder(coin, "ask"), bid=build_ladder(coin, "bid")) for coin in ("BTC", "ETH")}
ladder_stats = {}
for coin in ("BTC", "ETH"):
    mid = books[coin]["mid"]
    ladder_stats[coin] = {}
    for side in ("ask", "bid"):
        r = lad[coin][side]
        tot = sum(x["size"] * ((x["lo"] + x["hi"]) / 2 if x["kind"] == "bucket" else x["px"]) for x in r)
        reach = ((r[-1]["px"] / mid - 1) * 1e4) if side == "ask" else ((1 - r[-1]["px"] / mid) * 1e4)
        ladder_stats[coin][side] = dict(rungs=len(r), total_notional_usd=tot, reach_bp=reach)

# consistency checks between granularities
checks = {}
for coin in ("BTC", "ETH"):
    mid = books[coin]["mid"]
    for side, tag in (("ask", 1), ("bid", 0)):
        pass
    fr = variants["variants"][f"{coin}_fine"]
    asks_f = sorted(levels_of(fr, 1)); bids_f = sorted(levels_of(fr, 0), reverse=True)
    e_ask, e_bid = asks_f[-1][0], bids_f[-1][0]
    cum_fine_ask = sum(p * s for p, s in asks_f)
    cum_fine_bid = sum(p * s for p, s in bids_f)

    def ns_cum(tag_, P, side_):
        r = build_ladder_cached(coin, tag_, side_)
        if side_ == "ask":
            return cost_ask_up_to(r, P)[0]
        return cost_bid_down_to(r, P)[0]

    _cache = {}
    def build_ladder_cached(coin_, tag_, side_):
        key = (coin_, tag_, side_)
        if key not in _cache:
            rungs = []
            s = NS_STEP[coin_][tag_]
            if side_ == "ask":
                for L, sz in sorted(levels_of(variants["variants"][f"{coin_}_{tag_}"], 1)):
                    rungs.append(dict(kind="bucket", lo=L - s, hi=L, px=L, size=sz))
            else:
                for L, sz in sorted(levels_of(variants["variants"][f"{coin_}_{tag_}"], 0), reverse=True):
                    rungs.append(dict(kind="bucket", lo=L, hi=L + s, px=L, size=sz))
            _cache[key] = rungs
        return _cache[key]

    checks[coin] = dict(
        ratio_ns4_over_fine_ask=ns_cum("ns4", e_ask, "ask") / cum_fine_ask,
        ratio_ns4_over_fine_bid=ns_cum("ns4", e_bid, "bid") / cum_fine_bid,
    )
    last4_ask = max(L for L, _ in levels_of(variants["variants"][f"{coin}_ns4"], 1))
    last4_bid = min(L for L, _ in levels_of(variants["variants"][f"{coin}_ns4"], 0))
    checks[coin].update(dict(
        ratio_ns3_over_ns4_ask=ns_cum("ns3", last4_ask, "ask") / ns_cum("ns4", last4_ask, "ask"),
        ratio_ns3_over_ns4_bid=ns_cum("ns3", last4_bid, "bid") / ns_cum("ns4", last4_bid, "bid")))

# depth context
depth_ctx = {}
for coin in ("BTC", "ETH"):
    mid = books[coin]["mid"]
    depth_ctx[coin] = {f"within_{x}bp": dict(ask_usd=depth_within(lad[coin]["ask"], x, "ask", mid),
                                             bid_usd=depth_within(lad[coin]["bid"], x, "bid", mid))
                       for x in (0.5, 1, 2.4, 5, 10, 20, 30, 60)}

# ---------------- mechanisms ----------------
FEE_TAKER = {"base_4.5bp": 4.5e-4, "diamond_2.7bp": 2.7e-4, "incident_implied_2.25bp": 2.25e-4}
FEE_MAKER_BASE = 1.5e-4

def mech_A(coin, direction, target_mid):
    t = TICK[coin]; mid = books[coin]["mid"]
    if direction == "up":
        P = 2 * target_mid - books[coin]["best_bid"] - t
        P = max(P, books[coin]["best_ask"])
        cost, size = cost_ask_up_to(lad[coin]["ask"], P)
        if size <= 0: return None
        lbl = next_label_above(lad[coin]["ask"], P)
        return dict(P_est=P, size=size, notional=cost, vwap=cost / size,
                    new_best_ask_est=P + t, new_mid_est=(books[coin]["best_bid"] + P + t) / 2,
                    new_mid_label_variant=((books[coin]["best_bid"] + lbl) / 2 if lbl else None),
                    src_end=None)
    else:
        P = 2 * target_mid - books[coin]["best_ask"] + t
        P = min(P, books[coin]["best_bid"])
        cost, size = cost_bid_down_to(lad[coin]["bid"], P)
        if size <= 0: return None
        lbl = next_label_below(lad[coin]["bid"], P)
        return dict(P_est=P, size=size, notional=cost, vwap=cost / size,
                    new_best_bid_est=P - t, new_mid_est=(books[coin]["best_ask"] + P - t) / 2,
                    new_mid_label_variant=((books[coin]["best_ask"] + lbl) / 2 if lbl else None),
                    src_end=None)

def mech_B(coin, direction, target_mid):
    t = TICK[coin]
    if direction == "up":
        P = max(books[coin]["best_ask"], target_mid - t / 2)
        cost, size = cost_ask_up_to(lad[coin]["ask"], P)
        if size <= 0: return None
        return dict(limit_px=P, size=size, notional=cost, vwap=cost / size,
                    new_mid_est=P + t / 2, new_best_ask_est=P + t)
    else:
        P = min(books[coin]["best_bid"], target_mid + t / 2)
        cost, size = cost_bid_down_to(lad[coin]["bid"], P)
        if size <= 0: return None
        return dict(limit_px=P, size=size, notional=cost, vwap=cost / size,
                    new_mid_est=P - t / 2, new_best_bid_est=P - t)

# ---------------- cost tables ----------------
cost_tables = {}
for coin in ("BTC", "ETH"):
    mid = books[coin]["mid"]
    cost_tables[coin] = dict(mid_at_snapshot=mid, moves={})
    for m in TARGETS_BP:
        entry = dict(move_bp=m, up={}, down={})
        for direction, sign in (("up", 1), ("down", -1)):
            tgt = mid * (1 + sign * m / 1e4)
            row = dict(target_mid=tgt)
            for tag, res in (("A", mech_A(coin, direction, tgt)), ("B", mech_B(coin, direction, tgt))):
                if res is None:
                    row[f"mech{tag}"] = None; row[f"roundtrip_mech{tag}"] = None; continue
                row[f"mech{tag}"] = res
                size = res["size"]; sweep_notional = res["notional"]
                if direction == "up":
                    unw, unw_vwap, unw_used, covered = consume_size(lad[coin]["bid"], size)
                    slip_buy = (res["vwap"] - mid); slip_unw = (mid - (unw_vwap or 0))
                else:
                    unw, unw_vwap, unw_used, covered = consume_size(lad[coin]["ask"], size)
                    slip_buy = (mid - res["vwap"]); slip_unw = ((unw_vwap or 0) - mid)
                slip_usd = (slip_buy + slip_unw) * size
                rt = dict(sweep_size=size, sweep_notional_usd=sweep_notional, sweep_vwap=res["vwap"],
                          sweep_slippage_bp=slip_buy / mid * 1e4,
                          unwind_notional_usd=unw, unwind_vwap=unw_vwap,
                          unwind_size_covered=covered,
                          unwind_slippage_bp=slip_unw / mid * 1e4,
                          slippage_roundtrip_usd=slip_usd,
                          slippage_roundtrip_pct_of_sweep=slip_usd / sweep_notional * 100)
                rt["fees_usd"] = {k: v * (sweep_notional + unw) for k, v in FEE_TAKER.items()}
                rt["fees_usd"]["maker_unwind_1.5bp"] = 4.5e-4 * sweep_notional + FEE_MAKER_BASE * unw
                rt["total_roundtrip_cost_usd"] = {k: slip_usd + v for k, v in rt["fees_usd"].items()}
                rt["cost_as_pct_of_notional"] = {k: v / sweep_notional * 100 for k, v in rt["total_roundtrip_cost_usd"].items()}
                slip2 = 2 * slip_buy * size
                rt["rule_2x_slippage_usd"] = slip2
                rt["rule_2x_total_usd"] = {k: slip2 + rt["fees_usd"][k] for k in rt["fees_usd"]}
                rt["cost_per_bp_usd"] = {k: v / m for k, v in rt["total_roundtrip_cost_usd"].items()}
                row[f"roundtrip_mech{tag}"] = rt
            entry[direction] = row
        cost_tables[coin]["moves"][str(m)] = entry

# first-step floor
first_step = {}
for coin in ("BTC", "ETH"):
    r = lad[coin]["ask"]; t = TICK[coin]; mid = books[coin]["mid"]
    f0 = next(x for x in r if x["kind"] == "fine")
    nxt = next_label_above(r, f0["px"]) or (f0["px"] + t)
    first_step[coin] = dict(cost_usd=f0["size"] * f0["px"], size=f0["size"],
                            new_mid_pure_sweep=(books[coin]["best_bid"] + nxt) / 2,
                            new_mid_rest_at_ask=(f0["px"] + nxt) / 2,
                            move_bp_pure_sweep=(((books[coin]["best_bid"] + nxt) / 2) / mid - 1) * 1e4,
                            move_bp_rest_at_ask=(((f0["px"] + nxt) / 2) / mid - 1) * 1e4)

# ---------------- volatility ----------------
vol = {}
for coin in ("BTC", "ETH"):
    cl = [(c["t"], float(c["c"]), float(c["h"]), float(c["l"])) for c in candles[coin]["candles"]]
    cs = [c for _, c, _, _ in cl]; hi = [h for _, _, h, _ in cl]; lo = [l for _, _, _, l in cl]
    r1 = [cs[i] / cs[i - 1] - 1 for i in range(1, len(cs))]
    a1 = [abs(x) for x in r1]
    r5 = [cs[i + 5] / cs[i] - 1 for i in range(len(cs) - 5)]
    a5 = [abs(x) for x in r5]
    rng1 = [(hi[i] - lo[i]) / cs[i] for i in range(len(cs))]
    bp = lambda x: x * 1e4
    pge = lambda arr, thr: sum(1 for x in arr if bp(x) >= thr) / len(arr)
    qs = statistics.quantiles(a1, n=100)
    events = []
    for i in range(1, len(cs)):
        d = bp(cs[i] / cs[i - 1] - 1)
        if abs(d) >= 15:
            sgn = 1 if d > 0 else -1; pre = cs[i - 1]; k_rev = None
            for k in range(1, 31):
                if i + k >= len(cs): break
                if bp(cs[i + k] / pre - 1) * sgn < 7.5:
                    k_rev = k; break
            events.append(k_rev or 31)
    peak = cs[0]; mdd = 0
    for c in cs:
        peak = max(peak, c); mdd = min(mdd, c / peak - 1)
    vol[coin] = dict(
        n_candles=len(cl),
        window_start_utc=datetime.datetime.fromtimestamp(cl[0][0] / 1000, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        window_end_utc=datetime.datetime.fromtimestamp(cl[-1][0] / 1000, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        last_price=cs[-1], rv_annualized_1m=statistics.pstdev(r1) * math.sqrt(1440 * 365),
        abs1m_bp_mean=bp(statistics.fmean(a1)), abs1m_bp_median=bp(statistics.median(a1)),
        abs1m_bp_quantiles={f"p{p}": bp(qs[p - 1]) for p in (50, 75, 90, 95, 99)},
        abs1m_bp_max=bp(max(a1)),
        prob_1m_move_ge={str(x): pge(a1, x) for x in (5, 10, 15, 30, 60)},
        prob_5m_move_ge={str(x): pge(a5, x) for x in (5, 10, 15, 30, 60)},
        prob_1m_range_ge={str(x): pge(rng1, x) for x in (5, 10, 15, 30, 60)},
        n_1m_windows=len(r1), n_5m_windows=len(r5),
        max_drawdown_24h_pct=mdd * 100, max_1m_drop_bp=bp(min(r1)), max_1m_rise_bp=bp(max(r1)),
        persistence_ge15bp_events=len(events),
        persistence_revert_median_min=(statistics.median(events) if events else None),
        persistence_revert_mean_min=(statistics.fmean(events) if events else None),
        persistence_censored_at_30min_share=(sum(1 for e in events if e == 31) / len(events) if events else None),
        persistence_revert_within_1min_share=(sum(1 for e in events if e <= 1) / len(events) if events else None),
        persistence_revert_within_5min_share=(sum(1 for e in events if e <= 5) / len(events) if events else None))

# ---------------- incident calibration ----------------
calib = {}
for coin in ("ETH", "BTC"):
    mid = books[coin]["mid"]
    rows = {}
    for m in (10, 15, 20):
        tgt = mid * (1 + m / 1e4)
        A_ = mech_A(coin, "up", tgt); B_ = mech_B(coin, "up", tgt)
        rows[str(m)] = dict(mechA_notional_usd=(A_["notional"] if A_ else None),
                            mechB_notional_usd=(B_["notional"] if B_ else None))
    calib[coin] = rows
calib["incident"] = dict(eth_mid_move_bp="10-20", flow_usd=20e6, total_volume_usd=231e6, fees_usd=52e3,
                         implied_fee_rate_bp=52e3 / 231e6 * 1e4,
                         note="public reporting as relayed in task brief (2026-10-10/11); not independently verified")

out = dict(
    generated_utc=GEN,
    snapshot_round=dict(start=variants["round_start_utc"], end=variants["round_end_utc"]),
    data_sources=dict(
        books="POST https://api.hyperliquid.xyz/info {'type':'l2Book',...} fine + nSigFigs 4/3/2",
        candles="candleSnapshot 1m last 24h", fees_doc="hyperliquid.gitbook.io fees page (fetched 2026-10-15)"),
    tick_and_mechanism_notes=dict(
        tick_rule="BTC tick $1, ETH tick $0.1 (5-significant-figure price rule at current magnitudes)",
        spreads="both quoted at 1-tick spread; any mid move requires crossing; no free quote improvement"),
    fee_assumptions=dict(perp_base_taker_bp=4.5, perp_base_maker_bp=1.5, perp_diamond_staking_taker_bp=2.7,
                         perp_top_maker_rebate_bp=-0.3, incident_implied_effective_bp=2.25,
                         source="HL fees docs 2026-10-15; incident-implied = 52k/231M"),
    books=books, ladder_stats=ladder_stats, book_consistency_checks=checks,
    depth_context=depth_ctx, first_step_floor=first_step, cost_model=cost_tables,
    volatility=vol, incident_calibration=calib, churn_observation=(churn if churn else None),
    assumptions=[
        "Single ~5s snapshot round; no book replenishment during sweep; no quote pull-back by others.",
        "Bucket depth uniform within bucket range; fine 20 levels exact; labels: asks ceil, bids floor to nSigFigs grid.",
        "After a sweep to last-fill P, next best quote estimated at P +/- tick (uniform central); label variant (next bucket edge) also reported.",
        "Mech A: best bid static. Mech B: marketable limit at P, residual rests at P, becoming best quote on its side.",
        "Unwind: aggressive taker of the exact acquired size through the untouched opposite ladder (no refill / no drift).",
        "Roundtrip slippage $ = (sweep VWAP - mid)*size + (mid - unwind VWAP)*size, sign-adjusted.",
        "Fees: charged on notional of each fill; both legs taker at 4.5bp baseline; variants reported.",
    ])
with open(f"{A}/child3-cost-model.json", "w") as f:
    json.dump(out, f, indent=1)

# console summary
for coin in ("BTC", "ETH"):
    b = books[coin]
    print(f"=== {coin} mid={b['mid']} spread={b['spread_bp']:.3f}bp @{b['fetched_at_utc']}")
    print("  consistency ratios (ns4/fine ask,bid): %.3f %.3f" % (checks[coin]["ratio_ns4_over_fine_ask"], checks[coin]["ratio_ns4_over_fine_bid"]),
          "| ns3/ns4 ask,bid: %.3f %.3f" % (checks[coin]["ratio_ns3_over_ns4_ask"], checks[coin]["ratio_ns3_over_ns4_bid"]))
    print("  ladder:", {s: f"${v['total_notional_usd']/1e6:.0f}M to {v['reach_bp']:.0f}bp" for s, v in ladder_stats[coin].items()})
    print("  depth +bp ask / -bp bid:", {k: f"${v['ask_usd']/1e6:.1f}M/${v['bid_usd']/1e6:.1f}M" for k, v in depth_ctx[coin].items()})
    for m in TARGETS_BP:
        e = cost_tables[coin]["moves"][str(m)]
        for d in ("up", "down"):
            r = e[d]
            for tag in ("A", "B"):
                mm = r[f"mech{tag}"]; rt = r[f"roundtrip_mech{tag}"]
                if mm is None:
                    print(f"  {m}bp {d} mech{tag}: n/a"); continue
                tot = rt["total_roundtrip_cost_usd"]["base_4.5bp"]
                print(f"  {m}bp {d} mech{tag}: sweep ${mm['notional']/1e6:.2f}M vwap {mm['vwap']:.2f} slip {rt['sweep_slippage_bp']:.1f}bp "
                      f"newmid~{mm['new_mid_est']:.2f} (lbl var {mm.get('new_mid_label_variant') and round(mm['new_mid_label_variant'],2)}) | unwind ${rt['unwind_notional_usd']/1e6:.2f}M ({rt['unwind_slippage_bp']:.1f}bp, cov={rt['unwind_size_covered']}) "
                      f"| fees ${rt['fees_usd']['base_4.5bp']/1e3:.1f}k | RT total ${tot/1e3:.0f}k ({rt['cost_as_pct_of_notional']['base_4.5bp']:.3f}%) | 2x-rule ${rt['rule_2x_total_usd']['base_4.5bp']/1e3:.0f}k")
    print("  first step:", {k: round(v, 4) for k, v in first_step[coin].items()})
print("vol:")
for coin in ("BTC", "ETH"):
    v = vol[coin]
    print(f"  {coin}: rv {v['rv_annualized_1m']*100:.1f}% | P1m>=15bp {v['prob_1m_move_ge']['15']*100:.2f}% P5m>=15bp {v['prob_5m_move_ge']['15']*100:.2f}% "
          f"| p99|r1| {v['abs1m_bp_quantiles']['p99']:.0f}bp max {v['abs1m_bp_max']:.0f}bp | mdd {v['max_drawdown_24h_pct']:.1f}% | events {v['persistence_ge15bp_events']} med rev {v['persistence_revert_median_min']}min")
print("calibration:", json.dumps(calib, indent=1))
