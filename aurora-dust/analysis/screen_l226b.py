#!/usr/bin/env python3
"""L2-26: get factories from known pairs; scan BTTC/opBNB DEX factories (reserves+skim+USD)."""
import sys, json, urllib.request
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")
APL = sel("allPairsLength()")
AP = sel("allPairs(uint256)")
BAL = sel("balanceOf(address)")
DEC = sel("decimals()")
FAC = sel("factory()")

def price_map(chain, tokens):
    prices = {}
    toks = sorted(set(tokens))
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

def scan(chain, factory, label, limit=600):
    n = rpc(chain, "eth_call", [{"to": factory, "data": APL}, "latest"])
    try: n = int(n, 16)
    except Exception:
        print(f"== {label} {factory}: no allPairsLength -> {str(n)[:80]}")
        return None
    addrs = []
    for i in range(0, min(n, limit), 30):
        res = batch(chain, [("eth_call", [{"to": factory, "data": AP + enc_uint(j)}, "latest"]) for j in range(i, min(i+30, n, limit))], chunk=30)
        for r in res:
            if isinstance(r, str) and r.startswith("0x") and len(r) >= 42:
                addrs.append("0x" + r[2:][24:64])
    reserves = {}
    for i in range(0, len(addrs), 40):
        chunk = addrs[i:i+40]
        res = batch(chain, [("eth_call", [{"to": a, "data": GR}, "latest"]) for a in chunk], chunk=20)
        for a, r in zip(chunk, res):
            if isinstance(r, str) and len(r) >= 2+192:
                raw = r[2:]
                reserves[a] = (int(raw[:64],16), int(raw[64:128],16))
    live = {a: v for a, v in reserves.items() if v[0] > 10**6 or v[1] > 10**6}
    # tokens
    items = list(live.items())
    tok = {}
    for i in range(0, len(items), 30):
        chunk = items[i:i+30]
        calls = []
        for a, _ in chunk:
            calls.append(("eth_call", [{"to": a, "data": T0}, "latest"]))
            calls.append(("eth_call", [{"to": a, "data": T1}, "latest"]))
        res = batch(chain, calls, chunk=20)
        for k, (a, rv) in enumerate(chunk):
            t0 = "0x" + res[2*k][2:][24:64] if isinstance(res[2*k], str) and len(res[2*k]) >= 42 else None
            t1 = "0x" + res[2*k+1][2:][24:64] if isinstance(res[2*k+1], str) and len(res[2*k+1]) >= 42 else None
            tok[a] = (t0, t1, rv)
    toks = sorted({t for v in tok.values() for t in v[:2] if t})
    dec = {}
    for i in range(0, len(toks), 30):
        chunk = toks[i:i+30]
        res = batch(chain, [("eth_call", [{"to": t, "data": DEC}, "latest"]) for t in chunk], chunk=15)
        for t, r in zip(chunk, res):
            try: dec[t] = int(r, 16)
            except Exception: dec[t] = 18
    prices = price_map(chain, toks)
    rows = []
    for a, (t0, t1, (r0, r1)) in tok.items():
        d0, d1 = dec.get(t0, 18), dec.get(t1, 18)
        p0, p1 = prices.get((t0 or "").lower(), 0), prices.get((t1 or "").lower(), 0)
        usd = (r0/10**d0)*p0 + (r1/10**d1)*p1
        rows.append({"pair": a, "t0": t0, "t1": t1, "r0": r0, "r1": r1, "usd": usd})
    rows.sort(key=lambda x: -x["usd"])
    total = sum(r["usd"] for r in rows)
    print(f"== {label} {factory}: pairs={n} live={len(live)} USD=${total:,.2f}")
    for r in rows[:8]:
        print(f"   ${r['usd']:>10,.2f} {r['pair']} {str(r['t0'])[:12]} {r['r0']} {str(r['t1'])[:12]} {r['r1']}")
    # skim excess on live pairs
    excess = []
    for i in range(0, len(items), 40):
        chunk = items[i:i+40]
        calls = []
        for a, _ in chunk:
            calls.append(("eth_call", [{"to": a, "data": GR}, "latest"]))
        res = batch(chain, calls, chunk=20)
        for (a, rv), r in zip(chunk, res):
            if not (isinstance(r, str) and len(r) >= 2+192): continue
            raw = r[2:]
            rr0 = int(raw[:64],16); rr1 = int(raw[64:128],16)
            t0, t1 = tok[a][0], tok[a][1]
            b0 = rpc(chain, "eth_call", [{"to": t0, "data": BAL + enc_addr(a)}, "latest"])
            b1 = rpc(chain, "eth_call", [{"to": t1, "data": BAL + enc_addr(a)}, "latest"])
            try:
                e0 = int(b0,16)-rr0; e1 = int(b1,16)-rr1
            except Exception:
                continue
            if e0 > 0 or e1 > 0:
                excess.append({"pair": a, "e0": str(e0), "e1": str(e1)})
    print(f"   skim-excess pairs: {len(excess)}")
    for e in excess[:10]: print("     ", e)
    return {"label": label, "factory": factory, "n_pairs": n, "live": len(live), "usd_total": total, "rows": rows[:20], "excess": excess}

if __name__ == "__main__":
    out = {}
    # get LuigiSwap factories from known pairs
    for chain, pair, tag in [("opbnb", "0xc948161f0eb0979a783388dc3c7744e7b67d7d63", "luigiswap-opbnb"),
                              ("scroll", "0x9293fd53cf34fdfcf439a8827a85eace24b71e09", "luigiswap-scroll")]:
        r = rpc(chain, "eth_call", [{"to": pair, "data": FAC}, "latest"])
        f = "0x" + r[2:][24:64] if isinstance(r, str) and len(r) >= 42 else None
        print(tag, "factory:", f)
        if f:
            out[tag] = scan(chain, f, tag, limit=200)
    # known BTTC factories
    out["intercroneswap-bttc"] = scan("bttc", "0x0cEE0dFb5C680e3CcAA46FA28D5057f204E24F0a", "intercroneswap-bttc", limit=300)
    out["kyber-bttc"] = scan("bttc", "0xD9bfE9979e9CA4b2fe84bA5d4Cf963bBcB376974", "kyber-bttc", limit=300)
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/l2-26-scan1.json", "w"), indent=1, default=str)
