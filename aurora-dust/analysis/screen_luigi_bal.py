#!/usr/bin/env python3
"""LuigiSwap opBNB+Scroll: real balances (not reserves) per pair -> true custody + extractability screen."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint, RPCS
RPCS["scroll"] = "https://rpc.scroll.io"
GR = sel("getReserves()"); T0 = sel("token0()"); T1 = sel("token1()")
APL = sel("allPairsLength()"); AP = sel("allPairs(uint256)")
BAL = sel("balanceOf(address)"); DEC = sel("decimals()")

def price_map(chain, tokens):
    prices = {}
    toks = sorted(set(t for t in tokens if t))
    for i in range(0, len(toks), 40):
        ids = ",".join(f"{chain}:{t}" for t in toks[i:i+40])
        try:
            with urllib.request.urlopen(urllib.request.Request("https://coins.llama.fi/prices/current/" + ids,
                                                              headers={"User-Agent": "research"}), timeout=30) as r:
                d = json.load(r)
            for k, v in (d.get("coins") or {}).items():
                prices[k.split(":")[1].lower()] = v.get("price")
        except Exception:
            pass
    return prices

def scan(chain, factory, label, limit=300):
    n = int(rpc(chain, "eth_call", [{"to": factory, "data": APL}, "latest"]), 16)
    addrs = []
    for i in range(0, min(n, limit), 30):
        res = batch(chain, [("eth_call", [{"to": factory, "data": AP + enc_uint(j)}, "latest"]) for j in range(i, min(i+30, n, limit))], chunk=30)
        for r in res:
            if isinstance(r, str) and r.startswith("0x") and len(r) >= 42:
                addrs.append("0x" + r[2:][24:64])
    rows = []
    for a in addrs:
        t0 = rpc(chain, "eth_call", [{"to": a, "data": T0}, "latest"])
        t1 = rpc(chain, "eth_call", [{"to": a, "data": T1}, "latest"])
        if not (isinstance(t0, str) and len(t0) >= 42): continue
        t0 = "0x" + t0[2:][24:64]; t1 = "0x" + t1[2:][24:64]
        res = rpc(chain, "eth_call", [{"to": a, "data": GR}, "latest"])
        try:
            raw = res[2:]; r0 = int(raw[:64],16); r1 = int(raw[64:128],16)
        except Exception:
            continue
        b0 = rpc(chain, "eth_call", [{"to": t0, "data": BAL + enc_addr(a)}, "latest"])
        b1 = rpc(chain, "eth_call", [{"to": t1, "data": BAL + enc_addr(a)}, "latest"])
        try:
            b0 = int(b0,16); b1 = int(b1,16)
        except Exception:
            continue
        rows.append({"pair": a, "t0": t0, "t1": t1, "r0": r0, "r1": r1, "b0": b0, "b1": b1})
    toks = sorted({t for r in rows for t in (r["t0"], r["t1"])})
    dec = {}
    for i in range(0, len(toks), 30):
        chunk = toks[i:i+30]
        res = batch(chain, [("eth_call", [{"to": t, "data": DEC}, "latest"]) for t in chunk], chunk=15)
        for t, r in zip(chunk, res):
            try: dec[t] = int(r,16)
            except Exception: dec[t] = 18
    prices = price_map(chain, toks)
    total_bal = 0.0; total_res = 0.0
    live_bal = []
    for r in rows:
        d0, d1 = dec.get(r["t0"],18), dec.get(r["t1"],18)
        p0, p1 = prices.get(r["t0"],0), prices.get(r["t1"],0)
        usd_bal = (r["b0"]/10**d0)*p0 + (r["b1"]/10**d1)*p1
        usd_res = (r["r0"]/10**d0)*p0 + (r["r1"]/10**d1)*p1
        r["usd_bal"] = usd_bal; r["usd_res"] = usd_res
        total_bal += usd_bal; total_res += usd_res
        if usd_bal > 1: live_bal.append(r)
    live_bal.sort(key=lambda x: -x["usd_bal"])
    print(f"== {label}: pairs={len(rows)}  USD(balances)=${total_bal:,.2f}  USD(reserves)=${total_res:,.2f}")
    for r in live_bal[:12]:
        print(f"   ${r['usd_bal']:>10,.2f} (res ${r['usd_res']:>10,.2f}) {r['pair']} t0={r['t0'][:12]} b0={r['b0']} r0={r['r0']} | t1={r['t1'][:12]} b1={r['b1']} r1={r['r1']}")
    return {"label": label, "factory": factory, "pairs": len(rows), "usd_balances": total_bal, "usd_reserves": total_res, "top": live_bal[:15]}

if __name__ == "__main__":
    out = {}
    out["luigiswap-opbnb"] = scan("opbnb", "0x0dAe6d22182c20AB9150a4DCB3160591Dc41027a", "luigiswap-opbnb")
    out["luigiswap-scroll"] = scan("scroll", "0x0dAe6d22182c20AB9150a4DCB3160591Dc41027a", "luigiswap-scroll")
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/l2-26-luigiswap.json","w"), indent=1, default=str)
