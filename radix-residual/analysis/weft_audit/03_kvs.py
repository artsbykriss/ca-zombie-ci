#!/usr/bin/env python3
"""Fetch all Weft V2 sub-KVS contents at current state version."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import *

KVSS = {
    "price_feed_manager_entries": "internal_keyvaluestore_rdx1kpgamdkry93m0g6y0p6txdeyxrwq9f7fhaxpgg96x4h4y5kc642yc6",
    "loan_config_manager_entries": "internal_keyvaluestore_rdx1kqhrmxz9dltruje0z2flxy86v9gm58vs38y3kjqxcazhy63z94zmre",
    "collateral_config_manager_entries": "internal_keyvaluestore_rdx1krp789s9vy4rny9c6wsm2hs3nxgxxnhafxs2t2lv9qpkdze6rna8qe",
    "efficiency_group_manager_entries": "internal_keyvaluestore_rdx1kpcw9se76zuryjp2ju7jl3xk9mea32fgj7w83mxq8tx0fgl8a4w7mc",
    "resource_configs": "internal_keyvaluestore_rdx1kr89xu06dc83cqvevjs22hg202pkm4xmh5qeka29rc94r2af7vc55n",
    "collateral_assets": "internal_keyvaluestore_rdx1kpy6kzepwfpddlm23w6arsv40uxypn6dszqdf36sl3wgzwwn294qm0",
    "nft_collateral_assets": "internal_keyvaluestore_rdx1kztjqxdpc24thmhctrwjcuzvne390dqvml966xrj9nns49vadd7kqy",
    "price_cache": "internal_keyvaluestore_rdx1krnvw2lrk6jdhemskgsjldjahq2aatvycpwuuccaap93880hr2s0dh",
    "resource_type_cache": "internal_keyvaluestore_rdx1kqw5mfqmjjxm6uzx2evpumy22jjw65qa9d8r5xg5sgqpejyam9amag",
    "nft_resource_type_cache": "internal_keyvaluestore_rdx1kp0x2dwzmsw79t2medjk5duh88qqmkxryzqe62ryvhlansky2s4ha7",
    "nft_valuation_cache": "internal_keyvaluestore_rdx1kzvpfm08mv3gxtx3vc42lasq9kw4vg929eljp9u03ktkajwyh67eda",
    "liquidation_fees": "internal_keyvaluestore_rdx1kpk8h5t8xlcvkghtfnpnrarrd0sw0anf90p8mspju238ee4l4jtlz9",
    "loan_service_manager_entries": "internal_keyvaluestore_rdx1krqp74wz473l3d7v08m3v66kv46fe03aq5retc7hhy7ha9vgedfha7",
    "collateral_service_manager_entries": "internal_keyvaluestore_rdx1kzsa48ew4vwj7l3y0wdxkkgz6lrrg50lyultllruqzaqawkesf2gre",
    "isolation_group_manager_entries": "internal_keyvaluestore_rdx1kqc0xygg9aq4hxg9aa7m4cvr2n2xdx0em50du3myld434xtv8lzgfn",
    "loan_unit_ratio_cache": "internal_keyvaluestore_rdx1kpgl6hmg4nml9yhgh6adtxtljdelfkstsqwt5fwtzhzfj9nermchvu",
    "deposit_unit_ratio_cache": "internal_keyvaluestore_rdx1kzecg0lj4du9yl03dqge24yer28qy3mcjuqnrz22mpn0u8cvv7ywge",
    "pool_lending_service_manager_entries": "internal_keyvaluestore_rdx1krz350jhmvvuw2cctslmg3axnxagqas4muf5rxvfd8jcqru7s4v9a3",
    "pool_deposit_unit_lookup": "internal_keyvaluestore_rdx1krvgtms6a4erg0vmly6lx6pdskcxa4fnh8r9s3lhwh3q4m98zcnj46",
    "pool_resource_pools": "internal_keyvaluestore_rdx1kzjr763caq96j0kv883vy8gnf3jvrrp7dfm9zr5n0akryvzsxvyujc",
}

out = {}
for name, kvs in KVSS.items():
    try:
        keys = kvs_keys(kvs)
        data = kvs_data(kvs, keys)
        out[name] = {"kvs": kvs, "keys": keys, "data": data.get("entries", [])}
        print(f"{name}: {len(keys)} keys, {len(data.get('entries', []))} entries")
    except Exception as e:
        out[name] = {"kvs": kvs, "error": str(e)}
        print(f"{name}: ERROR {e}")
json.dump(out, open("weft_all_kvs_live.json", "w"), indent=1)
print("written weft_all_kvs_live.json")
