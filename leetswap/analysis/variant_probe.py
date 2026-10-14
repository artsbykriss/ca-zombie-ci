#!/usr/bin/env python3
"""Discriminate contract variant per chain: UniV2 pair vs LeetSwapV2Pair (Solidly-style)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

SELS = {
    # LeetSwapV2Pair (Solidly) specific
    "stable()": "0x22be3de1",
    "fees()": "0x9af1d35a",
    "claimFees()": "0xeed3b5d4",
    "index0()": "0x8d8ea727",
    "claimable0(address)": "0x40a5737f",
    "_transferFeesSupportingTaxTokens(address,uint256)": "0xec7e683d",
    "getReserves()": "0x0902f1ac",
    "tradingFees(address,address)": "0x5cf73108",
    "protocolFeesShare()": "0xafda13e9",
    "protocolFeesRecipient()": "0x68930637",
    # UniV2 pair specific
    "kLast()": "0x7464fc3d",
    "MINIMUM_LIQUIDITY()": "0xba9a7a56",
    # factory specific
    "isPaused()": "0xb187bd26",
    "pauser()": "0x9fd0506d",
    "owner()": "0x8da5cb5b",
    "pairCodeHash()": "0xdc4c90d3",
}

JOBS = {
    "op_bnb": ["0xa2899c776baaf9925d432f83c950d5054a6cf59c",
               "0x3e5b8c9e1c98a457b68a4337897a8f6020725e18"],
    "manta": ["0xa2899c776baaf9925d432f83c950d5054a6cf59c",
              "0xf5f8a569483663e9f7227d16e4ec21de9e729f93"],
    "scroll": ["0xa2899c776baaf9925d432f83c950d5054a6cf59c",
               "0xb355bf1016184de795c786baa78d2cf5fb1165da"],
    "linea": ["0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c",
              "0x3bc53c353cb117d616c9e51811b2aa2a818c5db3"],
}

out = {}
for chain, addrs in JOBS.items():
    print("=" * 70, flush=True)
    print(chain, flush=True)
    res = {}
    for a in addrs:
        row = {}
        calls = [("eth_call", [{"to": a, "data": s}, "latest"]) for s in SELS.values()]
        try:
            rs = B.batch(chain, calls)
            for (name, sel), r in zip(SELS.items(), rs):
                if r is None or r == "0x":
                    row[name] = None
                else:
                    try:
                        row[name] = "0x" + B.words(r)[0][-40:] if len(B.words(r)) >= 1 and len(r) == 66 and name.endswith("(address)") else B.dec_uint(B.words(r)[0])
                    except Exception:
                        row[name] = r[:20]
            # code size
            row["code_size"] = len(B.code(chain, a) or "0x") // 2
        except Exception as e:
            row["err"] = str(e)[:150]
        res[a] = row
        present = [k for k, v in row.items() if v not in (None, 0) and not k.endswith("(address)")]
        print(a, "code_size", row.get("code_size"), flush=True)
        for k in SELS:
            if k in row and row[k] is not None:
                print("   ", k, "=", str(row[k])[:40], flush=True)
    out[chain] = res
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "variant-probe.json"), "w"), indent=1)
print("saved variant-probe.json")
