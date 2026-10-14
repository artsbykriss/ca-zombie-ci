#!/usr/bin/env python3
"""Token + contract metadata reads on Kaia at pinned block (parallel)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from kaia_rpc import rpc, rpc_many, dec_uint, dec_str, dec_addr, sel

BLOCK = int(sys.argv[1]) if len(sys.argv) > 1 else None
if BLOCK is None:
    BLOCK = int(rpc("eth_blockNumber", []), 16)
print(f"block={BLOCK}")
BH = hex(BLOCK)

TOKENS = [
    "0x5c74070fdea071359b86082bd9f9b3deaafbe32b",
    "0x754288077d0ff82af7a5317c7cb8c444d421d103",
    "0x4fa62f1f404188ce860c8f0041d6ac3765a72e67",
    "0xce40569d65106c32550626822b91565643c07823",
    "0x807c4e063eb0ac21e8eef7623a6ed50a8ede58ca",
    "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167",
    "0x168439b5eebe8c83db9eef44a0d76c6f54767ae4",
]
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

out = {"block": BLOCK, "tokens": {}, "owners": {}}

# token metadata
calls, keys = [], []
for t in TOKENS:
    for sig4 in ["0x06fdde03", "0x95d89b41", "0x313ce567", "0x18160ddd"]:
        calls.append(("eth_call", [{"to": t, "data": sig4}, BH])); keys.append((t, sig4))
    calls.append(("eth_getCode", [t, BH])); keys.append((t, "code"))
res = rpc_many(calls)
for (t, k), r in zip(keys, res):
    rec = out["tokens"].setdefault(t, {"address": t})
    if k == "0x06fdde03": rec["name"] = dec_str(r)
    elif k == "0x95d89b41": rec["symbol"] = dec_str(r)
    elif k == "0x313ce567": rec["decimals"] = dec_uint(r)
    elif k == "0x18160ddd": rec["totalSupply"] = dec_uint(r)
    elif k == "code": rec["code_len"] = len(r[2:]) // 2 if isinstance(r, str) else r
for t, rec in out["tokens"].items():
    print(t, rec.get("symbol"), rec.get("decimals"), "supply", rec.get("totalSupply"), "code", rec.get("code_len"))

ROLE_SIGS = {
    "owner()": "0x8da5cb5b",
    "admin()": "0xf851a440",
    "governance()": "0x5aa6e675",
    "pendingOwner()": "0xe30c3978",
    "paused()": "0x5c975abb",
    "operator()": "0x570ca735",
    "controller()": "0xf77c4791",
    "stakingToken()": "0x72f702f3",
    "want()": "0x1f1fcd51",
    "token()": "0xfc0c546a",
    "vault()": "0xfbfa77cf",
    "proxyAdmin()": "0x204e1c7a",
    "implementation()": "0x5c60da1b",
    "strategy()": "0xa8c62d78",
    "getOwner()": "0x893d20e8",
    "rewardToken()": "0xf7c618c1",
    "stakingContract()": "0xbab4ca3b",
    "name()": "0x06fdde03",
    "totalSupply()": "0x18160ddd",
    "depositToken()": "0x2f9b3453",
    "underlying()": "0x6f307dc3",
    "lpToken()": "0x964b6a72",
    "rewardPool()": "0x6f5f9e6b",
    "staking()": "0x4cf088d9",
}
ADDR_KEYS = {"owner()", "admin()", "governance()", "pendingOwner()", "operator()", "controller()",
             "proxyAdmin()", "implementation()", "getOwner()", "token()", "vault()", "strategy()",
             "stakingToken()", "want()", "rewardToken()", "stakingContract()", "depositToken()",
             "underlying()", "lpToken()", "rewardPool()", "staking()"}

calls, keys = [], []
for o in OWNERS:
    calls.append(("eth_getCode", [o, BH])); keys.append((o, "code"))
    for k, s in ROLE_SIGS.items():
        calls.append(("eth_call", [{"to": o, "data": s}, BH])); keys.append((o, k))
res = rpc_many(calls)
for (o, k), r in zip(keys, res):
    rec = out["owners"].setdefault(o, {"address": o, "roles": {}})
    if k == "code":
        rec["code_len"] = len(r[2:]) // 2 if isinstance(r, str) else r
    else:
        if isinstance(r, dict):
            rec["roles"][k] = r
        elif r is None or r == "0x":
            rec["roles"][k] = None
        elif k in ADDR_KEYS:
            rec["roles"][k] = dec_addr(r)
        elif k in ("paused()", "totalSupply()"):
            rec["roles"][k] = dec_uint(r)
        elif k == "name()":
            rec["roles"][k] = dec_str(r)
        else:
            rec["roles"][k] = r
for o, rec in out["owners"].items():
    print(o, "code", rec.get("code_len"), json.dumps(rec["roles"])[:260])

with open(os.path.join(os.path.dirname(__file__), "state_metadata.json"), "w") as f:
    json.dump(out, f, indent=1)
print("saved state_metadata.json")
