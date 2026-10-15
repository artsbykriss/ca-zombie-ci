#!/usr/bin/env python3
"""DefiPlaza extraction tests (Radix Gateway PREVIEW only; nothing submitted).

Paths: swap round-trips (DEX + direct pair), add/remove liquidity round-trips,
micro-swaps, direct-pair calls bypassing the DEX.
"""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
RESULTS = []
DFP2 = "resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq"
DEX = "component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68"
PAIR_XRD_DFP2 = "component_rdx1cppd8rq7gfwad75z56mz9tldqmw4aps48hqnx2stf4eeew8v6tyd72"
ASTRL = "resource_rdx1t4tjx4g3qzd98nayqxm7qdpj0a0u8ns6a0jrchq49dyfevgh6u0gj3"
PAIR_ASTRL_DFP2 = "component_rdx1cqvxkaazmpnvg3f9ufc5n2msv6x7ztjdusdm06lhtf5n7wr8guggg5"


def dex_roundtrip(amount, tag, token_out=DFP2):
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("in1")
;
CALL_METHOD
    Address("{DEX}")
    "swap"
    Bucket("in1")
    Address("{token_out}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{token_out}")
    Bucket("mid")
;
CALL_METHOD
    Address("{DEX}")
    "swap"
    Bucket("mid")
    Address("{XRD}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("back")
;
TAKE_ALL_FROM_WORKTOP
    Address("{token_out}")
    Bucket("leftover")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("back"), Bucket("leftover"))
;
'''.strip()
    return run(m, tag)


def pair_roundtrip(amount, tag):
    """direct pair.swap call (bypasses PlazaDex routing)"""
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("in1")
;
CALL_METHOD
    Address("{PAIR_XRD_DFP2}")
    "swap"
    Bucket("in1")
;
TAKE_ALL_FROM_WORKTOP
    Address("{DFP2}")
    Bucket("mid")
;
CALL_METHOD
    Address("{PAIR_XRD_DFP2}")
    "swap"
    Bucket("mid")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("back")
;
TAKE_ALL_FROM_WORKTOP
    Address("{DFP2}")
    Bucket("leftover")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("back"), Bucket("leftover"))
;
'''.strip()
    return run(m, tag)


def add_remove_liquidity(amount, tag, co=None):
    co_arg = "None" if co is None else f'Some(Bucket("co"))'
    pre = ""
    if co is not None:
        pre = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{co}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{co}")
    Bucket("co")
;
'''
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("x")
;
{pre}
CALL_METHOD
    Address("{DEX}")
    "add_liquidity"
    Bucket("x")
    {co_arg}
    None
;
'''.strip()
    # returns (lp_bucket, remainder) -> on worktop
    m += f'''
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xrest")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit"
    Bucket("xrest")
;
'''.strip()
    return run(m, tag)


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else "all"
    if only in ("all", "rt"):
        for amt in ("10", "100", "1000"):
            RESULTS.append(dex_roundtrip(amt, f"dp_dex_rt_xrd_dfp2_{amt}"))
        RESULTS.append(dex_roundtrip("10", "dp_dex_rt_xrd_astrl_10", token_out=ASTRL))
    if only in ("all", "pair"):
        RESULTS.append(pair_roundtrip("10", "dp_pair_rt_xrd_dfp2_10"))
    if only in ("all", "lp"):
        RESULTS.append(add_remove_liquidity("100", "dp_add_liquidity_xrd_100"))
    json.dump(RESULTS, open("defiplaza_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
