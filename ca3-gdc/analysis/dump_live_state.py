#!/usr/bin/env python3
"""Dump the live GDC state as JSON. Usage: dump_live_state.py <rpc_url>
The RPC URL is passed by the caller; this file contains no secrets."""
import json
import sys
import urllib.request

RPC = sys.argv[1]
T = "0x39a90d082e19bD2AC30DA6964D3d2FDa50077777"
P = "0xe3349Ca6AC1656e02B20b8d5a4C095e28255eb0A"
M = "0x8955Be303f033a837f7C3c407e0B2b3f9bC4fD5C"
D = "0x3cf55c7c22C6555139c818aB7a7a89aFf70F8360"
W = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
SEL = {
    "getReserves": "0x0902f1ac", "token0": "0x0dfe1681", "token1": "0xd21220a7",
    "balanceOf": "0x70a08231", "maxSellAmount": "0x66d602ae", "currentStage": "0x5bf5d54c",
    "reserveDistributor": "0xac1b0deb", "depositContract": "0xe94ad65b",
    "companyAccount": "0x642a833f", "rewardAccount": "0x0e708203", "totalSupply": "0x18160ddd",
}


def pad(a):
    return "0" * 24 + a[2:].lower()


def rpc(method, params):
    req = urllib.request.Request(
        RPC,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json"},
    )
    r = json.load(urllib.request.urlopen(req, timeout=40))
    if "error" in r:
        raise RuntimeError(r["error"])
    return r["result"]


def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])


out = {
    "block": int(rpc("eth_blockNumber", []), 16),
    "token": T, "pair": P, "main": M, "distributor": D, "wbnb": W,
    "note": "eth_call at latest; all values are raw wei (18 decimals on both sides)",
    "state": {},
}
s = out["state"]
r = call(P, SEL["getReserves"])
assert r.startswith("0x") and len(r) >= 194, r
s["reserve0_gdc_wei"] = int(r[2:66], 16)
s["reserve1_wbnb_wei"] = int(r[66:130], 16)
s["blockTimestampLast"] = int(r[130:194], 16)
s["reserve0_gdc"] = s["reserve0_gdc_wei"] / 1e18
s["reserve1_wbnb"] = s["reserve1_wbnb_wei"] / 1e18
s["token0"] = "0x" + call(P, SEL["token0"])[26:]
s["token1"] = "0x" + call(P, SEL["token1"])[26:]
s["wbnb_balance_of_pair_wei"] = int(call(W, SEL["balanceOf"] + pad(P)), 16)
s["wbnb_decimals"] = int(call(W, "0x313ce567"), 16)
s["gdc_decimals"] = int(call(T, "0x313ce567"), 16)
for name, to in [
    ("maxSellAmount", T), ("currentStage", T), ("reserveDistributor", T),
    ("depositContract", T), ("companyAccount", T), ("rewardAccount", T),
    ("totalSupply", T),
]:
    h = call(to, SEL[name])
    v = int(h, 16)
    s[name] = ("0x" + h[26:]) if name in (
        "reserveDistributor", "depositContract", "companyAccount", "rewardAccount") else v
s["distributor_gdc_wei"] = int(call(T, SEL["balanceOf"] + pad(D)), 16)
s["main_gdc_wei"] = int(call(T, SEL["balanceOf"] + pad(M)), 16)
s["dead_gdc_wei"] = int(call(T, SEL["balanceOf"] + pad("0x000000000000000000000000000000000000dEaD")), 16)
print(json.dumps(out, indent=2))
