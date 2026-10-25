#!/usr/bin/env python3
"""Recon 1: program accounts, upgrade authority, ELF hashes for Streamflow stake
+ reward-pool programs (and probe for the vesting program). Read-only keyless RPC."""
import json, os, sys, base64, hashlib, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import (get_account_info, get_program_accounts, get_slot, b58enc,
                 upgrade_authority, is_on_curve_b58, b58dec, find_program_address)

PROGS = {
    "stake":  "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH",
    "reward": "RWRDdfRbi3339VgKxTAXg4cjyniF7cbhNbMxZWiSKmj",
    "reward_dyn": "RWRDyfZa6Rk9UYi85yjYYfGmoUqffLqjo6vZdFawEez",
    "governor": "GVERNASJFxi8vjjJtwCKYQTeN51XsV1y2B1ap1GtKrKR",
    "fee_mgr": "FEELzfBhsWXTNJX53zZcDVfRNoFYZQ6cZA3jLiGVL16V",
    "vesting?": "strmRqUCoQUgGUan5YhzUZa6KqdzwX5L6FpUxfmKg5m",
}

out = {"slot": None, "programs": {}}
for name, pid in PROGS.items():
    try:
        v = get_account_info(pid)
        if not v:
            out["programs"][name] = {"program": pid, "exists": False}
            continue
        raw = base64.b64decode(v["data"][0])
        tag = int.from_bytes(raw[0:4], "little")
        rec = {"program": pid, "exists": True, "owner": v.get("owner"),
               "space": v.get("space"), "tag": tag}
        if tag == 2 and len(raw) >= 36:
            pd = b58enc(raw[4:36])
            pv = get_account_info(pd)
            praw = base64.b64decode(pv["data"][0])
            slot = int.from_bytes(praw[4:12], "little")
            auth = b58enc(praw[13:45]) if praw[12] == 1 else "NONE"
            elf = praw[45:]
            e_shoff = int.from_bytes(elf[0x28:0x30], "little")
            e_shentsize = int.from_bytes(elf[0x3a:0x3c], "little")
            e_shnum = int.from_bytes(elf[0x3c:0x3e], "little")
            elf_len = e_shoff + e_shentsize * e_shnum if e_shnum else None
            rec.update({
                "programdata": pd,
                "programdata_alloc": pv.get("space"),
                "upgrade_authority": auth,
                "authority_on_curve": (is_on_curve_b58(auth) if auth != "NONE" else None),
                "last_deploy_slot": slot,
                "elf_len": elf_len,
                "elf_sha256_trunc": hashlib.sha256(elf[:elf_len] if elf_len else elf).hexdigest(),
                "elf_sha256_full_alloc": hashlib.sha256(elf).hexdigest(),
            })
        out["programs"][name] = rec
    except Exception as e:
        out["programs"][name] = {"program": pid, "error": f"{type(e).__name__}: {e}"}

out["slot"] = get_slot()
print(json.dumps(out, indent=1))
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "programs.json"), "w") as f:
    json.dump(out, f, indent=1)
