#!/usr/bin/env python3
"""Second-factory scan: the plain UniswapV2 factories (0xa2899c77 / 0xd3Ea3BC1) per chain.

The phase-1 triage only covered one factory per chain; LeetSwap deployed both a
UniV2 factory and a Solidly-style V2 factory on several chains. This script
enumerates the UniV2 factories and reports the native-token (WETH/WBNB) custody.
Read-only.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "analysis"))
import rpcb as B

OUT = os.path.join(os.path.dirname(HERE), "ci-out")
os.makedirs(OUT, exist_ok=True)

JOBS = [
    ("base", "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "0x4200000000000000000000000000000000000006", "WETH"),
    ("linea", "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f", "WETH"),
    ("manta", "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "0x0dc808adce2099a9f62aa87d9670745aba741746", "WETH"),
    ("op_bnb", "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "0x4200000000000000000000000000000000000006", "WBNB"),
    ("scroll", "0xa2899c776baaf9925d432f83c950d5054a6cf59c", "0x5300000000000000000000000000000000000004", "WETH"),
    ("shibarium", "0xd3Ea3BC1F5A3F881bD6cE9761cbA5A0833a5d737", "0x0000000000000000000000000000000000000000", "BONE"),
    # also probe the other known factories for cross-presence
    ("base", "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c", "0x4200000000000000000000000000000000000006", "WETH-solidly2"),
    ("linea", "0xcE87E0960f4e2702f4bFFE277655E993Ae720e84", "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f", "WETH-solidly2"),
    ("op_bnb", "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c", "0x4200000000000000000000000000000000000006", "WBNB-solidly2"),
    ("manta", "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c", "0x0dc808adce2099a9f62aa87d9670745aba741746", "WETH-solidly2"),
]


def main():
    out = {}
    for chain, f, native, sym in JOBS:
        key = f"{chain}:{f}"
        try:
            r = B.batch(chain, [("eth_call", [{"to": f, "data": "0x574f2ba3"}, "latest"]),
                                ("eth_call", [{"to": f, "data": "0x017e7e58"}, "latest"]),
                                ("eth_call", [{"to": f, "data": "0xb187bd26"}, "latest"]),
                                ("eth_getCode", [f, "latest"])])
            code = len(r[3] or "0x") // 2 - 1 if r[3] else 0
            if code <= 0:
                print(f"== {key}: no code", flush=True)
                out[key] = {"no_code": True}
                continue
            n = B.dec_uint(B.words(r[0])[0]) if r[0] else 0
            feeTo = B.dec_addr(B.words(r[1])[0]) if r[1] else None
            paused = bool(B.dec_uint(B.words(r[2])[0])) if r[2] and r[2] != "0x" else None
            print(f"== {key}: {n} pairs feeTo={feeTo} isPaused={paused} code={code}", flush=True)
            if not n:
                out[key] = {"n": 0, "feeTo": feeTo, "paused": paused, "code": code}
                continue
            pr = B.batch(chain, [("eth_call", [{"to": f, "data": "0x1e3dd18b" + B.pad_uint(i)}, "latest"]) for i in range(n)])
            pairs = [B.dec_addr(B.words(x)[0]) for x in pr if x and x != "0x"]
            tr = B.batch(chain, [c for p in pairs for c in (
                ("eth_call", [{"to": p, "data": "0x0dfe1681"}, "latest"]),
                ("eth_call", [{"to": p, "data": "0xd21220a7"}, "latest"]),
                ("eth_call", [{"to": p, "data": "0x0902f1ac"}, "latest"]),
                ("eth_call", [{"to": p, "data": "0x18160ddd"}, "latest"]))])
            rows = []
            tot_native = 0
            for i, p in enumerate(pairs):
                t0 = B.dec_addr(B.words(tr[4*i])[0]) if tr[4*i] else None
                t1 = B.dec_addr(B.words(tr[4*i+1])[0]) if tr[4*i+1] else None
                ws = B.words(tr[4*i+2]) if tr[4*i+2] else []
                r0 = B.dec_uint(ws[0]) if ws else None
                r1 = B.dec_uint(ws[1]) if len(ws) > 1 else None
                sup = B.dec_uint(B.words(tr[4*i+3])[0]) if tr[4*i+3] else None
                nat = 0
                if native != "0x" + "0"*40:
                    if t0 == native: nat = r0 or 0
                    if t1 == native: nat = max(nat, r1 or 0)
                tot_native += nat
                rows.append({"pair": p, "t0": t0, "t1": t1, "r0": r0, "r1": r1, "lp": sup, "native": nat})
            rows.sort(key=lambda x: -(x.get("native") or 0))
            print(f"   {sym} in reserves across {len(pairs)} pairs: {tot_native/1e18:.6f}", flush=True)
            for x in rows[:8]:
                print(f"   {x['pair']} t0={x['t0']} t1={x['t1']} native={x['native']/1e18:.6f}", flush=True)
            out[key] = {"n": n, "feeTo": feeTo, "paused": paused, "code": code,
                        "native_total": tot_native, "rows": rows}
        except Exception as e:
            print(f"== {key}: FAIL {str(e)[:150]}", flush=True)
            out[key] = {"error": str(e)[:200]}
    json.dump(out, open(os.path.join(OUT, "second-factory.json"), "w"), indent=1)
    print("wrote ci-out/second-factory.json", flush=True)


if __name__ == "__main__":
    main()
