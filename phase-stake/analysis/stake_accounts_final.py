#!/usr/bin/env python3
"""Derive the pool's validator stake account(s) with correct seeds [vote, pool(,seed)]."""
import sys, json
sys.path.insert(0, ".")
from sol_util import b58decode, pda, rpc

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"
VOTE = "CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe"
a, b = pda([b58decode(VOTE), b58decode(POOL)], PROG)
v = rpc("getAccountInfo", [a, {"encoding": "jsonParsed"}])
res = {"stake_account": a, "bump": b, "lamports": v["value"]["lamports"], "parsed": v["value"]["data"]["parsed"]}
json.dump(res, open("stake_account_final.json", "w"), indent=2)
print(json.dumps(res, indent=2)[:1200])
