#!/usr/bin/env python3
"""RadLock adversarial probes (simulation only, never submitted).

Live components (package_rdx1p53g7...):
  RadlockService  : component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs
  TokenLockService: component_rdx1crn49lcmzyuqpz4lgx8fulegk4pdzjz89lhegs4g5attrgxqjp4amc
  TokenVestService: component_rdx1cp7vsz98w06urq3n00rf9xz9jrlppyk0sukqrm4kvqvkjwucne6puh

Phase 1: discover argument shapes via type-check errors.
"""
import json
import re
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
PKG = "package_rdx1p53g7gvj96xphlgeuzn4c4njlmrkvpqw94hxstrpdn4u2swu9t2qpp"
RADSVC = "component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs"
LOCKSVC = "component_rdx1crn49lcmzyuqpz4lgx8fulegk4pdzjz89lhegs4g5attrgxqjp4amc"
VESTSVC = "component_rdx1cp7vsz98w06urq3n00rf9xz9jrlppyk0sukqrm4kvqvkjwucne6puh"


def probe_call(manifest, nonce):
    ls = ledger_state()
    try:
        r = post("/transaction/preview", {
            "manifest": manifest, "start_epoch_inclusive": ls["epoch"],
            "end_epoch_exclusive": ls["epoch"] + 2, "nonce": nonce,
            "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                      "skip_epoch_check": True}})
    except Exception as e:  # noqa: BLE001
        return {"status": "HTTP_FAIL", "error": str(e)[:400]}
    rc = r.get("receipt", {})
    return {"status": rc.get("status"), "error": str(rc.get("error_message"))[:400],
            "raw": r,
            "events": [(e["type"].get("name"),
                        e["type"]["emitter"]["entity"].get("entity_address", "")[:46])
                       for e in rc.get("events", [])]}


if __name__ == "__main__":
    blueprint = sys.argv[1] if len(sys.argv) > 1 else "RadlockService"
    methods = sys.argv[2].split(",") if len(sys.argv) > 2 else [
        "withdraw_flat_xrd_fees", "withdraw_liquidity_fees", "get_xrd_fee_vault"]
    res = {}
    for i, m in enumerate(methods):
        man = f'''
CALL_FUNCTION
    Address("{PKG}")
    "{blueprint}"
    "{m}"
;
'''
        out = probe_call(man, 20000 + i)
        fe = re.search(r"expected_field_count: (\d+), found: (\d+)", out.get("error") or "")
        res[m] = {"expected_fields": fe.group(1) if fe else None,
                  "status": out["status"], "error": (out.get("error") or "")[:200]}
        print(f"{blueprint}.{m}: fields={res[m]['expected_fields']} status={out['status']} :: {str(res[m]['error'])[:180]}")
    json.dump(res, open(f"{OUT}/radlock_probe_{blueprint}.json", "w"), indent=1)
