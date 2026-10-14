#!/usr/bin/env python3
"""Merge all collected data into era-positions-raw.json + era-positions-summary.md."""
import glob, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = ["rfUSDCe", "rfETH", "rfWBTC", "rfUSDT", "rfZK", "rfUSDC"]
LABEL = {"rfUSDCe": "USDC.e", "rfETH": "ETH (native)", "rfWBTC": "WBTC",
         "rfUSDT": "USDT", "rfZK": "ZK", "rfUSDC": "USDC (native)"}


def load_config():
    c = json.load(open(os.path.join(HERE, "era-positions-config.json")))
    cfg = c["cfg"]
    out = {"block": c["block"], "oracle": c["oracle"], "raw": cfg}
    for m in MARKETS:
        mk = cfg[f"{m}|markets"]["raw"]
        out[m] = {
            "decimals": int(cfg[f"{m}|decimals"]["raw"], 16),
            "cf": int(mk[66:130], 16),
            "listed": int(mk[2:66], 16),
            "totalSupply": int(cfg[f"{m}|totalSupply"]["raw"], 16),
            "totalBorrows": int(cfg[f"{m}|totalBorrows"]["raw"], 16),
            "cash": int(cfg[f"{m}|cash"]["raw"], 16),
            "xrate": int(cfg[f"{m}|xrate"]["raw"], 16),
            "price": int(cfg[f"{m}|price"]["raw"], 16),
        }
    out["closeFactor"] = int(cfg["closeFactor"]["raw"], 16) if cfg["closeFactor"].get("raw") else 500000000000000000
    out["liqIncentive"] = int(cfg["liqIncentive"]["raw"], 16) if cfg["liqIncentive"].get("raw") else 1080000000000000000
    return out


def usd(underlying, dec, price):
    if underlying is None or price is None:
        return None
    return underlying * price / 1e18 / 1e18


def merge_state():
    accounts = {}
    for name in ["era-positions-topstate.json", "era-positions-whales.json"]:
        p = os.path.join(HERE, name)
        if os.path.exists(p):
            d = json.load(open(p))
            for a, st in (d.get("accounts") or {}).items():
                tgt = accounts.setdefault(a, {"snapshots": {}, "liquidity": None, "src": []})
                for m, s in (st.get("snapshots") or {}).items():
                    if isinstance(s, list) and len(s) == 4:
                        tgt["snapshots"][m] = s
                if st.get("liquidity") and "err" in (st.get("liquidity") or {}):
                    tgt["liquidity"] = st["liquidity"]
                tgt["src"].append(name.replace("era-positions-", "").replace(".json", ""))
    # debt-only info from borrow reads (no snapshots, just borrowBalanceStored)
    debt = {}
    for fp in glob.glob(os.path.join(HERE, "era-positions-borrows*.json")):
        try:
            d = json.load(open(fp))
        except Exception:
            continue
        for k, v in (d.get("pairs") or {}).items():
            if isinstance(v, int) and v > 0:
                m, a = k.split("|")
                if v > debt.get((a, m), 0):
                    debt[(a, m)] = v
    return accounts, debt


