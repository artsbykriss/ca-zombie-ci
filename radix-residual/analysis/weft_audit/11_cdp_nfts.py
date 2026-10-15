#!/usr/bin/env python3
"""Fetch CDP (Wefty) NFT ids and data; inspect resource shape."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details

CDP_RES = "resource_rdx1nt22yfvhuuhxww7jnnml5ec3yt5pkxh0qlghm6f0hz46z2wfk80s9r"

r = entity_details([CDP_RES], opt_ins={"explicit_metadata": ["name", "symbol", "description"]})
json.dump(r, open("weft_cdp_resource.json", "w"), indent=1)
it = r["items"][0]
print("CDP resource details keys:", list(it.get("details", {}).keys()))
det = it["details"]
print("blueprint:", det.get("blueprint_name"), det.get("blueprint_version"))
print("total_supply:", det.get("total_supply"), "| total_non_fungible_ids:", det.get("total_non_fungible_ids"))
print("non_fungible_resources:", json.dumps(it.get("non_fungible_resources"))[:300])

# NFT ids
ids = []
cursor = None
while True:
    body = {"resource_address": CDP_RES, "limit_per_page": 100}
    if cursor:
        body["cursor"] = cursor
    page = post("/state/non-fungible/ids", body)
    ids.extend(page.get("items", []))
    cursor = page.get("next_cursor")
    if not cursor:
        break
print("NFT ids fetched:", len(ids))
json.dump(ids, open("weft_cdp_nft_ids.json", "w"), indent=1)
print("first ids:", json.dumps(ids[:5])[:500])
