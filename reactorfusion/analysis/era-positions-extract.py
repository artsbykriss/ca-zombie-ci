#!/usr/bin/env python3
"""Extract accounts + reconstruct share/borrow positions from scanned logs.

Input: era-positions-rpclogs-<market>.jsonl (from era-positions-scan-logs.py)
Output: era-positions-accounts.json

Event layouts (Compound v2):
  Borrow(borrower, borrowAmount, accountBorrows, totalBorrows)      non-indexed
  Mint(minter, mintAmount, mintTokens)                              non-indexed
  RepayBorrow(payer, borrower, repayAmount, accountBorrows, totalBorrows) non-indexed
  Redeem(redeemer, redeemAmount, redeemTokens)                      non-indexed
  LiquidateBorrow(liquidator, borrower, repayAmount, cTokenCollateral, seizeTokens) non-indexed
  Transfer(from, to, value)                                         indexed from/to
Robust to indexed variants (address from topics when present).
"""
import json, os, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = ["rfUSDCe", "rfETH", "rfWBTC", "rfUSDT", "rfZK", "rfUSDC"]
ZERO = "0x" + "00" * 20

T = {
    "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
    "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
    "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
    "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
    "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer",
}


def addr_from_word(w):
    return "0x" + w[-40:].lower()


def words(d):
    d = (d or "")[2:]
    return [d[i:i + 64] for i in range(0, len(d), 64)]


def intw(w):
    return int(w, 16) if w else 0


def decode(ev):
    """Return dict with addresses/amounts or {'bad': reason}."""
    t = ev["t"][0]
    name = T.get(t)
    if not name:
        return {"bad": "unknown topic"}
    ws = words(ev["d"])
    topics = ev["t"]
    out = {"ev": name, "block": ev["b"]}
    try:
        if name == "Borrow":
            # borrower, borrowAmount, accountBorrows, totalBorrows
            if len(topics) >= 2:
                borrower = addr_from_word(topics[1]); w = ws
            else:
                borrower = addr_from_word(ws[0]); w = ws[1:]
            if len(w) < 3:
                return {"bad": f"Borrow data len {len(w)}"}
            out.update(borrower=borrower, amount=intw(w[0]), acctBorrows=intw(w[1]))
        elif name == "Mint":
            if len(topics) >= 2:
                minter = addr_from_word(topics[1]); w = ws
            else:
                minter = addr_from_word(ws[0]); w = ws[1:]
            out.update(minter=minter, amount=intw(w[0]), tokens=intw(w[1]))
        elif name == "Redeem":
            if len(topics) >= 2:
                redeemer = addr_from_word(topics[1]); w = ws
            else:
                redeemer = addr_from_word(ws[0]); w = ws[1:]
            out.update(redeemer=redeemer, amount=intw(w[0]), tokens=intw(w[1]))
        elif name == "RepayBorrow":
            if len(topics) >= 3:
                payer = addr_from_word(topics[1]); borrower = addr_from_word(topics[2]); w = ws
            else:
                payer = addr_from_word(ws[0]); borrower = addr_from_word(ws[1]); w = ws[2:]
            out.update(payer=payer, borrower=borrower, amount=intw(w[0]), acctBorrows=intw(w[1]))
        elif name == "LiquidateBorrow":
            if len(topics) >= 3:
                liquidator = addr_from_word(topics[1]); borrower = addr_from_word(topics[2]); w = ws
            else:
                liquidator = addr_from_word(ws[0]); borrower = addr_from_word(ws[1]); w = ws[2:]
            out.update(liquidator=liquidator, borrower=borrower, repayAmount=intw(w[0]),
                       collateral=addr_from_word(w[1]), seizeTokens=intw(w[2]))
        elif name == "Transfer":
            out.update(frm=addr_from_word(topics[1]), to=addr_from_word(topics[2]), value=intw(ws[0]))
    except Exception as e:
        return {"bad": f"decode exc {e}"}
    return out