def main():
    cfg = load_config()
    accounts, debt = merge_state()
    rows = []
    for a, st in accounts.items():
        coll, dbt = {}, {}
        cu = du = 0.0
        for m in MARKETS:
            s = st["snapshots"].get(m)
            if not isinstance(s, list):
                continue
            _, cbal, bbal, xr = s
            p = cfg[m]
            if cbal and cbal > 0:
                und = cbal * (xr or p["xrate"]) / 1e18
                v = usd(und, p["decimals"], p["price"])
                coll[m] = {"shares": cbal, "underlying": und, "usd": v}
                cu += v or 0
            if bbal and bbal > 0:
                v = usd(bbal, p["decimals"], p["price"])
                dbt[m] = {"balance": bbal, "usd": v}
                du += v or 0
        if not coll and not dbt:
            continue
        liq = st.get("liquidity") or {}
        sf = liq.get("shortfall")
        adj = sum((coll[m]["usd"] or 0) * (cfg[m]["cf"] / 1e18) for m in coll)
        row = {"account": a, "collateral_usd": cu, "debt_usd": du,
               "collateral_adjusted_usd": adj, "shortfall_raw": sf,
               "shortfall_usd": (sf / 1e18) if isinstance(sf, int) else None,
               "collateral": coll, "debt": dbt, "src": st.get("src")}
        rows.append(row)
    rows.sort(key=lambda r: -(r["debt_usd"] or 0))
    underwater = [r for r in rows if isinstance(r.get("shortfall_usd"), float) and r["shortfall_usd"] > 0]
    underwater.sort(key=lambda r: -r["shortfall_usd"])
    close = cfg["closeFactor"] / 1e18
    inc = cfg["liqIncentive"] / 1e18
    for r in underwater:
        repay = close * r["debt_usd"]
        r["liq"] = {"max_repay_usd": repay, "seize_usd": repay * inc, "bonus_usd": repay * (inc - 1)}
    # also flag "negative-adjusted" accounts (my own check) not caught by shortfall
    nearmiss = [r for r in rows if r not in underwater and r["debt_usd"] > 0 and r["collateral_adjusted_usd"] < r["debt_usd"]]

    # event counts from scan segments
    ev = {}
    for fp in glob.glob(os.path.join(HERE, "era-positions-rpcsegments-*.json")):
        base = os.path.basename(fp)
        m = base.replace("era-positions-rpcsegments-", "").split("-")[0].replace(".json", "")
        try:
            st = json.load(open(fp))
        except Exception:
            continue
        e = ev.setdefault(m, {"n_logs": 0, "failed": 0, "done_segments": 0, "topics": {}})
        e["n_logs"] += st.get("n_logs", 0)
        e["failed"] += len(st.get("failed", []))
        e["done_segments"] += len(st.get("done", []))
        for t, n in (st.get("topic_counts") or {}).items():
            e["topics"][t] = e["topics"].get(t, 0) + n
    T = {"0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
         "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
         "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
         "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
         "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
         "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer"}
    ev_named = {}
    for m, e in ev.items():
        ev_named[m] = {"n_logs": e["n_logs"], "failed_segments": e["failed"],
                       "counts": {T.get(k, k[:14]): v for k, v in e["topics"].items()}}

    raw = {"block": cfg["block"], "comptroller": "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2",
           "oracle": cfg["oracle"], "closeFactor": cfg["closeFactor"], "liqIncentive": cfg["liqIncentive"],
           "market_params": {m: cfg[m] for m in MARKETS},
           "event_counts": ev_named,
           "n_accounts_state": len(accounts), "n_rows_with_positions": len(rows),
           "n_underwater": len(underwater), "underwater": underwater,
           "positions": rows[:5000],
           "debt_pairs_read": {f"{a}|{m}": v for (a, m), v in sorted(debt.items(), key=lambda kv: -kv[1])[:20000]},
           "near_miss_negative_adjusted": nearmiss[:50]}
    json.dump(raw, open(os.path.join(HERE, "era-positions-raw.json"), "w"), indent=1)
    print(f"raw json: {len(accounts)} accounts with state, {len(rows)} with positions, {len(underwater)} underwater, {len(nearmiss)} near-miss")

    # summary md
    L = []
    L.append("# ReactorFusion (zkSync Era) — borrower / depositor / liquidation scan")
    L.append("")
    L.append(f"- **Block**: {cfg['block']} (all state reads at this block unless noted)")
    L.append(f"- Comptroller `0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2`, Oracle `{cfg['oracle']}`")
    L.append(f"- closeFactor = {close:g}, liquidationIncentive = {inc:g}")
    L.append(f"- Accounts with on-chain state read: **{len(accounts)}**; with positions: **{len(rows)}**; underwater (shortfall>0): **{len(underwater)}**")
    L.append("")
    L.append("## Markets (live, at scan block)")
    L.append("")
    L.append("| market | underlying | listed | CF | decimals | price USD | totalSupply (underlying) | totalBorrows | cash | supply USD | borrows USD |")
    L.append("|---|---|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        p = cfg[m]
        sup_u = p["totalSupply"] * p["xrate"] / 1e18
        sup_usd = usd(sup_u, p["decimals"], p["price"])
        bor_usd = usd(p["totalBorrows"], p["decimals"], p["price"])
        pr_h = p["price"] / 1e18 / (10 ** (18 - p["decimals"]))
        L.append(f"| {m} | {LABEL[m]} | {p['listed']} | {p['cf']/1e18:.2f} | {p['decimals']} | "
                 f"{pr_h:,.6g} | {sup_u/10**p['decimals']:,.4f} | {p['totalBorrows']/10**p['decimals']:,.4f} | "
                 f"{p['cash']/10**p['decimals']:,.4f} | ${sup_usd:,.0f} | ${bor_usd:,.0f} |")
    tot_cash = sum(usd(cfg[m]["cash"], cfg[m]["decimals"], cfg[m]["price"]) for m in MARKETS)
    tot_bor = sum(usd(cfg[m]["totalBorrows"], cfg[m]["decimals"], cfg[m]["price"]) for m in MARKETS)
    tot_sup = sum(usd(cfg[m]["totalSupply"] * cfg[m]["xrate"] / 1e18, cfg[m]["decimals"], cfg[m]["price"]) for m in MARKETS)
    L.append("")
    L.append(f"**Totals: supply ${tot_sup:,.0f}; borrows ${tot_bor:,.0f}; cash ${tot_cash:,.0f}.**")
    L.append("")
    L.append("## Underwater accounts (shortfall > 0)")
    L.append("")
    if not underwater:
        L.append("_None found among the accounts whose state was read._")
    else:
        L.append("| # | account | shortfall USD | debt USD | collateral USD | max repay USD | seize USD | bonus USD | debt mkts | coll mkts |")
        L.append("|---|---|---|---|---|---|---|---|---|---|")
        for i, r in enumerate(underwater[:100], 1):
            dm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["debt"].items())
            cm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["collateral"].items())
            L.append(f"| {i} | `{r['account']}` | {r['shortfall_usd']:,.2f} | {r['debt_usd']:,.2f} | {r['collateral_usd']:,.2f} | "
                     f"{r['liq']['max_repay_usd']:,.2f} | {r['liq']['seize_usd']:,.2f} | {r['liq']['bonus_usd']:,.2f} | {dm} | {cm} |")
        tr = sum(r["liq"]["max_repay_usd"] for r in underwater)
        tb = sum(r["liq"]["bonus_usd"] for r in underwater)
        L.append("")
        L.append(f"**Underwater totals: {len(underwater)} accounts; max single-pass repay ≈ ${tr:,.2f}; liquidator bonus ≈ ${tb:,.2f}.**")
    L.append("")
    L.append("## Largest positions read (by debt)")
    L.append("")
    L.append("| account | debt USD | collateral USD | adj collateral USD | shortfall USD | debt mkts |")
    L.append("|---|---|---|---|---|---|")
    for r in rows[:30]:
        dm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["debt"].items())
        L.append(f"| `{r['account']}` | {r['debt_usd']:,.2f} | {r['collateral_usd']:,.2f} | {r['collateral_adjusted_usd']:,.2f} | "
                 f"{(r['shortfall_usd'] if r['shortfall_usd'] is not None else 0):,.2f} | {dm} |")
    L.append("")
    L.append("## Event counts per market (eth_getLogs scan, partial coverage)")
    L.append("")
    L.append("| market | logs scanned | Mint | Redeem | Transfer | Borrow | RepayBorrow | LiquidateBorrow | failed segments |")
    L.append("|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        e = ev_named.get(m, {})
        c = e.get("counts", {})
        L.append(f"| {m} | {e.get('n_logs', 0):,} | {c.get('Mint', 0):,} | {c.get('Redeem', 0):,} | {c.get('Transfer', 0):,} | "
                 f"{c.get('Borrow', 0)} | {c.get('RepayBorrow', 0)} | {c.get('LiquidateBorrow', 0)} | {e.get('failed_segments', 0)} |")
    L.append("")
    L.append("## Method & coverage caveats")
    L.append("")
    L.append("- State read via `getAccountSnapshot`, `getAccountLiquidity`, `getAssetsIn` eth_calls at one fixed block (public + keyed env RPCs; keys never stored).")
    L.append("- **This fork's cTokens do not emit Borrow/RepayBorrow/LiquidateBorrow events** (verified ABI + 1M+ logs scanned). Borrowers were enumerated from transactions (borrow/repay/liquidate methodId + inputs) via the zkSync explorer txlist API, then `borrowBalanceStored`/snapshots.")
    L.append("- GoldRush `events/address` is broken for these contracts (stops ~May 2023, missing events) — not used for enumeration.")
    L.append("- Event scan (eth_getLogs) coverage is partial (RPC rate limits); counts above are lower bounds.")
    L.append(f"- Borrower universe in crawled txs: rfUSDCe 16.8k, rfETH 2.4k, rfUSDT 5.8k, rfWBTC 10.1k unique borrowers (by borrow calls).")
    open(os.path.join(HERE, "era-positions-summary.md"), "w").write("\n".join(L) + "\n")
    print("wrote era-positions-summary.md")


if __name__ == "__main__":
    main()
