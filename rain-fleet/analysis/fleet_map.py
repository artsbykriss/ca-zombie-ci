#!/usr/bin/env python3
"""Fleet map: all programdata accounts by authority/size, with deploy dates + program IDs."""
import json, sys, time
import sol_rpc as S

BPF = S.BPF_UPGRADEABLE

def gpa(filters):
    return S.rpc("getProgramAccounts", [BPF, {"encoding": "base64", "filters": filters, "commitment": "finalized"}])

def auth_programs(auth):
    r = gpa([{"memcmp": {"offset": 13, "bytes": auth}}])
    return [(it["pubkey"], S.parse_programdata_account(it["account"]["data"][0])) for it in r]

def size_programs(size):
    r = gpa([{"dataSize": size}])
    return [(it["pubkey"], S.parse_programdata_account(it["account"]["data"][0])) for it in r]

def prog_id_for(pd_addr):
    r = gpa([{"dataSize": 36}, {"memcmp": {"offset": 4, "bytes": pd_addr}}])
    return [it["pubkey"] for it in r]

def blocktime(slot):
    try:
        return S.rpc("getBlockTime", [slot])
    except Exception:
        return None

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "map":
        auth = sys.argv[2]
        rows = auth_programs(auth)
        out = []
        for pd, info in rows:
            t = blocktime(info["last_deploy_slot"])
            pids = prog_id_for(pd)
            out.append({
                "programdata": pd,
                "program": pids[0] if pids else None,
                "n_program_accounts_matching": len(pids),
                "code_size": info["len"] - 45,
                "last_deploy_slot": info["last_deploy_slot"],
                "last_deploy_utc": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(t)) if t else None,
                "authority": info["authority"],
            })
            print(json.dumps(out[-1]))
        json.dump(out, open(f"fleet_{auth[:8]}.json", "w"), indent=1)
    elif cmd == "size":
        size = int(sys.argv[2])
        rows = size_programs(size)
        print("count", len(rows))
        for pd, info in rows:
            print(json.dumps({"programdata": pd, "code_size": info["len"] - 45, "slot": info["last_deploy_slot"], "auth": info["authority"]}))
