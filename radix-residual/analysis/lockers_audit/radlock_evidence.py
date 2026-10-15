#!/usr/bin/env python3
"""RadLock: save consolidated adversarial evidence (simulation only)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
RADSVC = "component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs"
LOCKSVC = "component_rdx1crn49lcmzyuqpz4lgx8fulegk4pdzjz89lhegs4g5attrgxqjp4amc"
VESTSVC = "component_rdx1cp7vsz98w06urq3n00rf9xz9jrlppyk0sukqrm4kvqvkjwucne6puh"
LOCKV4 = "component_rdx1cqvjerqdt5lmfqhzekhxzjm0dyjmr6d29rra843cxqk9z6epva2xwa"
WHALE = "account_rdx12xthsg9xusgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
LID = "[5ded22d96d5957329947918f8131e91eb75522640ef1f2f987c3ed760e2431]"

ls = ledger_state()
results = {}


def run(name, manifest, nonce):
    try:
        r = post("/transaction/preview", {
            "manifest": manifest, "start_epoch_inclusive": ls["epoch"],
            "end_epoch_exclusive": ls["epoch"] + 2, "nonce": nonce,
            "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                      "skip_epoch_check": True}})
        rc = r.get("receipt", {})
        results[name] = {"status": rc.get("status"),
                         "error": str(rc.get("error_message"))[:600],
                         "output": rc.get("output"),
                         "events": [(e["type"].get("name"),
                                     e["type"]["emitter"]["entity"].get("entity_address", "")[:60])
                                    for e in rc.get("events", [])]}
    except Exception as e:  # noqa: BLE001
        results[name] = {"status": "HTTP_FAIL", "error": str(e)[:600]}
    print(name, "->", results[name]["status"], "|", results[name]["error"][:200])


run("get_xrd_fee_vault", f'CALL_METHOD\n    Address("{RADSVC}")\n    "get_xrd_fee_vault"\n;\n', 90001)
run("withdraw_flat_xrd_fees_fresh",
    f'CALL_METHOD\n    Address("{RADSVC}")\n    "withdraw_flat_xrd_fees"\n;\n', 90002)
run("withdraw_liquidity_fees_fresh",
    f'CALL_METHOD\n    Address("{RADSVC}")\n    "withdraw_liquidity_fees"\n;\n', 90003)
run("lock_proxy_method_call_fresh",
    f'CALL_METHOD\n    Address("{LOCKSVC}")\n    "method_call"\n;\n', 90004)
run("vest_proxy_withdraw_auth_fresh",
    f'CALL_METHOD\n    Address("{VESTSVC}")\n    "withdraw_auth"\n;\n', 90005)
# withdraw signature probes
run("withdraw_0args", f'CALL_METHOD\n    Address("{LOCKV4}")\n    "withdraw"\n;\n', 90006)
run("withdraw_lock_proof_type", f'''
CALL_METHOD
    Address("{WHALE}")
    "withdraw"
    Address("{XRD}")
    Decimal("1")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("1")
    Bucket("b")
;
CREATE_PROOF_FROM_BUCKET_OF_ALL
    Bucket("b")
    Proof("p")
;
CALL_METHOD
    Address("{LOCKV4}")
    "withdraw"
    Proof("p")
    Some(Array<NonFungibleLocalId>(NonFungibleLocalId("{LID}")))
    Proof("p")
;
CALL_METHOD
    Address("{WHALE}")
    "deposit_batch"
    Array<Bucket>(Bucket("b"))
;
'''.strip(), 90007)
json.dump(results, open(f"{OUT}/radlock_preview_evidence.json", "w"), indent=1)
