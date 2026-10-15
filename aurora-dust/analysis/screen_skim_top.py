#!/usr/bin/env python3
"""Robust (sequential, no batching) skim-excess check on top Trisolaris + WannaSwap pairs."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, sel, enc_addr

CHAIN = "aurora"
GR = sel("getReserves()"); BAL = sel("balanceOf(address)")

def check_pair(pair, t0, t1):
    g = rpc(CHAIN, "eth_call", [{"to": pair, "data": GR}, "latest"])
    if not (isinstance(g, str) and len(g) >= 2+192): return None
    raw = g[2:]; r0 = int(raw[:64],16); r1 = int(raw[64:128],16)
    b0 = rpc(CHAIN, "eth_call", [{"to": t0, "data": BAL + enc_addr(pair)}, "latest"])
    b1 = rpc(CHAIN, "eth_call", [{"to": t1, "data": BAL + enc_addr(pair)}, "latest"])
    try:
        b0 = int(b0,16); b1 = int(b1,16)
    except Exception:
        return None
    return {"pair": pair, "r0": r0, "r1": r1, "b0": b0, "b1": b1, "e0": b0-r0, "e1": b1-r1}

if __name__ == "__main__":
    tri = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-pair-usd2.json"))
    wan = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/wannaswap-pairs.json"))
    out = {"trisolaris": [], "wannaswap": []}
    n_excess = 0
    for label, rows, limit in [("trisolaris", tri, 80), ("wannaswap", wan, 40)]:
        for r in rows[:limit]:
            res = check_pair(r["pair"], r["t0"], r["t1"])
            if not res: continue
            out[label].append(res)
            if res["e0"] > 0 or res["e1"] > 0:
                n_excess += 1
                print(f"EXCESS {label} {res['pair']} e0={res['e0']} e1={res['e1']}")
    print(f"checked: tri={len(out['trisolaris'])} wan={len(out['wannaswap'])}; pairs with excess: {n_excess}")
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/skim-top-verified.json","w"), indent=1)
