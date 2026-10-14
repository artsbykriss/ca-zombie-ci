#!/usr/bin/env python3
"""Analyze era-positions-raw.json -> underwater accounts, liquidation sizes, summary.md."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = ["rfUSDCe", "rfETH", "rfWBTC", "rfUSDT", "rfZK", "rfUSDC"]


def main():
    raw = json.load(open(os.path.join(HERE, "era-positions-raw.json")))
    cfg = raw["market_config_raw"]
    block = raw["block"]
    oracle = raw["oracle"]
    close = int(cfg["closeFactor"]["raw"], 16) if cfg["closeFactor"].get("raw") else None
    inc = int(cfg["liqIncentive"]["raw"], 16) if cfg["liqIncentive"].get("raw") else None

    M = {}
    for m in MARKETS:
        dec = int(cfg[f"{m}|decimals"]["raw"], 16) if cfg[f"{m}|decimals"].get("raw") else None
        price = int(cfg[f"{m}|price"]["raw"], 16) if cfg.get(f"{m}|price", {}).get("raw") else None
        mk = cfg[f"{m}|markets"]["raw"]
        listed = int(mk[2:66], 16) if mk else None
        cf = int(mk[66:130], 16) if mk else None
        M[m] = {
            "decimals": dec, "price": price, "cf": cf, "listed": listed,
            "totalSupply": int(cfg[f"{m}|totalSupply"]["raw"], 16) if cfg[f"{m}|totalSupply"].get("raw") else None,
            "totalBorrows": int(cfg[f"{m}|totalBorrows"]["raw"], 16) if cfg[f"{m}|totalBorrows"].get("raw") else None,
            "cash": int(cfg[f"{m}|cash"]["raw"], 16) if cfg[f"{m}|cash"].get("raw") else None,
            "xrate": int(cfg[f"{m}|xrate"]["raw"], 16) if cfg[f"{m}|xrate"].get("raw") else None,
            "reserveFactor": int(cfg[f"{m}|reserveFactor"]["raw"], 16) if cfg.get(f"{m}|reserveFactor", {}).get("raw") else None,
        }

    def usd(underlying_amt, dec, price):
        # underlying_amt in underlying decimals; price = 1e(36-dec)
        if underlying_amt is None or price is None:
            return None
        return underlying_amt * price / 1e18 / 1e18

    accounts = raw["accounts"]
    rows = []
    pos = 0
    under = []
    sum_borrows = {m: 0 for m in MARKETS}
    sum_shares = {m: 0 for m in MARKETS}
    n_holders = {m: 0 for m in MARKETS}
    n_borrowers = {m: 0 for m in MARKETS}
    for a, st in accounts.items():
        liq = st.get("liquidity") or {}
        shortfall = liq.get("shortfall")
        liquidity = liq.get("liquidity")
        snaps = st.get("snapshots") or {}
        coll = {}
        debt = {}
        coll_usd = 0.0
        debt_usd = 0.0
        has_pos = False
        for m in MARKETS:
            s = snaps.get(m)
            if not isinstance(s, list):
                continue
            err, cbal, bbal, xr = s
            mm = M[m]
            if cbal and cbal > 0:
                has_pos = True
                n_holders[m] += 1
                sum_shares[m] += cbal
                und = cbal * (xr or mm["xrate"] or 0) / 1e18
                v = usd(und, mm["decimals"], mm["price"])
                coll[m] = {"shares": cbal, "underlying": und, "usd": v}
                if v:
                    coll_usd += v
            if bbal and bbal > 0:
                has_pos = True
                n_borrowers[m] += 1
                sum_borrows[m] += bbal
                v = usd(bbal, mm["decimals"], mm["price"])
                debt[m] = {"balance": bbal, "usd": v}
                if v:
                    debt_usd += v
        if not has_pos:
            continue
        pos += 1
        row = {"account": a, "shortfall": shortfall, "liquidity": liquidity,
               "collateral_usd": coll_usd, "debt_usd": debt_usd,
               "collateral": coll, "debt": debt, "assetsIn": st.get("assetsIn")}
        rows.append(row)
        if shortfall and shortfall > 0:
            # liquidation: closeFactor x debt, seize = repay * (1 + incentive)
            repay = (close or 0) * debt_usd
            seize = repay * ((inc or 0) / 1e18)
            bonus = seize - repay
            row["liq"] = {"max_repay_usd": repay, "seize_value_usd": seize, "bonus_usd": bonus}
            under.append(row)

    under.sort(key=lambda r: -(r["liq"]["max_repay_usd"] if r.get("liq") else 0))

    # validation
    val = {}
    for m in MARKETS:
        mm = M[m]
        val[m] = {
            "sum_shares_snapshots": sum_shares[m], "totalSupply": mm["totalSupply"],
            "sum_borrows_snapshots": sum_borrows[m], "totalBorrows": mm["totalBorrows"],
            "holders_seen": n_holders[m], "borrowers_seen": n_borrowers[m],
            "share_coverage_pct": (100.0 * sum_shares[m] / mm["totalSupply"]) if mm["totalSupply"] else None,
            "borrow_coverage_pct": (100.0 * sum_borrows[m] / mm["totalBorrows"]) if mm["totalBorrows"] else None,
        }

    out = {"block": block, "oracle": oracle, "closeFactor": close, "liqIncentive": inc,
           "market_params": M, "validation": val,
           "n_accounts_read": len(accounts), "n_with_positions": pos,
           "n_underwater": len(under), "underwater": under,
           "positions": rows}
    json.dump(out, open(os.path.join(HERE, "era-positions-underwater.json"), "w"), indent=1)

    # human summary
    lines = []
    lines.append(f"# ReactorFusion (zkSync Era) — positions & liquidation scan")
    lines.append("")
    lines.append(f"- Block: **{block}** (single block; all calls at this block)")
    lines.append(f"- Comptroller: `0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2`; Oracle: `{oracle}`")
    lines.append(f"- closeFactor = {close} ({close/1e18 if close else '?'}), liquidationIncentive = {inc} ({inc/1e18 if inc else '?'})")
    lines.append(f"- Accounts read: {len(accounts)}; accounts with positions: {pos}; underwater (shortfall>0): {len(under)}")
    lines.append("")
    lines.append("## Market parameters & coverage validation")
    lines.append("")
    lines.append("| market | decimals | price(1e36-d) | CF | totalSupply | Σshares(snaps) | cover% | totalBorrows | Σborrows(snaps) | cover% |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|")
    for m in MARKETS:
        mm = M[m]; v = val[m]
        def f(x):
            return f"{x}" if x is not None else "-"
        lines.append(f"| {m} | {mm['decimals']} | {mm['price']} | {mm['cf']} | {mm['totalSupply']} | {v['sum_shares_snapshots']} | "
                     f"{v['share_coverage_pct']:.2f}% | {mm['totalBorrows']} | {v['sum_borrows_snapshots']} | {v['borrow_coverage_pct']:.2f}% |")
    lines.append("")
    lines.append("## Underwater accounts (shortfall > 0) — liquidatable")
    lines.append("")
    if not under:
        lines.append("_None found in the enumerated set._")
    else:
        lines.append("| # | account | shortfall USD | debt USD | collateral USD | max repay USD | seize value USD | bonus USD | debt markets | collateral markets |")
        lines.append("|---|---|---|---|---|---|---|---|---|---|")
        for i, r in enumerate(under, 1):
            sf = (r["shortfall"] or 0) / 1e18
            dm = ", ".join(f"{k}:{v['usd']:.2f}" for k, v in r["debt"].items())
            cm = ", ".join(f"{k}:{v['usd']:.2f}" for k, v in r["collateral"].items())
            lines.append(f"| {i} | `{r['account']}` | {sf:.2f} | {r['debt_usd']:.2f} | {r['collateral_usd']:.2f} | "
                         f"{r['liq']['max_repay_usd']:.2f} | {r['liq']['seize_value_usd']:.2f} | {r['liq']['bonus_usd']:.2f} | {dm} | {cm} |")
    lines.append("")
    tot_repay = sum(r["liq"]["max_repay_usd"] for r in under)
    tot_bonus = sum(r["liq"]["bonus_usd"] for r in under)
    lines.append(f"**Totals: {len(under)} underwater accounts; max single-pass repay ≈ ${tot_repay:,.0f}; liquidator bonus ≈ ${tot_bonus:,.0f} (at closeFactor=0.5, incentive=1.08).**")
    open(os.path.join(HERE, "era-positions-summary.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines[:40]))
    print("wrote era-positions-underwater.json + era-positions-summary.md")


if __name__ == "__main__":
    main()
