#!/usr/bin/env python3
"""Probe whether the vulnerable public _transferFeesSupportingTaxTokens exists on live pairs.

Read-only: eth_call simulation only (no tx). With amount=0 the function returns 0
immediately if present; if absent the pair reverts (no fallback).
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

SEL_TF = "0xec7e683d"      # _transferFeesSupportingTaxTokens(address,uint256)
SEL_PAUSED = "0xb187bd26"  # isPaused()
SEL_FEES = "0x9af1d35a"    # fees()
SEL_TFEE = "0x5cf73108"    # tradingFees(address,address)
SEL_PFS = "0xafda13e9"     # protocolFeesShare()
SEL_PFR = "0x68930637"     # protocolFeesRecipient()
SEL_RESERVES = "0x0902f1ac"
SEL_TOTALSUPPLY = "0x18160ddd"
SEL_BAL = "0x70a08231"
SEL_TOKEN0 = "0x0dfe1681"
SEL_TOKEN1 = "0xd21220a7"
SEL_STABLE = "0x22be3de1"  # stable()
SEL_PAIRCODEHASH = "0xdc4c90d3"  # pairCodeHash()
SEL_ALLPAIRS = "0x1e3dd18b"
SEL_ALLPAIRSLEN = "0x574f2ba3"

JOBS = {
    "op_bnb": {"factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
               "pairs": ["0x3e5b8c9e1c98a457b68a4337897a8f6020725e18",
                         "0xf9e34e8dae9767df2a7f99713ea3c5c20b149adb",
                         "0x18d4b3a71bda8758c56b5dcc1874915b16b9df20"]},
    "manta": {"factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
              "pairs": ["0xf5f8a569483663e9f7227d16e4ec21de9e729f93",
                        "0xfedd2f73e128fc52ee717ed666bef9bedbf57d22",
                        "0xead80cbf96cff47f8f12672885a9b901b5623b5e"]},
    "linea": {"factory": "0x4DDf0fa98B5f9Bd7Cb0645c25bA89A574fe9Be8c",
              "pairs": ["0x3bc53c353cb117d616c9e51811b2aa2a818c5db3",
                        "0x86094dc0ea554443dec8707d1b420c551cb0f756",
                        "0x26fe275cffef3a037d04494ad55d7c6744fbb8fd"]},
    "scroll": {"factory": "0xa2899c776baaf9925d432f83c950d5054a6cf59c",
               "pairs": ["0xb355bf1016184de795c786baa78d2cf5fb1165da",
                         "0x3c56643cbdee012310c1db570f35680870f0a11a"]},
    "shibarium": {"factory": "0xd3Ea3BC1F5A3F881bD6cE9761cbA5A0833a5d737",
                  "pairs": ["0xdd12d8f1f05e534957e85d8d44364c50f7556251",
                            "0x9bad3adc8ef464a9ec2d90526085e065167c8571"]},
    "polygon_zkevm": {"factory": "0xcE87E0960f4e2702f4bFFE277655E993Ae720e84",
                      "pairs": ["0xc6e70676eaeac6ef0c51cc618fc71a717d68b572",
                                "0xecaff93978d70c6513cda3a6009e0ceaf5c39e4a"]},
    "base": {"factory": "0x169C06b4cfB09bFD73A81e6f2Bb1eB514D75bB19",
             "pairs": ["0xef849707a01fff93a7b4b398307b8cd839f6a57b",
                       "0xc6ac0110084f6ca058bfaa741aa68be5189a8ca4"]},
}

NULL = "0x" + "0" * 64
out = {}
for chain, j in JOBS.items():
    print("=" * 70, flush=True)
    print(chain, flush=True)
    res = {"factory": j["factory"], "pairs": {}}
    try:
        blk = B.block_number(chain)
        res["block"] = blk
        print("block", blk, flush=True)
    except Exception as e:
        print("BLOCK FAIL", str(e)[:100], flush=True)
        out[chain] = {"error": str(e)[:200]}
        continue
    f = j["factory"]
    # factory reads in one batch
    calls = [("eth_call", [{"to": f, "data": SEL_PAUSED}, "latest"]),
             ("eth_call", [{"to": f, "data": SEL_ALLPAIRSLEN}, "latest"]),
             ("eth_call", [{"to": f, "data": SEL_PFS}, "latest"]),
             ("eth_call", [{"to": f, "data": SEL_PFR}, "latest"]),
             ("eth_call", [{"to": f, "data": SEL_PAIRCODEHASH}, "latest"])]
    try:
        r = B.batch(chain, calls)
        res["factory_isPaused"] = None if r[0] is None else bool(B.dec_uint(B.words(r[0])[0]))
        res["factory_allPairsLength"] = None if r[1] is None else B.dec_uint(B.words(r[1])[0])
        res["protocolFeesShare"] = None if r[2] is None else B.dec_uint(B.words(r[2])[0])
        res["protocolFeesRecipient"] = None if r[3] is None else B.dec_addr(B.words(r[3])[0])
        res["pairCodeHash"] = r[4]
        print("factory isPaused:", res["factory_isPaused"], "allPairs:", res["factory_allPairsLength"],
              "pfs:", res["protocolFeesShare"], "pfr:", res["protocolFeesRecipient"], flush=True)
    except Exception as e:
        print("factory batch fail", str(e)[:100], flush=True)

    for p in j["pairs"]:
        row = {"pair": p}
        try:
            t0r = B.batch(chain, [("eth_call", [{"to": p, "data": SEL_TOKEN0}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_TOKEN1}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_STABLE}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_FEES}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_RESERVES}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_TOTALSUPPLY}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_TF + B.pad_addr("0x0000000000000000000000000000000000000001") + B.pad_uint(0)}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_TFEE + B.pad_addr(p) + B.pad_addr("0x0000000000000000000000000000000000000001")}, "latest"]),
                                  ("eth_call", [{"to": p, "data": SEL_PAUSED}, "latest"]),
                                  ])
            row["token0"] = B.dec_addr(B.words(t0r[0])[0]) if t0r[0] else None
            row["token1"] = B.dec_addr(B.words(t0r[1])[0]) if t0r[1] else None
            row["stable"] = bool(B.dec_uint(B.words(t0r[2])[0])) if t0r[2] else None
            row["fees"] = B.dec_addr(B.words(t0r[3])[0]) if t0r[3] else None
            if t0r[4]:
                ws = B.words(t0r[4])
                row["reserve0"], row["reserve1"] = B.dec_uint(ws[0]), B.dec_uint(ws[1])
            if t0r[5]:
                row["lp_totalSupply"] = B.dec_uint(B.words(t0r[5])[0])
            row["transferFees_probe"] = ("OK:" + t0r[6][:66]) if t0r[6] is not None else "REVERT/ABSENT"
            row["tradingFees"] = B.dec_uint(B.words(t0r[7])[0]) if t0r[7] else None
            row["pair_isPaused_probe"] = ("OK:" + str(B.dec_uint(B.words(t0r[8])[0]))) if t0r[8] else "ABSENT"
            # balances
            if row.get("token0"):
                bals = B.batch(chain, [
                    ("eth_call", [{"to": row["token0"], "data": SEL_BAL + B.pad_addr(p)}, "latest"]),
                    ("eth_call", [{"to": row["token1"], "data": SEL_BAL + B.pad_addr(p)}, "latest"]),
                ])
                row["balance0"] = B.dec_uint(B.words(bals[0])[0]) if bals[0] else None
                row["balance1"] = B.dec_uint(B.words(bals[1])[0]) if bals[1] else None
                if row.get("reserve0") is not None:
                    row["excess0"] = (row["balance0"] or 0) - row["reserve0"]
                    row["excess1"] = (row["balance1"] or 0) - row["reserve1"]
            print(json.dumps(row)[:400], flush=True)
        except Exception as e:
            row["err"] = str(e)[:150]
            print("pair fail", p, str(e)[:120], flush=True)
        res["pairs"][p] = row
    out[chain] = res

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "probe-vuln.json"), "w"), indent=1)
print("saved probe-vuln.json", flush=True)
