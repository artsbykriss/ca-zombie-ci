#!/usr/bin/env python3
"""RadLock: verify components from the live app bundle and dump their live state."""
import json
import sys

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details, fungibles, kvs_keys, kvs_data, ledger_state  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
RADLOCK_PKG = "package_rdx1pk65frtcahcv0tnllnmucshajj7jl2q3nga0ds9de900nh9yc7vtsq"
COMPONENTS = [
    "component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs",
    "component_rdx1crn49lcmzyuqpz4lgx8fulegk4pdzjz89lhegs4g5attrgxqjp4amc",
    "component_rdx1cp7vsz98w06urq3n00rf9xz9jrlppyk0sukqrm4kvqvkjwucne6puh",
]
RESOURCES = [
    "resource_rdx1thy5r0vgfk7gckjcsrld9jlmasd95mvckyffwkwdpplx0av582as3t",
    "resource_rdx1t5rrujkldrzhrl4pu3ftt8hltdft8lrxcwqqv90nyu5exnhwu6k28m",
    "resource_rdx1th5shllnhx33m5jkcqxsrgztp72yuxpg54cyxj2vcj3lpdup7f33ff",
    "resource_rdx1nf2ddsqmp9n0y4kl8lgege709hxkemahpktdtzkcnay7l76upssq9f",
    "resource_rdx1nfkacdapa9j2wr6jj874f0x07shygxheaj5hew7a5c8348fth6e6vx",
    "resource_rdx1nfkwleqccre92w8rwy235ahkv8yvlrkhjhwjndnry20qf5ht4xt6hg",
    "resource_rdx1ng3hxz66dklc8n7snhdfr8kzkdhgepss7w4qpnqe8mpuv8mq0hxhey",
]
DAPP_DEF = "account_rdx12xtayjlrzs0d9rga27w48256d98ycgrpde6yrqpmavmyrr0e4svsqy"

ls = ledger_state()
print("state_version", ls)

comp_raw = entity_details(COMPONENTS, aggregation_level="Global",
                          opt_ins={"non_fungible_include_nfdata": True})
json.dump(comp_raw, open(f"{OUT}/radlock_components_state.json", "w"), indent=1)
comp_summary = []
for it in comp_raw["items"]:
    d = it.get("details", {})
    rec = {"address": it["address"], "blueprint": d.get("blueprint_name"),
           "package": d.get("package_address"),
           "is_radlock": d.get("package_address") == RADLOCK_PKG,
           "state": d.get("state"),
           "fungibles": [
               {"resource": f["resource_address"], "amount": f["amount"]}
               for f in it.get("fungible_resources", {}).get("items", [])
               if f["amount"] != "0"],
           "nfts": [
               {"resource": f["resource_address"], "amount": f["amount"]}
               for f in it.get("non_fungible_resources", {}).get("items", [])
               if f["amount"] != "0"],
           }
    comp_summary.append(rec)
    print(rec["address"], "|", rec["blueprint"], "| radlock:", rec["is_radlock"])
json.dump({"ledger_state": ls, "components": comp_summary},
          open(f"{OUT}/radlock_components_summary.json", "w"), indent=1)

res_raw = entity_details(RESOURCES, aggregation_level="Global",
                         opt_ins={"explicit_metadata": ["name", "symbol", "description"]})
json.dump(res_raw, open(f"{OUT}/radlock_resources_state.json", "w"), indent=1)
for it in res_raw["items"]:
    d = it.get("details", {})
    md = {m["key"]: m["value"].get("typed", {}).get("value")
          for m in it.get("metadata", {}).get("items", [])}
    print(it["address"][:44], d.get("type"), "supply:", d.get("total_supply"),
          "| name:", md.get("name"), "| symbol:", md.get("symbol"))

# dapp definition account metadata (paired dApps)
dd = entity_details([DAPP_DEF], opt_ins={"explicit_metadata": ["name", "claimed_entities"]})
json.dump(dd, open(f"{OUT}/radlock_dapp_def.json", "w"), indent=1)
print("dapp def fetched")
