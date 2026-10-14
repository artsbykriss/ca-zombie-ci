#!/usr/bin/env python3
"""Enumerate all MiniSwap pairs: tokens, reserves, balances, LP supply, kLast, feeTo LP share.
Writes analysis/pairs_raw.json. RPC URLs come from rpclib (keys read from .env at runtime)."""
import sys, json, time
sys.path.insert(0, 'analysis')
import rpclib as R

FACTORY = "0x1e2c2102cf8efcaaaf20ffe926469ec7cd0d0f6e"
FACTORY2 = "0xbbe026500e273e2f2e6b41c93d11fe6d5c6d71bf"
BLOCK = None

def main():
    global BLOCK
    bn = R.rpc_batch([("eth_blockNumber", [])])[0]
    BLOCK = int(bn, 16)
    n = int(R.eth_call(FACTORY, R.SEL["allPairsLength"]), 16)
    print(f"block={BLOCK} pairs={n}", flush=True)
    feeTo = "0x" + (R.eth_call(FACTORY, R.SEL["feeTo"]) or "0x"+"0"*40)[-40:]
    feeToSetter = "0x" + (R.eth_call(FACTORY, R.SEL["feeToSetter"]) or "0x"+"0"*40)[-40:]
    print(f"feeTo={feeTo} feeToSetter={feeToSetter}", flush=True)

    # 1) all pair addresses
    pairs = []
    for i in range(n):
        d = R.SEL["allPairs"] + R.pad_hex(i) if hasattr(R,'pad_hex') else "0x1e3dd18b" + f"{i:064x}"
        r = R.eth_call(FACTORY, d)
        pairs.append("0x" + r[-40:])
    print("pairs:", len(pairs), flush=True)

    # 2) per-pair reads (batched)
    items = []
    meta = []
    for p in pairs:
        for sel,arg in [("token0",None),("token1",None),("getReserves",None),("totalSupply",None),
                        ("kLast",None),("symbol",None),("balanceOf",R.pad(feeTo))]:
            data = R.SEL[sel] + (arg or "")
            items.append((p, data)); meta.append((p, sel, arg))
    res = R.calls_batched(items, chunk=10)
    recs = {p: {} for p in pairs}
    for (p, sel, arg), r in zip(meta, res):
        key = sel if arg is None else f"{sel}_{arg}"
        recs[p][key] = r
    print("per-pair base reads done", flush=True)

    # 3) balances of tokens held by each pair
    toks = {}
    for p in pairs:
        t0 = "0x" + (recs[p].get("token0") or "0x" + "0"*40)[-40:]
        t1 = "0x" + (recs[p].get("token1") or "0x" + "0"*40)[-40:]
        toks[p] = (t0, t1)
    items2, meta2 = [], []
    for p,(t0,t1) in toks.items():
        items2.append((t0, R.SEL["balanceOf"] + R.pad(p))); meta2.append((p,"bal0"))
        items2.append((t1, R.SEL["balanceOf"] + R.pad(p))); meta2.append((p,"bal1"))
    res2 = R.calls_batched(items2, chunk=10)
    for (p, k), r in zip(meta2, res2):
        recs[p][k] = r
    print("balance reads done", flush=True)

    # 4) token metadata (symbol/decimals) for both sides
    tset = set()
    for p,(t0,t1) in toks.items(): tset.add(t0); tset.add(t1)
    items3, meta3 = [], []
    for t in tset:
        items3.append((t, R.SEL["symbol"])); meta3.append((t,"symbol"))
        items3.append((t, R.SEL["decimals"])); meta3.append((t,"decimals"))
    res3 = R.calls_batched(items3, chunk=10)
    tmeta = {t: {} for t in tset}
    for (t,k), r in zip(meta3, res3):
        tmeta[t][k] = r
    print("token meta done", flush=True)

    def dec_str(h):
        if not h or len(h) < 130: return None
        try:
            b = bytes.fromhex(h[2:])
            off = int.from_bytes(b[0:32],'big')
            if off+32 > len(b): return None
            ln = int.from_bytes(b[off:off+32],'big')
            if ln > 64 or off+32+ln > len(b): return None
            return b[off+32:off+32+ln].decode('utf-8','replace')
        except Exception: return None

    out = {"block": BLOCK, "factory": FACTORY, "feeTo": feeTo, "feeToSetter": feeToSetter, "pairs": []}
    for p in pairs:
        r = recs[p]
        t0,t1 = toks[p]
        def U(h): return int(h,16) if h and h != "0x" else None
        g = r.get("getReserves") or ""
        rec = {
            "pair": p,
            "token0": t0, "token1": t1,
            "symbol0": dec_str(tmeta[t0].get("symbol")), "symbol1": dec_str(tmeta[t1].get("symbol")),
            "decimals0": U(tmeta[t0].get("decimals")), "decimals1": U(tmeta[t1].get("decimals")),
            "reserve0": U(g[2:66]) if len(g)>=130 else None,
            "reserve1": U(g[66:130]) if len(g)>=130 else None,
            "totalSupply": U(r.get("totalSupply")),
            "kLast": U(r.get("kLast")),
            "bal0": U(r.get("bal0")), "bal1": U(r.get("bal1")),
            "feeToLP": U(r.get("balanceOf_"+R.pad(feeTo))),
        }
        rec["excess0"] = (rec["bal0"]-rec["reserve0"]) if rec["bal0"] is not None and rec["reserve0"] is not None else None
        rec["excess1"] = (rec["bal1"]-rec["reserve1"]) if rec["bal1"] is not None and rec["reserve1"] is not None else None
        out["pairs"].append(rec)
    json.dump(out, open("analysis/pairs_raw.json","w"), indent=1)
    print("saved analysis/pairs_raw.json", flush=True)

if __name__ == "__main__":
    main()
