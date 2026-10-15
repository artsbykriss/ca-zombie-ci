#!/usr/bin/env python3
"""PrecisionPool LP round-trip + immediate fee-claim tests, and DefiPlaza LP round-trip.
Preview only (never submitted)."""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
RESULTS = []

# Ociswap PrecisionPool OCI/XRD
PP = "component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp"
PPX = "resource_rdx1t52pvtk5wfhltchwh3rkzls2x0r98fw9cjhpyrf3vsykhkuwrf7jg8"  # OCI
PPLP = "resource_rdx1n2qukjm07d26matv7cyc5ev2f942uy44zn9h3x7p8hnm9dah5flht4"
# DefiPlaza XRD/DFP2 pair LP tokens (from pair_to_lps KVS)
DP_LP_BASE = None
DP_LP_QUOTE = None

try:
    d = json.load(open("dp_pair_to_lps.json"))
    for e in d.get("entries", []):
        pj = (e.get("key") or {}).get("programmatic_json") or {}
        if pj.get("value") == "component_rdx1cppd8rq7gfwad75z56mz9tldqmw4aps48hqnx2stf4eeew8v6tyd72":
            ents = ((e.get("value") or {}).get("programmatic_json") or {}).get("fields") or []
            addrs = [f.get("value") for f in ents if isinstance(f, dict) and str(f.get("value", "")).startswith("resource_")]
            print("DP LP tokens:", addrs)
            if len(addrs) >= 2:
                DP_LP_BASE, DP_LP_QUOTE = addrs[0], addrs[1]
except Exception as exc:  # noqa: BLE001
    print("lp lookup failed", exc)


def pp_add_remove(xamt, yamt, left, right, tag):
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{PPX}")
    Decimal("{xamt}")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{yamt}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("x")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("y")
;
CALL_METHOD
    Address("{PP}")
    "add_liquidity"
    {left}i32
    {right}i32
    Bucket("x")
    Bucket("y")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPLP}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("xrest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yrest")
;
CALL_METHOD
    Address("{PP}")
    "claimable_fees"
    Array<NonFungibleLocalId>()
;
CALL_METHOD
    Address("{PP}")
    "remove_liquidity"
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("xout")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yout")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("xrest"), Bucket("yrest"), Bucket("xout"), Bucket("yout"))
;
'''.strip()
    return run(m, tag)


def pp_add_claim(left, right, tag):
    """add liquidity then claim fees from the fresh position (should be ~0)."""
    m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("5")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("y")
;
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{PPX}")
    Decimal("20")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("x")
;
CALL_METHOD
    Address("{PP}")
    "add_liquidity"
    {left}i32
    {right}i32
    Bucket("x")
    Bucket("y")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPLP}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("xrest")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("yrest")
;
CREATE_PROOF_FROM_BUCKET_OF_ALL
    Bucket("lp")
    Proof("lp_proof")
;
CALL_METHOD
    Address("{PP}")
    "claim_fees"
    Proof("lp_proof")
;
TAKE_ALL_FROM_WORKTOP
    Address("{PPX}")
    Bucket("fee_x")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("fee_y")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("xrest"), Bucket("yrest"), Bucket("fee_x"), Bucket("fee_y"), Bucket("lp"))
;
'''.strip()
    return run(m, tag)


def dp_add_remove_lp(amount, tag):
    # XRD/DFP2 pair LP tokens (from PlazaDex pair_to_lps KVS)
    DP_LP_A = "resource_rdx1tknxlx2sy23qkg6twvnu3kqcd5l4daacq0n6mdam54upqgx50f4ju8"
    DP_LP_B = "resource_rdx1t4a5clnxmnctmezaty08cuugfzmj2lezqcjk2szezrfdfl4w4ederu"
    assert DP_LP_A and DP_LP_B
    for lp in (DP_LP_A, DP_LP_B):
        m = f'''
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{amount}")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("x")
;
CALL_METHOD
    Address("component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68")
    "add_liquidity"
    Bucket("x")
    None
    None
;
TAKE_ALL_FROM_WORKTOP
    Address("{lp}")
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xrest")
;
CALL_METHOD
    Address("component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68")
    "remove_liquidity"
    Bucket("lp")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("xout")
;
TAKE_ALL_FROM_WORKTOP
    Address("resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq")
    Bucket("dout")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Array<Bucket>(Bucket("xrest"), Bucket("xout"), Bucket("dout"))
;
'''.strip()
        RESULTS.append(run(m, f"{tag}_{lp[-6:]}"))


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else "all"
    if only in ("all", "pp"):
        RESULTS.append(pp_add_remove("20", "5", -887272, 887272, "pp_oci_addremove_fullrange"))
        RESULTS.append(pp_add_remove("20", "5", -600, 600, "pp_oci_addremove_narrow"))
        RESULTS.append(pp_add_claim(-887272, 887272, "pp_oci_add_claim_fees"))
    if only in ("all", "dp"):
        RESULTS.append(dp_add_remove_lp("100", "dp_addremove_lp_xrd_100"))
    json.dump(RESULTS, open("lp_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
