#!/usr/bin/env python3
"""Probe 2: DIA oracle internals + oracle-switch timeline + Redstone oracle check.
Read-only. No secrets."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import RPC, default_urls, calldata, dec

DIA = "0x86c5997d10d1df6cbb15c01280e596ed5ac90a33"
ORACLE_DIA = "0x0fa9de8362e662d6659a05ad284a2f454f49a8e2"
ORACLE_RS = "0x3b7023f3c99eae2fa0aaeb9490a78d5d98a24148"
KEYS = ["USDC/USD", "USDT/USD", "ETH/USD", "TLOS/USD"]

def main():
    rpc = RPC(default_urls("telos"), "telos")
    block = rpc.block_number()
    print("block", block)
    out = {"block": block}

    items, keys = [], []
    def add(to, sig, types, vals, otypes, key):
        items.append((to, calldata(sig, types, vals)))
        keys.append((key, otypes))

    add(DIA, "oracleUpdater()", (), (), ["address"], "dia.oracleUpdater")
    for k in KEYS:
        add(DIA, "getValue(string)", ["string"], [k], ["uint128", "uint128"], f"dia.getValue[{k}]")
        add(DIA, "values(string)", ["string"], [k], ["uint256"], f"dia.values[{k}]")
    # oracle impl config
    add(ORACLE_DIA, "owner()", (), (), ["address"], "oracle.owner")
    add(ORACLE_DIA, "dia()", (), (), ["address"], "oracle.dia")
    # old redstone oracle: check push signature & state
    add(ORACLE_RS, "getDataServiceId()", (), (), ["string"], "rs.getDataServiceId")
    add(ORACLE_RS, "getUniqueSignersThreshold()", (), (), ["uint8"], "rs.threshold")
    add(ORACLE_RS, "rawPrices(bytes32)", ["bytes32"], [b"TLOS"], ["uint256"], "rs.rawPrices[TLOS]")

    res = rpc.try_calls(items, block=hex(block))
    for (key, otypes), (raw, err) in zip(keys, res):
        v = None
        if raw is not None:
            try:
                v = list(dec(otypes, raw)) if len(otypes) > 1 else dec(otypes, raw)[0]
                if isinstance(v, bytes):
                    v = "0x" + v.hex()
            except Exception as e:
                v = f"decode_err {e} raw={raw[:80]}"
        out[key] = {"v": v, "err": err}
        print(f"{key:30s} = {v!r}  err={err}")

    # block timestamps for oracle switch events
    for label, bhex in [("oracle0->RS", "0x12b607d9"), ("RS->DIA", "0x171b5cb3"), ("head", hex(block))]:
        r, e = rpc.call_ret("eth_getBlockByNumber", [bhex, False])
        if r:
            out[f"blocktime.{label}"] = {"block": int(bhex, 16), "ts": int(r["timestamp"], 16)}
            print(label, int(bhex, 16), int(r["timestamp"], 16))
        else:
            print(label, "ERR", e)

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "telos-probe2.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
