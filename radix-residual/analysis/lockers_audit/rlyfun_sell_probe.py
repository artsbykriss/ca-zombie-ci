#!/usr/bin/env python3
"""RlyFun EarlyCurves adversarial previews (simulation only).

Tests on the COKE curve (component_rdx1cptaes92hs2tea34m9mwvj9u7yesegvzjpkvy2uc02y92r6xrq3ksh):
 S1: legit sell of 100 COKE tokens
 S2: sell a FOREIGN token bucket (1,000,000 DCKS) - tests resource verification
 S3: sell a large foreign bucket (50,000,000 DCKS) - drain attempt
 S4: sell 100 COKE with a dev-proof-less claim attempt (claim_lp_fees w/o proof)
 G1: getter probes (last_price etc.)
"""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
CURVE = "component_rdx1cptaes92hs2tea34m9mwvj9u7yesegvzjpkvy2uc02y92r6xrq3ksh"
COKE = "resource_rdx1t5g9m9xj88lj2je53fal2ft5ytyk9agx5dqaffumu74zxgg0s6tv5h"
DCKS = "resource_rdx1t42hpqvsk4t42l6aw09hwphd2axvetp6gvas9ztue0p30f4hzdwxrp"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
COKE_WHALE = "account_rdx129u9z6c2c3pjpgmam3cp4eag3qd7zcv37l8dytquw77vu8v4hmk3yq"
DCKS_WHALE = "account_rdx12yafv0emkuk7q2gjem8upm074ey87ejs6fy8ratvzjrmwgzyklxefe"


def run(manifest, nonce):
    ls = ledger_state()
    r = post("/transaction/preview", {
        "manifest": manifest, "start_epoch_inclusive": ls["epoch"],
        "end_epoch_exclusive": ls["epoch"] + 2, "nonce": nonce,
        "signer_public_keys": [],
        "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                  "skip_epoch_check": True}})
    rc = r.get("receipt", {})
    ev = []
    for e in rc.get("events", []):
        nm = e["type"].get("name")
        if nm in ("Buy", "Sell", "Claim", "DevClaim", "Launch", "Launched"):
            ev.append({"name": nm, "data": e.get("data", {}).get("programmatic_json")})
    # account XRD change
    xrd_delta = None
    changes = {}
    for g in r.get("resource_changes", []):
        for rr in g.get("resource_changes", []):
            for ec in rr.get("entity_changes", []):
                changes.setdefault(rr["resource_address"], []).append(
                    (ec.get("entity_address", "")[:60], ec.get("change")))
    return {"status": rc.get("status"), "error": str(rc.get("error_message"))[:300],
            "events": ev, "changes": changes}


def sell_manifest(acct, res, amount):
    return f'''
CALL_METHOD
    Address("{acct}")
    "withdraw"
    Address("{res}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res}")
    Bucket("tok")
;
CALL_METHOD
    Address("{CURVE}")
    "sell"
    Bucket("tok")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("x1")
;
TAKE_ALL_FROM_WORKTOP
    Address("{res}")
    Bucket("x2")
;
CALL_METHOD
    Address("{acct}")
    "deposit_batch"
    Array<Bucket>(Bucket("x1"), Bucket("x2"))
;
'''.strip()


if __name__ == "__main__":
    res = {}
    tests = [
        ("S1_sell_100_coke", sell_manifest(COKE_WHALE, COKE, "100"), 11001),
        ("S2_sell_1000000_dcks_foreign", sell_manifest(DCKS_WHALE, DCKS, "1000000"), 11002),
        ("S3_sell_50000000_dcks_foreign", sell_manifest(DCKS_WHALE, DCKS, "50000000"), 11003),
    ]
    for name, m, nonce in tests:
        r = run(m, nonce)
        res[name] = r
        xrd = r["changes"].get(XRD)
        tok = r["changes"].get(COKE)
        print(name, "|", r["status"], "|", r["error"][:120])
        print("   events:", json.dumps(r["events"])[:400])
        print("   XRD changes:", json.dumps(xrd)[:300])
        print("   COKE changes:", json.dumps(tok)[:200] if tok else None)
    # claim_lp_fees without proof
    m = f'''
CALL_METHOD
    Address("{CURVE}")
    "claim_lp_fees"
    None
;
'''
    try:
        r = run(m, 11004)
        res["S4_claim_lp_fees_None"] = r
        print("S4_claim_lp_fees_None |", r["status"], "|", r["error"][:160])
    except Exception as e:  # noqa: BLE001
        print("S4 HTTP fail", str(e)[:120])
    json.dump(res, open(f"{OUT}/rlyfun_sell_probes.json", "w"), indent=1)
