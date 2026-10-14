#!/usr/bin/env python3
"""Enumerate MiniSwap factory2 (0x22945770...) pairs: tokens, reserves, balances, LP supply.
Usage: python3 enumerate2.py [factory] [outfile]"""
import sys, json
sys.path.insert(0, 'analysis')
import rpclib as R

FACTORY = sys.argv[1] if len(sys.argv) > 1 else "0x2294577031f113df4782b881cf0b140e94209a6f"
OUT = sys.argv[2] if len(sys.argv) > 2 else "analysis/pairs_raw_f2.json"

def main():
    bn = R.rpc_batch([("eth_blockNumber", [])])[0]
    BLOCK = int(bn, 16)
    n = int(R.eth_call(FACTORY, R.SEL["allPairsLength"]), 16)
    print(f"block={BLOCK} factory={FACTORY} pairs={n}", flush=True)
    pairs = []
    for i in range(n):
        r = R.eth_call(FACTORY, "0x1e3dd18b" + f"{i:064x}")
        pairs.append("0x" + r[-40:])
    items, meta = [], []
    for p in pairs:
        for sel in ["token0","token1","getReserves","totalSupply","kLast","symbol"]:
            items.append((p, R.SEL[sel])); meta.append((p, sel))
    res = R.calls_batched(items, chunk=8)
    recs = {p: {} for p in pairs}
    for (p, sel), r in zip(meta, res):
        recs[p][sel] = r
    toks = {}
    for p in pairs:
        toks[p] = ("0x"+(recs[p].get("token0") or "0x"+"0"*40)[-40:], "0x"+(recs[p].get("token1") or "0x"+"0"*40)[-40:])
    items2, meta2 = [], []
    for p,(t0,t1) in toks.items():
        items2.append((t0, R.SEL["balanceOf"] + R.pad(p))); meta2.append((p,"bal0"))
        items2.append((t1, R.SEL["balanceOf"] + R.pad(p))); meta2.append((p,"bal1"))
    res2 = R.calls_batched(items2, chunk=8)
    for (p,k), r in zip(meta2, res2):
        recs[p][k] = r
    tset = set()
    for p,(t0,t1) in toks.items(): tset.add(t0); tset.add(t1)
    items3, meta3 = [], []
    for t in tset:
        items3.append((t, R.SEL["symbol"])); meta3.append((t,"symbol"))
        items3.append((t, R.SEL["decimals"])); meta3.append((t,"decimals"))
    res3 = R.calls_batched(items3, chunk=8)
    tmeta = {t: {} for t in tset}
    for (t,k), r in zip(meta3, res3): tmeta[t][k] = r

    def dec_str(h):
        if not h or len(h) < 130: return None
        try:
            b = bytes.fromhex(h[2:]); off = int.from_bytes(b[0:32],'big')
            if off+32 > len(b): return None
            ln = int.from_bytes(b[off:off+32],'big')
            if ln > 64 or off+32+ln > len(b): return None
            return b[off+32:off+32+ln].decode('utf-8','replace')
        except Exception: return None
    def U(h): return int(h,16) if h and h != "0x" else None
    out = {"block": BLOCK, "factory": FACTORY, "pairs": []}
    for p in pairs:
        r = recs[p]; t0,t1 = toks[p]
        g = r.get("getReserves") or ""
        rec = {"pair": p, "token0": t0, "token1": t1,
               "symbol0": dec_str(tmeta[t0].get("symbol")), "symbol1": dec_str(tmeta[t1].get("symbol")),
               "decimals0": U(tmeta[t0].get("decimals")), "decimals1": U(tmeta[t1].get("decimals")),
               "reserve0": U(g[2:66]) if len(g)>=130 else None,
               "reserve1": U(g[66:130]) if len(g)>=130 else None,
               "totalSupply": U(r.get("totalSupply")), "kLast": U(r.get("kLast")),
               "bal0": U(r.get("bal0")), "bal1": U(r.get("bal1"))}
        rec["excess0"] = (rec["bal0"]-rec["reserve0"]) if rec["bal0"] is not None and rec["reserve0"] is not None else None
        rec["excess1"] = (rec["bal1"]-rec["reserve1"]) if rec["bal1"] is not None and rec["reserve1"] is not None else None
        out["pairs"].append(rec)
    json.dump(out, open(OUT,"w"), indent=1)
    print("saved", OUT, flush=True)
    for rec in out["pairs"]:
        print(f"{rec['pair']} {str(rec['symbol0'])[:10]:10s}/{str(rec['symbol1'])[:10]:10s} r0={rec['reserve0']} r1={rec['reserve1']} ts={rec['totalSupply']} excess=({rec['excess0']},{rec['excess1']})")

if __name__ == "__main__":
    main()
