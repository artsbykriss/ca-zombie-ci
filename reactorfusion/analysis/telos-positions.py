#!/usr/bin/env python3
"""Read live account positions on the 4 ReactorFusion Telos markets.
For each account (holders + borrowers): getAssetsIn, getAccountLiquidity,
getAccountSnapshot x4 markets. Read-only, no secrets.
Writes telos-positions-raw.json (plus market/oracle snapshot)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

OUT = os.path.dirname(os.path.abspath(__file__))
C = "0x19646a04bfdcf3553adc8faaf8b16d76ec41e494"
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}
ORACLE = "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2"


def main():
    holders = json.load(open(os.path.join(OUT, "telos-holders.json")))
    bfile = os.path.join(OUT, "telos-borrowers.json")
    borrowers = []
    if os.path.exists(bfile):
        borrowers = json.load(open(bfile)).get("borrowers", [])
    accts = sorted(set(a.lower() for a in holders.get("_all_holders", [])) | set(a.lower() for a in borrowers))
    print("accounts:", len(accts), "holders:", len(holders.get("_all_holders", [])), "borrowers:", len(borrowers), flush=True)

    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    print("block", block, flush=True)

    items, keys = [], []
    def add(to, sig, types, vals, otypes, key):
        items.append((to, calldata(sig, types, vals)))
        keys.append((key, otypes))

    # market/oracle snapshot
    for name, m in MARKETS.items():
        add(C, "markets(address)", ["address"], [m], ["bool", "uint256"], f"market|{name}")
        add(ORACLE, "getUnderlyingPrice(address)", ["address"], [m], ["uint256"], f"price|{name}")
    add(C, "closeFactorMantissa()", (), (), ["uint256"], "closeFactor")
    add(C, "liquidationIncentiveMantissa()", (), (), ["uint256"], "liqIncentive")
    add(C, "getAllMarkets()", (), (), ["address[]"], "allMarkets")

    # per-account calls
    for a in accts:
        add(C, "getAssetsIn(address)", ["address"], [a], ["address[]"], f"{a}|assetsIn")
        add(C, "getAccountLiquidity(address)", ["address"], [a], ["uint256", "uint256", "uint256"], f"{a}|liquidity")
        for name, m in MARKETS.items():
            add(m, "getAccountSnapshot(address)", ["address"], [a], ["uint256", "uint256", "uint256", "uint256"], f"{a}|snap|{name}")

    print("total calls:", len(items), "batches:", len(items) // 3 + 1, flush=True)

    # run in slices so partial results are saved
    raw = {}
    t0 = time.time()
    slice_size = 240
    for i in range(0, len(items), slice_size):
        sl_items = items[i:i + slice_size]
        sl_keys = keys[i:i + slice_size]
        res = rpc.try_calls(sl_items, block="latest")
        for (key, otypes), (r, err) in zip(sl_keys, res):
            v = None
            if r is not None:
                try:
                    v = list(dec(otypes, r)) if len(otypes) > 1 else dec(otypes, r)[0]
                    if isinstance(v, bytes):
                        v = "0x" + v.hex()
                except Exception as e:
                    v = f"decode_err {e}"
                    err = err or str(e)[:120]
            raw[key] = {"v": v, "err": err}
        print(f"slice {i//slice_size}: done {min(i+slice_size, len(items))}/{len(items)} ({time.time()-t0:.0f}s)", flush=True)
        with open(os.path.join(OUT, "telos-positions-raw.json"), "w") as f:
            json.dump({"block": block, "n_accounts": len(accts), "accounts": accts, "data": raw}, f, indent=1)

    print("done", time.time() - t0, flush=True)


if __name__ == "__main__":
    main()
