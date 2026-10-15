#!/usr/bin/env python3
"""Probe liquidate 3-arg field types."""
import sys, json, re
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"


def try_args(args_block, label):
    m = f"""CALL_METHOD
    Address("{MARKET}")
    "liquidate"
{args_block}
;
"""
    try:
        resp = preview(m, nonce=43)
        rc = resp.get("receipt", {})
        st = rc.get("status")
        err = str(rc.get("error_message"))
    except Exception as e:
        st, err = "HTTPERR", str(e)[:400]
    # extract cause
    mm = re.search(r'cause: (.*?)\}\)\]', err)
    cause = mm.group(1) if mm else err[:300]
    print("-" * 100)
    print(label, "->", st, "|", cause[:400] if st != "Succeeded" else "SUCCESS!")


NF = 'NonFungibleLocalId("#1015#")'
try_args(f'    {NF}\n    Decimal("1")\n    Decimal("1")', "F0=NFid,1,1")
try_args(f'    {NF}\n    Map<Address, Decimal>()\n    Decimal("1")', "F0=NFid,Map,1")
try_args(f'    {NF}\n    Array<Bucket>()\n    Decimal("1")', "F0=NFid,ArrB,1")
try_args(f'    {NF}\n    Decimal("1")\n    Map<Address, Decimal>()', "F0=NFid,1,Map")
try_args(f'    {NF}\n    Decimal("1")\n    Array<Bucket>()', "F0=NFid,1,ArrB")
try_args(f'    Decimal("1")\n    Decimal("1")\n    Decimal("1")', "all Dec")
try_args(f'    Address("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")\n    Decimal("1")\n    Decimal("1")', "F0=Address,1,1")
try_args(f'    Array<Bucket>()\n    Decimal("1")\n    Decimal("1")', "F0=ArrB,1,1")
try_args(f'    Map<Address, Decimal>()\n    Decimal("1")\n    Decimal("1")', "F0=Map,1,1")
