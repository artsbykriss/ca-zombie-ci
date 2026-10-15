#!/usr/bin/env python3
"""Pair reserves + bridge state + misc live values (threaded)."""
import json
import rpcmulti as R

HZN_BNB = "0xdc9a574b9b341d4a98ce29005b614e1e27430e74"
ZUSD_BUSD = "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf"
BRIDGE = "0x4ceb5c49d7e8ad212f19b8e5ea4a5f48c01630fb"
SNX = "0x0110bcbeb89a43ec47e62d1980e29e0683745ffc"
FEED = "0x95a49608f30e8e7ac4adc5565a206e2b874b9763"  # ExchangeRates
A = {}

def call(tag, to, data):
    A[tag] = R.call(to, data)

def main():
    jobs = []
    def add(fn):
        jobs.append(fn)
    add(lambda: call("HZNBNB.reserves", HZN_BNB, "0x0902f1ac"))
    add(lambda: call("HZNBNB.token0", HZN_BNB, "0x0dfe1681"))
    add(lambda: call("HZNBNB.token1", HZN_BNB, "0x0dfe1681"))
    add(lambda: call("HZNBNB.totalSupply", HZN_BNB, "0x18160ddd"))
    add(lambda: call("ZUSDBUSD.reserves", ZUSD_BUSD, "0x0902f1ac"))
    add(lambda: call("ZUSDBUSD.token0", ZUSD_BUSD, "0x0dfe1681"))
    add(lambda: call("ZUSDBUSD.token1", ZUSD_BUSD, "0x0dfe1681"))
    add(lambda: call("ZUSDBUSD.totalSupply", ZUSD_BUSD, "0x18160ddd"))
    add(lambda: call("BRIDGE.initiationActive", BRIDGE, "0x100be6d4"))
    add(lambda: call("SNX.bal_self", SNX, "0x70a08231" + SNX[2:].rjust(64, "0")))
    R.multi(jobs, workers=6)
    # token1 for pairs needs a second call; do separately
    t0 = R.call(HZN_BNB, "0x0dfe1681")
    t1 = R.call(HZN_BNB, "0xd21220a7")
    z0 = R.call(ZUSD_BUSD, "0x0dfe1681")
    z1 = R.call(ZUSD_BUSD, "0xd21220a7")
    A["HZNBNB.token1"] = t1
    A["ZUSDBUSD.token1"] = z1
    json.dump(A, open("pairs-state.json", "w"), indent=1, sort_keys=True)
    for k, v in A.items():
        print(k, "=", v)

if __name__ == "__main__":
    main()
