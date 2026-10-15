#!/usr/bin/env python3
"""Preview: liquidate #1015 (hUSDC debt vs XRD collateral) using a simulated hUSDC holder as attacker."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
HUSDC = "resource_rdx1thxj9m87sn5cc9ehgp9qxp6vzeqxtce90xm5cp33373tclyp4et4gv"
ACCT = sys.argv[1] if len(sys.argv) > 1 else "account_rdx129v8sg52dex7ct6gf7ne0rqvyxck4rn5mp0uyp30f898qfy3hxqrmj"
CDP = sys.argv[2] if len(sys.argv) > 2 else "#1015#"
PAY = sys.argv[3] if len(sys.argv) > 3 else "45"

manifest = f"""
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{HUSDC}")
    Decimal("{PAY}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{HUSDC}")
    Bucket("pay")
;
CALL_METHOD
    Address("{MARKET}")
    "liquidate"
    NonFungibleLocalId("{CDP}")
    Array<Bucket>(Bucket("pay"))
    Enum<1u8>(Array<Address>(Address("{XRD}")))
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
resp = preview(manifest, nonce=1001)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
if rc.get("status") != "Succeeded":
    print("ERR:", str(rc.get("error_message"))[-900:])
    json.dump(resp, open("preview_liq1015_failed.json", "w"), indent=1)
else:
    json.dump(resp, open("preview_liq1015.json", "w"), indent=1)
    print("cost units:", rc.get("fee_summary", {}).get("execution_cost_units_consumed"))
    print()
    print("EVENTS:")
    for e in rc.get("events", []):
        tid = e.get("type", {}).get("type_reference", {})
        print("-", tid.get("entity_address", "")[-14:], json.dumps(e.get("data", {}).get("programmatic_json"))[:260])
    print()
    print("RESOURCE CHANGES:")
    for r in resp.get("resource_changes", []):
        for ec in r.get("entity_changes", []):
            if float(ec.get("amount") or 0) != 0:
                print(f"  {ec['entity_address'][:40]} {r['resource_address'][:52]} {ec.get('amount')}")
