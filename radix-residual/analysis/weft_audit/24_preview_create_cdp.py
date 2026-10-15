#!/usr/bin/env python3
"""Preview: open a CDP with XRD collateral (create_cdp signature test)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"


def run(manifest, label):
    resp = preview(manifest, nonce=77)
    rc = resp.get("receipt", {})
    print("=" * 100)
    print(label, "->", rc.get("status"))
    err = str(rc.get("error_message"))
    if rc.get("status") != "Succeeded":
        print("ERR:", err[-600:])
        return None
    # events
    names = {}
    for e in rc.get("events", []):
        n = e.get("type", {}).get("type_reference", {}).get("name")
        names[n] = names.get(n, 0) + 1
    print("events:", names)
    for e in rc.get("events", []):
        n = e.get("type", {}).get("type_reference", {}).get("name")
        if n and ("CDP" in n or "Cdp" in n or "Loan" in n or "Collateral" in n):
            print("  EV", n, json.dumps(e.get("data", {}).get("programmatic_json"))[:300])
    return resp


m = f"""
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("300")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("300")
    Bucket("col_0")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("0")
    Bucket("xrd_empty")
;
CALL_METHOD
    Address("{MARKET}")
    "create_cdp"
    Bucket("xrd_empty")
    Enum<1u8>("audit_test")
    Enum<0u8>()
    Enum<0u8>()
    Array<Bucket>(Bucket("col_0"))
    Array<Bucket>()
    Map<Address, Decimal>()
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
resp = run(m, "create_cdp basic")
if resp:
    json.dump(resp, open("preview_create_cdp.json", "w"), indent=1)
    # look at new CDP id in state changes
    for su in resp["receipt"].get("state_updates", {}).get("new_global_entities", []):
        print("NEW ENTITY:", json.dumps(su)[:200])
