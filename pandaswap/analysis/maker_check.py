#!/usr/bin/env python3
"""Check feeTo (BambooMaker) holdings: LP token balances across all pairs + PNDA/other."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, encode_addr, as_addr, as_int

HERE = os.path.dirname(os.path.abspath(__file__))
FEE_TO = "0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07"
PNDA = "0x47dcc83a14ad53ed1f13d3cae8aa4115f07557c0"
BAR = "0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2"
SEL_BAL = "0x70a08231"


def paced(calls, label, batch=20, retries=10, pause=0.7):
    results = [None] * len(calls)
    pending = list(range(len(calls)))
    attempt = 0
    while pending and attempt < retries:
        chunk = pending[:batch]
        rest = pending[batch:]
        out = rpc_batch([calls[i] for i in chunk], retries=3, batch=batch)
        for j, i in enumerate(chunk):
            if out[j] is not None:
                results[i] = out[j]
        pending = [i for i in chunk if results[i] is None] + rest
        attempt += 1
        print(f"  [{label}] {len(pending)} pending", flush=True)
        if pending:
            time.sleep(pause * attempt)
    return results


def main():
    d = json.load(open(os.path.join(HERE, "all-pairs.json")))
    bn = d["block"]
    pairs = [p for p, v in d["pairs"].items() if v.get("token0")]
    print("block", bn, "pairs", len(pairs), flush=True)
    calls = [("eth_call", [{"to": p, "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]) for p in pairs]
    out = paced(calls, "makerLP")
    holdings = []
    for j, p in enumerate(pairs):
        b = as_int(out[j])
        if b:
            v = d["pairs"][p]
            t0 = d["tokens"].get(v["token0"], {}); t1 = d["tokens"].get(v["token1"], {})
            holdings.append({"pair": p, "sym0": t0.get("symbol"), "sym1": t1.get("symbol"),
                             "makerLP": b, "lpTotalSupply": v.get("lpTotalSupply"),
                             "reserve0": v.get("reserve0"), "reserve1": v.get("reserve1")})
    # maker's PNDA + WBNB + a few token balances
    extra = rpc_batch([
        ("eth_call", [{"to": PNDA, "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]),
        ("eth_call", [{"to": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]),
        ("eth_call", [{"to": BAR, "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]),
        ("eth_getBalance", [FEE_TO, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL_BAL + encode_addr(BAR)}, hex(bn)]),
        ("eth_call", [{"to": "0x2170ed0880ac9a755fd29b2688956bd959f933f8", "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]),
        ("eth_call", [{"to": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", "data": SEL_BAL + encode_addr(FEE_TO)}, hex(bn)]),
    ])
    res = {"block": bn, "feeTo": FEE_TO, "maker_lp_holdings": holdings,
           "maker_pnda": as_int(extra[0]), "maker_wbnb": as_int(extra[1]), "maker_bar_shares": as_int(extra[2]),
           "maker_bnb": as_int(extra[3]), "bar_pnda": as_int(extra[4]),
           "maker_eth": as_int(extra[5]), "maker_usdc": as_int(extra[6])}
    json.dump(res, open(os.path.join(HERE, "maker.json"), "w"), indent=1)
    print("maker LP holdings:", len(holdings), flush=True)
    for h in holdings:
        print(json.dumps(h), flush=True)
    print("maker PNDA:", res["maker_pnda"], "WBNB:", res["maker_wbnb"], "BNB:", res["maker_bnb"],
          "bar shares:", res["maker_bar_shares"], "ETH:", res["maker_eth"], "USDC:", res["maker_usdc"], flush=True)


if __name__ == "__main__":
    main()
