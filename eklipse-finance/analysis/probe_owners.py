#!/usr/bin/env python3
"""Probe the 9 Eklipse 'owner' contracts + staking contract: ERC20 + Curve-V1 method fingerprints."""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from kaia_rpc import rpc, rpc_many, dec_uint, dec_str, dec_addr

BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print(f"block={BLOCK}", flush=True)

OWNERS = [
    "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4",
    "0xe59234EeDC854b3b37D48EFd8a529069C3990F83",
    "0xddA06aaB425a1A390c131F790A56AB3380e3B7EC",
    "0x7f352a4332fAD433D381d700118f8C9b0A1E1abb",
    "0xB1b782f2D30505e9984e37e00C6494437d94c223",
    "0x75Dc33f8247245E8E08852E68E7f275E2a41fD40",
    "0x323fdda29fa2B8028eF9Fb48c1D45e5A39214D9A",
    "0x5B4ed8321ea13047195104037798f29257EAc28c",
    "0x29c6Eb808020Ef4889A9f25d35b69edBAfB0C78e",
    "0xD067C3b871ee9E07BA4205A8F96c182baBBA6c58",
    "0x625ae9043e8730c4a1e30b36838502fb90e1d3c2",
]
# sig -> key
PROBES = {
    "0x06fdde03": "name",
    "0x95d89b41": "symbol",
    "0x313ce567": "decimals",
    "0x18160ddd": "totalSupply",
    "0xf446c1d0": "A()",
    "0xddca3f43": "fee()",
    "0xbb7b8b80": "get_virtual_price()",
    "0x8da5cb5b": "owner()",
    "0xf851a440": "admin()",
    "0x5c975abb": "paused()",
    "0xc6610657_0": "coins(0)",
    "0xc6610657_1": "coins(1)",
    "0xc6610657_2": "coins(2)",
    "0xc6610657_3": "coins(3)",
    "0x4903b0d1_0": "balances(0)",
    "0x4903b0d1_1": "balances(1)",
    "0x4903b0d1_2": "balances(2)",
    "0x4903b0d1_3": "balances(3)",
    "0xfc0c546a": "token()",
    "0x72f702f3": "stakingToken()",
    "0xf7c618c1": "rewardToken()",
    "0xbab4ca3b": "stakingContract()",
    "0x4cf088d9": "staking()",
    "0x6f5f9e6b": "rewardPool()",
}

def data_of(key):
    if key.startswith("coins("):
        idx = int(key[6]); return "0xc6610657" + hex(idx)[2:].rjust(64, "0")
    if key.startswith("balances("):
        idx = int(key[9]); return "0x4903b0d1" + hex(idx)[2:].rjust(64, "0")
    rev = {v: k for k, v in PROBES.items() if "_" not in k}
    return rev[key]

ADDR_KEYS = {"owner()", "admin()", "token()", "stakingToken()", "rewardToken()", "stakingContract()", "staking()", "rewardPool()"}
calls, keys = [], []
for o in OWNERS:
    calls.append(("eth_getCode", [o, BH])); keys.append((o, "__code"))
    for k in PROBES:
        if k.startswith("coins(") or k.startswith("balances("):
            d = data_of(k)
        else:
            d = PROBES[k]
        calls.append(("eth_call", [{"to": o, "data": d}, BH])); keys.append((o, k))

res = rpc_many(calls, workers=8)
out = {}
for (o, k), r in zip(keys, res):
    rec = out.setdefault(o, {})
    if k == "__code":
        rec["code_len"] = len(r[2:]) // 2 if isinstance(r, str) else r
    elif isinstance(r, dict):
        rec[k] = r
    elif r is None or r == "0x":
        rec[k] = None
    elif k in ("name", "symbol"):
        rec[k] = dec_str(r)
    elif k in ADDR_KEYS:
        rec[k] = dec_addr(r)
    else:
        rec[k] = dec_uint(r)
for o, rec in out.items():
    print(o, json.dumps(rec)[:400], flush=True)

with open(os.path.join(os.path.dirname(__file__), "owner_probe.json"), "w") as f:
    json.dump({"block": BLOCK, "owners": out}, f, indent=1)
print("saved owner_probe.json")
