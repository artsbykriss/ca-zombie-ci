#!/usr/bin/env python3
"""Merge-scan the early window [START, 20_000_000) for debt-token mints that the main scan may
have missed (the main scan starts at 20M). Adds any new live debtors to ci-out/borrowers.json.
Read-only. Uses the same RPC selection as scan_borrowers.py.
"""
import importlib.util, json, os, sys, time

spec = importlib.util.spec_from_file_location("sb", os.path.join(os.path.dirname(__file__), "scan_borrowers.py"))
sb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sb)

START = int(os.environ.get("PREFIX_START", "17_000_000".replace("_", "")))
END = 20_000_000

def main():
    sb.choose_rpc()
    head = int(sb.rpc("eth_blockNumber", []), 16)
    print(f"# prefix scan [{START},{END}) head={head}", file=sys.stderr)

    cands = set()
    for (sym, asset, vdebt) in sb.RESERVES:
        try:
            addrs, n = sb.scan_transfers(vdebt, START, END - 1)
            print(f"# {sym}: {n} logs, {len(addrs)} addrs", file=sys.stderr)
            cands |= addrs
        except Exception as e:
            print(f"# {sym} ERR {str(e)[:120]}", file=sys.stderr)
    print(f"# prefix candidates: {len(cands)}", file=sys.stderr)

    # existing results
    path = "ci-out/borrowers.json"
    if os.path.exists(path):
        data = json.load(open(path))
    else:
        data = {"head": head, "pool": sb.POOL, "scan": {}, "borrowers": [], "n_candidates": 0}
    known = {b["address"] for b in data["borrowers"]}
    new_cands = sorted(a for a in cands if a not in known)
    print(f"# new candidates not already known: {len(new_cands)}", file=sys.stderr)

    if new_cands:
        toks = [r[2] for r in sb.RESERVES]
        sym_by_token = {r[2]: r[0] for r in sb.RESERVES}
        multi = sb.multicall_balances_multi(toks, new_cands)
        debt = {}
        for c, per in multi.items():
            for tok, v in per.items():
                debt.setdefault(c, {})[sym_by_token[tok]] = v
        print(f"# new live debtors: {len(debt)}", file=sys.stderr)
        for c in sorted(debt):
            try:
                res = sb.rpc("eth_call", [{"to": sb.POOL, "data": "0xbf92857c" + c[2:].rjust(64, "0")}, "latest"])
                b = bytes.fromhex(res[2:])
                vals = [int.from_bytes(b[i*32:(i+1)*32], "big") for i in range(6)]
                data["borrowers"].append({
                    "address": c, "totalCollateralETH": str(vals[0]), "totalDebtETH": str(vals[1]),
                    "availableBorrowsETH": str(vals[2]), "currentLiquidationThreshold": str(vals[3]),
                    "ltv": str(vals[4]), "healthFactor": str(vals[5]), "debt": debt[c]})
            except Exception as e:
                data["borrowers"].append({"address": c, "error": str(e)[:150], "debt": debt[c]})
            time.sleep(0.02)
    data.setdefault("scan", {})["prefix_window"] = {"start": START, "end": END, "candidates": len(cands)}
    os.makedirs("ci-out", exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=1)
    rows = sorted(data["borrowers"], key=lambda b: int(b.get("healthFactor", 2**256 - 1)))
    with open("ci-out/borrowers.txt", "w") as f:
        for b in rows:
            if "healthFactor" in b:
                f.write(b["address"] + "," + b["healthFactor"] + "\n")
    print(f"# total borrowers now: {len(data['borrowers'])}", file=sys.stderr)

if __name__ == "__main__":
    main()
