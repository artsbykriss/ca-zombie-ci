#!/usr/bin/env python3
"""Fetch all Wefty NFT ids + data (positions)."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post

CDP_RES = "resource_rdx1nt22yfvhuuhxww7jnnml5ec3yt5pkxh0qlghm6f0hz46z2wfk80s9r"

ids = []
cursor = None
sv = None
while True:
    body = {"resource_address": CDP_RES, "limit_per_page": 100}
    if cursor:
        body["cursor"] = cursor
        body["at_ledger_state"] = {"state_version": sv}
    page = post("/state/non-fungible/ids", body)
    if sv is None:
        sv = page["ledger_state"]["state_version"]
    ids.extend(page["non_fungible_ids"]["items"])
    cursor = page["non_fungible_ids"].get("next_cursor")
    if not cursor:
        break
print("ids total:", len(ids))
json.dump(ids, open("weft_cdp_nft_ids.json", "w"), indent=1)

# data batches of 50
data = []
for i in range(0, len(ids), 50):
    batch = ids[i:i+50]
    page = post("/state/non-fungible/data", {"resource_address": CDP_RES, "non_fungible_ids": batch})
    data.extend(page.get("non_fungible_ids", []))
    if (i // 50) % 5 == 0:
        print("fetched", i + len(batch))
json.dump(data, open("weft_cdp_nft_data.json", "w"), indent=1)
print("data items:", len(data))
print(json.dumps(data[0], indent=1)[:1200])
