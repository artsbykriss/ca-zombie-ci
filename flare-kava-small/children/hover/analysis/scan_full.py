#!/usr/bin/env python3
"""Full-history log scan for Hover markets via evm.kava-rpc.com (big ranges OK)."""
import json, sys, urllib.request, time

RPC = "https://evm.kava-rpc.com"
MARKETS = {
    "hKAVA": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
    "hATOM": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
    "hUSDT": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
}
TOPICS = {
    "Borrow": "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80",
    "Mint": "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f",
    "Redeem": "0xbd5034ffbd47e4e72a94baa2cdb74c6fad73cb3bcdc13036b72ec8306f5a7646",
    "LiquidateBorrow": "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52",
    "Transfer": "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
    "AccrueInterest": "0x4dec04e750ca11537cabcd8a9eab06494de08da3735bc8871cd41250e190bc04",
}

def rpc(url, method, params, tries=5, timeout=120):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "result" in out: return out["result"]
            last = out.get("error")
        except Exception as e:
            last = e
        time.sleep(1.0*(i+1))
    raise RuntimeError(f"{method} failed: {last}")

def scan(addr, topic, lo, hi, span=1500000):
    out = []
    b = lo
    while b <= hi:
        top = min(b + span - 1, hi)
        res = rpc(RPC, "eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(top), "address": addr, "topics": [topic]}])
        out.extend(res)
        print(f"  {addr} {b}-{top}: +{len(res)} (total {len(out)})", flush=True)
        b = top + 1
    return out

if __name__ == "__main__":
    lo = int(sys.argv[1]) if len(sys.argv) > 1 else 7400000
    hi = int(rpc(RPC, "eth_blockNumber", []), 16)
    for mname, maddr in MARKETS.items():
        for ev, topic in TOPICS.items():
            if ev == "Transfer" and mname not in ("hUSDT",):
                continue  # Transfer only for hUSDT holders for now
            fn = f"logs_{mname}_{ev}.json"
            try:
                res = scan(maddr, topic, lo, hi)
                json.dump(res, open(fn, "w"))
                print(f"{mname} {ev}: {len(res)} events -> {fn}", flush=True)
            except Exception as e:
                print(f"{mname} {ev}: FAILED {e}", flush=True)
