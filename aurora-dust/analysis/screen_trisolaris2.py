#!/usr/bin/env python3
"""Recompute Trisolaris pair USD with per-token decimals; check skim excess."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr

CHAIN = "aurora"
DEC = sel("decimals()")
BAL = sel("balanceOf(address)")
GR = sel("getReserves()")

def main():
    live = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-live-pairs.json"))
    prices = json.load(open("/home/heisenberg/CA/aurora-dust/analysis/aurora-prices.json"))
    toks = sorted({t for v in live.values() for t in (v["t0"], v["t1"]) if t})
    # fetch decimals
    dec = {}
    for i in range(0, len(toks), 30):
        chunk = toks[i:i+30]
        res = batch(CHAIN, [("eth_call", [{"to": t, "data": DEC}, "latest"]) for t in chunk], chunk=15)
        for t, r in zip(chunk, res):
            try: dec[t] = int(r, 16)
            except Exception: dec[t] = None
    json.dump(dec, open("/home/heisenberg/CA/aurora-dust/analysis/aurora-decimals.json", "w"), indent=1)
    missing = [t for t in toks if dec.get(t) is None]
    print("tokens:", len(toks), "decimals missing:", len(missing))
    # recompute
    rows = []
    for a, v in live.items():
        t0, t1 = v["t0"], v["t1"]
        r0, r1 = int(v["r0"]), int(v["r1"])
        d0, d1 = dec.get(t0) or 18, dec.get(t1) or 18
        p0, p1 = prices.get(t0) or 0, prices.get(t1) or 0
        h0, h1 = r0 / 10**d0, r1 / 10**d1
        usd = h0 * p0 + h1 * p1
        rows.append({"usd": usd, "pair": a, "t0": t0, "t1": t1, "h0": h0, "h1": h1, "p0": p0, "p1": p1, "d0": d0, "d1": d1})
    rows.sort(key=lambda x: -x["usd"])
    total = sum(r["usd"] for r in rows)
    print(f"TOTAL Trisolaris live-pair USD: ${total:,.2f}  (DefiLlama: $2,094,870)")
    for r in rows[:25]:
        print(f"  ${r['usd']:>11,.2f} {r['pair']} t0={r['t0'][:10]} {r['h0']:,.4f}@{r['p0']} t1={r['t1'][:10]} {r['h1']:,.4f}@{r['p1']}")
    json.dump(rows, open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-pair-usd2.json", "w"), indent=1)
    # skim excess for top 60 pairs: pair balance vs reserves
    top = [r["pair"] for r in rows[:60] if r["usd"] > 100]
    excess = []
    for i in range(0, len(top), 20):
        chunk = top[i:i+20]
        calls = []
        for a in chunk:
            calls.append(("eth_call", [{"to": a, "data": GR}, "latest"]))
        res = batch(CHAIN, calls, chunk=20)
        for a, r in zip(chunk, res):
            if not (isinstance(r, str) and len(r) >= 2+192): continue
            raw = r[2:]
            r0 = int(raw[:64], 16); r1 = int(raw[64:128], 16)
            v = live[a]
            # token balances
            b0 = rpc(CHAIN, "eth_call", [{"to": v["t0"], "data": BAL + enc_addr(a)}, "latest"])
            b1 = rpc(CHAIN, "eth_call", [{"to": v["t1"], "data": BAL + enc_addr(a)}, "latest"])
            try:
                b0i = int(b0, 16); b1i = int(b1, 16)
                e0, e1 = b0i - r0, b1i - r1
            except Exception:
                e0 = e1 = None
            if (e0 or 0) > 0 or (e1 or 0) > 0:
                excess.append({"pair": a, "excess0": e0, "excess1": e1, "res0": r0, "res1": r1})
    print("pairs with skim excess>0 (top60):", len(excess))
    for e in excess[:15]:
        print("  ", e)
    json.dump(excess, open("/home/heisenberg/CA/aurora-dust/analysis/trisolaris-skim-excess.json", "w"), indent=1)

if __name__ == "__main__":
    main()
