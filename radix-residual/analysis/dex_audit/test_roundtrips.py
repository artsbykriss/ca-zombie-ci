#!/usr/bin/env python3
"""Round-trip / micro-swap extraction tests on live Ociswap pools (preview only)."""
import json
import os
import sys

sys.path.insert(0, ".")
from preview_lib import ACCT, XRD, run, swap_roundtrip  # noqa: E402

os.makedirs("receipts", exist_ok=True)
RESULTS = []

POOLS = {
    # tag -> (component, x, y, blueprint)
    "precision_reddicks": ("component_rdx1cpwwhuxpe2npedx0axkj4nae8uv5222r0syjtu5fxuaxaj78rf30v9",
                           "resource_rdx1t42hpqvsk4t42l6aw09hwphd2axvetp6gvas9ztue0p30f4hzdwxrp", XRD, "PrecisionPool"),
    "precision_oci": ("component_rdx1crm530ath85gcwm4gvwq8m70ay07df085kmupp6gte3ew94vg5pdcp",
                      "resource_rdx1t52pvtk5wfhltchwh3rkzls2x0r98fw9cjhpyrf3vsykhkuwrf7jg8", XRD, "PrecisionPool"),
    "basic_dfp2": ("component_rdx1cpj25l4f8v2n4xl2auhwsagwmt5mmxsavxttmkpl90cr2qnyejqcmt",
                   "resource_rdx1t5ywq4c6nd2lxkemkv4uzt8v7x7smjcguzq5sgafwtasa6luq7fclq", XRD, "BasicPool"),
    "basic_early": ("component_rdx1cpzydtpn2pvq5xp584mk5hz0nakq4dr5e6xv8mwhpuzd4flu6t2jv5",
                    "resource_rdx1t4kc5ljyrwlxvg54s6gnctt7nwwgx89h9r2gvrpm369s23yhzyyzlx", XRD, "BasicPool"),
    "poolv2_fusd": ("component_rdx1cpmacy5gwzswse56jprvlfhrpnt3mplswupu7qtq8pdz2hywy5uaqd",
                    "resource_rdx1t49wa75gve8ehvejr760g3pgvkawsgsgq0u3kh7vevzk0g0cnsmscq", XRD, "Pool(v2.1)"),
}


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    amt = sys.argv[2] if len(sys.argv) > 2 else "10"
    for tag, (comp, xres, yres, bp) in POOLS.items():
        if which != "all" and which not in tag:
            continue
        # direction 1: XRD -> token -> XRD
        r = swap_roundtrip(comp, XRD, xres, amt, f"{tag}_rt_xrd_first_{amt}")
        RESULTS.append(r)
        # direction 2: token -> XRD -> token
        r2 = swap_roundtrip(comp, xres, XRD, "1", f"{tag}_rt_tok_first_{amt}")
        RESULTS.append(r2)
    json.dump(RESULTS, open("roundtrip_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
