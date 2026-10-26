#!/usr/bin/env python3
"""Live state for marginfi-v2 (Project 0): groups, banks, vault balances. Read-only."""
import json, sys, os, hashlib, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import (get_program_accounts, get_account_info, get_slot, b58enc,
                 upgrade_authority, result)

PROG = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"

def disc(name):
    return hashlib.sha256(f"account:{name}".encode()).digest()[:8]

def b64(v):
    return base64.b64decode(v["data"][0]) if v else None

def main():
    slot = get_slot()
    out = {"slot": slot, "program": PROG}
    # groups
    d = disc("MarginfiGroup")
    groups = get_program_accounts(PROG, filters=[{"memcmp": {"offset": 0, "bytes": b58enc(d)}}])
    gl = []
    if isinstance(groups, list):
        for g in groups:
            raw = base64.b64decode(g["account"]["data"][0])
            gl.append({"pubkey": g["pubkey"], "space": g["account"]["space"],
                       "admin": b58enc(raw[8:40]),
                       "group_flags": int.from_bytes(raw[40:48], "little")})
    out["group_count"] = len(gl)
    out["groups"] = gl
    # banks
    d = disc("Bank")
    banks = get_program_accounts(PROG, filters=[{"memcmp": {"offset": 0, "bytes": b58enc(d)}}])
    bl = []
    if isinstance(banks, list):
        for b in banks:
            raw = base64.b64decode(b["account"]["data"][0])
            mint = b58enc(raw[8:40])
            grp = b58enc(raw[41:73])
            liq = b58enc(raw[112:144]) if len(raw) >= 178 else None
            ins = b58enc(raw[146:178]) if len(raw) >= 178 else None
            bl.append({"pubkey": b["pubkey"], "space": b["account"]["space"],
                       "mint": mint, "decimals": raw[40], "group": grp,
                       "liquidity_vault": liq, "insurance_vault": ins})
    out["bank_count"] = len(bl)
    out["banks"] = bl
    # upgrade authority
    out["upgrade"] = upgrade_authority(PROG)
    print(json.dumps(out, indent=1))
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           "live_state.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
