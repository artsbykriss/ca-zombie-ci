#!/usr/bin/env python3
"""Probe 1: oracle mechanism identification on Telos (DIA vs Redstone).
Read-only. No secrets."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

ORACLE = "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2"
OLD_ORACLE = "0x3b7023f3"  # truncated from research; skip if unknown
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}

def main():
    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    print("block", block)
    out = {"block": block}

    items, keys = [], []
    def add(to, sig, types, vals, otypes, key):
        items.append((to, calldata(sig, types, vals)))
        keys.append((key, otypes))

    # oracle probes
    add(ORACLE, "dia()", (), (), ["address"], "oracle.dia()")
    add(ORACLE, "owner()", (), (), ["address"], "oracle.owner()")
    add(ORACLE, "isPriceOracle()", (), (), ["bool"], "oracle.isPriceOracle()")
    for name, m in MARKETS.items():
        add(ORACLE, "assetsKeys(address)", ["address"], [m], ["string"], f"assetsKeys.{name}")
        add(ORACLE, "getUnderlyingPrice(address)", ["address"], [m], ["uint256"], f"price.{name}")
        add(ORACLE, "rawPrices(bytes32)", ["bytes32"], [b"\x00"*32], ["uint256"], f"rawPrices0.{name}")
        add(m, "decimals()", (), (), ["uint8"], f"decimals.{name}")
        add(m, "symbol()", (), (), ["string"], f"symbol.{name}")
        add(m, "redStoneFeedID()", (), (), ["bytes32"], f"redstoneFeedID.{name}")
    res = rpc.try_calls(items, block=hex(block))
    for (key, otypes), (raw, err) in zip(keys, res):
        v = None
        if raw is not None:
            try:
                if len(otypes) == 1:
                    v = dec(otypes, raw)[0]
                    if isinstance(v, bytes):
                        v = "0x" + v.hex()
                else:
                    v = list(dec(otypes, raw))
            except Exception as e:
                v = f"decode_err {e} raw={raw[:80]}"
        out[key] = {"v": v, "err": err}
        print(f"{key:28s} = {v!r}  err={err}")
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-probe1.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
