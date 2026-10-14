#!/usr/bin/env python3
"""Check live state of gap-crawl borrower candidates (top net principal).
Read-only. Writes analysis/era-crawl-candidates.json"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}


def main():
    cands = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-crawl-netprincipal.json")))
    accts = [a["account"] for a in cands["accounts"]][:40]
    rpc = RPC(default_urls("era"), "era")
    blk = rpc.block_number()
    out = {"block": blk, "accounts": {}}
    # 1) liquidity + rfETH debt + rfETH collateral for all candidates
    calls, keys = [], []
    for a in accts:
        calls.append((C, calldata("getAccountLiquidity(address)", ["address"], [a]))); keys.append((a, "liq", ["uint256", "uint256", "uint256"]))
        calls.append((MARKETS["rfETH"], calldata("borrowBalanceStored(address)", ["address"], [a]))); keys.append((a, "debt_rfETH", ["uint256"]))
        calls.append((MARKETS["rfETH"], calldata("balanceOf(address)", ["address"], [a]))); keys.append((a, "coll_rfETH", ["uint256"]))
        calls.append((MARKETS["rfUSDCe"], calldata("borrowBalanceStored(address)", ["address"], [a]))); keys.append((a, "debt_rfUSDCe", ["uint256"]))
        calls.append((MARKETS["rfUSDCe"], calldata("balanceOf(address)", ["address"], [a]))); keys.append((a, "coll_rfUSDCe", ["uint256"]))
    res = rpc.try_calls(calls)
    for (a, tag, ot), (raw, err) in zip(keys, res):
        e = out["accounts"].setdefault(a, {})
        if raw is None:
            e[tag] = None
            continue
        try:
            v = dec(ot, raw)
            e[tag] = [str(x) for x in v] if len(v) > 1 else str(v[0])
        except Exception:
            e[tag] = None
    print(f"[candidates] {len(out['accounts'])} accounts read at block {blk}", flush=True)
    # 2) for accounts with any debt or collateral, read the remaining markets
    interesting = []
    for a, e in out["accounts"].items():
        liq = e.get("liq")
        debt_eth = int(e.get("debt_rfETH") or 0)
        coll_eth = int(e.get("coll_rfETH") or 0)
        debt_usdc = int(e.get("debt_rfUSDCe") or 0)
        coll_usdc = int(e.get("coll_rfUSDCe") or 0)
        if (liq and int(liq[2]) > 0) or debt_eth > 10 ** 12 or coll_eth > 10 ** 12 or debt_usdc > 10 ** 4 or coll_usdc > 10 ** 4:
            interesting.append(a)
    print(f"[candidates] interesting (debt/coll/shortfall): {len(interesting)}", flush=True)
    calls, keys = [], []
    for a in interesting:
        for n, m in MARKETS.items():
            if n in ("rfETH", "rfUSDCe"):
                continue
            calls.append((m, calldata("borrowBalanceStored(address)", ["address"], [a]))); keys.append((a, f"debt_{n}", ["uint256"]))
            calls.append((m, calldata("balanceOf(address)", ["address"], [a]))); keys.append((a, f"coll_{n}", ["uint256"]))
    if calls:
        res = rpc.try_calls(calls)
        for (a, tag, ot), (raw, err) in zip(keys, res):
            e = out["accounts"].setdefault(a, {})
            if raw is None:
                e[tag] = None
                continue
            try:
                e[tag] = str(dec(ot, raw)[0])
            except Exception:
                e[tag] = None
    json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-crawl-candidates.json"), "w"), indent=1)
    print("[candidates] written era-crawl-candidates.json", flush=True)


if __name__ == "__main__":
    main()
