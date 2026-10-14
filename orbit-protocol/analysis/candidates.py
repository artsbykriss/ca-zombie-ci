"""Build the liquidation candidate list from Borrow events.

Writes ci-out/candidates.json: [{comptroller, market, borrower}] (unique borrower-market
pairs for the markets where liquidation is feasible).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LOGDIR = os.environ.get("LOG_DIR", os.path.join(HERE, "logs"))
OUTDIR = os.environ.get("CI_OUT", HERE)

COMPTROLLER_OF = {
    # debt market oracle is refreshable (Pyth) AND borrow is not paused
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa": "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    "0x586abb06179535de9eb6c6d968a355128dd74511": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
}


def main():
    cands = []
    seen = set()
    for fn in sorted(os.listdir(LOGDIR)):
        if not fn.endswith("_Borrow.json"):
            continue
        market = fn.split("_")[0].lower()
        comp = COMPTROLLER_OF.get(market)
        if not comp:
            continue
        try:
            logs = json.load(open(os.path.join(LOGDIR, fn)))
        except Exception:  # noqa: BLE001
            continue
        for lg in logs:
            try:
                borrower = "0x" + lg["data"][2:][24:64]
            except Exception:  # noqa: BLE001
                continue
            key = (market, borrower.lower())
            if key in seen:
                continue
            seen.add(key)
            cands.append({"comptroller": comp, "market": market, "borrower": borrower.lower()})
    out = {"count": len(cands), "candidates": cands}
    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "candidates.json"), "w") as f:
        json.dump(out, f)
    with open(os.path.join(OUTDIR, "candidates.txt"), "w") as f:
        for c in cands:
            f.write(f"{c['comptroller']},{c['borrower']}\n")
    print(f"wrote candidates.json with {len(cands)} unique borrower-market pairs", flush=True)


if __name__ == "__main__":
    main()
