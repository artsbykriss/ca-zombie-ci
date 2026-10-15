#!/usr/bin/env python3
"""JustLock adversarial previews, part 2: discovery + negatives (simulation only).

Discovery manifest: withdraw the account's lock receipts and call locker.unlock
without depositing outputs -> if unlock succeeds the tx ends with
DropNonEmptyBucket, but the receipt still contains EventUnlock evidence.
Targeted mode re-runs with the exact delivered resources so the tx Succeeds.
"""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
LOCKER = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"
RECEIPT = "resource_rdx1nfajj55xgl6dm4ecfv9hru2xnr45ydtuuecs7phgvctuarcvzcrkr6"


def run(manifest, nonce):
    ls = ledger_state()
    return post("/transaction/preview", {
        "manifest": manifest, "start_epoch_inclusive": ls["epoch"],
        "end_epoch_exclusive": ls["epoch"] + 2, "nonce": nonce,
        "signer_public_keys": [],
        "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                  "skip_epoch_check": True}})


def summarize(r):
    rc = r.get("receipt", {})
    out = {"status": rc.get("status"), "error": str(rc.get("error_message"))[:300],
           "unlock_events": []}
    for e in rc.get("events", []):
        name = e.get("type", {}).get("type_reference", {}).get("name")
        if name == "EventUnlock":
            d = e.get("data", {}).get("programmatic_json", {})
            fields = {f.get("field_name"): f for f in d.get("fields", [])}
            out["unlock_events"].append({
                "lock_id": fields.get("lock_id", {}).get("value"),
                "resource": fields.get("resource", {}).get("value"),
                "contents": fields.get("locked_contents"),
                "unlockable_at": fields.get("unlockable_at"),
            })
    out["cost_units"] = rc.get("fee_summary", {}).get("execution_cost_units_consumed")
    return out


def discover(acct, n, nonce):
    m = f'''
CALL_METHOD
    Address("{acct}")
    "withdraw"
    Address("{RECEIPT}")
    Decimal("{n}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{RECEIPT}")
    Bucket("receipts")
;
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("receipts")
;
'''.strip()
    return run(m, nonce)


def targeted(acct, resources, nonce):
    takes = "\n".join(
        f'TAKE_ALL_FROM_WORKTOP\n    Address("{r}")\n    Bucket("o{i}")\n;'
        for i, r in enumerate(resources))
    args = ", ".join([f'Bucket("o{i}")' for i in range(len(resources))])
    m = f'''
CALL_METHOD
    Address("{acct}")
    "withdraw"
    Address("{RECEIPT}")
    Decimal("1")
;
TAKE_ALL_FROM_WORKTOP
    Address("{RECEIPT}")
    Bucket("receipts")
;
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("receipts")
;
{takes}
CALL_METHOD
    Address("{acct}")
    "deposit_batch"
    Array<Bucket>({args})
;
'''.strip()
    return run(m, nonce)


def negatives():
    res = []
    # N1: fresh account that holds no receipts tries to withdraw one
    acct = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"
    n_own = 0
    m = f'''
CALL_METHOD
    Address("{acct}")
    "withdraw"
    Address("{RECEIPT}")
    Decimal("1")
;
'''
    r = run(m, 5001)
    s = summarize(r)
    s.update({"test": "N1_fresh_account_withdraw_receipt", "account": acct,
              "receipts_actually_held": n_own})
    res.append(s)
    # N2: unlock with an EMPTY receipt bucket (ResourceCheck passes, loop empty)
    m = f'''
TAKE_ALL_FROM_WORKTOP
    Address("{RECEIPT}")
    Bucket("empty")
;
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("empty")
;
'''
    r = run(m, 5002)
    s = summarize(r)
    s.update({"test": "N2_unlock_empty_bucket", "account": "-"})
    res.append(s)
    # N3: attempt to take receipts from the LOCKER component itself (used receipts vault)
    m = f'''
CALL_METHOD
    Address("{LOCKER}")
    "unlock"
    Bucket("nope")
;
'''
    try:
        r = run(m, 5003)
        s = summarize(r)
        s.update({"test": "N3_unlock_missing_bucket_label", "account": "-"})
    except Exception as e:  # noqa: BLE001
        s = {"test": "N3_unlock_missing_bucket_label", "status": "HTTP_FAIL",
             "error": str(e)[:200]}
    res.append(s)
    # N4: call a non-existent method "withdraw" on the locker (permissionless drain attempt)
    m = f'''
CALL_METHOD
    Address("{LOCKER}")
    "withdraw"
    Decimal("1")
;
'''
    try:
        r = run(m, 5004)
        s = summarize(r)
        s.update({"test": "N4_locker_withdraw_method", "account": "-"})
    except Exception as e:  # noqa: BLE001
        s = {"test": "N4_locker_withdraw_method", "status": "HTTP_FAIL",
             "error": str(e)[:200]}
    res.append(s)
    json.dump(res, open(f"{OUT}/jl_preview_negatives.json", "w"), indent=1)
    for s in res:
        print(json.dumps(s)[:400])


if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "neg":
        negatives()
    elif mode == "discover":
        holders = json.load(open(f"{OUT}/jl_receipt_holders.json"))
        accts = [h for h in holders if h["holder_address"].startswith("account_")]
        accts.sort(key=lambda h: h.get("non_fungible_ids_count", 999))
        out = []
        for i, h in enumerate(accts):
            acct, n = h["holder_address"], h.get("non_fungible_ids_count", 1)
            try:
                s = summarize(discover(acct, n, 2000 + i))
            except Exception as e:  # noqa: BLE001
                s = {"status": "HTTP_FAIL", "error": str(e)[:200]}
            s["account"] = acct
            s["receipts_held"] = n
            out.append(s)
            nev = len(s.get("unlock_events", []))
            print(f"{acct[:30]} n={n} {s['status']} unlocks={nev} {str(s['error'])[:110]}")
            time.sleep(0.3)
        json.dump(out, open(f"{OUT}/jl_preview_discovery.json", "w"), indent=1)
    elif mode == "targeted":
        spec = json.load(open(sys.argv[2]))
        out = []
        for i, t in enumerate(spec):
            r = targeted(t["account"], t["resources"], 3000 + i)
            s = summarize(r)
            s.update(t)
            out.append(s)
            print(json.dumps(s)[:600])
            time.sleep(0.3)
        json.dump(out, open(f"{OUT}/jl_preview_targeted.json", "w"), indent=1)
