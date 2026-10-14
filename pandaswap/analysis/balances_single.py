#!/usr/bin/env python3
"""Re-read pair balances with SINGLE calls (no batching) for all 129 pairs; verify excess."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import RPCS, _post, as_addr, as_int, encode_addr, block_number

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "balances-single.json")
SEL_BAL = "0x70a08231"


def single_call(to, data, block, retries=6):
    payload = {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, hex(block)]}
    urls = list(RPCS)
    for attempt in range(retries):
        for u in urls:
            try:
                r = _post(u, payload, timeout=15)
                if isinstance(r, dict) and "result" in r:
                    return r["result"]
            except Exception:
                continue
        time.sleep(1.0 + attempt)
    return None


def main():
    d = json.load(open(os.path.join(HERE, "all-pairs.json")))
    bn = d["block"]
    print("block", bn, flush=True)
    pairs = list(d["pairs"].items())
    res = {}
    for idx, (p, v) in enumerate(pairs):
        t0, t1 = v.get("token0"), v.get("token1")
        b0 = single_call(t0, SEL_BAL + encode_addr(p), bn) if t0 else None
        b1 = single_call(t1, SEL_BAL + encode_addr(p), bn) if t1 else None
        res[p] = {"bal0": as_int(b0), "bal1": as_int(b1)}
        if idx % 20 == 0:
            print(f"{idx}/{len(pairs)}", flush=True)
    json.dump({"block": bn, "balances": res}, open(OUT, "w"), indent=1)

    n_ex = 0
    tot_real = 0.0
    for p, v in pairs:
        r = res[p]
        e0 = (r["bal0"] or 0) - (v.get("reserve0") or 0)
        e1 = (r["bal1"] or 0) - (v.get("reserve1") or 0)
        if e0 > 0 or e1 > 0:
            n_ex += 1
            t0 = d["tokens"].get(v.get("token0"), {}).get("symbol")
            t1 = d["tokens"].get(v.get("token1"), {}).get("symbol")
            print(f"excess {p} {t0}/{t1}: e0={e0} e1={e1} (r0={v.get('reserve0')}, r1={v.get('reserve1')})", flush=True)
    print("excess pairs:", n_ex, flush=True)


if __name__ == "__main__":
    main()
