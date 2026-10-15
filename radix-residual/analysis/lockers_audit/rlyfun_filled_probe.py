#!/usr/bin/env python3
"""RlyFun: filled-curve migration + buy/foreign probes (simulation only)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
FILLED = "component_rdx1crjf9ulms3svafyv4zkyh8kxu99xrawxfjnwu9tmk6ggzf73cssc3j"
COKE = "component_rdx1cptaes92hs2tea34m9mwvj9u7yesegvzjpkvy2uc02y92r6xrq3ksh"
COKE_RES = "resource_rdx1t5g9m9xj88lj2je53fal2ft5ytyk9agx5dqaffumu74zxgg0s6tv5h"
DCKS = "resource_rdx1t42hpqvsk4t42l6aw09hwphd2axvetp6gvas9ztue0p30f4hzdwxrp"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
ACCT = "account_rdx12xthsg9xusgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt"
DCKS_WHALE = "account_rdx12yafv0emkuk7q2gjem8upm074ey87ejs6fy8ratvzjrmwgzyklxefe"
COKE_WHALE = "account_rdx129u9z6c2c3pjpgmam3cp4eag3qd7zcv37l8dytquw77vu8v4hmk3yq"


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
        if nm not in ("DepositEvent", "WithdrawEvent"):
            ev.append({"name": nm,
                       "emitter": e["type"]["emitter"]["entity"].get("entity_address", "")[:46],
                       "data": json.dumps(e.get("data", {}).get("programmatic_json"))[:260]})
    changes = {}
    for g in r.get("resource_changes", []):
        for rr in g.get("resource_changes", []):
            for ec in rr.get("entity_changes", []):
                changes.setdefault(rr["resource_address"], []).append(
                    (ec.get("entity_type"), ec.get("entity_address", "")[:52], ec.get("change")))
    return {"status": rc.get("status"), "error": str(rc.get("error_message"))[:400],
            "events": ev, "changes": changes, "cost": rc.get("fee_summary", {}).get(
                "execution_cost_units_consumed")}


if __name__ == "__main__":
    res = {}
    # F1: set_curve_filled() on a filled curve, no args
    m = f'CALL_METHOD\n    Address("{FILLED}")\n    "set_curve_filled"\n;\n'
    r = run(m, 12001)
    res["F1_set_curve_filled_filled"] = r
    print("F1:", r["status"], r["error"][:220])
    print("    events:", json.dumps(r["events"])[:500])
    # F2: buy_from_pool with 1 XRD on filled curve
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("1")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xrd")
;
CALL_METHOD
    Address("{FILLED}")
    "buy_from_pool"
    Bucket("xrd")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("back")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("back"))
;
'''.strip()
    r = run(m, 12002)
    res["F2_buy_from_pool_1xrd"] = r
    print("F2:", r["status"], r["error"][:220])
    print("    events:", json.dumps(r["events"])[:400])
    # F3: buy with a FOREIGN token bucket (1,000,000 DCKS) on the unfilled COKE curve
    m = f'''
CALL_METHOD
    Address("{DCKS_WHALE}")
    "withdraw"
    Address("{DCKS}")
    Decimal("1000000")
;
TAKE_ALL_FROM_WORKTOP
    Address("{DCKS}")
    Bucket("foreign")
;
CALL_METHOD
    Address("{COKE}")
    "buy"
    Bucket("foreign")
;
TAKE_ALL_FROM_WORKTOP
    Address("{COKE_RES}")
    Bucket("got")
;
CALL_METHOD
    Address("{DCKS_WHALE}")
    "deposit_batch"
    Array<Bucket>(Bucket("got"))
;
'''.strip()
    r = run(m, 12003)
    res["F3_buy_foreign_dcks"] = r
    print("F3:", r["status"], r["error"][:260])
    # F4: buy 10 XRD -> sell the bought COKE back in same tx (round-trip profitability)
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("10")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xrd")
;
CALL_METHOD
    Address("{COKE}")
    "buy"
    Bucket("xrd")
;
TAKE_ALL_FROM_WORKTOP
    Address("{COKE_RES}")
    Bucket("tokens")
;
CALL_METHOD
    Address("{COKE}")
    "sell"
    Bucket("tokens")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("back")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("back"))
;
'''.strip()
    r = run(m, 12004)
    res["F4_buy_sell_roundtrip"] = r
    print("F4:", r["status"], r["error"][:220])
    xrd = r["changes"].get(XRD)
    print("    XRD changes:", json.dumps(xrd)[:400])
    print("    events:", json.dumps(r["events"])[:600])
    json.dump(res, open(f"{OUT}/rlyfun_filled_and_misc_probes.json", "w"), indent=1)
