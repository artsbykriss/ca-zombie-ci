#!/usr/bin/env python3
"""Cross-validate Phase Stake pool: mint supply, reserve stake, epoch info."""
import json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, get_data, b58encode

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
RESERVE = "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2"
VLIST = "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821"
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"

out = {}

# epoch info
out["epoch"] = rpc("getEpochInfo", [])

# mint supply + info
mi = rpc("getAccountInfo", [MINT, {"encoding": "jsonParsed"}])
out["mint_account"] = mi["value"]

# reserve stake account
ri = rpc("getAccountInfo", [RESERVE, {"encoding": "jsonParsed"}])
out["reserve_stake"] = ri["value"]

# validator list raw
vo, vdata = get_data(VLIST)
out["vlist_owner"] = vo
out["vlist_len"] = len(vdata)
out["vlist_head_hex"] = vdata[:16].hex()
# ValidatorListHeader: account_type u8, max_validators u32
out["vlist_account_type"] = vdata[0]
out["vlist_max_validators"] = struct.unpack_from("<I", vdata, 1)[0]

# parse validator entries (73 bytes each, after 1+4=5 byte header)
LEN_ENTRY = 73
n = (len(vdata) - 5) // LEN_ENTRY
entries = []
for i in range(n):
    off = 5 + i * LEN_ENTRY
    e = vdata[off:off+LEN_ENTRY]
    vote = b58encode(e[0:32])
    active_lamports = struct.unpack_from("<Q", e, 32)[0]
    transient_seed = struct.unpack_from("<Q", e, 40)[0]
    transient_lamports = struct.unpack_from("<Q", e, 48)[0]
    status = e[56]
    validator_seed = struct.unpack_from("<I", e, 57)[0]
    # remaining 12 bytes unused (57+4=61, entry=73 -> 12 spare)
    entries.append(dict(vote=vote, active_lamports=active_lamports,
                        transient_seed=transient_seed, transient_lamports=transient_lamports,
                        status=status, validator_seed=validator_seed))
out["vlist_entries_count"] = n
out["vlist_entries_nonzero"] = [e for e in entries if e["active_lamports"] or e["transient_lamports"] or e["status"]]
out["vlist_entries_all"] = entries

json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/crossval.json", "w"), indent=2)
print(json.dumps({k: v for k, v in out.items() if k not in ("vlist_entries_all",)}, indent=2, default=str)[:4000])
print("entries:", n, "nonzero:", len(out["vlist_entries_nonzero"]))
for e in out["vlist_entries_nonzero"]:
    print(e)
