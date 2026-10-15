#!/usr/bin/env python3
"""Liquidity add/remove round-trip + share-inflation tests on live Ociswap pools (preview only).

Paths tested:
  1. BasicPool legacy (native TwoResourcePool): add both sides, then immediately remove all LP
     -> does the caller get back more than deposited?
  2. Donation test: can a fresh account add liquidity in a skewed ratio and redeem more value?
  3. PrecisionPool: add_liquidity -> remove_liquidity immediately (same tx).
  4. PrecisionPool claim_fees with a freshly minted position.
"""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
RESULTS = []

# legacy BasicPool (DFP2/XRD), native pool + lp
BP = "component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt"
BPX = "resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq"
BPLP = "resource_rdx1th68g9hn0u6u29uv6pqm8qjnd7luhn3nk9x436vvwzdu9vcwqndc2c"
BPNAT = "pool_rdx1ckdf4tq62lznn5c3zlkx7paxjth7g2d0ryqhexxzq0yrufmev096nd"

# PrecisionPool OCI/XRD
PP = "component_rdx1crm530ath85gc4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp"  # placeholder (overwritten below)


def add_remove_basic(xamt, yamt, tag):
    """deposit x+y into legacy BasicPool then remove ALL LP in the same tx."""
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{BPX}")
    Decimal("{xamt}")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{yamt}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{BPX}")
    Bucket("x")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("y")
;
CALL_METHOD
    Address("{BP}")
    "add_liquidity"
    Bucket("x")
    Bucket("y")
;
TAKE_ALL_FROM_WORKTOP
    Address("{BPLP}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{BPX}")
    Bucket("xrest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yrest")
;
CALL_METHOD
    Address("{BP}")
    "remove_liquidity"
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{BPX}")
    Bucket("xout")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yout")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("xrest"), Bucket("yrest"), Bucket("xout"), Bucket("yout"))
;
'''.strip()
    return run(m, tag)


def add_remove_precision(pool, xres, xamt, yamt, left, right, tag):
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{xres}")
    Decimal("{xamt}")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{yamt}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{xres}")
    Bucket("x")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("y")
;
CALL_METHOD
    Address("{pool}")
    "add_liquidity"
    {left}i32
    {right}i32
    Bucket("x")
    Bucket("y")
;
TAKE_ALL_FROM_WORKTOP
    Address("{xres}")
    Bucket("xrest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yrest")
;
'''.strip()
    # the LP NFT bucket is on the worktop; find its resource by calling add then removing all NFTs
    m += f'''
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("xrest"), Bucket("yrest"))
;
'''.strip()
    return run(m, tag)


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else "basic"
    if only in ("basic", "all"):
        RESULTS.append(add_remove_basic("1", "1.5", "basic_dfp2_addremove_1_1.5"))
        RESULTS.append(add_remove_basic("0.000000000000000001", "0.000000000000000001",
                                        "basic_dfp2_addremove_dust"))
    json.dump(RESULTS, open("addremove_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
