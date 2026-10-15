#!/usr/bin/env python3
"""JustLock semantic round-trip previews (simulation only, never submitted).

A: lock(1 XRD, unlockable_at=past)  -> unlock -> expect Succeeded + XRD back
B: lock(1 XRD, unlockable_at=None)  -> unlock -> expect panic "unlockable at: None"
C: lock(1 XRD, unlockable_at=future)-> unlock -> expect panic with timestamp
D: lock receipt forgery/other-resource: unlock with a random NFT bucket -> expect
   "Invalid lock receipts" panic
"""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
LOCKER = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"
RECEIPT = "resource_rdx1nfajj55xgl6dm4ecfv9hru2xnr45ydtuuecs7phgvctuarcvzcrkr6"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
ACCT = "account_rdx12xthsg9xusgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt"


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
        if nm in ("EventLock", "EventUnlock"):
            ev.append({"name": nm,
                       "data": e.get("data", {}).get("programmatic_json")})
    return {"status": rc.get("status"), "error": str(rc.get("error_message"))[:320],
            "events": ev,
            "cost_units": rc.get("fee_summary", {}).get("execution_cost_units_consumed"),
            "raw": r}


def lock_unlock_manifest(unlockable, deposit_resources):
    takes = "\n".join(
        f'TAKE_ALL_FROM_WORKTOP\n    Address("{r}")\n    Bucket("d{i}")\n;'
        for i, r in enumerate(deposit_resources))
    args = ", ".join([f'Bucket("d{i}")' for i in range(len(deposit_resources))])
    return f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("1")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("1")
    Bucket("x")
;
CALL_METHOD
    Address("{LOCKER}")
    "lock"
    Bucket("x")
    {unlockable}
    "probe lock"
    "simulation"
    "https://justlock.io/images/lock_receipt_key_image.png"
;
TAKE_ALL_FROM_WORKTOP
    Address("{RECEIPT}")
    Bucket("receipt")
;
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("receipt")
;
{takes}
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>({args})
;
'''.strip()


if __name__ == "__main__":
    res = []
    # A: past unlockable -> success, 1 XRD back
    a = run(lock_unlock_manifest('Some(1700000000i64)', [XRD]), 9001)
    a["test"] = "A_lock_unlock_past"
    res.append(a)
    print("A:", a["status"], a["error"][:180])
    print("   events:", json.dumps([e["name"] for e in a["events"]]))
    # B: None unlockable -> unlock panics
    b = run(lock_unlock_manifest('None', [XRD]), 9002)
    b["test"] = "B_lock_unlock_None"
    res.append(b)
    print("B:", b["status"], b["error"][:250])
    # C: future unlockable -> panic with timestamp
    c = run(lock_unlock_manifest('Some(2082700000i64)', [XRD]), 9003)
    c["test"] = "C_lock_unlock_future"
    res.append(c)
    print("C:", c["status"], c["error"][:250])
    # D: unlock with a foreign resource bucket (XRD) -> Invalid lock receipts
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("1")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("1")
    Bucket("foreign")
;
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("foreign")
;
'''.strip()
    d = run(m, 9004)
    d["test"] = "D_unlock_foreign_nft_bucket"
    res.append(d)
    print("D:", d["status"], d["error"][:250])
    json.dump([{k: v for k, v in x.items() if k != "raw"} for x in res],
              open(f"{OUT}/jl_semantics_previews.json", "w"), indent=1)
    # save raw receipts of A for the report
    json.dump(res[0]["raw"], open(f"{OUT}/jl_preview_A_raw.json", "w"), indent=1)
