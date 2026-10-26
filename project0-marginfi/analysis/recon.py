#!/usr/bin/env python3
"""Recon: programdata size, upgrade auth on/off-curve, current slot."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, get_slot, upgrade_authority, is_on_curve_b58

TARGETS = {
    "project0": "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA",
    "streamflow_stake": "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH",
}
slot = get_slot()
print("current slot:", slot)
for name, prog in TARGETS.items():
    ua = upgrade_authority(prog)
    pd = get_account_info(ua["programdata"])
    raw_size = len(pd["data"][0]) * 3 // 4 if pd else None
    auth = ua["upgrade_authority"]
    onc = is_on_curve_b58(auth) if auth and auth != "NONE (immutable)" else None
    print(json.dumps({"name": name, "program": prog,
                      "programdata": ua["programdata"],
                      "programdata_space": (pd or {}).get("space"),
                      "elf_bytes_approx": raw_size,
                      "last_deploy_slot": ua["last_deploy_slot"],
                      "upgrade_authority": auth, "authority_on_curve": onc}))
