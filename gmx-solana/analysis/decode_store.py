#!/usr/bin/env python3
"""Decode the GMX-Solana Store account: admin authority, roles, members, token_map (read-only)."""
import base64, json, os, sys, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_account_info, b58dec, b58enc, is_on_curve_b58

STORE = "CTDLvGGXnoxvqLyTpGzdGLg9pD6JexKxKXSV8tqqo8bN"
HERE = os.path.dirname(os.path.abspath(__file__))
MAX_ROLES, MAX_MEMBERS = 32, 64

def fixed_str(b):
    return b.split(b"\x00")[0].decode("utf-8", "replace")

def main():
    v = get_account_info(STORE)
    raw = base64.b64decode(v["data"][0])
    out = {"store": STORE, "len": len(raw), "lamports": v["lamports"]}

    # locate token_map by known pubkey from prior scan
    tm = b58dec("7cEiyyEB2VGMtnKLb7Ro7SsJKYZVBZjpS8ihBD8jR938")
    off = raw.find(tm)
    authority = b58enc(raw[off - 64:off - 32])
    next_authority = b58enc(raw[off - 32:off])
    out["token_map"] = b58enc(tm)
    out["authority"] = authority
    out["authority_on_curve"] = is_on_curve_b58(authority)
    out["next_authority"] = next_authority

    role_off = 80
    members_off = role_off + MAX_ROLES * 66 + 4
    # roles
    roles = {}
    for i in range(MAX_ROLES):
        e = role_off + i * 66
        key = raw[e:e + 32]
        name = fixed_str(raw[e + 32:e + 64])
        enabled = raw[e + 64]
        index = raw[e + 65]
        if name and key != b"\x00" * 32:
            roles[index] = {"name": name, "enabled": enabled == 0xFF}
    out["roles_enabled"] = roles
    # members
    members = []
    for i in range(MAX_MEMBERS):
        e = members_off + i * 36
        pk = b58enc(raw[e:e + 32])
        bitmap = int.from_bytes(raw[e + 32:e + 36], "little")
        if bitmap:
            members.append({"member": pk, "bitmap": bitmap,
                            "roles": sorted(roles.get(b, {"name": f"bit{b}"})["name"]
                                            for b in range(32) if bitmap >> b & 1),
                            "on_curve": is_on_curve_b58(pk)})
    out["members"] = members
    print(json.dumps(out, indent=2))
    with open(os.path.join(HERE, "store_decoded.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
