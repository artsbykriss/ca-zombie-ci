#!/usr/bin/env python3
"""Fleet enumeration: all programs under a given upgrade authority + all programdata
accounts of an exact code size. Read-only. Outputs JSON."""
import json, sys, time, base64, hashlib
import sol_rpc as S

BPF = S.BPF_UPGRADEABLE

def programs_by_authority(auth: str):
    res = S.rpc("getProgramAccounts", [BPF, {
        "encoding": "base64",
        "filters": [
            {"dataSize": 45},
            {"memcmp": {"offset": 13, "bytes": auth}},
        ],
        "commitment": "finalized",
    }])
    out = []
    for it in res:
        pd_addr = it["pubkey"]
        info = S.parse_programdata_account(it["account"]["data"][0])
        out.append({"programdata": pd_addr, **info})
    return out

def programs_by_size(size: int, cap=None):
    res = S.rpc("getProgramAccounts", [BPF, {
        "encoding": "base64",
        "filters": [{"dataSize": size}],
        "commitment": "finalized",
    }])
    out = []
    for it in res:
        info = S.parse_programdata_account(it["account"]["data"][0])
        out.append({"programdata": it["pubkey"], **info})
        if cap and len(out) >= cap:
            break
    return out

def program_id_from_programdata(pd_addr: str):
    """Reverse: the Program account whose data holds this programdata address."""
    res = S.rpc("getProgramAccounts", [BPF, {
        "encoding": "base64",
        "filters": [
            {"dataSize": 36},
            {"memcmp": {"offset": 4, "bytes": pd_addr}},
        ],
        "commitment": "finalized",
    }])
    return [it["pubkey"] for it in res]

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "byauth":
        auth = sys.argv[2]
        r = programs_by_authority(auth)
        print(json.dumps({"authority": auth, "count": len(r), "programdatas": r}, indent=1))
    elif cmd == "bysize":
        size = int(sys.argv[2])
        r = programs_by_size(size)
        print(json.dumps({"dataSize": size, "count": len(r), "programdatas": r}, indent=1))
    elif cmd == "toprog":
        for pd in sys.argv[2:]:
            print(pd, "->", program_id_from_programdata(pd))
