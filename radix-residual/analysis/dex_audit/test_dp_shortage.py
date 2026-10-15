#!/usr/bin/env python3
"""DefiPlaza: add-liquidity value-conservation test for BOTH sides of a pair in shortage.

The live XRD/DFP2 pair (older PlazaPair package 1p4lnurh, 135 pairs) is in QuoteShortage,
so adding DFP2 exercises the "in shortage + co-liquidity" code path (audit H01 area) while
adding XRD exercises the simple path. We add and immediately redeem in the SAME tx and
compare value in/out. Preview only."""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
R = []
DFP2 = "resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq"
DEX = "component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68"
LP_A = "resource_rdx1tknxlx2sy23qkg6twvnu3kqcd5l4daacq0n6mdam54upqgx50f4ju8"  # base pool LP
LP_B = "resource_rdx1t4a5clnxmnctmezaty08cuugfzmj2lezqcjk2szezrfdfl4w4ederu"  # quote pool LP


def add_remove(token, co_token, amt, co_amt, lp, tag):
    """token=DFP2 -> base_token must be Some(XRD)."""
    base_opt = f'Some(Address("{XRD}"))' if token == DFP2 else "None"
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{token}")
    Decimal("{amt}")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{co_token}")
    Decimal("{co_amt}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{token}")
    Bucket("t")
;
TAKE_ALL_FROM_WORKTOP
    Address("{co_token}")
    Bucket("co")
;
CALL_METHOD
    Address("{DEX}")
    "add_liquidity"
    Bucket("t")
    Some(Bucket("co"))
    {base_opt}
;
TAKE_ALL_FROM_WORKTOP
    Address("{lp}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{token}")
    Bucket("trest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{co_token}")
    Bucket("corest")
;
CALL_METHOD
    Address("{DEX}")
    "remove_liquidity"
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xout")
;
TAKE_ALL_FROM_WORKTOP
    Address("{DFP2}")
    Bucket("dout")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("trest"), Bucket("corest"), Bucket("xout"), Bucket("dout"))
;
'''.strip()
    return run(m, tag)


def main():
    # XRD side (non-shortage): 100 XRD, no co-liquidity needed (empty bucket)
    R.append(add_remove(XRD, XRD, "100", "0", LP_A, "dp_add_XRD_nonshortage"))
    # DFP2 side (shortage): 100 DFP2 with XRD co-liquidity
    R.append(add_remove(DFP2, XRD, "100", "60", LP_B, "dp_add_DFP2_shortage"))
    # DFP2 side without co-liquidity (should revert if shortage really requires it)
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{DFP2}")
    Decimal("100")
;
TAKE_ALL_FROM_WORKTOP
    Address("{DFP2}")
    Bucket("t")
;
CALL_METHOD
    Address("{DEX}")
    "add_liquidity"
    Bucket("t")
    None
    Some(Address("{XRD}"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{DFP2}")
    Bucket("trest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{LP_B}")
    Bucket("lp")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("trest"), Bucket("lp"))
;
'''.strip()
    R.append(run(m, "dp_add_DFP2_shortage_no_coliq"))
    json.dump(R, open("dp_shortage_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
