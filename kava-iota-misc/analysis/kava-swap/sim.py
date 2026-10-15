#!/usr/bin/env python3
"""Recompute Kava Swap exploit numbers from state.json (exact integer math, READ-ONLY).

Mirrors the deployed x/swap module math (kava v0.28.2, commit 686d591) exactly:
  exact-in : out = floor(R_out * floor(in*(1-fee)) / (R_in + floor(in*(1-fee))))
  exact-out: in  = ceil(ceil(R_in*out/(R_out-out)) / (1-fee))
  fee = 0.0015, applied to input denom; pool reserves keep the full input (fee accrues to pool).

Osmosis legs (pools 792/1390/1631) use the GAMM v1 constant-mean formula:
  out = R_out * (1 - (R_in/(R_in + in*(1-fee)))^(w_in/w_out))

Usage: python3 sim.py            (prints report; writes sim_output.txt)
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
S = json.load(open(os.path.join(HERE, "state.json")))

FEE = 0.0015  # kava swap fee (params: 0.001500000000000000)

DEC = {"usdx": 6, "ukava": 6, "hard": 6, "swp": 6, "bnb": 8, "btcb": 8, "busd": 8, "xrpb": 8,
       "uosmo": 6, "uatom": 6, "uakt": 6, "uusd(SifUSTC)": 6, "uluna(SifLUNC)": 6,
       "ibc/0471F1C4E7AFD3F07702BEF6DC365268D64570F7C1FDC98EA6098DD6DE59817B": 6,  # uosmo
       "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2": 6,  # uatom
       "ibc/799FDD409719A1122586A629AE8FCA17380351A51C1F47A80A1B8E7F2A491098": 6,  # uakt
       "ibc/B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C": 6,  # uusd (Sifchain USTC)
       "ibc/B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395": 6}  # uluna (Sifchain LUNC)

NICE = {"ibc/0471F1C4E7AFD3F07702BEF6DC365268D64570F7C1FDC98EA6098DD6DE59817B": "uosmo",
        "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2": "uatom",
        "ibc/799FDD409719A1122586A629AE8FCA17380351A51C1F47A80A1B8E7F2A491098": "uakt",
        "ibc/B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C": "uusd(SifUSTC)",
        "ibc/B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395": "uluna(SifLUNC)"}

LIQUID_EXIT = {"ukava": True, "uatom": True, "uosmo": True, "uakt": True,
               "bnb": False, "btcb": False, "busd": False, "xrpb": False, "hard": False,
               "swp": False, "uusd(SifUSTC)": False, "uluna(SifLUNC)": False}
# liquid = convertible to USD permissionlessly (IBC to Osmosis / external market).
# The BEP2-origin assets (bnb,btcb,busd,xrpb) can only round-trip through this same swap module;
# SWP/HARD have only tiny (<$130) Osmosis/Kava pools; Sif USTC/LUNC have no exit venue at all.

KAVA_EXIT_HAIRCUT = 0.007  # IBC to Osmosis + KAVA/OSMO->USDC swap + slippage, ~0.7%

# ---------------- load pools ----------------
pools = {}   # id -> {"a":(denomA,amtA), "b":(denomB,amtB), "shares": int}
for p in S["kava_swap_pools"]["pools"]:
    coins = p["coins"]
    pools[p["name"]] = {"coins": {c["denom"]: int(c["amount"]) for c in coins},
                        "shares": int(p["total_shares"])}

params = S["kava_swap_params"]["params"]
assert abs(float(params["swap_fee"]) - FEE) < 1e-12

# module balance consistency
modbal = {b["denom"]: int(b["amount"]) for b in S["module_balances"]["swap"]["balances"]}
sumres = {}
for pid, p in pools.items():
    for d, a in p["coins"].items():
        sumres[d] = sumres.get(d, 0) + a

# ---------------- external prices ----------------
pr = {c: v["price"] for c, v in S["prices"]["llama"]["coins"].items()}
P = {"ukava": pr["coingecko:kava"], "uosmo": pr["coingecko:osmosis"], "uatom": pr["coingecko:cosmos"],
     "uakt": pr["coingecko:akash-network"], "uusd(SifUSTC)": pr["coingecko:terrausd"],
     "uluna(SifLUNC)": pr["coingecko:terra-luna"], "bnb": pr["coingecko:binancecoin"],
     "btcb": pr["coingecko:bitcoin"], "xrpb": pr["coingecko:ripple"],
     "busd": pr["coingecko:binance-usd"], "hard": S["prices"]["hard_cg"]["kava-lend"]["usd"]}

def human(denom, raw):
    return raw / 10 ** DEC[denom]

# SWP price derived from Osmosis pool 1631 (constant-mean, spot)
o1631 = S["osmosis_pools"]["1631"]["pool"]
a_s = o1631["pool_assets"]
w = {a["token"]["denom"]: int(a["weight"]) for a in a_s}
r = {a["token"]["denom"]: int(a["token"]["amount"]) for a in a_s}
swp_den, osmo_den = [d for d in w if d != "uosmo"][0], "uosmo"
TOTW1631 = int(o1631["total_weight"])
WS, WO = w[swp_den] / TOTW1631, w[osmo_den] / TOTW1631
P["swp"] = (WS / WO) * (r[osmo_den] / 10 ** 6) / (r[swp_den] / 10 ** 6) * P["uosmo"]
# spot price of SWP in OSMO: d(out)/d(in) at 0 = (w_swp/w_osmo)*(R_osmo/R_swp)

def name(d):
    return NICE.get(d, d)

# ---------------- Kava exact math ----------------
def kava_exact_in(pool, in_denom, in_raw, fee=FEE):
    c = pools[pool]["coins"]
    out_denom = [d for d in c if d != in_denom][0]
    Rin, Rout = c[in_denom], c[out_denom]
    in_after = math.floor(in_raw * (1 - fee))
    if in_after <= 0:
        return 0, out_denom
    out = (Rout * in_after) // (Rin + in_after)
    return out, out_denom

def kava_exact_out(pool, out_denom, out_raw, fee=FEE):
    c = pools[pool]["coins"]
    in_denom = [d for d in c if d != out_denom][0]
    Rin, Rout = c[in_denom], c[out_denom]
    if out_raw >= Rout:
        return None, in_denom
    num = Rin * out_raw
    in_no_fee = -((-num) // (Rout - out_raw))  # ceil
    in_raw = math.ceil(in_no_fee / (1 - fee))
    return in_raw, in_denom

# Osmosis GAMM constant-mean exact-in
def osmo_exact_in(pool_json, in_denom, in_raw, fee):
    j = pool_json["pool"]
    a = {x["token"]["denom"]: int(x["token"]["amount"]) for x in j["pool_assets"]}
    w = {x["token"]["denom"]: int(x["weight"]) for x in j["pool_assets"]}
    out_denom = [d for d in a if d != in_denom][0]
    W = int(j["total_weight"])
    wi, wo = w[in_denom] / W, w[out_denom] / W
    Rin, Rout = a[in_denom], a[out_denom]
    in_eff = in_raw * (1 - fee)
    ratio = Rin / (Rin + in_eff)
    out = Rout * (1 - ratio ** (wi / wo))
    return math.floor(out), out_denom

# ---------------- spot table ----------------
def pool_spot_usdx(pid):
    c = pools[pid]["coins"]
    usdx = c.get("usdx")
    if not usdx:
        return None, None
    other = [d for d in c if d != "usdx"][0]
    p_other = P.get(name(other))
    if p_other is None:
        return other, None
    return other, p_other * (c[other] / 10 ** DEC[other]) / (usdx / 10 ** 6)

# ---------------- optimizer (scan + golden) ----------------
def optimize(f, lo, hi, steps=600):
    best = (f(lo), lo)
    for i in range(steps + 1):
        x = lo + (hi - lo) * i / steps
        v = f(x)
        if v > best[0]:
            best = (v, x)
    a, b = best[1] - (hi - lo) / steps, best[1] + (hi - lo) / steps
    a, b = max(lo, a), min(hi, b)
    gr = (math.sqrt(5) - 1) / 2
    c, d = b - gr * (b - a), a + gr * (b - a)
    fc, fd = f(c), f(d)
    for _ in range(120):
        if fc > fd:
            b, d, fd = d, c, fc
            c = b - gr * (b - a); fc = f(c)
        else:
            a, c, fc = c, d, fd
            d = a + gr * (b - a); fd = f(d)
    for x in (c, d, (a + b) / 2):
        v = f(x)
        if v > best[0]:
            best = (v, x)
    return best

def sell_usdx_best(usdx_raw, allow=("ukava", "uosmo", "uatom", "uakt", "bnb", "btcb", "busd", "xrpb", "hard", "swp")):
    """Sell usdx_raw into pools (greedy 1-USDX steps), return (usd_value_gross, allocation)."""
    remaining = usdx_raw
    total = 0.0
    alloc = {}
    step = 10 ** 6  # 1 USDX
    # precompute marginal value curves lazily
    while remaining > 0:
        amt = min(step, remaining)
        best = None
        for pid, p in pools.items():
            c = p["coins"]
            if "usdx" not in c:
                continue
            other = [d for d in c if d != "usdx"][0]
            if name(other) not in allow:
                continue
            out, _ = kava_exact_in(pid, "usdx", amt)
            # marginal USD value
            val = human(other, out) * P[name(other)]
            # note P for this pool is pre-trade; recompute ratio-based value:
            val = human(other, out) * P[name(other)]
            if best is None or val > best[0]:
                best = (val, pid, other, out)
        if best is None or best[0] <= 0:
            break
        total += best[0]
        remaining -= amt
        alloc[best[1]] = alloc.get(best[1], 0) + amt
        # apply the trade to pool state (update reserves like the chain does)
        pid, other, out = best[1], best[2], best[3]
        feev = amt - math.floor(amt * (1 - FEE))
        pools[pid]["coins"][other] -= out
        pools[pid]["coins"]["usdx"] += amt
    return total, alloc

def snapshot_pools():
    return {pid: dict(p["coins"]) for pid, p in pools.items()}

def restore(snap):
    for pid, c in snap.items():
        pools[pid]["coins"] = dict(c)

# ---------------- report ----------------
out = []
def pr_line(s=""):
    out.append(s)
    print(s)

h = S["heights"]
pr_line("=" * 100)
pr_line("KAVA SWAP — exploit simulation (kava v0.28.2 commit 686d591; state heights %s..%s)" % (h["kava_before"], h["kava_after"]))
pr_line("=" * 100)
pr_line("swap_fee=%.4f  allowed_pools=%d  pools=%d" % (FEE, len(params["allowed_pools"]), len(pools)))
pr_line("")

# invariant check
ok = all(modbal.get(d, 0) == a for d, a in sumres.items()) and all(
    sumres.get(d, 0) == a for d, a in modbal.items() if d in sumres)
pr_line("[check] swap module balance == sum(pool reserves): %s" % ("PASS" if ok else "FAIL"))
extra = {d: a for d, a in modbal.items() if d not in sumres}
pr_line("[check] module denoms not in any pool: %s" % (extra or "none"))
pr_line("")

pr_line("--- pool table (spot = implied USD value of 1 USDX in that pool) ---")
pr_line("%-28s %-34s %-18s %10s %14s %10s %s" % ("pool", "reserves", "usdx_reserve", "impliedUSDX", "other_side_USD", "shares", "recent_trades*"))
swap_sample = S["recent_swap_sample"]["result"]["txs"]
recent = {}
for t in swap_sample:
    try:
        for lg in json.loads(t["tx_result"]["log"]):
            for e in lg["events"]:
                if e["type"] == "swap_trade":
                    at = {a["key"]: a["value"] for a in e["attributes"]}
                    recent[at["pool_id"]] = recent.get(at["pool_id"], 0) + 1
    except Exception:
        pass
tot_real_usd_liquid = 0.0
tot_real_usd_all = 0.0
for pid in sorted(pools):
    c = pools[pid]["coins"]
    other, spot = pool_spot_usdx(pid)
    if spot is None:
        continue
    val_other = human(other, c[other]) * P[name(other)]
    tot_real_usd_all += val_other
    if LIQUID_EXIT.get(name(other), False):
        tot_real_usd_liquid += val_other
    pr_line("%-28s %-34s %-18s %10.4f %14.1f %10d %s" % (
        pid[:28],
        "%s + %s" % (("%.6f" % human(other, c[other])).rstrip('0'), ("%.6f" % human("usdx", c["usdx"])).rstrip('0')),
        ("%.2f" % human("usdx", c["usdx"])), spot, val_other, pools[pid]["shares"], recent.get(pid, 0)))
pr_line("")
pr_line("Pool-side USD value (external prices): all pools $%.0f; of which liquid-exit assets $%.0f"
        % (tot_real_usd_all, tot_real_usd_liquid))
pr_line("* recent_trades = swaps seen in the last-100-swap RPC sample (heights %s..%s)"
        % (swap_sample[-1]["height"], swap_sample[0]["height"]))
pr_line("")

base = snapshot_pools()

# --- Route A: buy cheap USDX with stranded Sifchain USTC (uusd pool) then sell for KAVA ---
def route_stranded(cheap_pool, cheap_denom, cheap_price, exit_haircut, in_raw):
    ret = {}
    px = math.floor(in_raw * (1 - FEE))
    usdx_out = (pools[cheap_pool]["coins"]["usdx"] * px) // (pools[cheap_pool]["coins"][cheap_denom] + px)
    if usdx_out <= 0:
        return -1e18, None
    # sell USDX for KAVA (single pool, exact in)
    kava_out, _ = kava_exact_in("ukava:usdx", "usdx", usdx_out)
    usd_in = human(cheap_denom, in_raw) * cheap_price
    usd_out = human("ukava", kava_out) * P["ukava"] * (1 - exit_haircut)
    return usd_out - usd_in, (in_raw, usdx_out, kava_out, usd_in, usd_out)

pr_line("--- Route A/B: buy USDX cheap with stranded Sifchain-origin USTC / LUNC, sell for KAVA ---")
for pool, denom, label in [("ibc/B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C:usdx", "ibc/B448C0CA358B958301D328CCDC5D5AD642FC30A6D3AE106FF721DB315F3DDE5C", "SifUSTC"),
                           ("ibc/B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395:usdx", "ibc/B8AF5D92165F35AB31F3FC7C7B444B9D240760FA5D406C49D24862BD0284E395", "SifLUNC")]:
    price = P[name(denom)]
    reserve_human = human(denom, pools[pool]["coins"][denom])
    hi = int(reserve_human * 10 ** DEC[denom] * 3)   # input is unbounded; search 3x reserve
    restore(base)
    v, x = optimize(lambda r: route_stranded(pool, denom, price, KAVA_EXIT_HAIRCUT, int(r))[0], 1, hi, 800)
    restore(base)
    _, det = route_stranded(pool, denom, price, KAVA_EXIT_HAIRCUT, int(x))
    in_raw, usdx_out, kava_out, usd_in, usd_out = det
    pr_line("%s: swap in %.0f %s (mkt $%.2f) -> %.2f USDX -> %.1f KAVA (worth $%.2f at market, %.1f%% exit haircut applied)"
            % (label, human(denom, in_raw), label, usd_in, human("usdx", usdx_out),
               human("ukava", kava_out), usd_out, KAVA_EXIT_HAIRCUT * 100))
    pr_line("        net profit = $%.2f (gross before exit haircut $%.2f)" % (v, usd_out / (1 - KAVA_EXIT_HAIRCUT) - usd_in))
    # also gross (no haircut)
    vg, _ = optimize(lambda r: route_stranded(pool, denom, price, 0.0, int(r))[0], 1, hi, 400)
    restore(base)
    pr_line("        gross (mark KAVA at market, no exit cost): $%.2f" % vg)
pr_line("")

# --- Route C: SWP -> USDX (Kava swp pool) <- SWP bought on Osmosis pool 1631 ---
def route_swp(in_osmo_raw):
    swp_out, _, _ = osmo_exact_in(S["osmosis_pools"]["1631"], "uosmo", int(in_osmo_raw), 0.0005), None, None
    swp_out = swp_out[0]
    if swp_out <= 0:
        return -1e18, None
    usdx_out, _ = kava_exact_in("swp:usdx", "swp", swp_out)
    kava_out, _ = kava_exact_in("ukava:usdx", "usdx", usdx_out)
    usd_in = human("uosmo", in_osmo_raw) * P["uosmo"]
    usd_out = human("ukava", kava_out) * P["ukava"] * (1 - KAVA_EXIT_HAIRCUT)
    return usd_out - usd_in, (swp_out, usdx_out, kava_out, usd_in, usd_out)

restore(base)
osm_osmo_res = int(S["osmosis_pools"]["1631"]["pool"]["pool_assets"][1]["token"]["amount"])
v, x = optimize(lambda r: route_swp(int(r))[0], 1, osm_osmo_res * 0.9, 800)
restore(base)
if v > 0:
    _, det = route_swp(int(x))
    pr_line("--- Route C: SWP (Osmosis pmkt) -> USDX (Kava) -> KAVA  => net $%.2f  [in %.0f OSMO, SWP %.0f, USDX %.2f, KAVA %.1f]" % (v, human("uosmo", int(x)), det[0], human("usdx", det[1]), human("ukava", det[2])))
else:
    pr_line("--- Route C: SWP -> USDX -> KAVA => no profit (best $%.2f)" % v)
pr_line("")

# --- Route D: USDX bought on Osmosis pool 1390 (5% fee) -> sold into Kava pools ---
def route_osm_usdx(in_osmo_raw):
    usdx_out, _ = osmo_exact_in(S["osmosis_pools"]["1390"], "uosmo", int(in_osmo_raw), 0.05)
    if usdx_out <= 0:
        return -1e18, None
    usd_in = human("uosmo", in_osmo_raw) * P["uosmo"]
    # sell USDX via greedy best across pools (liquid exits only for honesty: kava/atom/osmo/akt)
    restore(base)
    total, alloc = sell_usdx_best(usdx_out, allow=("ukava",))
    usd_out = total * (1 - KAVA_EXIT_HAIRCUT)
    restore(base)
    return usd_out - usd_in, (usdx_out, usd_in, usd_out, alloc)

restore(base)
osm_usdx_res = int(S["osmosis_pools"]["1390"]["pool"]["pool_assets"][0]["token"]["amount"])
v, x = optimize(lambda r: route_osm_usdx(int(r))[0], 1, 10 ** 12, 600)
restore(base)
_, det = route_osm_usdx(int(x))
pr_line("--- Route D: USDX bought on Osmosis pool 1390 (5%% fee) -> sold into Kava ukava pool => net $%.2f  [in %.0f OSMO ($%.2f), USDX %.2f, back $%.2f]" % (v, human("uosmo", int(x)), det[1], human("usdx", det[0]), det[2]))
pr_line("")

# --- Route E: cross-pool scan among Kava pools (input asset A -> USDX -> output asset B) ---
pr_line("--- Route E: best cross-pool cycles on Kava swap (external-value P&L, gross mark-to-market) ---")
results = []
for pidi in pools:
    ci = pools[pidi]["coins"]
    if "usdx" not in ci:
        continue
    ai = [d for d in ci if d != "usdx"][0]
    for pidj in pools:
        if pidj == pidi:
            continue
        cj = pools[pidj]["coins"]
        if "usdx" not in cj:
            continue
        bj = [d for d in cj if d != "usdx"][0]
        if name(bj) not in ("ukava", "uatom", "uosmo", "uakt"):
            continue  # require realistic exit asset

        def f(in_raw):
            restore(base)
            usdx_mid, _ = kava_exact_in(pidi, ai, int(in_raw))
            b_out, _ = kava_exact_in(pidj, "usdx", usdx_mid)
            restore(base)
            usd_in = human(ai, int(in_raw)) * P[name(ai)]
            usd_out = human(bj, b_out) * P[name(bj)] * (1 - KAVA_EXIT_HAIRCUT)
            return usd_out - usd_in

        cap = int(human(ai, ci[ai]) * 10 ** DEC[ai] * 3)
        v, x = optimize(f, 1, max(2, cap), 300)
        if v > 0.01:
            results.append((v, pidi, pidj, int(x)))
results.sort(reverse=True)
for v, pidi, pidj, x in results[:8]:
    ai = [d for d in pools[pidi]["coins"] if d != "usdx"][0]
    bj = [d for d in pools[pidj]["coins"] if d != "usdx"][0]
    pr_line("  buy USDX with %-6s in %-22s -> sell USDX for %-6s in %-22s : net $%.2f (in %.6f)" % (
        name(ai), pidi[:22], name(bj), pidj[:22], v, human(ai, x)))
if not results:
    pr_line("  no profitable cycle found")
pr_line("")

# --- Route F: drain curves vs hypothetical USDX acquisition price ---
pr_line("--- Route F: value-at-risk — what each pool pays if attacker can obtain USDX at price p ---")
pr_line("(per pool: buy the pool's non-USDX asset with USDX; mark at market; no exit haircut)")
pr_line("%-44s %8s %8s %8s %8s %8s" % ("pool", "p=0", "p=0.1", "p=0.3", "p=0.5", "p=0.626"))
for pid in sorted(pools):
    c = pools[pid]["coins"]
    if "usdx" not in c:
        continue
    other = [d for d in c if d != "usdx"][0]
    outv = []
    for p in (0.0, 0.1, 0.3, 0.5, 0.6263):
        def f(u_raw, other=other, pid=pid, p=p):
            restore(base)
            o, _ = kava_exact_in(pid, "usdx", int(u_raw))
            restore(base)
            return human(other, o) * P[name(other)] - human("usdx", int(u_raw)) * p
        cap = int(human("usdx", c["usdx"]) * 0.98) * 10 ** 6
        v, x = optimize(f, 1, max(2, cap), 200)
        outv.append(max(v, 0))
    pr_line("%-44s %8.1f %8.1f %8.1f %8.1f %8.1f" % (pid[:44], *outv))
tot = [0.0] * 5
for pid in sorted(pools):
    c = pools[pid]["coins"]
    if "usdx" not in c:
        continue
    other = [d for d in c if d != "usdx"][0]
    for i, p in enumerate((0.0, 0.1, 0.3, 0.5, 0.6263)):
        def f(u_raw, other=other, pid=pid, p=p):
            restore(base)
            o, _ = kava_exact_in(pid, "usdx", int(u_raw))
            restore(base)
            return human(other, o) * P[name(other)] - human("usdx", int(u_raw)) * p
        cap = int(human("usdx", c["usdx"]) * 0.98) * 10 ** 6
        v, x = optimize(f, 1, max(2, cap), 120)
        tot[i] += max(v, 0)
pr_line("%-44s %8.1f %8.1f %8.1f %8.1f %8.1f" % ("TOTAL (USDX at price p, unlimited supply)", *tot))
pr_line("")
pr_line("(p = attacker's USD cost per USDX; p=0 => free USDX; p=0.6263 = current marginal Osmosis USDX price)")
pr_line("")

# --- Route G: recent activity summary ---
pr_line("--- recent swap activity (per pool, last-100-swap sample) ---")
for pid in sorted(recent, key=lambda x: -recent[x]):
    pr_line("  %-60s %d" % (pid[:60], recent[pid]))
pr_line("  pools NOT traded in sample: %s" % sorted(set(pools) - set(recent)))
pr_line("")
pr_line("kava_swap_params.allowed_pools but no pool created: %s" % [
    x for x in ["uabc:ukava"] if x not in pools])

with open(os.path.join(HERE, "sim_output.txt"), "w") as f:
    f.write("\n".join(out) + "\n")
print("\nwrote sim_output.txt")
