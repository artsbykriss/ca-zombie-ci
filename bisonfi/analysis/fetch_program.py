#!/usr/bin/env python3
"""Fetch BisonFi program + ProgramData accounts; write ELF + metadata (read-only)."""
import base64, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

PROG = "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi"
PROGDATA = "42snJ7ip4zKKsip3EtaMoBo8wzoRsQJSzgUSFXAVJFfG"
OUT = os.path.dirname(os.path.abspath(__file__))

def get_account(addr):
    r = rpc("getAccountInfo", [addr, {"encoding": "base64", "commitment": "confirmed"}])
    return r.get("result", {}).get("context", {}).get("slot"), r.get("result", {}).get("value")

slot_p, prog = get_account(PROG)
slot_d, pdata = get_account(PROGDATA)
print("slot(program)=", slot_p, "slot(programdata)=", slot_d)

def save(name, slot, acc):
    if not acc:
        print("MISSING", name); return None
    raw = base64.b64decode(acc["data"][0])
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(raw)
    meta = {k: v for k, v in acc.items() if k != "data"}
    meta["dataLen"] = len(raw)
    meta["slot"] = slot
    meta["sha256"] = __import__("hashlib").sha256(raw).hexdigest()
    with open(os.path.join(OUT, name + ".meta.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print(name, "len=", len(raw), "owner=", acc.get("owner"), "exec=", acc.get("executable"), "lamports=", acc.get("lamports"), "slot=", slot)
    return raw

prog_raw = save("bisonfi-program-account.bin", slot_p, prog)
pdata_raw = save("bisonfi-programdata-account.bin", slot_d, pdata)

if prog_raw:
    with open(os.path.join(OUT, "bisonfi-live.elf"), "wb") as f:
        f.write(prog_raw)
    print("program ELF magic:", prog_raw[:4])

if pdata_raw:
    # ProgramData layout: 0..4 tag(3), 4..12 slot, 12 opt(u8), 13..45 authority(32), 45..45+len ELF
    import struct
    tag = struct.unpack("<I", pdata_raw[:4])[0]
    last_deploy_slot = struct.unpack("<Q", pdata_raw[4:12])[0]
    has_auth = pdata_raw[12]
    auth = pdata_raw[13:45]
    b58 = None
    try:
        import base58  # optional
    except Exception:
        pass
    print("ProgramData tag=", tag, "last_deploy_slot=", last_deploy_slot, "has_auth=", has_auth)
    with open(os.path.join(OUT, "bisonfi-programdata-elf.bin"), "wb") as f:
        f.write(pdata_raw[45:])
    with open(os.path.join(OUT, "programdata-header.json"), "w") as f:
        json.dump({"tag": tag, "last_deploy_slot": last_deploy_slot, "has_auth": has_auth,
                   "authority_bytes_hex": auth.hex(), "pdata_len": len(pdata_raw)}, f, indent=1)
    print("ELF inside ProgramData magic:", pdata_raw[45:49])
