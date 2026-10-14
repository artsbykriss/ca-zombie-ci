#!/usr/bin/env python3
"""Run the live-market (PancakeSwap) arb check over all PandaSwap pairs. Local evidence script."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pancake_arb import ArbEngine
from rpc import block_number, _post, RPCS

HERE = os.path.dirname(os.path.abspath(__file__))


def make_call(bn):
    block = hex(bn)
    state = {"url": None}

    def call(to, data, blk):
        payload = {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, blk]}
        urls = ([state["url"]] if state["url"] else []) + [u for u in RPCS if u != state["url"]]
        for attempt in range(6):
            for u in urls:
                try:
                    r = _post(u, payload, timeout=15)
                    if isinstance(r, dict) and "result" in r:
                        state["url"] = u
                        return r["result"]
                except Exception:
                    continue
            time.sleep(0.8 + 0.5 * attempt)
        return None
    return call


def main():
    d = json.load(open(os.path.join(HERE, "all-pairs.json")))
    priced = json.load(open(os.path.join(HERE, "priced.json")))
    prices = priced["prices"]
    bn = d["block"]
    tokens = d["tokens"]
    dec = {a: (m.get("decimals") or 18) for a, m in tokens.items()}
    call = make_call(bn)
    eng = ArbEngine(call, hex(bn), dec)
    rows = []
    t0t = time.time()
    for i, (p, v) in enumerate(d["pairs"].items()):
        t0, t1 = v.get("token0"), v.get("token1")
        r0, r1 = v.get("reserve0"), v.get("reserve1")
        if not (t0 and t1 and r0 and r1):
            continue
        d0 = dec.get(t0, 18); d1 = dec.get(t1, 18)
        p0 = prices.get(t0.lower()); p1 = prices.get(t1.lower())
        # USD prices fallback: derive from WBNB when missing
        wbnb_usd = prices.get("0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", 745.0)
        try:
            res = eng.compute(t0, t1, r0, r1, d0, d1, p0, p1)
        except Exception as e:
            res = {"profit_usd": 0.0, "err": str(e)}
        if res.get("profit_usd", 0) > 0.1:
            rows.append({"pair": p, "sym0": tokens.get(t0, {}).get("symbol"), "sym1": tokens.get(t1, {}).get("symbol"),
                         **res})
            print(f"ARB {res['profit_usd']:.2f} USD {tokens.get(t0,{}).get('symbol')}/{tokens.get(t1,{}).get('symbol')} {p} {res}", flush=True)
        if i % 20 == 0:
            print(f"  {i}/{len(d['pairs'])} elapsed {time.time()-t0t:.0f}s", flush=True)
    rows.sort(key=lambda r: -r["profit_usd"])
    total = sum(r["profit_usd"] for r in rows)
    out = {"block": bn, "total_arb_usd": round(total, 2), "rows": rows,
           "method": "exact simulation vs live PancakeSwap pools (direct or via WBNB), fees 0.3%/0.25%"}
    json.dump(out, open(os.path.join(HERE, "arb-live.json"), "w"), indent=1)
    print(f"TOTAL live-market arb: ${total:,.2f}", flush=True)


if __name__ == "__main__":
    main()
