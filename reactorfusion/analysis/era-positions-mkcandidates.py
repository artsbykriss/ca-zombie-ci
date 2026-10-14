#!/usr/bin/env python3
"""Build era-positions-candidates.json from borrow results (+ optional holders)."""
import glob, json, os

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    debtors = set()
    for fp in glob.glob(os.path.join(HERE, "era-positions-borrows*.json")):
        try:
            d = json.load(open(fp))
        except Exception:
            continue
        for k, v in (d.get("pairs") or {}).items():
            if isinstance(v, int) and v > 0:
                debtors.add(k.split("|")[1])
    holders = set()
    hp = os.path.join(HERE, "era-positions-holders.json")
    if os.path.exists(hp):
        h = json.load(open(hp))
        holders = set(h.get("holders", []))
    cands = sorted(debtors | holders)
    json.dump({"candidates": cands, "n_debtors": len(debtors), "n_holders": len(holders)},
              open(os.path.join(HERE, "era-positions-candidates.json"), "w"))
    print(f"debtors: {len(debtors)}, holders: {len(holders)}, candidates: {len(cands)}")


if __name__ == "__main__":
    main()
