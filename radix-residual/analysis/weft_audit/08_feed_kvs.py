#!/usr/bin/env python3
"""Dump default PriceFeed internals: prices KVS + registered_resources KVS."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import *

FEED1_PRICES = "internal_keyvaluestore_rdx1kq80eygwcpnlrpu3pgkxg5pz2d6yj9ycfurdnxyrwlmxc64v2y7dxz"
FEED1_REG = "internal_keyvaluestore_rdx1krpe8jgf5rv0s4n3f7ua73rd5twtkmn3v5gmmf7f4vfpqfahk0694d"
FEED2_PRICES = "internal_keyvaluestore_rdx1kznvj8n3rtlvytlgtny8rdcm3rkmn20ngrenmzegxg9nl7jgv9qm8e"
FEED2_REG = "internal_keyvaluestore_rdx1krw7f0cxe8rv0pgyldz66m3j3dy4vhhg5nuv0lrgelqj9dfs8jtfdg"

out = {}
for tag, kvs in (("feed1_prices", FEED1_PRICES), ("feed1_registered", FEED1_REG),
                 ("feed2_prices", FEED2_PRICES), ("feed2_registered", FEED2_REG)):
    keys = kvs_keys(kvs)
    data = kvs_data(kvs, keys) if keys else {"entries": []}
    out[tag] = {"keys": keys, "entries": data.get("entries", [])}
    print(tag, "keys:", len(keys), "entries:", len(data.get("entries", [])))
json.dump(out, open("weft_feeds_kvs.json", "w"), indent=1)

import datetime
for tag in ("feed1_prices", "feed2_prices"):
    print("#" * 100, tag)
    for e in out[tag]["entries"]:
        k = e["key"].get("programmatic_json") or {}
        v = e["value"].get("programmatic_json") or {}
        keyval = k.get("value") or json.dumps(k)[:80]
        vf = {f.get("field_name"): f.get("value") for f in v.get("fields", [])}
        ts = int(vf.get("timestamp", 0))
        print(f"  {keyval} -> price={vf.get('price') or vf} ts={datetime.datetime.utcfromtimestamp(ts).isoformat() if ts else None}")
for tag in ("feed1_registered", "feed2_registered"):
    print("#" * 100, tag)
    for e in out[tag]["entries"]:
        print("  key:", json.dumps(e["key"].get("programmatic_json"))[:200])
        print("  val:", json.dumps(e["value"].get("programmatic_json"))[:400])
