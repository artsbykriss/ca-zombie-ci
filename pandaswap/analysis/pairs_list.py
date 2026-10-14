#!/usr/bin/env python3
"""Fetch all pair addresses + probe specific pairs/tokens (robust, small call count)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, encode_uint, encode_addr, as_addr, as_int

FACTORY = "0x9ad32bf5dafe152cbe027398219611db4e8753b3"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pairs-list.json")

SPECIAL_PAIRS = [
    "0x059fc92273cdf0809ba45f199e0a12d8899ab402",  # PNDA/ETH (dex screener)
    "0xbe01056bc0e29eb28c9c357c227e320afd12776c",  # PNDA/USDC (dex screener)
    "0x60816ccec71161d69ee883f2be4522622d4a1cc9",  # PNDA-V2 pair per bscscan
]

SEL = {
    "token0": "0x0dfe1681", "token1": "0xd21220a7", "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd", "factory": "0xc45a0155", "kLast": "0x7464fc3d",
    "balanceOf": "0x70a08231", "symbol": "0x95d89b41", "decimals": "0x313ce567",
    "name": "0x06fdde03", "allPairsLength": "0x574f2ba3", "allPairs": "0x1e3dd18b",
    "owner": "0x8da5cb5b", "feeTo": "0x017e7e58", "feeToSetter": "0x094b7415",
    "pairCodeHash": "0x9aab9248",
}


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
    print("block:", bn, flush=True)
    out = rpc_batch([("eth_call", [{"to": FACTORY, "data": SEL["allPairsLength"]}, hex(bn)])])
    n = as_int(out[0]); print("n:", n, flush=True)
    out = rpc_batch([("eth_call", [{"to": FACTORY, "data": SEL["allPairs"] + encode_uint(i)}, hex(bn)]) for i in range(n)])
    pairs = [as_addr(x) for x in out]
    ok = sum(1 for p in pairs if p)
    print(f"pairs: {ok}/{n}", flush=True)

    # factory extras
    extra = rpc_batch([
        ("eth_call", [{"to": FACTORY, "data": SEL["feeTo"]}, hex(bn)]),
        ("eth_call", [{"to": FACTORY, "data": SEL["feeToSetter"]}, hex(bn)]),
        ("eth_call", [{"to": FACTORY, "data": SEL["pairCodeHash"]}, hex(bn)]),
        ("eth_getCode", [FACTORY, hex(bn)]),
    ])
    feeTo = as_addr(extra[0]); feeToSetter = as_addr(extra[1]); pch = extra[2]
    faccode = extra[3]
    print("feeTo:", feeTo, "feeToSetter:", feeToSetter, flush=True)
    print("pairCodeHash:", pch, flush=True)

    special = {}
    for p in SPECIAL_PAIRS:
        o = rpc_batch([
            ("eth_call", [{"to": p, "data": SEL["token0"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["token1"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["getReserves"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["totalSupply"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["factory"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["name"]}, hex(bn)]),
            ("eth_call", [{"to": p, "data": SEL["symbol"]}, hex(bn)]),
        ])
        t0 = as_addr(o[0]); t1 = as_addr(o[1])
        r = o[2]; r0 = r1 = ts = None
        if r and len(r) >= 2 + 192:
            r0 = int(r[2:66], 16); r1 = int(r[66:130], 16); ts = int(r[130:194], 16)
        special[p] = {
            "token0": t0, "token1": t1, "reserve0": r0, "reserve1": r1,
            "lpTotalSupply": as_int(o[3]), "factory": as_addr(o[4]),
            "name": decode_string(o[5]), "symbol": decode_string(o[6]),
        }
        print(p, special[p], flush=True)
        if t0 and t1:
            t = rpc_batch([
                ("eth_call", [{"to": t0, "data": SEL["symbol"]}, hex(bn)]),
                ("eth_call", [{"to": t0, "data": SEL["decimals"]}, hex(bn)]),
                ("eth_call", [{"to": t0, "data": SEL["totalSupply"]}, hex(bn)]),
                ("eth_call", [{"to": t1, "data": SEL["symbol"]}, hex(bn)]),
                ("eth_call", [{"to": t1, "data": SEL["decimals"]}, hex(bn)]),
                ("eth_call", [{"to": t1, "data": SEL["totalSupply"]}, hex(bn)]),
                ("eth_call", [{"to": t0, "data": SEL["balanceOf"] + encode_addr(p)}, hex(bn)]),
                ("eth_call", [{"to": t1, "data": SEL["balanceOf"] + encode_addr(p)}, hex(bn)]),
            ])
            special[p]["tok"] = {
                t0: {"symbol": decode_string(t[0]), "decimals": as_int(t[1]), "totalSupply": as_int(t[2])},
                t1: {"symbol": decode_string(t[3]), "decimals": as_int(t[4]), "totalSupply": as_int(t[5])},
            }
            special[p]["bal0"] = as_int(t[6]); special[p]["bal1"] = as_int(t[7])
            print("  tokens:", json.dumps(special[p]["tok"]), flush=True)

    doc = {"block": bn, "factory": FACTORY, "allPairsLength": n, "pairs": pairs,
           "feeTo": feeTo, "feeToSetter": feeToSetter, "pairCodeHash": pch,
           "factory_code_sha256": __import__("hashlib").sha256((faccode or "").encode()).hexdigest() if faccode else None,
           "special": special}
    with open(OUT, "w") as f:
        json.dump(doc, f, indent=1)
    print("wrote", OUT, flush=True)


if __name__ == "__main__":
    main()
