#!/usr/bin/env python3
"""Final merge -> era-positions-raw.json + era-positions-summary.md (v2, all sources)."""
import glob, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = ["rfUSDCe", "rfETH", "rfWBTC", "rfUSDT", "rfZK", "rfUSDC"]
LABEL = {"rfUSDCe": "USDC.e", "rfETH": "ETH (native)", "rfWBTC": "WBTC",
         "rfUSDT": "USDT", "rfZK": "ZK", "rfUSDC": "USDC (native)"}
DEC = {"rfUSDCe": 6, "rfETH": 18, "rfWBTC": 8, "rfUSDT": 6, "rfZK": 18, "rfUSDC": 6}


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


def main():
    cfg = load_config()
    accounts = {}   # addr -> {"snapshots": {}, "liquidity": {...}, "debt_only": {}}
    # 1) full state (snapshots+liquidity)
    for name in ["era-positions-topstate.json", "era-positions-whales.json", "era-positions-debtorstate.json"]:
        p = os.path.join(HERE, name)
        if not os.path.exists(p):
            continue
        d = json.load(open(p))
        for a, st in (d.get("accounts") or {}).items():
            tgt = accounts.setdefault(a, {"snapshots": {}, "liquidity": None, "debt_only": {}})
            for m, s in (st.get("snapshots") or {}).items():
                if isinstance(s, list) and len(s) == 4:
                    tgt["snapshots"][m] = s
            liq = st.get("liquidity") or {}
            if isinstance(liq, dict) and "err" in liq:
                tgt["liquidity"] = liq
    # 2) debt-only sources
    def add_debt(k, v):
        if not isinstance(v, int) or v <= 0:
            return
        m, a = k.split("|")
        if m not in MARKETS:
            return
        tgt = accounts.setdefault(a, {"snapshots": {}, "liquidity": None, "debt_only": {}})
        if v > tgt["debt_only"].get(m, 0):
            tgt["debt_only"][m] = v
    for fp in glob.glob(os.path.join(HERE, "era-positions-borrows-part*.json")):
        try:
            d = json.load(open(fp))
        except Exception:
            continue
        for k, v in (d.get("pairs") or {}).items():
            add_debt(k, v)
    for name in ["era-positions-recentdebts.json", "era-positions-unbiased-out.json", "era-positions-crosscheck-eth-out.json"]:
        p = os.path.join(HERE, name)
        if os.path.exists(p):
            try:
                d = json.load(open(p))
            except Exception:
                d = {}
            for k, v in d.items():
                add_debt(k, v)
    for fp in glob.glob(os.path.join(HERE, "era-positions-debtscan-*.json")):
        m = os.path.basename(fp).replace("era-positions-debtscan-", "").replace(".json", "")
        try:
            d = json.load(open(fp))
        except Exception:
            continue
        for a, v in d.items():
            add_debt(f"{m}|{a}", v)

    rows = []
    for a, st in accounts.items():
        coll, dbt = {}, {}
        cu = du = 0.0
        for m in MARKETS:
            p = cfg[m]
            s = st["snapshots"].get(m)
            if isinstance(s, list):
                _, cbal, bbal, xr = s
                if cbal and cbal > 0:
                    und = cbal * (xr or p["xrate"]) / 1e18
                    v = usd(und, p["decimals"], p["price"])
                    coll[m] = {"shares": cbal, "underlying": und, "usd": v}
                    cu += v or 0
                if bbal and bbal > 0:
                    v = usd(bbal, p["decimals"], p["price"])
                    dbt[m] = {"balance": bbal, "usd": v}
                    du += v or 0
            dbo = st["debt_only"].get(m)
            if dbo and (m not in dbt):
                v = usd(dbo, p["decimals"], p["price"])
                dbt[m] = {"balance": dbo, "usd": v, "source": "borrowBalanceStored-only"}
                du += v or 0
        if not coll and not dbt:
            continue
        liq = st.get("liquidity") or {}
        sf = liq.get("shortfall")
        adj = sum((coll[m]["usd"] or 0) * (cfg[m]["cf"] / 1e18) for m in coll)
        row = {"account": a, "collateral_usd": cu, "debt_usd": du, "collateral_adjusted_usd": adj,
               "shortfall_raw": sf if isinstance(sf, int) else None,
               "shortfall_usd": (sf / 1e18) if isinstance(sf, int) else None,
               "collateral": coll, "debt": dbt,
               "has_full_state": bool(st["snapshots"])}
        rows.append(row)
    rows.sort(key=lambda r: -(r["debt_usd"] or 0))
    underwater = [r for r in rows if isinstance(r.get("shortfall_usd"), float) and r["shortfall_usd"] > 0]
    underwater.sort(key=lambda r: -r["shortfall_usd"])
    close = cfg["closeFactor"] / 1e18
    inc = cfg["liqIncentive"] / 1e18
    for r in underwater:
        repay = close * r["debt_usd"]
        r["liq"] = {"max_repay_usd": repay, "seize_usd": repay * inc, "bonus_usd": repay * (inc - 1)}

    # event counts
    ev = {}
    for fp in glob.glob(os.path.join(HERE, "era-positions-rpcsegments-*.json")):
        m = os.path.basename(fp).replace("era-positions-rpcsegments-", "").split("-")[0].replace(".json", "")
        try:
            st = json.load(open(fp))
        except Exception:
            continue
        e = ev.setdefault(m, {"n_logs": 0, "failed": 0, "topics": {}})
        e["n_logs"] += st.get("n_logs", 0)
        e["failed"] += len(st.get("failed", []))
        for t, n in (st.get("topic_counts") or {}).items():
            e["topics"][t] = e["topics"].get(t, 0) + n
    T = {"0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
         "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
         "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
         "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
         "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
         "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer"}
    ev_named = {m: {"n_logs": e["n_logs"], "failed_segments": e["failed"],
                    "counts": {T.get(k, k[:14]): v for k, v in e["topics"].items()}} for m, e in ev.items()}
    txstats = json.load(open(os.path.join(HERE, "era-positions-txstats.json"))) if os.path.exists(os.path.join(HERE, "era-positions-txstats.json")) else {}

    raw = {"block": cfg["block"], "comptroller": "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2",
           "oracle": cfg["oracle"], "closeFactor": cfg["closeFactor"], "liqIncentive": cfg["liqIncentive"],
           "market_params": {m: cfg[m] for m in MARKETS},
           "event_counts": ev_named, "tx_stats": txstats,
           "n_accounts_state": len(accounts), "n_rows_with_positions": len(rows),
           "n_underwater": len(underwater), "underwater": underwater,
           "positions": rows}
    json.dump(raw, open(os.path.join(HERE, "era-positions-raw.json"), "w"), indent=1)
    print(f"raw: {len(accounts)} accounts, {len(rows)} positions, {len(underwater)} underwater")

    # summary
    L = []
    L.append("# ReactorFusion (zkSync Era) — positions, borrowers & liquidation scan")
    L.append("")
    L.append(f"- **Block**: {cfg['block']} (single block; all reads at this block)")
    L.append(f"- Comptroller `0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2`, oracle `{cfg['oracle']}`")
    L.append(f"- closeFactor = {close:g}, liquidationIncentive = {inc:g}")
    L.append(f"- Accounts with on-chain state read: **{len(accounts)}**; with positions: **{len(rows)}**; underwater: **{len(underwater)}**")
    L.append("")
    L.append("## Markets (live)")
    L.append("")
    L.append("| market | underlying | CF | dec | price USD | supply | totalBorrows | cash | supply USD | borrows USD |")
    L.append("|---|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        p = cfg[m]
        sup_u = p["totalSupply"] * p["xrate"] / 1e18
        sup_usd = usd(sup_u, p["decimals"], p["price"])
        bor_usd = usd(p["totalBorrows"], p["decimals"], p["price"])
        pr_h = p["price"] / 1e18 / (10 ** (18 - p["decimals"]))
        L.append(f"| {m} | {LABEL[m]} | {p['cf']/1e18:.2f} | {p['decimals']} | {pr_h:,.6g} | "
                 f"{sup_u/10**p['decimals']:,.4f} | {p['totalBorrows']/10**p['decimals']:,.4f} | {p['cash']/10**p['decimals']:,.4f} | "
                 f"${sup_usd:,.0f} | ${bor_usd:,.0f} |")
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
        L.append("| # | account | shortfall USD | debt USD | collateral USD | max repay USD | bonus USD | debt mkts | coll mkts |")
        L.append("|---|---|---|---|---|---|---|---|---|")
        for i, r in enumerate(underwater[:60], 1):
            dm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["debt"].items())
            cm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["collateral"].items())
            L.append(f"| {i} | `{r['account']}` | {r['shortfall_usd']:,.2f} | {r['debt_usd']:,.2f} | {r['collateral_usd']:,.2f} | "
                     f"{r['liq']['max_repay_usd']:,.2f} | {r['liq']['bonus_usd']:,.2f} | {dm} | {cm} |")
        tr = sum(r["liq"]["max_repay_usd"] for r in underwater)
        tb = sum(r["liq"]["bonus_usd"] for r in underwater)
        L.append("")
        L.append(f"**Underwater totals: {len(underwater)} accounts; max single-pass repay ≈ ${tr:,.2f}; liquidator bonus ≈ ${tb:,.2f}.**")
    L.append("")
    L.append("## Largest positions read (by debt USD)")
    L.append("")
    L.append("| account | debt USD | collateral USD | adj collateral USD | shortfall USD | full state? | debt mkts |")
    L.append("|---|---|---|---|---|---|---|")
    for r in rows[:40]:
        dm = ", ".join(f"{k} ${v['usd']:,.2f}" for k, v in r["debt"].items())
        L.append(f"| `{r['account']}` | {r['debt_usd']:,.2f} | {r['collateral_usd']:,.2f} | {r['collateral_adjusted_usd']:,.2f} | "
                 f"{(r['shortfall_usd'] if r['shortfall_usd'] is not None else 0):,.2f} | {r['has_full_state']} | {dm} |")
    L.append("")
    L.append("## Transaction-based interaction stats (deduped by tx hash)")
    L.append("")
    L.append("| market | unique txs | accounts (tx.from) | borrowers (borrow txs) | borrow | repay | mint | redeem | liquidate |")
    L.append("|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        t = txstats.get(m)
        if not t:
            L.append(f"| {m} | - | - | - | - | - | - | - | - |")
            continue
        mm = t["methods"]
        L.append(f"| {m} | {t['n_unique_txs']:,} | {t['n_from_accounts']:,} | {t['n_borrowers']:,} | {mm.get('borrow',0):,} | "
                 f"{mm.get('repayBorrow',0)+mm.get('repayBorrow()',0):,} | {mm.get('mint',0)+mm.get('mint()',0):,} | "
                 f"{mm.get('redeem',0)+mm.get('redeemUnderlying',0):,} | {mm.get('liquidateBorrow',0):,} |")
    L.append("")
    L.append("## Event counts per market (eth_getLogs scan; coverage partial)")
    L.append("")
    L.append("| market | logs scanned | Mint | Redeem | Transfer | Borrow | RepayBorrow | LiquidateBorrow | failed segments |")
    L.append("|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        e = ev_named.get(m, {})
        c = e.get("counts", {})
        L.append(f"| {m} | {e.get('n_logs', 0):,} | {c.get('Mint', 0):,} | {c.get('Redeem', 0):,} | {c.get('Transfer', 0):,} | "
                 f"{c.get('Borrow', 0)} | {c.get('RepayBorrow', 0)} | {c.get('LiquidateBorrow', 0)} | {e.get('failed_segments', 0)} |")
    L.append("")
    L.append("## Debt coverage (attributed vs on-chain)")
    L.append("")
    L.append("| market | on-chain totalBorrows (USD) | attributed from reads (USD) | accounts with debt found | coverage |")
    L.append("|---|---|---|---|---|")
    att = {}
    for r in rows:
        for m, d in r["debt"].items():
            att[m] = att.get(m, 0) + (d["usd"] or 0)
    for m in MARKETS:
        p = cfg[m]
        onchain = usd(p["totalBorrows"], p["decimals"], p["price"])
        a = att.get(m, 0)
        n = len([r for r in rows if r["debt"].get(m)])
        L.append(f"| {m} | ${onchain:,.2f} | ${a:,.2f} | {n} | {100*a/onchain if onchain else 0:.3f}% |")
    L.append("")
    L.append("_The unattributed remainder sits in borrower accounts outside the crawled block ranges / sampled sets; sampled averages indicate it is spread over thousands of small residual positions._")
    L.append("")
    L.append("## Method & coverage caveats")
    L.append("")
    L.append("- State read via `getAccountSnapshot` / `getAccountLiquidity` eth_calls at one fixed block (keyed env RPCs + public; no secrets stored).")
    L.append("- **This fork's cTokens emit no Borrow/RepayBorrow/LiquidateBorrow events** (verified from verified ABI + 1M+ logs scanned with topic filters). Borrowers are enumerated from transactions (zkSync explorer txlist: methodId + input), then `borrowBalanceStored`/snapshots.")
    L.append("- GoldRush `events/address` is broken for these contracts (stops ~May-2023, no Borrow events) — not used as primary.")
    L.append("- Transaction crawls cover large but not all block ranges (public API rate limits): rfETH 1.9-6.1M + 40-64M; rfUSDCe 1.9-8.2M + 25-26M + 50-72.5M; rfWBTC 1.9-47M; rfUSDT 1.9-24M; rfZK/rfUSDC partial.")
    L.append("- Event scan (eth_getLogs) coverage is partial; event counts above are lower bounds. Historical totalBorrows sampled via archive eth_call.")
    L.append("- Borrower universe (deduped txs crawled): see table; the protocol was heavily farmed and most historical borrowers have fully repaid.")
    open(os.path.join(HERE, "era-positions-summary.md"), "w").write("\n".join(L) + "\n")
    print("wrote era-positions-summary.md")


if __name__ == "__main__":
    main()