def main():
    accounts = {}          # addr -> {last_block, markets: {m: {shares, borrows, ev: {type: n}}}}
    counts = {}            # market -> {evtype: n}
    bad = collections.Counter()
    coverage = {}
    for m in MARKETS:
        seg_p = os.path.join(HERE, f"era-positions-rpcsegments-{m}.json")
        log_p = os.path.join(HERE, f"era-positions-rpclogs-{m}.jsonl")
        cov = {"market": m, "logs": 0}
        if os.path.exists(seg_p):
            st = json.load(open(seg_p))
            cov["finished"] = st.get("finished", False)
            cov["failed_segments"] = st.get("failed", [])
            cov["segments_done"] = len(st.get("done", []))
            cov["scan_topic_counts"] = st.get("topic_counts", {})
        counts[m] = collections.Counter()
        if not os.path.exists(log_p):
            cov["logs"] = 0
            coverage[m] = cov
            print(f"[{m}] no logs file", flush=True)
            continue
        with open(log_p) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                ev = json.loads(line)
                d = decode(ev)
                if "bad" in d:
                    bad[(m, d["bad"])] += 1
                    continue
                evt = d["ev"]
                counts[m][evt] += 1
                cov["logs"] += 1
                for who in ("borrower", "minter", "redeemer", "payer", "liquidator", "frm", "to"):
                    a = d.get(who)
                    if not a or a == ZERO:
                        continue
                    acc = accounts.setdefault(a, {"last_block": 0, "markets": {}})
                    acc["last_block"] = max(acc["last_block"], ev["b"])
                    mm = acc["markets"].setdefault(m, {"shares": 0, "borrows": 0, "ev": {}})
                    mm["ev"][evt] = mm["ev"].get(evt, 0) + 1
                # position reconstruction
                if evt == "Mint":
                    mm = accounts[d["minter"]]["markets"][m]; mm["shares"] += d["tokens"]
                elif evt == "Redeem":
                    mm = accounts[d["redeemer"]]["markets"][m]; mm["shares"] -= d["tokens"]
                elif evt == "Transfer":
                    if d["frm"] != ZERO:
                        accounts[d["frm"]]["markets"][m]["shares"] -= d["value"]
                    if d["to"] != ZERO:
                        accounts[d["to"]]["markets"][m]["shares"] += d["value"]
                elif evt == "Borrow":
                    mm = accounts[d["borrower"]]["markets"][m]; mm["borrows"] = d["acctBorrows"]
                elif evt == "RepayBorrow":
                    mm = accounts[d["borrower"]]["markets"][m]; mm["borrows"] = d["acctBorrows"]
                elif evt == "LiquidateBorrow":
                    mm = accounts[d["borrower"]]["markets"][m]
                    mm["borrows"] = max(0, mm["borrows"] - d["repayAmount"])
                    # collateral market seize (could be another market)
                    cm = None
                    for lbl, addr in MARKETS_ADDR.items():
                        if addr.lower() == d["collateral"].lower():
                            cm = lbl
                    if cm:
                        b = accounts[d["borrower"]]["markets"].setdefault(cm, {"shares": 0, "borrows": 0, "ev": {}})
                        b["shares"] -= d["seizeTokens"]
                        liq = accounts[d["liquidator"]]["markets"].setdefault(cm, {"shares": 0, "borrows": 0, "ev": {}})
                        liq["shares"] += d["seizeTokens"]
        coverage[m] = cov
        print(f"[{m}] logs={cov['logs']} finished={cov.get('finished')} failed={len(cov.get('failed_segments', []))}", flush=True)

    # candidates: accounts with estimated nonzero shares or borrows
    cand = []
    for a, acc in accounts.items():
        for m, mm in acc["markets"].items():
            if mm["shares"] > 0 or mm["borrows"] > 0:
                cand.append(a)
                break
    out = {
        "markets": MARKETS,
        "event_counts": {m: dict(counts[m]) for m in counts},
        "n_accounts_total": len(accounts),
        "n_accounts_candidate": len(cand),
        "bad_logs": {f"{k[0]}|{k[1]}": v for k, v in bad.items()},
        "coverage": coverage,
        "accounts": accounts,
    }
    json.dump(out, open(os.path.join(HERE, "era-positions-accounts.json"), "w"), separators=(",", ":"))
    print(f"\nTOTAL distinct accounts: {len(accounts)}; candidates with est. nonzero position: {len(cand)}")
    print("event counts:", json.dumps(out["event_counts"], indent=1))
    if bad:
        print("BAD LOGS:", dict(bad))


MARKETS_ADDR = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}

if __name__ == "__main__":
    main()
