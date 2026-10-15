#!/usr/bin/env python3
"""Derive pool PDAs correctly: stake=[vote,pool(,seed)], transient=[b'transient',vote,pool,seed],
   withdraw auth=[pool,b'withdraw'], deposit auth=[pool,b'deposit']."""
import json, sys, struct, hashlib
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, get_data, b58encode, b58decode, pda, on_curve

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"

# 1) withdraw authority check: [pool, b"withdraw"] find_program_address
wa, wb = pda([b58decode(POOL), b"withdraw"], PROG)
print("withdraw authority PDA:", wa, "bump:", wb)
print("expected (reserve staker/mint auth): 9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa")
da, db = pda([b58decode(POOL), b"deposit"], PROG)
print("deposit authority PDA:", da, "bump:", db)

# 2) stake account for the active validator (seed=0)
VOTE = "CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe"
a, b = pda([b58decode(VOTE), b58decode(POOL)], PROG)
print("stake PDA for vote:", a, "bump:", b)
v = rpc("getAccountInfo", [a, {"encoding": "jsonParsed"}])
print(json.dumps(v, indent=2, default=str)[:1500])

# 3) authority accounts: on-curve?
for name, addr in [
    ("manager", "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1"),
    ("staker", "DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK"),
    ("stake_deposit_authority", "DTws8vTwkJ1U1gpfgtbLsxydVgnDkLBoB9n1KYvw27BT"),
    ("sol_withdraw_authority", "phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d"),
]:
    try:
        raw = b58decode(addr)
        oc = on_curve(raw) if len(raw) == 32 else None
    except Exception as e:
        oc = f"err {e}"
    acc = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
    val = acc["value"]
    print(f"{name}: {addr} on_curve={oc} exists={val is not None} "
          f"owner={val['owner'] if val else None} executable={val['executable'] if val else None} "
          f"lamports={val['lamports'] if val else 0} datalen={len(val['data'][0]) if val else 0}")
