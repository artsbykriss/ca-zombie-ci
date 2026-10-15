#!/usr/bin/env python3
"""Recon 1: enumerate live state for Weft V2, JustLock, RlyFun. Read-only."""
import json
from rdx import *

OUT = {}
ls = ledger_state()
OUT["ledger"] = ls
print("ledger:", ls)

# ---------- RlyFun: all launches ----------
RLY_KVS = "internal_keyvaluestore_rdx1krtyftm7ly5fcwj7p9n4ksan9atxcvwhdpg3mnuc42atsdtc5nyu3v"
keys = kvs_keys(RLY_KVS)
print("rlyfun keys:", len(keys))
curves = []
cursor = None
page = 0
all_entries = []
remaining = keys
for i in range(0, len(keys), 100):
    batch = keys[i:i+100]
    data = kvs_data(RLY_KVS, batch)
    all_entries.extend(data["entries"])
print("rlyfun entries:", len(all_entries))
for e in all_entries:
    try:
        v = e["value"]["programmatic_json"]
        f = v.get("fields", [])
        curves.append({
            "key": e["key"]["programmatic_json"]["value"] if e["key"]["programmatic_json"].get("type") == "U64" else e["key"]["programmatic_json"],
            "fields": f,
        })
    except Exception as ex:
        curves.append({"raw": json.dumps(e)[:200], "err": str(ex)})
OUT["rlyfun_launches"] = curves
json.dump(OUT, open("recon1_rlyfun.json", "w"), indent=1)
print("sample curve entry:", json.dumps(curves[0])[:500])
