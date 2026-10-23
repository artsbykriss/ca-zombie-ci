#!/usr/bin/env python3
"""Decode all live Cooldowns; then scan the RLP program's recent history for a real
`Withdraw` instruction and dump its exact account ordering."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
cools = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldowns.json")))
auths = {}
for c in cools:
    d = bytes.fromhex(c["hex"])
    authority = Pubkey.from_bytes(d[17:49])
    pool = d[49]
    idx = int.from_bytes(d[9:17], "little")
    unlock = int.from_bytes(d[50:58], "little")
    locked = int.from_bytes(d[58:66], "little")
    auths.setdefault(str(authority), []).append((c["pubkey"], pool, idx, unlock, locked))
    print(f"{c['pubkey']} auth={authority} pool={pool} idx={idx} unlock_ts={unlock} locked={locked}")

print("\nunique authorities:", len(auths))
for a, v in auths.items():
    print(" ", a, len(v))
json.dump({a: v for a, v in auths.items()},
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldown_auths.json"), "w"), indent=2)
