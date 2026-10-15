#!/usr/bin/env python3
"""Preview: liquidate a CDP with XRD payment (funded by simulated account)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"

CDP = sys.argv[1] if len(sys.argv) > 1 else "#523#"
PAY = sys.argv[2] if len(sys.argv) > 2 else "2000"
REQ = sys.argv[3] if len(sys.argv) > 3 else "nft"

if REQ == "nft":
    req = 'Enum<1u8>(Array<Address>(Address("resource_rdx1nfesadfsnamled8dqz6wvntez29gj7x474a8scluvch6sqjs3msx9y")))'
elif REQ == "some_nft_273":
    req = 'Enum<1u8>(Array<Address>(Address("resource_rdx1ntyg43hlwegw6q9f4v074ruxvke3keykfnew4kmnu57k9dawu94t8l")))'
else:
    req = 'Enum<0u8>()'

manifest = f"""
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{PAY}")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{PAY}")
    Bucket("pay")
;
CALL_METHOD
    Address("{MARKET}")
    "liquidate"
    NonFungibleLocalId("{CDP}")
    Array<Bucket>(Bucket("pay"))
    {req}
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
resp = preview(manifest, nonce=99)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
if rc.get("status") != "Succeeded":
    print("ERR:", str(rc.get("error_message"))[-800:])
    json.dump(resp, open("preview_liquidate_failed.json", "w"), indent=1)
else:
    json.dump(resp, open("preview_liquidate.json", "w"), indent=1)
    fs = rc.get("fee_summary", {})
    print("cost units:", fs.get("execution_cost_units_consumed"), "| xrd cost:", fs.get("xrd_total_execution_cost"))
    print()
    print("EVENTS:")
    for e in rc.get("events", []):
        tid = e.get("type", {}).get("type_reference", {})
        pkg = tid.get("entity_address", "")
        nm = tid.get("local_type_index", tid.get("local_type_id"))
        data = e.get("data", {}).get("programmatic_json")
        print("-", pkg[-14:], nm, json.dumps(data)[:300])
    print()
    print("RESOURCE CHANGES (ACCT/MARKET):")
    for r in resp.get("resource_changes", []):
        for ec in r.get("entity_changes", []):
            if ec.get("entity_address") in (ACCT, MARKET) and float(ec.get("amount") or 0) != 0:
                kind = ec.get("change", ec.get("kind", ""))
                print(f"  {ec['entity_address'][:26]} {r['resource_address'][:52]} {ec.get('amount')}")
