#!/usr/bin/env python3
"""TASK 3b: parse the getProgramAccounts(dataSize=611, memcmp account_type=1) result."""
import json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58encode

raw = json.load(open("/home/heisenberg/CA/phase-stake/analysis/gpa_type1.json"))
res = raw["response"]["result"]
import base64

def parse300(d):
    o = {}
    o["account_type"] = d[0]
    o["manager"] = b58encode(d[1:33])
    o["staker"] = b58encode(d[33:65])
    o["stake_deposit_authority"] = b58encode(d[65:97])
    o["stake_withdraw_bump_seed"] = d[97]
    o["validator_list"] = b58encode(d[98:130])
    o["reserve_stake"] = b58encode(d[130:162])
    o["pool_mint"] = b58encode(d[162:194])
    o["manager_fee_account"] = b58encode(d[194:226])
    o["token_program"] = b58encode(d[226:258])
    o["total_lamports"] = struct.unpack_from("<Q", d, 258)[0]
    o["pool_token_supply"] = struct.unpack_from("<Q", d, 266)[0]
    o["last_update_epoch"] = struct.unpack_from("<Q", d, 274)[0]
    return o

pools = []
for a in res:
    data_b64 = a["account"]["data"][0]
    d = base64.b64decode(data_b64)
    p = {"address": a["pubkey"], "lamports": a["account"]["lamports"], "owner": a["account"]["owner"],
         "data_len_slice": len(d)}
    p.update(parse300(d))
    p["nav_ratio"] = (p["total_lamports"] / p["pool_token_supply"]) if p["pool_token_supply"] else None
    pools.append(p)

pools.sort(key=lambda p: -p["total_lamports"])
json.dump({"endpoint": raw["endpoint"], "filter": raw["params"][1], "count": len(pools), "pools": pools},
          open("/home/heisenberg/CA/phase-stake/analysis/pools_scan.json", "w"), indent=2)

print("count:", len(pools))
print(f'{"pool":45s} {"mint":45s} {"TVL_SOL":>12s} {"supply_raw":>18s} {"NAV":>9s} {"last_ep":>7s} manager')
for p in pools:
    print(f'{p["address"]:45s} {p["pool_mint"]:45s} {p["total_lamports"]/1e9:12.2f} {p["pool_token_supply"]:18d} {str(round(p["nav_ratio"],4)) if p["nav_ratio"] else "n/a":>9s} {p["last_update_epoch"]:7d} {p["manager"][:12]}')

# Phase-relevant
print("\n--- Phase-named pools ---")
for p in pools:
    if p["address"].startswith(("phase", "aero")):
        print(json.dumps(p, indent=1))
print("\n--- pools sharing the Phase manager 7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1 ---")
for p in pools:
    if p["manager"] == "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1":
        print(p["address"], p["pool_mint"], p["total_lamports"]/1e9)
