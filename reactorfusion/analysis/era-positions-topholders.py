#!/usr/bin/env python3
"""Rank reconstructed holders by value; emit priority account list for state reads."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = ["rfUSDCe", "rfETH", "rfWBTC", "rfUSDT", "rfZK", "rfUSDC"]
CFG = {
    "rfUSDCe": {"dec": 6, "price": 999865390000000000000000000000, "xrate": 1281757275300693307},
    "rfETH":   {"dec": 18, "price": 2508716500000000000000, "xrate": 1037367544994526529},
    "rfWBTC":  {"dec": 8, "price": 832873330000000000000000000000000, "xrate": 1079247798570465785},
    "rfUSDT":  {"dec": 6, "price": 998744460000000000000000000000, "xrate": 1233278588448312986},
    "rfZK":    {"dec": 18, "price": 15945160000000000, "xrate": 1002655884336097385},
    "rfUSDC":  {"dec": 6, "price": 999865390000000000000000000000, "xrate": 1240313069520693093},
}


def usd(m, shares):
    c = CFG[m]
    und = shares * c["xrate"] / 1e18
    return und * c["price"] / 1e18 / 1e18


def main():
    recon = json.load(open(os.path.join(HERE, "era-positions-recon.json")))
    rows = []
    for a, mk in recon.items():
        tot = 0.0
        per = {}
        for m, sh in mk.items():
            if sh > 0 and m in CFG:
                v = usd(m, sh)
                per[m] = v
                tot += v
        if tot > 1.0:
            rows.append((tot, a, per))
    rows.sort(reverse=True)
    print(f"holders with reconstructed value > $1: {len(rows)}")
    print(f"top 40:")
    for tot, a, per in rows[:40]:
        detail = ", ".join(f"{m}=${v:,.0f}" for m, v in sorted(per.items(), key=lambda kv: -kv[1])[:3])
        print(f"  ${tot:>12,.2f}  {a}  {detail}")
    # save priority list: top 500 holders + all debtors from borrow reads
    prio = [a for _, a, _ in rows[:500]]
    debtors = set()
    import glob
    for fp in glob.glob(os.path.join(HERE, "era-positions-borrows*.json")):
        try:
            d = json.load(open(fp))
        except Exception:
            continue
        for k, v in (d.get("pairs") or {}).items():
            if isinstance(v, int) and v > 0:
                debtors.add(k.split("|")[1])
    allp = sorted(set(prio) | debtors)
    json.dump({"priority": allp, "n_top_holders": len(prio), "n_debtors": len(debtors)},
              open(os.path.join(HERE, "era-positions-priority.json"), "w"))
    print(f"\npriority list: {len(allp)} accounts ({len(prio)} top holders, {len(debtors)} debtors so far)")


if __name__ == "__main__":
    main()
