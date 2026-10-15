#!/usr/bin/env python3
"""Probe liquidate() argument type expectations using literal-only manifests."""
import sys, json
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
        resp = preview(m, nonce=42)
        rc = resp.get("receipt", {})
        st = rc.get("status")
        err = str(rc.get("error_message"))
    except Exception as e:
        st, err = "HTTPERR", str(e)[:300]
    print("=" * 100)
    print(label, "->", st)
    print(err[:1000] if err != "None" else "SUCCESS/none")


try_args('    NonFungibleLocalId("#1015#")', "A: (NFid)")
try_args('    Decimal("1")', "B: (Decimal)")
try_args('    Array<Bucket>()', "C: (Array<Bucket>)")
try_args('    Map<Address, Decimal>()', "D: (Map)")
try_args('    Array<NonFungibleLocalId>(NonFungibleLocalId("#1015#"))', "E: (Array<NFid>)")
try_args('    Enum<0u8>()', "F: (Enum)")
try_args('    Bucket("x")', "G: (Bucket-ref)")
try_args('    Address("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")', "H: (Address)")

# two-arg guesses
try_args('    NonFungibleLocalId("#1015#")\n    Array<Bucket>()', "I: (NFid, Array<Bucket>)")
try_args('    NonFungibleLocalId("#1015#")\n    Map<Address, Decimal>()', "J: (NFid, Map)")
