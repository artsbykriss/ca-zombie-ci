#!/usr/bin/env python3
"""Live-state snapshot for the Robinhood-Chain (4663) Morpho equity-oracle staleness finding.

Read-only. Keyless RPC. Writes JSON to stdout (ci/run.sh redirects it to ci-out/live-state.json).
"""
import json, urllib.request, os, sys

RPC = os.environ.get("RH_RPC_URL", "https://robinhood.drpc.org")
MORPHO = "0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010"
UA = {"content-type": "application/json",
      "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124 Safari/537.36"}

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read()).get("result")

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def word(hexstr, i):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return int(h[i * 64:(i + 1) * 64] or "0", 16)

SEL = {
    "price": "0xa035b1fe",          # price()
    "MAX_BASE_AGE": "0xe4955b3d",
    "MAX_QUOTE_AGE": "0x1b1043c8",
    "latestRoundData": "0xfeaf968c",
    "market": "0x5c60e39a",         # market(bytes32)
}

TARGETS = [
    ("AAPL",    "0xD625d488D552775D2867194C618B945E5dDfE097", "0x6B22A786bAa607d76728168703a39Ea9C99f2cD0", "0xdeb4782d012d5fd3b24962538c2f6559049d70bda4dabd2e4212dacb96c28d45"),
    ("NVDA",    "0xED29D310cfa91778A5850538DA28ed42234Cb78c", "0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15", "0x8b16891f032a93b771347c9cb470a780e6699dd701553d3402aa3cdba6189c3e"),
    ("SPCX",    "0x872F9D8955B34e841227a92dE755cd63042Ab7A5", "0xB265810950ba6c5C0Ff821c9963014a56fD8Bffb", "0x9b4b47cdf7e295341c6c6cdfd3efb9805c4a5b3d580dba0c0c39d3a4232b297b"),
    ("GOOGL",   "0x12Ec3474D1e321e0aAB065278B97FBC7eDa5F424", "0xF6f373a037c30F0e5010d854385cA89185AE638b", "0x7fa81b10e5d21b2e4c571f862442bc11aff2ed14f02335868d0ff933fd40d0ba"),
    ("NVDA_V2", "0xC5b8A6C5fDF14f9744dB1C8595f49E42Ce23031a", "0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15", "0x66306c087add8907752320b309934abcc354d21626de8115c79df49d9c214edc"),
]

def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    ts = int(rpc("eth_getBlockByNumber", [hex(blk), False])["timestamp"], 16)
    out = {"chain": 4663, "block": blk, "timestamp": ts, "oracles": []}
    for label, oracle, feed, mid in TARGETS:
        p = call(oracle, SEL["price"])
        mba = call(oracle, SEL["MAX_BASE_AGE"])
        mqa = call(oracle, SEL["MAX_QUOTE_AGE"])
        rd = call(feed, SEL["latestRoundData"])
        ans = word(rd, 1) if rd else None
        if ans is not None and ans >= 2**255:
            ans -= 2**256
        upd = word(rd, 3) if rd else None
        # market(bytes32) -> totalSupplyAssets, ..., totalBorrowAssets, ...
        mkt = call(MORPHO, SEL["market"] + mid[2:])
        sup = word(mkt, 0) if mkt else None
        bor = word(mkt, 2) if mkt else None
        out["oracles"].append({
            "label": label, "oracle": oracle, "feed": feed, "marketId": mid,
            "oracle_price_raw": int(p, 16) if p else None,
            "MAX_BASE_AGE": int(mba, 16) if mba else None,
            "MAX_QUOTE_AGE": int(mqa, 16) if mqa else None,
            "feed_answer": ans,
            "feed_updatedAt": upd,
            "feed_age_s": (ts - upd) if upd else None,
            "supply_assets": sup,
            "borrow_assets": bor,
            "free_liquidity": (sup - bor) if (sup is not None and bor is not None) else None,
        })
    json.dump(out, sys.stdout, indent=2)

if __name__ == "__main__":
    main()
