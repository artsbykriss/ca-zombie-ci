#!/usr/bin/env python3
"""Decode SPL stake-pool ValidatorList account (Borsh header + BigVec of ValidatorStakeInfo).
Layout: header{account_type u8, max_validators u32} = 5 bytes; BigVec{u32 len, items[80]}
ValidatorStakeInfo (80): active_stake_lamports u64, transient_stake_lamports u64, last_update_epoch u64,
  transient_seed_suffix u64, unused u32, validator_seed_suffix u32, status u8, pad[7], vote_account[32]
"""
import json, base64, struct, sys, time

STATUS = {0: "Active", 1: "DeactivatingTransient", 2: "ReadyForRemoval", 3: "DeactivatingValidator", 4: "DeactivatingAll"}

def decode(raw):
    account_type = raw[0]
    max_validators = struct.unpack_from('<I', raw, 1)[0]
    n = struct.unpack_from('<I', raw, 5)[0]
    out = {"account_type": account_type, "max_validators": max_validators, "len": n, "validators": []}
    import base58
    o = 9
    for i in range(n):
        active, transient, lue, tss = struct.unpack_from('<QQQQ', raw, o)
        unused, vss = struct.unpack_from('<II', raw, o + 32)
        status = raw[o + 40]
        vote = base58.b58encode(raw[o + 48:o + 80]).decode()
        out["validators"].append({"vote": vote, "active_lamports": active, "transient_lamports": transient,
                                  "last_update_epoch": lue, "transient_seed": tss,
                                  "validator_seed": vss, "status": STATUS.get(status, status)})
        o += 80
    out["_consumed"] = o
    out["_total"] = len(raw)
    return out

if __name__ == "__main__":
    d = json.load(open(sys.argv[1]))["result"]["value"]
    raw = base64.b64decode(d["data"][0])
    v = decode(raw)
    v["_owner"] = d["owner"]
    print(json.dumps(v, indent=1))
