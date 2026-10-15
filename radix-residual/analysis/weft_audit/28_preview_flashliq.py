#!/usr/bin/env python3
"""Preview: self-contained flash-loan liquidation: flash XRD -> liquidate #447 -> repay flash."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
TRANSIENT = "resource_rdx1nfeyk5cmjep98zae9vhg067elm2necwsvdnngp3je62ahqstsa8x2x"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"

CDP = sys.argv[1] if len(sys.argv) > 1 else "#447#"
FLASH = sys.argv[2] if len(sys.argv) > 2 else "10"
REPAY = sys.argv[3] if len(sys.argv) > 3 else "5"
REQ = sys.argv[4] if len(sys.argv) > 4 else XRD

manifest = f"""
CALL_METHOD
    Address("{POOL}")
    "take_flash_loan"
    Map<Address, Decimal>(Address("{XRD}") => Decimal("{FLASH}"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{TRANSIENT}")
    Bucket("terms")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{REPAY}")
    Bucket("pay")
;
CALL_METHOD
    Address("{MARKET}")
    "liquidate"
    NonFungibleLocalId("{CDP}")
    Array<Bucket>(Bucket("pay"))
    Enum<1u8>(Array<Address>(Address("{REQ}")))
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("all_xrd")
;
CALL_METHOD
    Address("{POOL}")
    "repay_flash_loan"
    Array<Bucket>(Bucket("all_xrd"))
    Bucket("terms")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
resp = preview(manifest, nonce=321)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
if rc.get("status") != "Succeeded":
    print("ERR:", str(rc.get("error_message"))[-900:])
    json.dump(resp, open("preview_flashliq_failed.json", "w"), indent=1)
else:
    json.dump(resp, open("preview_flashliq.json", "w"), indent=1)
    print("cost units:", rc.get("fee_summary", {}).get("execution_cost_units_consumed"))
    for e in rc.get("events", []):
        tid = e.get("type", {}).get("type_reference", {})
        print("-", tid.get("entity_address", "")[-14:], json.dumps(e.get("data", {}).get("programmatic_json"))[:230])
