#!/usr/bin/env python3
"""Probe the three programs: executable status, upgrade authority."""
import json, base64, sys
from sol_rpc import get_account_info

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = ALPHABET[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

def b58decode(s: str) -> bytes:
    n = 0
    for ch in s:
        n = n * 58 + ALPHABET.index(ch)
    b = n.to_bytes((n.bit_length() + 7)//8, "big")
    pad = 0
    for ch in s:
        if ch == "1": pad += 1
        else: break
    return b"\x00"*pad + b

PROGRAMS = {
    "O13": ("DiversiFi", "3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk"),
    "O14": ("Overpass",  "WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum"),
    "O15": ("Zodial",    "zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"),
}

def main():
    out = {}
    for k,(name,pid) in PROGRAMS.items():
        r = get_account_info(pid)
        v = r.get("result", {}).get("value")
        if v is None:
            print(k, name, pid, "-> NOT FOUND", json.dumps(r)[:300]); continue
        data = base64.b64decode(v["data"][0])
        info = {"name": name, "program_id": pid, "executable": v.get("executable"),
                "owner": v.get("owner"), "lamports": v.get("lamports"),
                "data_len": len(data)}
        if len(data) >= 4:
            tag = int.from_bytes(data[:4], "little")
            info["state_tag"] = tag
            if tag == 2 and len(data) >= 36:
                pd_addr = b58encode(data[4:36])
                info["programdata_address"] = pd_addr
                pr = get_account_info(pd_addr)
                pv = pr.get("result", {}).get("value")
                if pv:
                    pdata = base64.b64decode(pv["data"][0])
                    # ProgramData layout: u32 tag(=3), u64 slot, u8 option, [32] upgrade auth
                    pinfo = {"programdata_owner": pv.get("owner"), "data_len": len(pdata)}
                    if len(pdata) >= 13:
                        pinfo["last_deploy_slot"] = int.from_bytes(pdata[4:12], "little")
                        has_auth = pdata[12]
                        pinfo["upgrade_authority_option"] = has_auth
                        if has_auth == 1 and len(pdata) >= 45:
                            pinfo["upgrade_authority"] = b58encode(pdata[13:45])
                    info["programdata"] = pinfo
        out[k] = info
        print(json.dumps(info, indent=2))
    with open("program_info.json", "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
