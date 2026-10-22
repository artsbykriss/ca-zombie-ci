#!/usr/bin/env python3
"""Dump live BSC state for BTCX / NS / DMD (tokens + PancakeV2 pairs).
Read-only eth_call via keyless public RPC. Saves state.json.
"""
import json, urllib.request, os

RPC = os.environ.get("BSC_PUBLIC_RPC", "https://bsc-rpc.publicnode.com")


def call(m, p):
    b = json.dumps({"jsonrpc": "2.0", "id": 1, "method": m, "params": p}).encode()
    r = urllib.request.Request(RPC, data=b, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.loads(urllib.request.urlopen(r, timeout=30).read())


def hexcall(to, data):
    try:
        return call("eth_call", [{"to": to, "data": data}, "latest"]).get("result")
    except Exception as e:
        return "ERR:" + str(e)


def addr_word(r):
    if not r or r.startswith("ERR"):
        return r
    return "0x" + r[-40:]


def num(r):
    if not r or r.startswith("ERR"):
        return r
    return int(r, 16)


TOK = {
    "BTCX": "0xb1939843fb9220719d13076dceefb0aeaef06666",
    "NS": "0x33f1c4fbb7e4e040f4f4e6bc492e4fedf750fd41",
    "DMD": "0x939df4a5a5022037bb33102c6489e774e063b160",
}
PAIR = {
    "BTCX": "0x3cc292bb0011951f3151eb998816c31680a2ce87",
    "NS": "0xf1a5896d91c1e2372b159455ad013b2d17c0bb0b",
    "DMD": "0x29f9148a8518e327e8677ba21c3fa3a55dd1e6bc",
}
SEL = {
    "name": "0x06fdde03", "symbol": "0x95d89b41", "decimals": "0x313ce567",
    "totalSupply": "0x18160ddd", "token0": "0x0dfe1681", "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac", "owner": "0x8da5cb5b", "admin": "0xf851a440",
    "sync": "0xfff6cae9", "skim": "0xbc25cf77",
}

out = {"block": int(call("eth_blockNumber", [])["result"], 16), "rpc": "publicnode (keyless)"}
for k, t in TOK.items():
    p = PAIR[k]
    d = {}
    d["token"] = t
    d["pair"] = p
    d["decimals"] = num(hexcall(t, SEL["decimals"]))
    d["totalSupply"] = num(hexcall(t, SEL["totalSupply"]))
    d["token0"] = addr_word(hexcall(p, SEL["token0"]))
    d["token1"] = addr_word(hexcall(p, SEL["token1"]))
    res = hexcall(p, SEL["getReserves"])
    if res and not res.startswith("ERR"):
        d["reserve0"] = int(res[2:66], 16)
        d["reserve1"] = int(res[66:130], 16)
        d["blockTimestampLast"] = int(res[130:194], 16)
    d["token_bal_pair"] = num(hexcall(t, "0x70a08231" + "0" * 24 + p[2:]))
    d["owner"] = addr_word(hexcall(t, SEL["owner"]))
    d["admin"] = addr_word(hexcall(t, SEL["admin"]))
    # token balances of notable addresses
    for label, a in [("dead", "0x000000000000000000000000000000000000dead"),
                     ("zero", "0x0000000000000000000000000000000000000000")]:
        d["bal_" + label] = num(hexcall(t, "0x70a08231" + "0" * 24 + a[2:]))
    out[k] = d

json.dump(out, open(os.path.join(os.path.dirname(__file__), "state.json"), "w"), indent=1)
print(json.dumps(out, indent=1))
