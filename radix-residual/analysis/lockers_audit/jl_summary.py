#!/usr/bin/env python3
"""JustLock: build per-lock / per-resource summary + resource metadata."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
c = json.load(open(f"{OUT}/jl_vault_contents.json"))
nfd = json.load(open(f"{OUT}/jl_receipts_nfdata.json"))
holders = json.load(open(f"{OUT}/jl_receipt_holders.json"))
comp = json.load(open(f"{OUT}/jl_component_state.json"))["component"]


def rfield(v, name):
    d = v.get("data", {}).get("programmatic_json")
    if not d:
        return None
    for x in d["fields"]:
        if x.get("field_name") == name:
            return x
    return None


# holder map: address -> receipts (parse holder items)
holder_map = {}
for h in holders:
    addr = h.get("address") or h.get("holder_address")
    rid = h.get("last_updated" if False else "address")
    # gateway returns items with address + amount; per-holder nft list needs extra call
    holder_map.setdefault(addr, h)
print("holder entries:", len(holder_map), json.dumps(holders[:2], indent=1)[:500])

rows = {}
for k, v in c.items():
    ua = rfield(nfd.get(k, {}), "unlockable_at")
    us = rfield(nfd.get(k, {}), "unlocked_at")
    lc = rfield(nfd.get(k, {}), "locked_contents")
    name = rfield(nfd.get(k, {}), "name")
    # locked_contents: Fungible variant field Decimal value; NonFungible variant indexset
    lc_kind = lc["variant_name"] if lc else None
    lc_val = None
    if lc and lc_kind == "Fungible":
        lc_val = lc["fields"][0]["value"]
    elif lc and lc_kind == "NonFungible":
        lc_val = lc["fields"][0].get("value") if lc["fields"] else None
    rows[k] = {
        "unlockable_at": (ua["fields"][0]["value"] if ua and ua["variant_name"] == "Some" else None),
        "unlocked_at": (us["fields"][0]["value"] if us and us["variant_name"] == "Some" else None),
        "resource": v.get("resource"),
        "amount": v.get("amount"),
        "nft_count": v.get("total_count"),
        "receipt_locked_contents": lc_val,
        "name": name["value"] if name else None,
    }

# aggregate by resource & category
agg = {}
for k, r in rows.items():
    if r["unlocked_at"] is not None:
        cat = "spent"
    elif r["unlockable_at"] is None:
        cat = "forever"
    else:
        cat = "time_locked"
    key = (r["resource"], cat)
    a = agg.setdefault(key, {"resource": r["resource"], "category": cat,
                             "locks": [], "fungible_total": 0, "nft_locks": 0})
    a["locks"].append(k)
    if r["amount"]:
        a["fungible_total"] += float(r["amount"])
    if r["nft_count"]:
        a["nft_locks"] += 1

summary = {"rows": rows, "agg": [{**a, "tags": a["locks"][:5]} for a in agg.values()]}
json.dump(summary, open(f"{OUT}/jl_summary.json", "w"), indent=1)

# resources needing metadata
res_needed = sorted({r["resource"] for r in rows.values() if r["unlocked_at"] is None and r["resource"]})
print("resources with live/forever locks:", len(res_needed))
meta = {}
for i in range(0, len(res_needed), 20):
    r = entity_details(res_needed[i:i + 20], aggregation_level="Global",
                       opt_ins={"explicit_metadata": ["name", "symbol", "pool", "dapp_definition", "description"]})
    for it in r["items"]:
        md = {}
        for m in it.get("metadata", {}).get("items", []):
            md[m["key"]] = m["value"].get("typed", {}).get("value")
        meta[it["address"]] = md
    time.sleep(0.15)
json.dump(meta, open(f"{OUT}/jl_resource_metadata.json", "w"), indent=1)
for a in sorted(agg.values(), key=lambda x: -x["fungible_total"]):
    if a["category"] == "spent":
        continue
    nm = meta.get(a["resource"], {}).get("symbol") or meta.get(a["resource"], {}).get("name")
    print(f"{a['category']:11s} {a['resource'][:24]} {str(nm)[:18]:18s} amt={a['fungible_total']:.6f} nft_locks={a['nft_locks']} locks={len(a['locks'])}")
