#!/usr/bin/env python3
"""Scan Aurora Ante factories for pools + balances + test status. Read-only."""
import sys, json
sys.path.insert(0, '/home/heisenberg/CA/bttc-viction-aurora/analysis')
from rpclib import *

SEL_ALLPOOLS = "0x41d1de97"   # allPools(uint256)
SEL_TEST = "0xe0b4fb92"       # checkTestPasses()
SEL_TOTAL_STAKE = "0x" # compute below if needed

def all_pools(factory, maxn=200):
    pools = []
    for i in range(maxn):
        data = SEL_ALLPOOLS + pad32(i)
        r = eth_call("aurora", factory, data)
        if r is None or r == "0x":
            break
        a = dec_addr(r)
        if a is None or int(a, 16) == 0:
            break
        pools.append(a)
    return pools

if __name__ == "__main__":
    bn = block_number("aurora")
    print("aurora block", bn)
    factories = {
        "0xb4FD0Ce108e196d0C9844c48174d4C32Cd42F7bC": "v0.5.2 (DefiLlama)",
    }
    out = {"block": bn, "factories": {}}
    for f, ver in factories.items():
        code = get_code("aurora", f)
        pools = all_pools(f)
        print(f, ver, "code", (code or "0x")[:20], "pools", len(pools))
        info = []
        for p in pools:
            bal = get_balance("aurora", p)
            code_p = get_code("aurora", p)
            # try checkTestPasses()
            try:
                t = eth_call("aurora", p, SEL_TEST)
                tp = dec_uint(t) if t and t != "0x" else None
            except Exception as e:
                tp = f"err:{e}"
            info.append({"pool": p, "eth_wei": str(bal), "eth": bal / 1e18, "code_len": len(code_p or "0x"), "testPasses": tp})
            print(p, bal / 1e18, "ETH", "testPasses=", tp)
        out["factories"][f] = {"version": ver, "pools": info}
    with open("/home/heisenberg/CA/bttc-viction-aurora/analysis/aurora_ante_pools.json", "w") as fh:
        json.dump(out, fh, indent=2)
