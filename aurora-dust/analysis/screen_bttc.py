#!/usr/bin/env python3
"""BTTC DEX balance-based scans: SpookySwap, Intercroneswap, Kyber."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint
import urllib.request

GR = sel("getReserves()"); T0 = sel("token0()"); T1 = sel("token1()")
APL = sel("allPairsLength()"); AP = sel("allPairs(uint256)")
BAL = sel("balanceOf(address)"); DEC = sel("decimals()"); FAC = sel("factory()")

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

def scan(chain, factory, label, limit=400):
    try:
        n = int(rpc(chain, "eth_call", [{"to": factory, "data": APL}, "latest"]), 16)
    except Exception:
        print(f"== {label}: no allPairsLength"); return None
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
    for r in rows:
        d0, d1 = dec.get(r["t0"],18), dec.get(r["t1"],18)
        p0, p1 = prices.get(r["t0"],0), prices.get(r["t1"],0)
        r["usd_bal"] = (r["b0"]/10**d0)*p0 + (r["b1"]/10**d1)*p1
        r["usd_res"] = (r["r0"]/10**d0)*p0 + (r["r1"]/10**d1)*p1
        total_bal += r["usd_bal"]; total_res += r["usd_res"]
    live = sorted([r for r in rows if r["usd_bal"] > 0.5], key=lambda x: -x["usd_bal"])
    print(f"== {label}: pairs={len(rows)} USD(bal)=${total_bal:,.2f} USD(res)=${total_res:,.2f}")
    for r in live[:12]:
        print(f"   ${r['usd_bal']:>10,.2f} (res ${r['usd_res']:>10,.2f}) {r['pair']} {r['t0'][:10]} b0={r['b0']} | {r['t1'][:10]} b1={r['b1']}")
    # skim excess
    excess=[]
    for r in rows:
        if r["b0"] > r["r0"] or r["b1"] > r["r1"]:
            excess.append(r)
    print(f"   pairs with balance>reserve (skim-able): {len(excess)}")
    return {"label": label, "factory": factory, "pairs": len(rows), "usd_bal": total_bal, "usd_res": total_res, "top": live[:15], "skimable": len(excess)}

if __name__ == "__main__":
    out = {}
    # SpookySwap BTTC factory from known pool
    r = rpc("bttc", "eth_call", [{"to": "0x418afcd6d15fa51d59d6c7f7a5943eb04d5f21f0", "data": FAC}, "latest"])
    sf = "0x" + r[2:][24:64] if isinstance(r, str) and len(r) >= 42 else None
    print("SpookySwap BTTC factory:", sf)
    if sf:
        out["spookyswap-bttc"] = scan("bttc", sf, "spookyswap-bttc", limit=500)
    out["intercroneswap-bttc"] = scan("bttc", "0x0cEE0dFb5C680e3CcAA46FA28D5057f204E24F0a", "intercroneswap-bttc", limit=300)
    out["kyber-bttc"] = scan("bttc", "0xD9bfE9979e9CA4b2fe84bA5d4Cf963bBcB376974", "kyber-bttc", limit=300)
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/l2-26-bttc.json","w"), indent=1, default=str)
