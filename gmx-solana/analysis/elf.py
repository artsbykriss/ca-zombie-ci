#!/usr/bin/env python3
"""Dump deployed program ELF: sha256, size, ELF header, upgrade authority. Read-only."""
import json, sys, os, base64, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, get_slot, is_on_curve_b58

def elf_of(prog):
    v = get_account_info(prog)
    if not v: return {"program": prog, "error": "no account"}
    raw = base64.b64decode(v["data"][0])
    tag = int.from_bytes(raw[0:4], "little")
    if tag == 2:  # Program -> points to programdata
        from sol import b58enc
        progdata = b58enc(raw[4:36])
        pv = get_account_info(progdata)
        praw = base64.b64decode(pv["data"][0])
        slot = int.from_bytes(praw[4:12], "little")
        auth = b58enc(praw[13:45]) if praw[12] == 1 else "NONE"
        elf = praw[45:]
        # ELF size from section headers
        e_shoff = int.from_bytes(elf[0x28:0x30], "little")
        e_shentsize = int.from_bytes(elf[0x3a:0x3c], "little")
        e_shnum = int.from_bytes(elf[0x3c:0x3e], "little")
        elf_len = e_shoff + e_shentsize * e_shnum if e_shnum else None
        return {"program": prog, "programdata": progdata,
                "allocated_space": pv.get("space"),
                "elf_len_from_shdrs": elf_len,
                "elf_sha256_full_alloc": hashlib.sha256(elf).hexdigest(),
                "elf_sha256_trunc": hashlib.sha256(elf[:elf_len] if elf_len else elf).hexdigest(),
                "last_deploy_slot": slot, "upgrade_authority": auth,
                "authority_on_curve": is_on_curve_b58(auth) if auth != "NONE" else None,
                "elf_prefix": base64.b64encode(elf[:16]).decode()}
    return {"program": prog, "tag": tag, "owner": v.get("owner"), "space": v.get("space")}

if __name__ == "__main__":
    print("slot", get_slot())
    for p in sys.argv[1:]:
        print(json.dumps(elf_of(p)))
