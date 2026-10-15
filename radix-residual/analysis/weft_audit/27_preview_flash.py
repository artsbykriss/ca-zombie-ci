#!/usr/bin/env python3
"""Preview: flash loan mechanics (take_flash_loan / repay_flash_loan)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview
from rdx import ledger_state

POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
HUSDC = "resource_rdx1thxj9m87sn5cc9ehgp9qxp6vzeqxtce90xm5cp33373tclyp4et4gv"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"

mode = sys.argv[1] if len(sys.argv) > 1 else "take"

if mode == "take":
    # just take and dump, then deposit everything (will fail to repay -> see what happens)
    manifest = f"""
CALL_METHOD
    Address("{POOL}")
    "take_flash_loan"
    Map<Address, Decimal>(Address("{HUSDC}") => Decimal("1"))
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
elif mode == "full":
    manifest = f"""
CALL_METHOD
    Address("{POOL}")
    "take_flash_loan"
    Map<Address, Decimal>(Address("{HUSDC}") => Decimal("1"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{HUSDC}")
    Bucket("fl")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{HUSDC}")
    Decimal("0.001")
;
TAKE_ALL_FROM_WORKTOP
    Address("{HUSDC}")
    Bucket("fee")
;
CALL_METHOD
    Address("{POOL}")
    "repay_flash_loan"
    Array<Bucket>(Bucket("fl"), Bucket("fee"))
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
else:
    raise SystemExit("mode?")

resp = preview(manifest, nonce=123)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
if rc.get("status") != "Succeeded":
    print("ERR:", str(rc.get("error_message"))[-700:])
    json.dump(resp, open(f"preview_flash_{mode}_failed.json", "w"), indent=1)
else:
    json.dump(resp, open(f"preview_flash_{mode}.json", "w"), indent=1)
    print("cost units:", rc.get("fee_summary", {}).get("execution_cost_units_consumed"))
    for e in rc.get("events", [])[-8:]:
        tid = e.get("type", {}).get("type_reference", {})
        print("-", tid.get("entity_address","")[-14:], json.dumps(e.get("data", {}).get("programmatic_json"))[:220])
