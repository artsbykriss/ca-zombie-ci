#!/usr/bin/env python3
"""Fetch RLP + proxy program accounts, programdata (upgrade authority) and ELF."""
import json, base64, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e, b58d

PROGS = {
    "rlp":   "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av",
    "proxy": "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C",
}

out = {"slot": rpc("getSlot", [])["result"], "programs": {}}
for name, prog in PROGS.items():
    v = rpc("getAccountInfo", [prog, {"encoding": "base64"}])["result"]["value"]
    d = base64.b64decode(v["data"][0])
    owner = v["owner"]
    pd_pub = b58e(d[4:36])
    v2 = rpc("getAccountInfo", [pd_pub, {"encoding": "base64"}])["result"]["value"]
    d2 = base64.b64decode(v2["data"][0])
    tag = int.from_bytes(d2[0:4], "little")
    slot = int.from_bytes(d2[4:12], "little")
    opt = d2[12]
    auth = b58e(d2[13:45]) if opt else None
    elf = d2[45:]
    fn = os.path.join(os.path.dirname(os.path.abspath(__file__)), f"{name}.so")
    open(fn, "wb").write(elf)
    out["programs"][name] = {
        "program_id": prog, "program_owner": owner, "program_acct_len": len(d),
        "programdata": pd_pub, "programdata_len": len(d2),
        "upgrade_tag": tag, "last_deploy_slot": slot, "upgrade_authority": auth,
        "elf_len": len(elf), "elf_magic": elf[:4].hex(),
    }
    print(f"[{name}] program {prog} owner={owner} pd={pd_pub} auth={auth} last_deploy_slot={slot} elf={len(elf)}")

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "programs.json"), "w"), indent=2)
print("slot", out["slot"])
