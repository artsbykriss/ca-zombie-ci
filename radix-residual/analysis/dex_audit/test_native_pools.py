#!/usr/bin/env python3
"""Can an outsider bypass the DEX wrapper and withdraw directly from the native TwoResourcePools?
Also: read the native pools' role assignments (owner role = who can re-rule the pool)."""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details  # noqa: E402

NATIVE = {
    "ociswap_basic_dfp2_xrd": "pool_rdx1ckdf4tq62lznn5c3zlkx7paxjth7g2d0ryqhexxzq0yrufmev096nd",
    "ociswap_poolv2_fusd_xrd": "pool_rdx1ch3z73nkykmfslz6gxz7466xzdqcy8q33xex66v7k5c0n9tu2rf8p6",
    "defiplaza_xrd_dfp2_native": "pool_rdx1chxn0nqj840r78t2ah5agchq4ue9p65q23nc9ckqfe0mmjstq8fyg0",
}
R = []


def main():
    # role assignments of the native pools
    d = entity_details(list(NATIVE.values()))
    for k, it in zip(NATIVE, d["items"]):
        ra = it.get("details", {}).get("role_assignments") or {}
        own = json.dumps(ra.get("owner", {}))[:400]
        print(f"{k} ({it['address']}) OWNER ROLE: {own}")
        for e in ra.get("entries", []):
            rk = e.get("role_key", {})
            if rk.get("module") in ("Main", "PoolManager") or "manager" in str(rk.get("name", "")):
                print("   role", rk, "->", json.dumps(e.get("assignment"))[:200])
    # attempt direct protected_withdraw as an unprivileged caller
    for k, addr in NATIVE.items():
        m = f'''
CALL_METHOD
    Address("{addr}")
    "protected_withdraw"
    Address("{XRD}")
    Decimal("1")
    Enum<WithdrawStrategy>("Rounded")
    Enum<RoundingMode>("ToZero")
;
TAKE_ALL_FROM_WORKTOP
    Address("{XRD}")
    Bucket("x")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit"
    Bucket("x")
;
'''.strip()
        R.append(run(m, f"native_protected_withdraw_{k}"))
    json.dump(R, open("native_pool_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
