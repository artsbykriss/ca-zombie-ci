#!/usr/bin/env python3
"""Read current on-chain state for candidate accounts of ReactorFusion Era markets.

Candidate set = tx-method accounts (borrow/repay/liquidate) + reconstructed current
cToken holders + liquidators. Reads (at one fixed block):
  - 6x getAccountSnapshot(account)  -> (err, cTokenBalance, borrowBalance, xRate)
  - getAccountLiquidity(account)    -> (err, liquidity, shortfall)
  - getAssetsIn(account)            -> address[]
  - market config: oracle prices, collateral factors, closeFactor, incentive
Output: era-positions-raw.json (+ progress file for resume).
"""
import glob, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, calldata, dec

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
MADDR2LBL = {v.lower(): k for k, v in MARKETS.items()}
SEL = {
    "0xc5ebeaec": "borrow", "0x0e752702": "repayBorrow", "0x4e4d9fea": "repayBorrow()",
    "0x2608f818": "repayBorrowBehalf", "0xf5e3c462": "liquidateBorrow",
    "0xa0712d68": "mint", "0x1249c58b": "mint()", "0xdb006a75": "redeem",
    "0x852a12e3": "redeemUnderlying", "0xc2998238": "enterMarkets", "0xede4edd0": "exitMarket",
    "0xa6afed95": "accrueInterest",
}
BORROWISH = {"borrow", "repayBorrow", "repayBorrow()", "repayBorrowBehalf", "liquidateBorrow"}


def w2addr(w):
    return "0x" + w[-40:].lower()


def load_sources():
    """Returns (recon, tx_accounts, stats)."""
    recon = {}   # addr -> market -> shares
    ev_counts = {}
    for fp in sorted(glob.glob(os.path.join(HERE, "era-positions-rpclogs-*.jsonl"))):
        base = os.path.basename(fp)
        m = base.replace("era-positions-rpclogs-", "").split("-")[0].replace(".jsonl", "")
        if m not in MARKETS:
            continue
        ev_counts.setdefault(m, {})
        T = {
            "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
            "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
            "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
            "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
            "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
            "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer",
        }
        seen = set()
        with open(fp) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                ev = json.loads(line)
                key = (ev["b"], ev["i"])
                if key in seen:
                    continue
                seen.add(key)
                t = ev["t"][0]
                name = T.get(t)
                if not name:
                    continue
                ev_counts[m][name] = ev_counts[m].get(name, 0) + 1
                d = (ev["d"] or "")[2:]
                w = [d[i:i + 64] for i in range(0, len(d), 64)]
                if name == "Mint" and len(w) >= 3:
                    a = w2addr(w[0]); tokens = int(w[2], 16)
                    recon.setdefault(a, {}).setdefault(m, 0)
                    recon[a][m] += tokens
                elif name == "Redeem" and len(w) >= 3:
                    a = w2addr(w[0]); tokens = int(w[2], 16)
                    recon.setdefault(a, {}).setdefault(m, 0)
                    recon[a][m] -= tokens
                elif name == "Transfer":
                    if len(ev["t"]) >= 3:
                        frm = w2addr(ev["t"][1]); to = w2addr(ev["t"][2])
                        val = int(w[0], 16) if w else 0
                        if frm != "0x" + "00" * 20:
                            recon.setdefault(frm, {}).setdefault(m, 0)
                            recon[frm][m] -= val
                        if to != "0x" + "00" * 20:
                            recon.setdefault(to, {}).setdefault(m, 0)
                            recon[to][m] += val
    tx_accounts = {}   # addr -> {methods:set, as_borrower_param:bool}
    tx_stats = {}
    for fp in sorted(glob.glob(os.path.join(HERE, "era-positions-txs-*.jsonl"))):
        base = os.path.basename(fp)
        m = base.replace("era-positions-txs-", "").split("-")[0].replace(".jsonl", "")
        if m not in MARKETS:
            continue
        n = 0
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            x = json.loads(line)
            n += 1
            name = SEL.get(x.get("mid", ""), x.get("mid") or "unknown")
            frm = (x.get("from") or "").lower()
            if frm:
                e = tx_accounts.setdefault(frm, {"methods": set(), "borrower_param": False, "markets": set()})
                e["methods"].add(name)
                e["markets"].add(m)
            inp = x.get("in") or ""
            if name == "repayBorrowBehalf" and len(inp) >= 74:
                b = w2addr(inp[10:74])
                e = tx_accounts.setdefault(b, {"methods": set(), "borrower_param": False, "markets": set()})
                e["borrower_param"] = True
                e["markets"].add(m)
            if name == "liquidateBorrow" and len(inp) >= 74:
                b = w2addr(inp[10:74])
                e = tx_accounts.setdefault(b, {"methods": set(), "borrower_param": False, "markets": set()})
                e["borrower_param"] = True
                e["markets"].add(m)
        tx_stats[m] = {"n_txs": n}
    return recon, tx_accounts, {"event_counts": ev_counts, "tx_stats": tx_stats}


def main():
    t0 = time.time()
    recon, tx_accounts, stats = load_sources()
    holders_now = {a: mk for a, mk in recon.items() if any(v > 0 for v in mk.values())}
    borrowers = {a: e for a, e in tx_accounts.items()
                 if e["borrower_param"] or (e["methods"] & BORROWISH)}
    liquidators = {a: e for a, e in tx_accounts.items() if "liquidateBorrow" in e["methods"]}
    other_tx = {a: e for a, e in tx_accounts.items() if a not in borrowers and a not in liquidators}
    candidates = set(borrowers) | set(holders_now) | set(liquidators)
    print(f"recon accounts: {len(recon)}, current holders (recon>0): {len(holders_now)}", flush=True)
    print(f"tx accounts: {len(tx_accounts)}; borrowish: {len(borrowers)}; liquidators: {len(liquidators)}; other: {len(other_tx)}", flush=True)
    print(f"candidate snapshot set: {len(candidates)}", flush=True)
    json.dump(recon, open(os.path.join(HERE, "era-positions-recon.json"), "w"), separators=(",", ":"))
    json.dump({"candidates": sorted(candidates), "n_recon": len(recon), "n_holders_now": len(holders_now),
               "n_borrowish": len(borrowers), "n_liquidators": len(liquidators),
               "n_tx_accounts": len(tx_accounts)}, open(os.path.join(HERE, "era-positions-candidates.json"), "w"))
    json.dump({"borrowers": sorted(a for a, e in borrowers.items() if (e["methods"] & {"borrow", "repayBorrow", "repayBorrow()"}) or "borrow" in e["methods"]),
               "borrower_params": sorted(a for a, e in borrowers.items() if e["borrower_param"]),
               "liquidators": sorted(liquidators),
               "all_borrowish": sorted(borrowers)},
              open(os.path.join(HERE, "era-positions-txaccounts.json"), "w"))
    print(f"load time {time.time()-t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
