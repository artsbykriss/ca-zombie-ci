#!/usr/bin/env python3
"""Enumerate Trisolaris factory pairs (1418) -> reserves; identify top pairs by USD."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

CHAIN = "aurora"
FACTORY = "0xc66F594268041dB60507F00703b152492fb176E7"
APL = sel("allPairsLength()")
AP = sel("allPairs(uint256)")
GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")
BAL = sel("balanceOf(address)")

def main():
    blk = rpc(CHAIN, "eth_blockNumber", [])
    print("Aurora block:", int(blk,16))
    n = int(rpc(CHAIN, "eth_call", [{"to": FACTORY, "data": APL}, "latest"]), 16)
    print("pairs:", n)
    # fetch pair addresses in batches
    addrs = []
    step = 25
    for i in range(0, n, step):
        calls = [("eth_call", [{"to": FACTORY, "data": AP + enc_uint(j)}, "latest"]) for j in range(i, min(i+step, n))]
        res = batch(CHAIN, calls, chunk=25)
        for r in res:
            if isinstance(r, str) and r.startswith("0x") and len(r) >= 42:
                addrs.append("0x" + r[2:][24:64])
    print("fetched addresses:", len(addrs), "unique:", len(set(addrs)))
    json.dump(addrs, open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-pairs.json", "w"))
    # reserves for all pairs
    reserves = {}
    for i in range(0, len(addrs), 30):
        chunk = addrs[i:i+30]
        calls = [("eth_call", [{"to": a, "data": GR}, "latest"]) for a in chunk]
        res = batch(CHAIN, calls, chunk=15)
        for a, r in zip(chunk, res):
            if isinstance(r, str) and r.startswith("0x") and len(r) >= 2+192:
                raw = r[2:]
                r0 = int(raw[:64], 16); r1 = int(raw[64:128], 16)
                reserves[a] = (r0, r1)
    print("pairs with reserves fetched:", len(reserves))
    # filter non-trivial (any reserve > 1e15)
    live = {a: v for a, v in reserves.items() if v[0] > 10**15 or v[1] > 10**15}
    print("pairs with any reserve >1e15:", len(live))
    # tokens of live pairs
    tok = {}
    for i in range(0, len(live), 25):
        chunk = list(live.items())[i:i+25]
        calls = []
        for a, _ in chunk:
            calls.append(("eth_call", [{"to": a, "data": T0}, "latest"]))
            calls.append(("eth_call", [{"to": a, "data": T1}, "latest"]))
        res = batch(CHAIN, calls, chunk=20)
        for k, (a, rv) in enumerate(chunk):
            t0r, t1r = res[2*k], res[2*k+1]
            t0 = "0x" + t0r[2:][24:64] if isinstance(t0r, str) and len(t0r) >= 42 else None
            t1 = "0x" + t1r[2:][24:64] if isinstance(t1r, str) and len(t1r) >= 42 else None
            tok[a] = (t0, t1, rv)
    json.dump({a: {"t0": v[0], "t1": v[1], "r0": str(v[2][0]), "r1": str(v[2][1])} for a, v in tok.items()},
              open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-live-pairs.json", "w"), indent=1)
    print("saved", len(tok), "live pairs with tokens")
    # prices for unique tokens
    toks = sorted({t for v in tok.values() for t in v[:2] if t})
    print("unique tokens:", len(toks))
    prices = {}
    for i in range(0, len(toks), 40):
        ids = ",".join(f"aurora:{t}" for t in toks[i:i+40])
        try:
            with urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/" + ids,
                                                              headers={"User-Agent": "research"}), timeout=30) as r:
                d = json.load(r)
            for k, v in (d.get("coins") or {}).items():
                prices[k.split(":")[1]] = v.get("price")
        except Exception as e:
            print("price batch err", e)
    json.dump(prices, open("/home/heisenberg/CA/aurora-dust/analysis/aurora-prices.json", "w"), indent=1)
    # total USD of live pairs
    total = 0.0
    rows = []
    for a, (t0, t1, (r0, r1)) in tok.items():
        p0 = prices.get(t0) or 0
        p1 = prices.get(t1) or 0
        usd = (r0/1e18)*p0 + (r1/1e18)*p1
        total += usd
        rows.append((usd, a, t0, t1, r0/1e18, r1/1e18, p0, p1))
    rows.sort(reverse=True)
    print(f"TOTAL live-pair USD (18-dec assumption): ${total:,.2f}")
    for usd, a, t0, t1, h0, h1, p0, p1 in rows[:20]:
        print(f"  ${usd:>12,.2f} {a} {t0[:12]}..{t1[:12]}.. r0={h0:,.4f}@{p0} r1={h1:,.4f}@{p1}")
    json.dump([{"usd": u, "pair": a, "t0": t0, "t1": t1, "r0": h0, "r1": h1, "p0": p0, "p1": p1} for u,a,t0,t1,h0,h1,p0,p1 in rows],
              open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-pair-usd.json","w"), indent=1)

if __name__ == "__main__":
    main()
