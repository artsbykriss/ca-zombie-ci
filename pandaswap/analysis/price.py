#!/usr/bin/env python3
"""Price all PandaSwap pair reserves via DefiLlama; compute USD totals; detect excess."""
import json, os, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) zombie-research"}


def llama_prices(tokens):
    """tokens: list of 0x addresses (bsc). Returns {addr: price}."""
    out = {}
    for i in range(0, len(tokens), 60):
        chunk = tokens[i:i + 60]
        url = "https://coins.llama.fi/prices/current/" + ",".join(f"bsc:{t}" for t in chunk)
        for attempt in range(4):
            try:
                req = urllib.request.Request(url, headers=UA)
                d = json.loads(urllib.request.urlopen(req, timeout=30).read())
                for k, v in d.get("coins", {}).items():
                    out[k.split(":")[1].lower()] = v.get("price")
                break
            except Exception as e:
                print("llama retry", i, type(e).__name__, flush=True)
                time.sleep(2 * (attempt + 1))
    return out


def main():
    d = json.load(open(os.path.join(HERE, "all-pairs.json")))
    pairs = d["pairs"]; tokens = d["tokens"]
    addrs = sorted({v.get("token0") for v in pairs.values() if v.get("token0")} |
                   {v.get("token1") for v in pairs.values() if v.get("token1")})
    print(f"tokens: {len(addrs)}", flush=True)
    prices = llama_prices(addrs)
    print(f"priced: {len(prices)}", flush=True)

    rows = []
    total = 0.0
    for p, v in pairs.items():
        t0, t1 = v.get("token0"), v.get("token1")
        r0, r1 = v.get("reserve0"), v.get("reserve1")
        if not (t0 and t1 and r0 is not None and r1 is not None):
            continue
        d0 = (tokens.get(t0, {}).get("decimals") or 18)
        d1 = (tokens.get(t1, {}).get("decimals") or 18)
        p0 = prices.get(t0.lower()); p1 = prices.get(t1.lower())
        v0 = (r0 / 10 ** d0) * p0 if p0 else 0.0
        v1 = (r1 / 10 ** d1) * p1 if p1 else 0.0
        usd = v0 + v1
        total += usd
        e0 = (v.get("bal0") or 0) - r0
        e1 = (v.get("bal1") or 0) - r1
        rows.append({
            "pair": p, "sym0": tokens.get(t0, {}).get("symbol"), "sym1": tokens.get(t1, {}).get("symbol"),
            "t0": t0, "t1": t1, "r0": r0, "r1": r1, "usd0": round(v0, 2), "usd1": round(v1, 2),
            "usd": round(usd, 2), "lp": v.get("lpTotalSupply"), "excess0": e0, "excess1": e1,
        })
    rows.sort(key=lambda r: -r["usd"])
    res = {"block": d["block"], "total_usd": round(total, 2), "priced_tokens": len(prices),
           "n_tokens": len(addrs), "top": rows[:40], "rows": rows, "prices": prices}
    json.dump(res, open(os.path.join(HERE, "priced.json"), "w"), indent=1)
    print(f"TOTAL USD: {total:,.2f}", flush=True)
    for r in rows[:25]:
        print(f"  {r['pair']} {r['sym0']}/{r['sym1']} = ${r['usd']:,.2f} (r0={r['r0']}, r1={r['r1']}) excess=({r['excess0']},{r['excess1']})", flush=True)
    unpriced = [t for t in addrs if t.lower() not in prices]
    print("unpriced tokens:", len(unpriced), flush=True)
    for t in unpriced[:40]:
        print("   ", t, tokens.get(t, {}).get("symbol"), flush=True)


if __name__ == "__main__":
    main()
