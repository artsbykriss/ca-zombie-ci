#!/usr/bin/env python3
"""Dump full live component state for top Ociswap pools + find funded XRD account for previews."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details, post  # noqa: E402

CAND = [
    "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk",
    "account_rdx12x2ecj3kp4mhq9u34xrdh7njzyz0ewcz4szv0jw5jksxxssnjh7z6z",
]


def show_state(addr):
    d = entity_details([addr])
    it = d["items"][0]
    det = it.get("details") or {}
    st = det.get("state") or {}
    print(f"\n=== {addr} [{det.get('blueprint_name')}] pkg={det.get('package_address')}")
    fields = st.get("fields", [])
    for f in fields:
        fj = f.get("programmatic_json") or {}
        fname = f.get("field_name")
        kind = fj.get("kind")
        val = fj.get("value")
        if kind == "Tuple" or (not val and fj.get("fields")):
            sub = json.dumps(fj.get("fields"))[:300]
            print(f"  {fname}: [{kind}] {sub}")
        else:
            print(f"  {fname}: {json.dumps(val)[:120]}")
    return d


def main():
    s = json.load(open("ociswap_top_summary.json"))
    for r in s[:6]:
        show_state(r["address"])
    print("\n\n=== candidate accounts ===")
    d = entity_details(CAND)
    json.dump(d, open("candidate_accounts.json", "w"), indent=1)
    for it in d["items"]:
        print(it["address"], json.dumps(it.get("fungible_resources", {}).get("items", []))[:600])


if __name__ == "__main__":
    main()
