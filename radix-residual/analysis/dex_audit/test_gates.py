#!/usr/bin/env python3
"""Gate tests: can an unprivileged caller reach admin methods? (preview only)"""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run  # noqa: E402

os.makedirs("receipts", exist_ok=True)
R = []

LEGACY_BP = "component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt"
V2_POOL = "component_rdx1cpmacy5gwzswse56jprvlfhrpnt3mplswupu7qtq8pdz2hywy5uaqd"
REGISTRY = "component_rdx1crdy3ut4f78nxjpum37kl0682nq0vee9ntwrz8eg7mtxe8kyanwjmv"
DP_DEX = "component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68"
DP_PAIR = "component_rdx1cppd8rq7gfwad75z56mz9tldqmw4aps48hqnx2stf4eeew8v6tyd72"

TESTS = [
    ("legacy_bp_set_liquidity_pool_meta",
     f'CALL_METHOD\n    Address("{LEGACY_BP}")\n    "set_liquidity_pool_meta"\n'
     f'    Address("{LEGACY_BP}")\n'
     '    Address("resource_rdx1th68g9hn0u6u29uv6pqm8qjnd7luhn3nk9x436vvwzdu9vcwqndc2c")\n'
     '    "HACKED"\n    "HACKED"\n'
     f'    Address("{ACCT}")\n;'),
    ("v2pool_set_liquidity_pool_meta",
     f'CALL_METHOD\n    Address("{V2_POOL}")\n    "set_liquidity_pool_meta"\n'
     f'    Address("{V2_POOL}")\n'
     '    Address("resource_rdx1tkc32nfsvwnt7ysq2sdgyq6w2g4s69w86yzk8zwegf7pcvya905ctv")\n'
     '    "HACKED"\n    "HACKED"\n'
     f'    Address("{ACCT}")\n;'),
    ("v2pool_sync_registry", f'CALL_METHOD\n    Address("{V2_POOL}")\n    "sync_registry"\n;'),
    ("registry_update_config",
     f'CALL_METHOD\n    Address("{REGISTRY}")\n    "update_config"\n    Decimal("0.25")\n'
     '    Decimal("86400")\n    Decimal("10")\n;'),
    ("registry_withdraw_protocol_fees",
     f'CALL_METHOD\n    Address("{REGISTRY}")\n    "withdraw_protocol_fees"\n'
     f'    Array<Address>(Address("{XRD}"))\n;'),
    ("dp_dex_withdraw_owned_liquidity",
     f'CALL_METHOD\n    Address("{DP_DEX}")\n    "withdraw_owned_liquidity"\n'
     f'    Address("{DP_PAIR}")\n;'),
    ("dp_dex_set_min_dfp2",
     f'CALL_METHOD\n    Address("{DP_DEX}")\n    "set_min_dfp2"\n    Decimal("1")\n;'),
    ("dp_dex_blacklist",
     'CALL_METHOD\n    Address("component_rdx1cqy7sq3mxj2whhlqlryy05hzs96m0ajnv23e7j7vanmdwwlccnmz68")\n'
     '    "blacklist"\n    Address("resource_rdx1tk3fxrz75ghllrqhyq8e574rkf4lsq2x5a0vegxwlh3defv225cth3")\n;'),
    ("dp_pair_get_state", f'CALL_METHOD\n    Address("{DP_PAIR}")\n    "get_state"\n;'),
]


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    for tag, body in TESTS:
        if only and only not in tag:
            continue
        R.append(run(body, tag))
    json.dump(R, open("gate_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
