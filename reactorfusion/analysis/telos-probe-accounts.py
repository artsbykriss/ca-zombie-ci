#!/usr/bin/env python3
"""Sharded per-account probe for ReactorFusion Telos.
Usage: telos-probe-accounts.py <shard> <nshards>
Reads account list = holders + candidate debtors, probes:
getAssetsIn, getAccountLiquidity, getAccountSnapshot x4.
Writes telos-accountprobe-shard<shard>.json. Read-only, no secrets."""
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

def main():
    shard = int(sys.argv[1]); nsh = int(sys.argv[2])
    holders = json.load(open(os.path.join(OUT, "telos-holders.json")))
    cands = json.load(open(os.path.join(OUT, "telos-debtor-candidates.json")))
    accts = sorted(set(a.lower() for a in holders.get("_all_holders", [])) | set(a.lower() for a in cands.keys()))
    my = [a for i, a in enumerate(accts) if i % nsh == shard]
    print(f"shard {shard}/{nsh}: {len(my)} accounts of {len(accts)}", flush=True)

    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    print("block", block, flush=True)

    items, keys = [], []
    def add(to, sig, types, vals, otypes, key):
        items.append((to, calldata(sig, types, vals)))
        keys.append((key, otypes))
    for a in my:
        add(C, "getAssetsIn(address)", ["address"], [a], ["address[]"], f"{a}|assetsIn")
        add(C, "getAccountLiquidity(address)", ["address"], [a], ["uint256", "uint256", "uint256"], f"{a}|liquidity")
        for name, m in MARKETS.items():
            add(m, "getAccountSnapshot(address)", ["address"], [a], ["uint256", "uint256", "uint256", "uint256"], f"{a}|snap|{name}")

    raw = {}
    t0 = time.time()
    for i in range(0, len(items), 60):
        res = rpc.try_calls(items[i:i+60], block="latest")
        for (key, otypes), (r, err) in zip(keys[i:i+60], res):
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
        print(f"  {min(i+60, len(items))}/{len(items)} ({time.time()-t0:.0f}s)", flush=True)
        with open(os.path.join(OUT, f"telos-accountprobe-shard{shard}.json"), "w") as f:
            json.dump({"block": block, "accounts": my, "data": raw}, f, indent=1)
    print("done", time.time() - t0, flush=True)

if __name__ == "__main__":
    main()
