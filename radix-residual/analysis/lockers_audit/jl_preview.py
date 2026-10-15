#!/usr/bin/env python3
"""JustLock adversarial previews (simulation only, never submitted).

Probes holder accounts: withdraw ALL of their lock receipts, call locker.unlock,
observe outcome (events / panic). Also negative tests with fresh accounts.
"""
import json
import sys
import time
from decimal import Decimal

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
LOCKER = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"
RECEIPT = "resource_rdx1nfajj55xgl6dm4ecfv9hru2xnr45ydtuuecs7phgvctuarcvzcrkr6"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"

holders = json.load(open(f"{OUT}/jl_receipt_holders.json"))
contents = json.load(open(f"{OUT}/jl_vault_contents.json"))
union = sorted({v.get("resource") for v in contents.values() if v.get("resource")} |
               {XRD, RECEIPT})


def run(manifest, nonce):
    ls = ledger_state()
    body = {"manifest": manifest, "start_epoch_inclusive": ls["epoch"],
            "end_epoch_exclusive": ls["epoch"] + 2, "nonce": nonce,
            "signer_public_keys": [],
            "flags": {"use_free_credit": True, "assume_all_signature_proofs": True,
                      "skip_epoch_check": True}}
    return post("/transaction/preview", body)


def holder_manifest(acct, n):
    takes = "\n".join(
        f'TAKE_ALL_FROM_WORKTOP\n    Address("{r}")\n    Bucket("o{i}")\n;'
        for i, r in enumerate(union))
    args = ", ".join([f'Bucket("o{i}")' for i in range(len(union))])
    return f'''
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
{takes}
CALL_METHOD
    Address("{acct}")
    "deposit_batch"
    Array<Bucket>({args})
;
'''.strip()


def summarize(r):
    rc = r.get("receipt", {})
    out = {"status": rc.get("status"),
           "error": str(rc.get("error_message"))[:400],
           "unlock_events": [], "delivered": []}
    for e in rc.get("events", []):
        name = e.get("type", {}).get("type_reference", {}).get("name")
        if name == "EventUnlock":
            d = e.get("data", {}).get("programmatic_json", {})
            out["unlock_events"].append(d)
    fs = rc.get("fee_summary", {})
    out["cost_units"] = fs.get("execution_cost_units_consumed")
    return out


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "small"
    res = []
    if which == "small":
        # accounts with the fewest receipts first
        accts = [h for h in holders if h["holder_address"].startswith("account_")]
        accts.sort(key=lambda h: h.get("non_fungible_ids_count", 999))
        targets = accts[:12]
    elif which == "neg":
        targets = [{"holder_address": "account_rdx12xthsg9xusgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt",
                    "non_fungible_ids_count": 0}]
    else:
        targets = []
    for i, h in enumerate(targets):
        acct, n = h["holder_address"], h.get("non_fungible_ids_count", 1)
        m = holder_manifest(acct, n)
        try:
            r = run(m, nonce=1000 + i)
            s = summarize(r)
        except Exception as e:  # noqa: BLE001
            s = {"status": "HTTP_FAIL", "error": str(e)[:300]}
        s["account"] = acct
        s["receipts_held"] = n
        res.append(s)
        print(json.dumps(s)[:500])
        time.sleep(0.4)
    json.dump(res, open(f"{OUT}/jl_preview_probe_{which}.json", "w"), indent=1)
