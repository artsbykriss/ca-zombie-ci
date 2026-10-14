#!/usr/bin/env python3
"""Probe the second (UniV2) factory per chain for additional custody."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

JOBS = {
    "base": {"factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "native": "0x4200000000000000000000000000000000000006"},
    "linea": {"factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "native": "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f"},
}
SEL = {
    "allPairsLength": "0x574f2ba3", "allPairs": "0x1e3dd18b",
    "token0": "0x0dfe1681", "token1": "0xd21220a7", "getReserves": "0x0902f1ac",
    "balanceOf": "0x70a08231", "feeTo": "0x017e7e58", "totalSupply": "0x18160ddd",
}

def main():
    for chain, j in JOBS.items():
        f = j["factory"]
        try:
            n = B.dec_uint(B.words(B.batch(chain, [("eth_call", [{"to": f, "data": SEL["allPairsLength"]}, "latest"])])[0])[0])
        except Exception as e:
            print(chain, "allPairsLength fail", str(e)[:80]); continue
        print(f"== {chain} UniV2 factory {f}: {n} pairs", flush=True)
        if not n: continue
        idx = list(range(min(n, 200)))
        pr = B.batch(chain, [("eth_call", [{"to": f, "data": SEL["allPairs"] + B.pad_uint(i)}, "latest"]) for i in idx])
        pairs = [B.dec_addr(B.words(x)[0]) for x in pr if x and x != "0x"]
        # read tokens/reserves/balances for each pair
        tot_native = 0
        rows = []
        for p in pairs:
            try:
                r = B.batch(chain, [
                    ("eth_call", [{"to": p, "data": SEL["token0"]}, "latest"]),
                    ("eth_call", [{"to": p, "data": SEL["token1"]}, "latest"]),
                    ("eth_call", [{"to": p, "data": SEL["getReserves"]}, "latest"]),
                ])
                t0 = B.dec_addr(B.words(r[0])[0]); t1 = B.dec_addr(B.words(r[1])[0])
                ws = B.words(r[2]); r0, r1 = B.dec_uint(ws[0]), B.dec_uint(ws[1])
                b = B.batch(chain, [
                    ("eth_call", [{"to": t0, "data": SEL["balanceOf"] + B.pad_addr(p)}, "latest"]),
                    ("eth_call", [{"to": t1, "data": SEL["balanceOf"] + B.pad_addr(p)}, "latest"]),
                ])
                b0 = B.dec_uint(B.words(b[0])[0]) if b[0] else 0
                b1 = B.dec_uint(B.words(b[1])[0]) if b[1] else 0
                nat = 0
                if t0 == j["native"]: nat = b0
                if t1 == j["native"]: nat = max(nat, b1)
                tot_native += nat
                rows.append((p, t0, t1, r0, r1, b0, b1, nat))
            except Exception as e:
                rows.append((p, "ERR", str(e)[:60], 0, 0, 0, 0, 0))
        rows.sort(key=lambda x: -x[7])
        print(f"   native-side total across {len(pairs)} pairs: {tot_native/1e18:.6f}")
        for x in rows[:12]:
            print(f"   {x[0]} t0={x[1]} t1={x[2]} r0={x[3]} r1={x[4]} b0={x[5]} b1={x[6]} native={x[7]/1e18:.6f}")

if __name__ == "__main__":
    main()
