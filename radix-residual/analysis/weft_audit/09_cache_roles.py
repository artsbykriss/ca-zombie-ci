#!/usr/bin/env python3
"""Compare market price_cache vs feed1 live prices; inspect CDP resource; pool roles."""
import json, sys, datetime
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import *

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
CDP_RES = "resource_rdx1nt22yfvhuuhxww7jnnml5ec3yt5pkxh0qlghm6f0hz46z2wfk80s9r"

d = json.load(open("weft_all_kvs_live.json"))
feeds = json.load(open("weft_feeds_kvs.json"))

# feed1 live prices (tokens) & registered types
feed1p = {}
for e in feeds["feed1_prices"]["entries"]:
    k = e["key"].get("programmatic_json") or {}
    v = e["value"].get("programmatic_json") or {}
    vf = {f.get("field_name"): f.get("value") for f in v.get("fields", [])}
    feed1p[k.get("value")] = (vf.get("price"), vf.get("timestamp"))
feed1reg = {}
for e in feeds["feed1_registered"]["entries"]:
    k = e["key"].get("programmatic_json") or {}
    v = e["value"].get("programmatic_json") or {}
    feed1reg[k.get("value")] = v.get("variant_name")

# market price cache: key is raw_hex-encoded resource address? print keys differently
print("### MARKET PRICE CACHE (key -> value, age)")
name = {}
import re
for e in d["price_cache"]["data"]:
    kj = e["key"].get("programmatic_json")
    v = e["value"]["programmatic_json"]
    vf = {f.get("field_name"): f.get("value") for f in v.get("fields", [])}
    ts = int(vf.get("timestamp") or 0)
    if kj and kj.get("type_name") == "ResourceAddress":
        key = kj.get("value")
    else:
        # raw hex: 80-prefixed address bytes; try decode via later mapping
        key = "hex:" + e["key"]["raw_hex"][:20]
    age = (1792057976 - ts)
    print(f"  {key} -> {vf.get('cached_value')} age={(age/3600):.1f}h feed={feed1p.get(key, ('-','-'))[0] if key in feed1p else '-'} reg={feed1reg.get(key,'-') if key in feed1reg else '-'}")

print()
print("### CDP resource details")
r = entity_details([CDP_RES], opt_ins={"explicit_metadata": ["name", "symbol", "description"]})
it = r["items"][0]
det = it["details"]
print("blueprint:", det.get("blueprint_name"), "| nft resources:", json.dumps(it.get("non_fungible_resources"))[:500])
meta = [(m["key"], m["value"].get("typed", {}).get("value")) for m in it.get("metadata", {}).get("items", [])]
print("metadata:", meta)
print("roles:", [ra["role_key"]["name"] for ra in det.get("role_assignments", {}).get("entries", [])])

print()
print("### POOL roles")
d2 = json.load(open("weft_entities_live.json"))
for it in d2["items"]:
    if it["address"].startswith("component_rdx1czmr"):
        for ra in it["details"].get("role_assignments", {}).get("entries", []):
            rr = ra["assignment"].get("explicit_rule") or {}
            print("  ", ra["role_key"]["name"], rr.get("type"), json.dumps(rr.get("access_rule", {}))[:150], "updaters:", [u["name"] for u in ra.get("updater_roles", [])])
