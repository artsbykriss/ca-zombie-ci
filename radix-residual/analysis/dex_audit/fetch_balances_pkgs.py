#!/usr/bin/env python3
"""On-chain balances for top pools + package blueprint interfaces (read-only)."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details, post  # noqa: E402


def details_chunked(addrs):
    out = {"items": []}
    for i in range(0, len(addrs), 20):
        d = entity_details(addrs[i:i + 20])
        out["items"].extend(d["items"])
    return out


def main():
    s = json.load(open("ociswap_top_summary.json"))
    # gather entity addresses: components + their liquidity pools + lp tokens
    comps = [r["address"] for r in s]
    pools = [r["liquidity_pool"] for r in s if r.get("liquidity_pool")]
    lps = [r["lp_address"] for r in s if r.get("lp_address")]
    d = details_chunked(comps + pools + lps)
    json.dump(d, open("ociswap_top_balances.json", "w"), indent=1)
    for it in d["items"]:
        det = it.get("details") or {}
        addr = it["address"]
        fr = it.get("fungible_resources", {}).get("items", [])
        if addr.startswith("pool_rdx1"):
            print(f"\n{addr} [{det.get('blueprint_name')}] native pool vaults:")
            for r in fr:
                amt = r.get("amount")
                print(f"   {r['resource_address']}  {amt}")
        elif addr.startswith("resource_"):
            print(f"\n{addr} [resource] total_supply={det.get('total_supply')}")
        else:
            print(f"\n{addr} [{det.get('blueprint_name')}] fungible items: {len(fr)}")
            for r in fr:
                print(f"   {r['resource_address']}  {r.get('amount')}")

    # packages -> blueprints
    pkgs = sorted({r["package"] for r in s if r.get("package")})
    print("\n=== packages:", pkgs)
    pd = entity_details(pkgs)
    json.dump(pd, open("ociswap_pkgs.json", "w"), indent=1)
    for it in pd["items"]:
        det = it.get("details") or {}
        print("\npackage", it["address"])
        print(" details keys:", list(det.keys()))
        bps = det.get("blueprint_definitions") or det.get("blueprints") or []
        for b in bps:
            print("  blueprint:", b.get("name"), "version", b.get("version"))


if __name__ == "__main__":
    main()
