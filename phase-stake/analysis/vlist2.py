#!/usr/bin/env python3
"""Validator list parse with correct ValidatorStakeInfo layout:
  0..8 active_lamports, 8..16 transient_lamports, 16..24 last_update_epoch,
  24..32 transient_seed, 32..36 unused, 36..40 validator_seed, 40 status, 41..73 vote."""
import json, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, get_data, b58encode, b58decode, pda

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"
VLIST = "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821"

_, vdata = get_data(VLIST)
print("len:", len(vdata))
print("account_type:", vdata[0], "max_validators:", struct.unpack_from("<I", vdata, 1)[0])
field4 = struct.unpack_from("<I", vdata, 5)[0]
print("u32@5:", field4)

STATUS = {0: "Active", 1: "DeactivatingTransient", 2: "ReadyForRemoval",
          3: "DeactivatingValidator", 4: "DeactivatingAll"}

region = vdata[9:]
n = len(region) // 73
entries = []
for i in range(n):
    e = region[i*73:(i+1)*73]
    ent = dict(idx=i,
               active_lamports=struct.unpack_from("<Q", e, 0)[0],
               transient_lamports=struct.unpack_from("<Q", e, 8)[0],
               last_update_epoch=struct.unpack_from("<Q", e, 16)[0],
               transient_seed=struct.unpack_from("<Q", e, 24)[0],
               unused=struct.unpack_from("<I", e, 32)[0],
               validator_seed=struct.unpack_from("<I", e, 36)[0],
               status=STATUS.get(e[40], e[40]),
               vote=b58encode(e[41:73]))
    entries.append(ent)

used = [e for e in entries if e["active_lamports"] or e["transient_lamports"] or e["transient_seed"] or e["validator_seed"] or e["status"] != "Active" or e["vote"].strip("1")]
# "vote.strip('1')" filters all-zero pubkeys
print("nonzero entries:", len(used))
for e in used:
    print(e)
json.dump(dict(max_validators=struct.unpack_from('<I', vdata, 1)[0], used=used),
          open("/home/heisenberg/CA/phase-stake/analysis/vlist_used.json", "w"), indent=2)

# derive stake PDAs for used entries (correct field names now)
res = []
tot_a = tot_t = 0
for e in used:
    vote = e["vote"]
    # main validator stake account: seeds [b"stake", pool, vote] when validator_seed==0 else +u32 LE
    if e["validator_seed"] == 0:
        seeds = [b"stake", b58decode(POOL), b58decode(vote)]
    else:
        seeds = [b"stake", b58decode(POOL), b58decode(vote), struct.pack("<I", e["validator_seed"])]
    a, b = pda(seeds, PROG)
    ai = rpc("getAccountInfo", [a, {"encoding": "jsonParsed"}])
    v = ai["value"]
    rec = dict(kind="stake", vote=vote, seed=e["validator_seed"], addr=a, bump=b,
               exists=v is not None, lamports=(v or {}).get("lamports", 0))
    if v and v["data"] and isinstance(v["data"], dict) and "parsed" in v["data"]:
        rec["parsed"] = v["data"]["parsed"]
    res.append(rec)
    tot_a += rec["lamports"]
    if e["transient_seed"]:
        seeds2 = [b"transient", b58decode(POOL), b58decode(vote), struct.pack("<Q", e["transient_seed"])]
        a2, b2 = pda(seeds2, PROG)
        ai2 = rpc("getAccountInfo", [a2, {"encoding": "jsonParsed"}])
        v2 = ai2["value"]
        rec2 = dict(kind="transient", vote=vote, seed=e["transient_seed"], addr=a2, bump=b2,
                    exists=v2 is not None, lamports=(v2 or {}).get("lamports", 0))
        res.append(rec2)
        tot_t += rec2["lamports"]

print("sum stake lamports:", tot_a, "=", tot_a/1e9, "SOL")
print("sum transient lamports:", tot_t, "=", tot_t/1e9, "SOL")
json.dump(dict(accounts=res, sum_stake=tot_a, sum_transient=tot_t),
          open("/home/heisenberg/CA/phase-stake/analysis/stake_accounts.json", "w"), indent=2)
for r in res:
    print(r["kind"], r["vote"], "seed", r["seed"], "->", r["addr"], "exists", r["exists"], r["lamports"]/1e9 if r["lamports"] else 0, "SOL")
