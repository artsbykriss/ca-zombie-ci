#!/usr/bin/env python3
"""Flash-loan extraction tests (preview only). Key question: can an unprivileged caller
take a flash loan and keep the funds (no repay)? And is the repay path sound?"""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
RESULTS = []


def fl_take_only(pool, res, amount, tag):
    """Take a flash loan, deposit the proceeds to the account, never repay."""
    m = f'''
CALL_METHOD
    Address("{pool}")
    "flash_loan"
    Address("{res}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res}")
    Bucket("loan")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit"
    Bucket("loan")
;
'''.strip()
    return run(m, tag)


def fl_take_repay(pool, res, amount, tag, extra=0):
    """Take a flash loan, repay the exact due amount (from the loan itself + extra funds)."""
    m = f'''
CALL_METHOD
    Address("{pool}")
    "flash_loan"
    Address("{res}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res}")
    Bucket("loan")
;
TAKE_ALL_FROM_WORKTOP
    Address("{fl_res_placeholder}")
    Bucket("terms")
;
{"".join([])}
'''.strip()
    return m


def main():
    tests = [
        # (tag, pool, resource, amount)
        ("fl_precision_oci_takeonly", "component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp",
         XRD, "100"),
        ("fl_poolv2_fusd_takeonly", "component_rdx1cpmacy5gwzswse56jprvlfhrpnt3mplswupu7qtq8pdz2hywy5uaqd",
         XRD, "100"),
        ("fl_flexpool_astrl_takeonly", "component_rdx1czrks23pt35cmapgt9amv6haxagpzds5pdqp6jxt97dm2azrtxvdch",
         XRD, "100"),
    ]
    only = sys.argv[1] if len(sys.argv) > 1 else None
    # 1) legacy BasicPool: does it even have flash_loan?
    r = run(f'''
CALL_METHOD
    Address("component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt")
    "flash_loan"
    Address("{XRD}")
    Decimal("1")
;
'''.strip(), "probe_legacy_basicpool_flash_loan")
    RESULTS.append(r)
    # 2) flash loan take-only tests
    for tag, pool, res, amt in tests:
        if only and only not in tag:
            continue
        RESULTS.append(fl_take_only(pool, res, amt, tag))
    # 3) flash loan take + repay exactly (need the NFT -> use repay_loan with the loan bucket)
    #    The terms bucket is an NFT bucket on the worktop; take it by its resource (flash address).
    fl = "resource_rdx1n2mpfjfmw44g5xygvvkm4809m7rj87repdcre3glqfksseza5zrc9h"  # OCI precision fl addr
    m = f'''
CALL_METHOD
    Address("component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp")
    "flash_loan"
    Address("{XRD}")
    Decimal("100")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("loan")
;
TAKE_ALL_FROM_WORKTOP
    Address("{fl}")
    Bucket("terms")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("dummy")
;
CALL_METHOD
    Address("component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp")
    "repay_loan"
    Bucket("loan")
    Bucket("terms")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("change")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit"
    Bucket("change")
;
'''.strip()
    if not only or "repay" in (only or ""):
        RESULTS.append(run(m, "fl_precision_oci_take_repay"))
    json.dump(RESULTS, open("flashloan_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
