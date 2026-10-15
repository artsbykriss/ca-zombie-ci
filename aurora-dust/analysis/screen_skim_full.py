#!/usr/bin/env python3
"""Full skim-excess check: all Trisolaris + WannaSwap pairs (balanceOf - reserves)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

CHAIN = "aurora"
BAL = sel("balanceOf(address)")
GR = sel("getReserves()")

def check(pairs, label):
    # pairs: {addr: (t0, t1)}
    items = list(pairs.items())
    excess = []
    for i in range(0, len(items), 40):
        chunk = items[i:i+40]
        calls = []
        for a, _ in chunk:
            calls.append(("eth_call", [{"to": a, "data": GR}, "latest"]))
        res = batch(CHAIN, calls, chunk=20)
        for (a, (t0, t1)), r in zip(chunk, res):
            if not (isinstance(r, str) and len(r) >= 2+192): continue
            raw = r[2:]
            r0 = int(raw[:64], 16); r1 = int(raw[64:128], 16)
            b0 = rpc(CHAIN, "eth_call", [{"to": t0, "data": BAL + enc_addr(a)}, "latest"])
            b1 = rpc(CHAIN, "eth_call", [{"to": t1, "data": BAL + enc_addr(a)}, "latest"])
            try:
                e0 = int(b0, 16) - r0; e1 = int(b1, 16) - r1
            except Exception:
                continue
            if e0 > 0 or e1 > 0:
                excess.append({"pair": a, "t0": t0, "t1": t1, "excess0": str(e0), "excess1": str(e1), "res0": str(r0), "res1": str(r1)})
    print(f"{label}: pairs={len(items)} pairs-with-excess={len(excess)}")
    for e in excess[:20]:
        print("  ", e["pair"], "e0=", e["excess0"], "e1=", e["excess1"])
    return excess

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("Aurora block:", int(blk,16))
    tri = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-live-pairs.json"))
    tri_pairs = {a: (v["t0"], v["t1"]) for a, v in tri.items()}
    w = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/wannaswap-pairs.json"))
    # wannaswap-pairs.json rows have pair/t0/t1
    wan_pairs = {r["pair"]: (r["t0"], r["t1"]) for r in w}
    out = {
        "trisolaris": check(tri_pairs, "Trisolaris"),
        "wannaswap": check(wan_pairs, "WannaSwap"),
    }
    json.dump({"block": int(blk,16), "excess": out}, open("/home/heisenberg/CA/aurora-dust/analysis/skim-excess-full.json","w"), indent=1)

if __name__ == "__main__":
    main()
