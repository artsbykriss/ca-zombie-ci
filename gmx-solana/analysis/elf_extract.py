#!/usr/bin/env python3
"""Extract the deployed store-program ELF from programdata and write it to disk (read-only RPC)."""
import sys, os, base64, hashlib, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, b58enc, get_slot

STORE = "Gmso1uvJnLbawvw7yezdfCDcPydwW2s2iqG3w6MDucLo"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "store_deployed.elf")

def main():
    slot = get_slot()
    v = get_account_info(STORE)
    raw = base64.b64decode(v["data"][0])
    progdata = b58enc(raw[4:36])
    pv = get_account_info(progdata)
    praw = base64.b64decode(pv["data"][0])
    deploy_slot = int.from_bytes(praw[4:12], "little")
    auth = b58enc(praw[13:45]) if praw[12] == 1 else "NONE"
    elf = praw[45:]
    e_shoff = int.from_bytes(elf[0x28:0x30], "little")
    e_shentsize = int.from_bytes(elf[0x3a:0x3c], "little")
    e_shnum = int.from_bytes(elf[0x3c:0x3e], "little")
    elf_len = e_shoff + e_shentsize * e_shnum
    with open(OUT, "wb") as f:
        f.write(elf[:elf_len])
    meta = {
        "observed_slot": slot,
        "program": STORE,
        "programdata": progdata,
        "deploy_slot": deploy_slot,
        "upgrade_authority": auth,
        "allocated_space": pv.get("space"),
        "elf_len": elf_len,
        "sha256_trunc": hashlib.sha256(elf[:elf_len]).hexdigest(),
        "sha256_full_alloc": hashlib.sha256(elf).hexdigest(),
        "elf_path": OUT,
    }
    print(json.dumps(meta, indent=2))
    with open(OUT + ".meta.json", "w") as f:
        json.dump(meta, f, indent=2)

if __name__ == "__main__":
    main()
