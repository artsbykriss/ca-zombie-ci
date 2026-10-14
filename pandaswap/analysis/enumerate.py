#!/usr/bin/env python3
"""Enumerate all PandaSwap pairs on BSC at a pinned block (column-wise batching). Read-only.

Writes analysis/pairs-raw.json
"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, encode_uint, encode_addr, as_addr, as_int

FACTORY = "0x9ad32bf5dafe152cbe027398219611db4e8753b3"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pairs-raw.json")

SEL_ALLPAIRS_LEN = "0x574f2ba3"
SEL_ALLPAIRS = "0x1e3dd18b"
SEL_TOKEN0 = "0x0dfe1681"
SEL_TOKEN1 = "0xd21220a7"
SEL_RESERVES = "0x0902f1ac"
SEL_TOTALSUPPLY = "0x18160ddd"
SEL_BALANCEOF = "0x70a08231"
SEL_SYMBOL = "0x95d89b41"
SEL_DECIMALS = "0x313ce567"
SEL_FACTORY = "0xc45a0155"
SEL_KLAST = "0x7464fc3d"


def decode_string(hexstr):
    if not hexstr or len(hexstr) <= 130:
        return None
    try:
        off = int(hexstr[2:66], 16)
        ln = int(hexstr[66 + off * 2: 66 + off * 2 + 64], 16)
        return bytes.fromhex(hexstr[66 + off * 2 + 64: 66 + off * 2 + 64 + ln * 2]).decode("utf-8", "replace")
    except Exception:
        return None


def main():
    bn = block_number()
    print("latest block:", bn, flush=True)
    out = rpc_batch([("eth_call", [{"to": FACTORY, "data": SEL_ALLPAIRS_LEN}, hex(bn)])])
    n = as_int(out[0])
    print("allPairsLength:", n, flush=True)

    # 1) all pair addresses
    calls = [("eth_call", [{"to": FACTORY, "data": SEL_ALLPAIRS + encode_uint(i)}, hex(bn)]) for i in range(n)]
    t = time.time()
    out = rpc_batch(calls)
    pairs = [as_addr(x) for x in out]
    print(f"pairs fetched {sum(1 for p in pairs if p)}/{n} in {time.time()-t:.0f}s", flush=True)

    def col(sel, addrs, label):
        calls = [("eth_call", [{"to": a, "data": sel}, hex(bn)]) for a in addrs]
        t0 = time.time()
        out = rpc_batch(calls)
        print(f"{label}: {sum(1 for x in out if x)}/{len(addrs)} in {time.time()-t0:.0f}s", flush=True)
        return out

    tok0 = [as_addr(x) for x in col(SEL_TOKEN0, pairs, "token0")]
    tok1 = [as_addr(x) for x in col(SEL_TOKEN1, pairs, "token1")]
    resv = col(SEL_RESERVES, pairs, "getReserves")
    lps = [as_int(x) for x in col(SEL_TOTALSUPPLY, pairs, "totalSupply")]
    facs = [as_addr(x) for x in col(SEL_FACTORY, pairs, "factory")]
    kl = [as_int(x) for x in col(SEL_KLAST, pairs, "kLast")]
    # balances of each pair in its tokens
    b0 = [as_int(x) for x in col(SEL_BALANCEOF + encode_addr(p), [tok0[i] if tok0[i] else "0x0000000000000000000000000000000000000000" for i, p in enumerate(pairs)], "bal0")]
    b1 = [as_int(x) for x in col(SEL_BALANCEOF + encode_addr(p), [tok1[i] if tok1[i] else "0x0000000000000000000000000000000000000000" for i, p in enumerate(pairs)], "bal1")]

    meta = {}
    for i, p in enumerate(pairs):
        r = resv[i]
        r0 = r1 = ts = None
        if r and len(r) >= 2 + 64 * 3:
            body = r[2:]
            r0 = int(body[0:64], 16); r1 = int(body[64:128], 16); ts = int(body[128:192], 16)
        meta[str(i)] = {
            "pair": p, "token0": tok0[i], "token1": tok1[i],
            "reserve0": r0, "reserve1": r1, "blockTimestampLast": ts,
            "lpTotalSupply": lps[i], "factory": facs[i], "kLast": kl[i],
            "bal0": b0[i], "bal1": b1[i],
        }

    tokens = sorted({m["token0"] for m in meta.values() if m["token0"]} | {m["token1"] for m in meta.values() if m["token1"]})
    print("unique tokens:", len(tokens), flush=True)
    tmeta = {}
    for start in range(0, len(tokens), 60):
        chunk = tokens[start:start + 60]
        calls = []
        for tk in chunk:
            calls.append(("eth_call", [{"to": tk, "data": SEL_SYMBOL}, hex(bn)]))
        calls += [("eth_call", [{"to": tk, "data": SEL_DECIMALS}, hex(bn)]) for tk in chunk]
        out = rpc_batch(calls)
        for j, tk in enumerate(chunk):
            tmeta[tk] = {"symbol": decode_string(out[j]), "decimals": as_int(out[len(chunk) + j])}
        print(f"token meta {min(start+60,len(tokens))}/{len(tokens)}", flush=True)

    doc = {"block": bn, "factory": FACTORY, "allPairsLength": n, "pairs": meta, "tokens": tmeta}
    with open(OUT, "w") as f:
        json.dump(doc, f, indent=1)
    print("wrote", OUT, flush=True)

    excess = []
    for i, m in meta.items():
        e0 = (m["bal0"] or 0) - (m["reserve0"] or 0)
        e1 = (m["bal1"] or 0) - (m["reserve1"] or 0)
        if e0 > 0 or e1 > 0:
            excess.append((i, m["pair"], e0, e1))
    print("pairs with excess balances:", len(excess), flush=True)
    for e in excess[:40]:
        print(e, flush=True)


if __name__ == "__main__":
    main()
